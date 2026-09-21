# Jobe Sandbox & CodeRunner Parser Internals

This reference explains the internal architecture and parsing mechanics of **Moodle CodeRunner** and its execution backend **Jobe**, specifically focusing on Java questions such as `java_class` and `java_method`.

---

## 1. The Grading Architecture

The grading workflow spans two distinct systems:
1. **Moodle Web Server** running the `qtype_coderunner` plugin (PHP).
2. **Jobe Sandbox Server** running as a separate service or container (PHP / C runguard).

```text
+-------------------------------------------------------------+
| Moodle Web Server (qtype_coderunner)                        |
|                                                             |
| 1. Student pastes Java code into text box                   |
| 2. Twig template compiles answer:                           |
|    - Demotes: "public class Foo" -> "class Foo"             |
|    - Appends: public class __tester__ { ... runTests(); }   |
| 3. CodeRunner Sandbox Driver (classes/jobesandbox.php):     |
|    - Calls get_main_class($sourcecode)                      |
|    - If found: progname = "$mainclass.java"                 |
|    - If false: progname = "NO_PUBLIC_CLASS_FOUND.java"      |
| 4. Sends JSON runspec to Jobe REST API                      |
+-------------------------------------------------------------+
                              |
                              v HTTP POST /jobe/index.php/restapi/runs
+-------------------------------------------------------------+
| Jobe Sandbox Server (app/Libraries/JavaTask.php)            |
|                                                             |
| 1. Extracts source code and filename from JSON              |
| 2. Writes file to temporary directory in sandbox            |
| 3. Invokes javac:                                           |
|    /usr/bin/javac <progname>                                |
| 4. Invokes java via runguard:                               |
|    /usr/bin/java -Xrs -Xss8m -Xmx200m <mainclass>           |
| 5. Returns stdout, stderr, and exit status as JSON          |
+-------------------------------------------------------------+
```

---

## 2. The Twig Template (`java_class`)

In `db/builtin_PROTOTYPES.xml` (BUILT_IN_PROTOTYPE_java_class), the question template defines how the compilation unit is assembled:

```twig
{{ STUDENT_ANSWER | replace({'public class ': 'class '}) }}

public class __tester__ {
    public static void main(String[] args) {
        __tester__ main = new __tester__();
        main.runTests();
    }

    public void runTests() {
        {{ TEST.testcode }};
    }
}
```

### Critical Observation on Twig Replacement
- The Twig filter `replace({'public class ': 'class '})` performs an **exact character-for-character substring replacement**.
- If the student writes `public   class Foo` (with two spaces) or `public\nclass Foo`, the filter **fails to match**.
- In that scenario, the resulting file contains *two* public classes (`public class Foo` and `public class __tester__`), causing immediate `javac` compilation failure.

---

## 3. The `get_main_class` Parser in `classes/jobesandbox.php`

Before dispatching code to Jobe, CodeRunner must determine what name to give the source file. For Java, this is governed by `classes/jobesandbox.php`:

```php
// classes/jobesandbox.php lines 193-199
if ($language === 'java') {
    $mainclass = $this->get_main_class($sourcecode);
    if ($mainclass) {
        $progname = "$mainclass.$language";
    } else {
        $progname = 'NO_PUBLIC_CLASS_FOUND.java';  // I give up. Over to the sandbox. Will probably fail.
    }
} else {
    $progname = "__tester__.$language";
}
```

### Parser Algorithm Implementation (lines 340–394)

