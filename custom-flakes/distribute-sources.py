#!/usr/bin/env python3
"""Distribute nvfetcher metadata to the matching standalone flake."""

import json
import re
import sys
from pathlib import Path


ENTRY_START = re.compile(r"^  ([A-Za-z0-9][A-Za-z0-9._+-]*) = \{$")


def split_nix_sources(text):
    lines = text.splitlines(keepends=True)
    root_openings = [
        index
        for index, line in enumerate(lines)
        if line.rstrip("\r\n") == "{" and index > 0 and lines[index - 1].strip() == "}:"
    ]
    if len(root_openings) != 1:
        raise ValueError("could not find the generated.nix root attribute set")

    root_open = root_openings[0]
    closing_lines = [
        index for index, line in enumerate(lines) if line.rstrip("\r\n") == "}"
    ]
    if not closing_lines or closing_lines[-1] != len(lines) - 1:
        raise ValueError("generated.nix must end with its root attribute set")
    root_close = closing_lines[-1]

    entries = {}
    index = root_open + 1
    while index < root_close:
        line = lines[index]
        if not line.strip() or line.lstrip().startswith("#"):
            index += 1
            continue

        match = ENTRY_START.fullmatch(line.rstrip("\r\n"))
        if match is None:
            raise ValueError(f"unexpected generated.nix content: {line.rstrip()}")
        name = match.group(1)
        if name in entries:
            raise ValueError(f"duplicate generated.nix entry: {name}")

        entry_lines = [line]
        index += 1
        while index < root_close and lines[index].rstrip("\r\n") != "  };":
            entry_lines.append(lines[index])
            index += 1
        if index >= root_close:
            raise ValueError(f"unterminated generated.nix entry: {name}")
        entry_lines.append(lines[index])
        entries[name] = entry_lines
        index += 1

    wrapper = lines[: root_open + 1]
    closing = lines[root_close:]
    return {
        name: "".join(wrapper + entry_lines + closing)
        for name, entry_lines in entries.items()
    }


def main():
    if len(sys.argv) < 2:
        raise ValueError("provide at least one automated flake name")

    script_dir = Path(__file__).resolve().parent
    source_dir = script_dir / "_sources"
    nix_path = source_dir / "generated.nix"
    json_path = source_dir / "generated.json"
    nix_text = nix_path.read_text(encoding="utf-8")
    json_data = json.loads(json_path.read_text(encoding="utf-8"))
    nix_entries = split_nix_sources(nix_text)

    if not isinstance(json_data, dict) or not all(isinstance(key, str) for key in json_data):
        raise ValueError("generated.json must contain a package-keyed object")
    if set(nix_entries) != set(json_data):
        missing_json = sorted(set(nix_entries) - set(json_data))
        missing_nix = sorted(set(json_data) - set(nix_entries))
        raise ValueError(
            "generated.nix and generated.json package keys differ "
            f"(missing from JSON: {missing_json}; missing from Nix: {missing_nix})"
        )

    names = sys.argv[1:]
    if len(names) != len(set(names)):
        raise ValueError("flake names must not be repeated")
    outputs = []
    for name in names:
        if Path(name).name != name or name in ("", ".", ".."):
            raise ValueError(f"invalid flake name: {name}")
        flake_dir = script_dir / name
        if not flake_dir.is_dir() or name not in nix_entries:
            continue
        local_sources = flake_dir / "_sources"
        outputs.extend(
            [
                (local_sources / "generated.nix", nix_entries[name]),
                (
                    local_sources / "generated.json",
                    json.dumps({name: json_data[name]}, indent=4) + "\n",
                ),
            ]
        )

    for path, content in outputs:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"source distribution failed: {error}", file=sys.stderr)
        sys.exit(1)