---
name: moodle-coderunner
description: "Guidelines, parser bug workarounds, and verification tools for submitting Java code to Moodle CodeRunner / Jobe programming assessments. TRIGGER when: preparing, reviewing, or debugging Java code for Moodle CodeRunner submissions, encountering NO_PUBLIC_CLASS_FOUND errors, or adapting classes for online grading platforms. DO NOT TRIGGER when: working purely on local offline builds with standard Gradle/Maven without Moodle CodeRunner constraints."
---

# Moodle CodeRunner & Jobe Java Submission Guidelines

This skill provides operational rules, parser bug workarounds, and verification tools for writing Java code that compiles and runs cleanly inside the **Moodle CodeRunner** and **Jobe** automated grading sandbox.

---

## Pre-Submission Verification (Run First)

Before submitting or suggesting Java code for a Moodle CodeRunner text field, run the built-in verifier script:

```bash
python3 /home/sstix/config/junie/skills/moodle-coderunner/scripts/verify_coderunner.py <path/to/File.java>
```

Or pass code via stdin:

```bash
cat <path/to/File.java> | python3 /home/sstix/config/junie/skills/moodle-coderunner/scripts/verify_coderunner.py
```

The script replicates CodeRunner's exact Twig template transformation and Jobe's PHP lexer (`get_main_class`) to confirm that:
1. No dangerous character literals break the PHP lexer.
2. The brace nesting counter returns to 0 before the test harness.
3. The test harness class `__tester__` is successfully identified by Jobe.

---

## MUST DO

- **Use ASCII integer codes for quote characters**:
  - Use `34` or `(char) 34` instead of `'"'` or `'\\"'`.
  - Use `39` or `(char) 39` instead of `'\\''`.
- **Format `public class` with exactly one space**:
  - Write `public class MyClass` on a single line. The Twig template uses a literal string replacement `replace({'public class ': 'class '})` to demote your class.
- **Ensure strictly balanced curly braces `{ ... }`**:
  - Every `{` must have a matching `}`.
- **Keep all code in a single top-level public class**:
  - CodeRunner's `java_class` prototype compiles student code alongside an appended `public class __tester__`. Only one class in the student snippet may be `public`.
- **Run the verification script before handing back code to the user**:
  - An exit code of `0` guarantees the submission will avoid `NO_PUBLIC_CLASS_FOUND.java`.

---

## MUST NOT DO

- **NEVER use the double-quote character literal `'"'` or `'\\"'`**:
  - Jobe's lexer does not recognize single-quoted character literals; it interprets `"` as the start of a String literal, fails to find the closing quote, aborts parsing, leaves the brace depth at $> 0$, and causes `NO_PUBLIC_CLASS_FOUND.java: error: class __tester__ is public`.
- **NEVER use irregular spacing in class declarations**:
  - Do not write `public   class` (multiple spaces), `public\nclass`, or `public/*...*/class`.
- **NEVER leave unmatched braces in comments or string literals**:
  - While single-line comments `//` and multi-line comments `/* */` are stripped, unescaped `{` inside complex regex string patterns can distort depth tracking if string matching desynchronizes.
- **NEVER include `package ...;` statements in the submission box**:
  - Unless the question specifically specifies a package, CodeRunner compiles files in the default package.

---

## Safe Replacement Reference

| Unsafe Pattern (Breaks CodeRunner) | Safe Replacement | Reason |
| :--- | :--- | :--- |
| `ch == '"'` | `ch == 34` | Avoids triggering false double-quote string scan in Jobe lexer. |
| `ch == '\''` | `ch == 39` | Avoids quote escape desynchronization. |
| `String q = "\"";` | `String q = Character.toString((char) 34);` | Prevents complex quote escaping inside regexes or string templates. |
| `public   class Foo` | `public class Foo` | Twig template matches exact string `'public class '`. |
| `public final class Foo` | `class Foo` or `public class Foo` | Twig replace only strips `'public class '`, not modifiers. |

---

## The `NO_PUBLIC_CLASS_FOUND` Error Anatomy

### Symptom
Submitting valid Java code causes the Moodle test runner to abort with:

```text
NO_PUBLIC_CLASS_FOUND.java:161: error: class __tester__ is public, should be declared in a file named __tester__.java
public class __tester__ {
       ^
1 error
```

### Cause
1. CodeRunner's Twig template appends `public class __tester__` to the compilation unit.
2. Jobe's PHP driver (`classes/jobesandbox.php`) runs `get_main_class($sourcecode)` to determine the `.java` filename for `javac`.
3. If an unhandled literal (such as `'"'`) causes the lexer to desynchronize, the brace depth counter fails to reset to 0.
4. Jobe blanks out `__tester__` thinking it is an inner class.
5. Finding no public class, Jobe saves the file as `NO_PUBLIC_CLASS_FOUND.java`.
6. `javac` rejects the file because a public class named `__tester__` must reside in `__tester__.java`.

---

## Reference Guide

| Load when | File |
| :--- | :--- |
| Deep dive into Jobe PHP lexer source code, Twig templates, and step-by-step failure traces | `references/jobe_parser_internals.md` |
| Upstream GitHub repositories, permanent permalinks, and CLI inspection curl commands | `references/upstream_sources.md` |

---

## Output Format When Providing Code for CodeRunner

When generating or editing Java code intended for Moodle CodeRunner:
1. Provide the code adhering strictly to the MUST DO / MUST NOT DO rules.
2. Confirm that the verification script passed (e.g. `verify_coderunner.py` returned 0).
3. Explicitly note that quote literals have been written using ASCII codes (`34`, `39`) to prevent the known CodeRunner parser issue.