```php
private function get_main_class($prog) {
    $prog = $prog . ' ';
    $filteredprog = [];
    $skipto = -1;
    $i = 0;
    $n = strlen($prog);

    while ($i < $n - 1) {
        if ($skipto === false) {
            break;
        }
        if ($i < $skipto) {
            $i++;
            continue;
        }
        if (substr($prog, $i, 2) === '//') {
            $idx = strpos($prog, "\n", $i + 2);
            $skipto = ($idx !== false) ? $idx : $n;
        } else if (substr($prog, $i, 2) === '/*') {
            $idx = strpos($prog, '*/', $i + 2);
            $skipto = ($idx !== false) ? $idx + 2 : $n;
            $filteredprog[] = ' ';
        } else if ($prog[$i] === '"') {
            if (preg_match('/"((\\\\.)|[^\\"])*"/', substr($prog, $i), $matches)) {
                $skipto = $i + strlen($matches[0]);
            } else {
                $skipto = false; // Aborts!
            }
        } else {
            $filteredprog[] = $prog[$i];
        }
        $i++;
    }

    // Brace depth counting & nested code blanking
    $depth = 0;
    for ($j = 0; $j < count($filteredprog); $j++) {
        if ($filteredprog[$j] === '{') {
            $depth++;
        } else if ($filteredprog[$j] === '}') {
            $depth--;
        }
        if ($filteredprog[$j] !== "\n" && $depth > 0 && !($depth === 1 && $filteredprog[$j] === '{')) {
            $filteredprog[$j] = ' ';
        }
    }

    $joined = implode('', $filteredprog);
    if (preg_match('/public\s+(\w*\s+)*class\s+(\w+)[^\w]/', $joined, $matches)) {
        return $matches[2];
    }
    return false;
}
```

---

## 4. Why Character Literals Break the Parser

Notice what the parser scans:
- `//` (single-line comments)
- `/*` (multi-line comments)
- `"` (double-quoted strings)
- It **completely ignores single-quoted character literals (`'...'`)**!

### Step-by-Step Failure Trace:

1. Student code contains:
   ```java
   if (ch == '"' || ch == '\'') {
   ```
2. Parser scans left-to-right:
   - Sees `'`. Not a comment, not `"`. Adds `'` to `$filteredprog`.
   - Sees `"`. It matches `$prog[$i] === '"'`.
   - The parser assumes this is the start of a String literal!
3. The regex `/"((\\.)|[^\\"])*"/` tries to find the closing quote:
   - What follows `"` in the buffer is: `' || ch == '\'' ...`.
   - The unescaped `'` and escaped `\'` interact with the regex. If the regex cannot find an unescaped matching `"`, `preg_match` returns 0.
   - `$skipto` is set to `false`.
4. The scanner hits:
   ```php
   if ($skipto === false) {
       break;
   }
   ```
5. **The loop aborts prematurely!**
   - The remainder of the student code is never added to `$filteredprog`.
   - Crucially, the closing braces `}` of methods and the class are never added.
6. **Brace Depth Corruption:**
   - The brace counter evaluates `$filteredprog` up to the crash point.
   - `$depth` might be 2, 3, or 5 when the loop ends.
7. **`__tester__` Masking:**
   - Because `$depth > 0`, any text (including `public class __tester__`) is blanked out with spaces:
     `$filteredprog[$j] = ' ';`
8. **Failure & Javac Crash:**
   - Regex cannot find `public class`.
   - Returns `false`.
   - File saved as `NO_PUBLIC_CLASS_FOUND.java`.
   - `javac NO_PUBLIC_CLASS_FOUND.java` fails with:
     `error: class __tester__ is public, should be declared in a file named __tester__.java`.

---

## 5. Summary of Scanner Pitfalls

| Syntax in Java | Scanner Behavior | Impact |
| :--- | :--- | :--- |
| `ch == '"'` | Mistaken for unclosed String literal | Desynchronizes scanner, `$depth > 0`, breaks build |
| `ch == '\''` | Can cause quote confusion in broken regex | Potential string scanner desynchronization |
| `public   class` | Fails exact Twig string match | Two public classes in one file; javac rejects |
| Unbalanced `{` in comments | Stripped by comment cleaner | Safe (comments are cleanly stripped) |
| Unbalanced `{` in strings | Handled if string regex succeeds | Risky if string contains complex escape sequences |
| Multi-file public classes | Java allows only 1 public class per file | Illegal in `java_class` prototype |
