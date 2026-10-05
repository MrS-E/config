#!/usr/bin/env python3
"""Annotate Fedora RPM manifest packages required by other listed packages."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


class ManifestDependencyError(Exception):
    """Raised when graph or manifest data cannot be read or validated."""


def _required_string(value: object, field: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ManifestDependencyError(f"{field} must be a non-empty string")
    return value


def load_graph(path: Path) -> tuple[dict[str, str], tuple[tuple[str, str], ...]]:
    """Read and validate a schema-version-1 dependency graph export."""
    try:
        with path.open(encoding="utf-8") as graph_file:
            data = json.load(graph_file)
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ManifestDependencyError(
            f"cannot read graph JSON {path}: {error}"
        ) from error

    if not isinstance(data, dict):
        raise ManifestDependencyError("graph JSON must be an object")
    schema_version = data.get("schema_version")
    if type(schema_version) is not int or schema_version != 1:
        raise ManifestDependencyError(
            f"unsupported schema_version {schema_version!r}; expected 1"
        )

    nodes = data.get("nodes")
    edges = data.get("edges")
    if not isinstance(nodes, list):
        raise ManifestDependencyError("graph nodes must be an array")
    if not isinstance(edges, list):
        raise ManifestDependencyError("graph edges must be an array")

    node_names: dict[str, str] = {}
    for index, node in enumerate(nodes):
        field = f"nodes[{index}]"
        if not isinstance(node, dict):
            raise ManifestDependencyError(f"{field} must be an object")

        node_id = _required_string(node.get("id"), f"{field}.id")
        name = _required_string(node.get("name"), f"{field}.name")
        if "\n" in name or "\r" in name:
            raise ManifestDependencyError(f"{field}.name must be a single-line string")
        _required_string(node.get("version"), f"{field}.version")

        architectures = node.get("architectures")
        if not isinstance(architectures, list) or any(
            not isinstance(architecture, str) or not architecture.strip()
            for architecture in architectures
        ):
            raise ManifestDependencyError(
                f"{field}.architectures must be an array of strings"
            )

        reason = _required_string(node.get("reason"), f"{field}.reason")
        if reason not in {"user-installed", "dependency"}:
            raise ManifestDependencyError(
                f"{field}.reason must be 'user-installed' or 'dependency'"
            )
        if node_id in node_names:
            raise ManifestDependencyError(f"{field}.id duplicates node id {node_id!r}")
        node_names[node_id] = name

    graph_edges = []
    for index, edge in enumerate(edges):
        field = f"edges[{index}]"
        if not isinstance(edge, dict):
            raise ManifestDependencyError(f"{field} must be an object")
        source = _required_string(edge.get("from"), f"{field}.from")
        target = _required_string(edge.get("to"), f"{field}.to")
        for node_id in (source, target):
            if node_id not in node_names:
                raise ManifestDependencyError(
                    f"{field} references unknown node id {node_id!r}"
                )
        graph_edges.append((source, target))

    return node_names, tuple(graph_edges)


def read_manifest(path: Path) -> str:
    """Read a manifest without normalizing its line endings."""
    try:
        with path.open(encoding="utf-8", newline="") as manifest_file:
            return manifest_file.read()
    except (OSError, UnicodeError) as error:
        raise ManifestDependencyError(f"cannot read manifest {path}: {error}") from error


def required_by_manifest_packages(
    node_names: dict[str, str],
    graph_edges: tuple[tuple[str, str], ...],
    manifest_packages: set[str],
) -> dict[str, set[str]]:
    """Map each listed dependency to distinct listed packages that require it."""
    required_by: dict[str, set[str]] = {}
    for source_id, target_id in graph_edges:
        source_name = node_names[source_id]
        target_name = node_names[target_id]
        if (
            source_name != target_name
            and source_name in manifest_packages
            and target_name in manifest_packages
        ):
            required_by.setdefault(target_name, set()).add(source_name)
    return required_by


def _line_parts(line: str) -> tuple[str, str]:
    if line.endswith("\r\n"):
        return line[:-2], "\r\n"
    if line.endswith(("\n", "\r")):
        return line[:-1], line[-1:]
    return line, ""


def annotate_manifest(
    content: str, required_by: dict[str, set[str]]
) -> tuple[str, set[str], set[str]]:
    """Add full-line comments after packages with direct in-manifest dependents."""
    output_lines = []
    manifest_packages: set[str] = set()
    annotated_packages: set[str] = set()

    for line in content.splitlines(keepends=True):
        line_content, line_ending = _line_parts(line)
        output_lines.append(line)

        package_name = line_content.strip()
        if not package_name or package_name.startswith("#"):
            continue

        manifest_packages.add(package_name)
        requiring_packages = sorted(required_by.get(package_name, set()))
        if not requiring_packages:
            continue

        comment_ending = line_ending or "\n"
        if not line_ending:
            output_lines[-1] += comment_ending
        output_lines.append(
            "# Required by manifest packages: "
            f"{', '.join(requiring_packages)}{comment_ending}"
        )
        annotated_packages.add(package_name)

    return "".join(output_lines), manifest_packages, annotated_packages


def _write_output(path: Path, content: str) -> None:
    try:
        with path.open("w", encoding="utf-8", newline="") as output_file:
            output_file.write(content)
    except OSError as error:
        raise ManifestDependencyError(f"cannot write {path}: {error}") from error


def _paths_collide(first: Path, second: Path) -> bool:
    return first.resolve() == second.resolve()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Create a copy of a Fedora RPM manifest annotated with packages "
            "directly required by other packages in that manifest."
        )
    )
    parser.add_argument(
        "--graph-json",
        required=True,
        type=Path,
        metavar="PATH",
        help="schema-v1 graph export",
    )
    parser.add_argument(
        "--manifest",
        required=True,
        type=Path,
        metavar="PATH",
        help="package manifest to read",
    )
    parser.add_argument(
        "--output",
        required=True,
        type=Path,
        metavar="PATH",
        help="annotated manifest to write",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if _paths_collide(args.graph_json, args.manifest):
        parser.error("--graph-json and --manifest must refer to different files")
    if _paths_collide(args.output, args.graph_json) or _paths_collide(
        args.output, args.manifest
    ):
        parser.error("--output must be different from both input files")

    try:
        node_names, graph_edges = load_graph(args.graph_json)
        manifest_content = read_manifest(args.manifest)
        manifest_packages = {
            line_content.strip()
            for line_content in manifest_content.splitlines()
            if line_content.strip() and not line_content.strip().startswith("#")
        }
        required_by = required_by_manifest_packages(
            node_names, graph_edges, manifest_packages
        )
        annotated_content, manifest_packages, annotated_packages = annotate_manifest(
            manifest_content, required_by
        )
        _write_output(args.output, annotated_content)
    except ManifestDependencyError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    missing_packages = sorted(manifest_packages - set(node_names.values()))
    if missing_packages:
        print(
            "warning: manifest packages absent from graph: "
            f"{', '.join(missing_packages)}",
            file=sys.stderr,
        )
    print(f"Wrote {args.output}; annotated {len(annotated_packages)} package(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())