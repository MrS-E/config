# Upstream CodeRunner & Jobe Repositories

This reference provides links and inspection recipes for the upstream repositories that power Moodle CodeRunner and the Jobe Sandbox.

---

## 1. Primary Repositories

### Moodle CodeRunner Question Type Plugin
- **GitHub Repository**: [https://github.com/trampgeek/moodle-qtype_coderunner](https://github.com/trampgeek/moodle-qtype_coderunner)
- **Principal Author**: Richard Lobb, University of Canterbury
- **Moodle Plugin Entry**: [https://moodle.org/plugins/qtype_coderunner](https://moodle.org/plugins/qtype_coderunner)
- **Official Documentation**: [https://trampgeek.github.io/moodle-qtype_coderunner](https://trampgeek.github.io/moodle-qtype_coderunner)

#### Key Source Files
1. **`classes/jobesandbox.php`**:
   - Lines 193–203: Filename selection and fallback to `NO_PUBLIC_CLASS_FOUND.java`.
   - Lines 340–394: `get_main_class($prog)` PHP implementation (string scanner, brace nesting counter, class regex).
   - [jobesandbox.php on GitHub](https://github.com/trampgeek/moodle-qtype_coderunner/blob/master/classes/jobesandbox.php)
2. **`db/builtin_PROTOTYPES.xml`**:
   - Lines 408–475: `BUILT_IN_PROTOTYPE_java_class` prototype definition, Twig replacement logic, and `public class __tester__` harness.
   - [builtin_PROTOTYPES.xml on GitHub](https://github.com/trampgeek/moodle-qtype_coderunner/blob/master/db/builtin_PROTOTYPES.xml)
3. **`question.php`**:
   - Core grading lifecycle and test runner dispatch.

---

### Jobe Sandbox Engine
- **GitHub Repository**: [https://github.com/trampgeek/jobe](https://github.com/trampgeek/jobe)
- **REST API Specification**: [https://github.com/trampgeek/jobe/blob/master/restapi.pdf](https://github.com/trampgeek/jobe/blob/master/restapi.pdf)

#### Key Source Files
1. **`app/Libraries/JavaTask.php`**:
   - Lines 45–95: Java task compiler configuration, memory limits, and `/usr/bin/javac` execution.
   - Lines 101–118: `getMainClass($prog)` fallback regex scanner.
   - [JavaTask.php on GitHub](https://github.com/trampgeek/jobe/blob/master/app/Libraries/JavaTask.php)
2. **`app/Libraries/LanguageTask.php`**:
   - Base class for all compilation and sandbox execution tasks.
3. **`runguard/`**:
   - C sandbox daemon enforcing resource constraints (CPU timeout, RAM, disk quotas).

---

### Companion Plugin: Adaptive Behaviour for CodeRunner
- **GitHub Repository**: [https://github.com/trampgeek/moodle-qbehaviour_adaptive_adapted_for_coderunner](https://github.com/trampgeek/moodle-qbehaviour_adaptive_adapted_for_coderunner)
- Manages question attempt state, penalty deductions, and sandbox result caching.

---

## 2. CLI Inspection Recipes

If an agent needs to inspect upstream logic in a non-interactive shell without cloning:

```bash
# 1. View the get_main_class() parser in CodeRunner
curl -s https://raw.githubusercontent.com/trampgeek/moodle-qtype_coderunner/master/classes/jobesandbox.php | sed -n '340,395p'

# 2. View the NO_PUBLIC_CLASS_FOUND dispatch branch
curl -s https://raw.githubusercontent.com/trampgeek/moodle-qtype_coderunner/master/classes/jobesandbox.php | sed -n '193,203p'

# 3. View the built-in java_class Twig template and __tester__ harness
curl -s https://raw.githubusercontent.com/trampgeek/moodle-qtype_coderunner/master/db/builtin_PROTOTYPES.xml | grep -n -C 15 "BUILT_IN_PROTOTYPE_java_class"

# 4. View Jobe JavaTask compilation and execution logic
curl -s https://raw.githubusercontent.com/trampgeek/jobe/master/app/Libraries/JavaTask.php | sed -n '45,115p'
```
