#!/usr/bin/env python3
"""
Moodle CodeRunner Java Submission Verifier.
Simulates the exact CodeRunner Twig template and Jobe sandbox PHP parser (get_main_class)
to verify whether a Java file will compile cleanly without 'NO_PUBLIC_CLASS_FOUND.java' errors.
"""

import sys
import os
import re
import argparse

def simulate_coderunner_filter(source_code: str):
    """
    Simulates CodeRunner's Twig template transformation:
    {{ STUDENT_ANSWER | replace({'public class ': 'class '}) }}
    and appends the test harness:
    public class __tester__ { ... }
    """
    demoted = source_code.replace("public class ", "class ")
    combined = demoted + "\n\npublic class __tester__ {\n    public static void main(String[] args) {}\n}\n"
    return combined

def jobe_get_main_class(prog: str):
    """
    Exact replication of CodeRunner classes/jobesandbox.php get_main_class($prog).
    Returns (detected_class_name, final_depth, quote_desync).
    """
    prog = prog + ' '
    filteredprog = []
    skipto = -1
    i = 0
    n = len(prog)

    quote_desync = False

    while i < n - 1:
        if skipto is False:
            quote_desync = True
            break
        if i < skipto:
            i += 1
            continue
        if prog[i:i+2] == '//':
            idx = prog.find('\n', i + 2)
            skipto = idx if idx != -1 else n
        elif prog[i:i+2] == '/*':
            idx = prog.find('*/', i + 2)
            skipto = (idx + 2) if idx != -1 else n
            filteredprog.append(' ')
        elif prog[i] == '"':
            m = re.match(r'"((\\.)|[^\"])*"', prog[i:])
            if m:
                skipto = i + len(m.group(0))
            else:
                skipto = False
        else:
            filteredprog.append(prog[i])
        i += 1

    depth = 0
    for j in range(len(filteredprog)):
        if filteredprog[j] == '{':
            depth += 1
        elif filteredprog[j] == '}':
            depth -= 1
        if filteredprog[j] != '\n' and depth > 0 and not (depth == 1 and filteredprog[j] == '{'):
            filteredprog[j] = ' '

    joined = "".join(filteredprog)
    m = re.search(r'public\s+(\w*\s+)*class\s+(\w+)[^\w]', joined)
    main_class = m.group(2) if m else None
    return main_class, depth, quote_desync

def scan_anti_patterns(source_code: str):
    """
    Scans for patterns known to break CodeRunner's PHP parser or Twig template.
    """
    warnings = []
    lines = source_code.splitlines()

    for line_idx, line in enumerate(lines, 1):
        # 1. Double quote char literal: '"' or '\"'
        if re.search(r"'(?:\\\"|\")'", line):
            warnings.append(
                f"Line {line_idx}: Contains double-quote char literal ('\"'). "
                f"Replace with '34' or '(char) 34'. The PHP parser mistakes this for an unclosed string."
            )
        # 2. Single quote char literal: '\''
        if re.search(r"'\\''", line):
            warnings.append(
                f"Line {line_idx}: Contains single-quote char literal ('\\''). "
                f"Prefer '39' or '(char) 39' to prevent quote desynchronization."
            )
        # 3. Non-standard public class whitespace
        if re.search(r"public\s{2,}class\b", line):
            warnings.append(
                f"Line {line_idx}: Non-standard spacing in 'public class'. "
                f"CodeRunner expects exactly 'public class ' (one space) for Twig demotion."
            )

    return warnings

def verify_file(filepath_or_content: str, is_content: bool = False):
    if is_content:
        content = filepath_or_content
        filename = "<stdin>"
    else:
        filename = filepath_or_content
        with open(filepath_or_content, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()

    print(f"=== Verifying {filename} for Moodle CodeRunner ===")

    # 1. Static pattern check
    anti_patterns = scan_anti_patterns(content)
    if anti_patterns:
        print("\n[!] Static Anti-Pattern Warnings:")
        for w in anti_patterns:
            print(f"  - {w}")
    else:
        print("[+] No known regex/literal anti-patterns detected.")

    # 2. Check for public class declaration in student code
    has_public_class = bool(re.search(r"\bpublic\s+class\s+(\w+)", content))
    if not has_public_class:
        print("[!] Note: No 'public class <Name>' found in student code. For 'java_class' questions, code must include a public class.")

    # 3. Simulate CodeRunner + Jobe execution
    assembled = simulate_coderunner_filter(content)
    detected_class, final_depth, quote_desync = jobe_get_main_class(assembled)

    print("\n--- Jobe Sandbox Simulation Results ---")
    print(f"Quote Lexer Desync : {'YES (FAILED)' if quote_desync else 'NO (OK)'}")
    print(f"Final Brace Depth  : {final_depth} (expected 0 before harness)")
    print(f"Detected Main Class: {detected_class}")

    if detected_class == "__tester__":
        print("\n[SUCCESS] CodeRunner simulation PASSED. Class '__tester__' was properly recognized.")
        print("          Jobe will compile this file as '__tester__.java'.")
        return 0
    else:
        print("\n[FAILURE] CodeRunner simulation FAILED!")
        print("          Jobe will fall back to 'NO_PUBLIC_CLASS_FOUND.java' and javac will fail with:")
        print("          'error: class __tester__ is public, should be declared in a file named __tester__.java'")
        return 1

def main():
    parser = argparse.ArgumentParser(description="Verify Java code against Moodle CodeRunner / Jobe parser.")
    parser.add_argument("file", nargs="?", help="Path to the Java source file (or omit to read stdin)")
    args = parser.parse_args()

    if args.file:
        if not os.path.isfile(args.file):
            print(f"Error: File not found: {args.file}", file=sys.stderr)
            sys.exit(2)
        sys.exit(verify_file(args.file))
    else:
        if sys.stdin.isatty():
            parser.print_help()
            sys.exit(2)
        content = sys.stdin.read()
        sys.exit(verify_file(content, is_content=True))

if __name__ == "__main__":
    main()
