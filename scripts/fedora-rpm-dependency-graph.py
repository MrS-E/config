#!/usr/bin/env python3
"""Export user-installed Fedora RPM packages and their dependency closure."""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict, deque
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


PackageKey = tuple[str, str]


class GraphError(Exception):
    """Raised when package metadata cannot be read or exported."""


@dataclass(frozen=True)
class PackageRecord:
    name: str
    version: str
    architecture: str
    dependencies: tuple[PackageKey, ...] = ()

    @property
    def key(self) -> PackageKey:
        return self.name, self.version


@dataclass(frozen=True)
class GraphNode:
    id: str
    name: str
    version: str
    architectures: tuple[str, ...]
    reason: str


@dataclass(frozen=True, order=True)
class GraphEdge:
    source: str
    target: str


@dataclass(frozen=True)
class PackageGraph:
    nodes: tuple[GraphNode, ...]
    edges: tuple[GraphEdge, ...]


def node_id(key: PackageKey) -> str:
    """Return a stable, unambiguous id for an RPM name and EVR pair."""
    return f"{key[0]}@{key[1]}"


def build_graph(
    packages: Iterable[PackageRecord], user_installed: Iterable[PackageKey]
) -> PackageGraph:
    """Build the reachable graph, merging packages by name and RPM EVR."""
    packages_by_key: dict[PackageKey, list[PackageRecord]] = defaultdict(list)
    for package in packages:
        if not package.name or not package.version or not package.architecture:
            raise GraphError("package name, version, and architecture must be set")
        packages_by_key[package.key].append(package)

    roots = set(user_installed)
    missing_roots = sorted(roots - packages_by_key.keys())
    if missing_roots:
        missing = ", ".join(node_id(key) for key in missing_roots)
        raise GraphError(f"user-installed packages are missing from installed RPM data: {missing}")

    pending = deque(sorted(roots))
    visited: set[PackageKey] = set()
    edge_keys: set[tuple[PackageKey, PackageKey]] = set()

    while pending:
        source = pending.popleft()
        if source in visited:
            continue
        visited.add(source)

        for package in packages_by_key[source]:
            for target in package.dependencies:
                if target not in packages_by_key or target == source:
                    continue
                edge_keys.add((source, target))
                if target not in visited:
                    pending.append(target)

    nodes = []
    for key in sorted(visited):
        records = packages_by_key[key]
        nodes.append(
            GraphNode(
                id=node_id(key),
                name=key[0],
                version=key[1],
                architectures=tuple(sorted({record.architecture for record in records})),
                reason="user-installed" if key in roots else "dependency",
            )
        )

    edges = tuple(
        sorted(GraphEdge(node_id(source), node_id(target)) for source, target in edge_keys)
    )
    return PackageGraph(tuple(nodes), edges)


def graph_to_json(graph: PackageGraph) -> str:
    """Serialize a graph as deterministic JSON."""
    data = {
        "schema_version": 1,
        "nodes": [
            {
                "id": node.id,
                "name": node.name,
                "version": node.version,
                "architectures": list(node.architectures),
                "reason": node.reason,
            }
            for node in graph.nodes
        ],
        "edges": [{"from": edge.source, "to": edge.target} for edge in graph.edges],
    }
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def _dot_quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def graph_to_dot(graph: PackageGraph) -> str:
    """Serialize a graph as Graphviz DOT."""
    lines = ["digraph rpm_dependencies {", "  rankdir=LR;"]
    for node in graph.nodes:
        label = "\n".join(
            (
                node.name,
                node.version,
                node.reason,
                f"arch: {', '.join(node.architectures)}",
            )
        )
        lines.append(f"  {_dot_quote(node.id)} [label={_dot_quote(label)}];")
    for edge in graph.edges:
        lines.append(f"  {_dot_quote(edge.source)} -> {_dot_quote(edge.target)};")
    lines.append("}")
    return "\n".join(lines) + "\n"


def _package_key(package, dnf5: bool) -> PackageKey:
    if dnf5:
        return package.get_name(), package.get_evr()
    return package.name, package.evr


def _package_architecture(package, dnf5: bool) -> str:
    return package.get_arch() if dnf5 else package.arch


def _collect_graph(installed, roots, provider_lookup, dnf5: bool) -> PackageGraph:
    records = []
    for package in installed:
        requirements = package.get_requires() if dnf5 else package.requires
        if dnf5:
            has_requirements = bool(list(requirements))
        else:
            has_requirements = bool(requirements)

        dependencies = ()
        if has_requirements:
            dependencies = tuple(
                sorted(
                    {
                        _package_key(provider, dnf5)
                        for provider in provider_lookup(package, requirements)
                    }
                )
            )

        key = _package_key(package, dnf5)
        records.append(
            PackageRecord(
                name=key[0],
                version=key[1],
                architecture=_package_architecture(package, dnf5),
                dependencies=dependencies,
            )
        )

    root_keys = {_package_key(package, dnf5) for package in roots}
    return build_graph(records, root_keys)


def _collect_dnf5_graph() -> PackageGraph:
    import libdnf5.base
    import libdnf5.repo
    import libdnf5.rpm

    try:
        base = libdnf5.base.Base()
        base.load_config()
        base.setup()

        repo_sack = base.get_repo_sack()
        repo_sack.create_repos_from_system_configuration()
        repo_sack.load_repos(libdnf5.repo.Repo.Type_SYSTEM)

        installed_query = libdnf5.rpm.PackageQuery(base)
        installed_query.filter_installed()
        root_query = libdnf5.rpm.PackageQuery(base)
        root_query.filter_userinstalled()

        def provider_lookup(_package, requirements):
            providers = libdnf5.rpm.PackageQuery(base)
            providers.filter_installed()
            providers.filter_provides(requirements)
            return providers

        return _collect_graph(
            list(installed_query), list(root_query), provider_lookup, dnf5=True
        )
    except Exception as error:
        raise GraphError(f"could not read installed RPM metadata through DNF5: {error}") from error


def _collect_dnf4_graph() -> PackageGraph:
    import dnf

    try:
        base = dnf.Base()
        base.conf.read()
        base.fill_sack(load_system_repo=True, load_available_repos=False)

        installed_query = base.sack.query().installed()
        root_query = installed_query.userinstalled(base.history.swdb)

        def provider_lookup(_package, requirements):
            return base.sack.query().installed().filter(provides=requirements)

        return _collect_graph(
            list(installed_query), list(root_query), provider_lookup, dnf5=False
        )
    except Exception as error:
        raise GraphError(f"could not read installed RPM metadata through DNF: {error}") from error


def collect_system_graph() -> PackageGraph:
    """Read the installed RPM database and DNF install reasons on Fedora."""
    if not Path("/etc/fedora-release").is_file():
        raise GraphError("this command requires Fedora with DNF-managed RPM packages")

    try:
        import libdnf5.base  # noqa: F401
        import libdnf5.repo  # noqa: F401
        import libdnf5.rpm  # noqa: F401
    except ImportError:
        try:
            import dnf  # noqa: F401
        except ImportError as error:
            raise GraphError(
                "DNF Python bindings not found; install python3-libdnf5 or python3-dnf"
            ) from error
        return _collect_dnf4_graph()

    return _collect_dnf5_graph()


def _read_package_key(value, field: str) -> PackageKey:
    if not isinstance(value, dict):
        raise GraphError(f"{field} entries must be objects with name and version fields")
    name = value.get("name")
    version = value.get("version")
    if (
        not isinstance(name, str)
        or not name
        or not isinstance(version, str)
        or not version
    ):
        raise GraphError(f"{field} entries must have non-empty string name and version fields")
    return name, version


def load_fixture(path: Path) -> PackageGraph:
    """Read normalized package records for offline CLI runs and tests."""
    try:
        with path.open(encoding="utf-8") as fixture_file:
            data = json.load(fixture_file)
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise GraphError(f"could not read fixture {path}: {error}") from error

    if not isinstance(data, dict):
        raise GraphError("fixture must be a JSON object")
    package_data = data.get("packages")
    root_data = data.get("user_installed")
    if not isinstance(package_data, list) or not isinstance(root_data, list):
        raise GraphError("fixture must contain packages and user_installed arrays")

    packages = []
    for index, item in enumerate(package_data):
        field = f"packages[{index}]"
        if not isinstance(item, dict):
            raise GraphError(f"{field} must be an object")
        key = _read_package_key(item, field)
        architecture = item.get("architecture")
        if not isinstance(architecture, str) or not architecture:
            raise GraphError(f"{field}.architecture must be a non-empty string")
        dependencies_data = item.get("dependencies", [])
        if not isinstance(dependencies_data, list):
            raise GraphError(f"{field}.dependencies must be an array")
        dependencies = tuple(
            _read_package_key(dependency, f"{field}.dependencies[{dependency_index}]")
            for dependency_index, dependency in enumerate(dependencies_data)
        )
        packages.append(PackageRecord(*key, architecture, dependencies))

    roots = {
        _read_package_key(root, f"user_installed[{index}]")
        for index, root in enumerate(root_data)
    }
    return build_graph(packages, roots)


def _write_output(path: Path, content: str) -> None:
    try:
        with path.open("w", encoding="utf-8", newline="\n") as output_file:
            output_file.write(content)
    except OSError as error:
        raise GraphError(f"cannot write {path}: {error}") from error


def _paths_collide(first: Path, second: Path) -> bool:
    return first.resolve() == second.resolve()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Export the full dependency closure of Fedora RPM packages marked "
            "user-installed by DNF."
        ),
        epilog=(
            "RPM nodes are merged by name and EVR ([epoch:]version-release); "
            "architectures are retained as node metadata."
        ),
    )
    parser.add_argument("--dot", type=Path, metavar="PATH", help="write a Graphviz DOT file")
    parser.add_argument(
        "--json", dest="json_path", type=Path, metavar="PATH", help="write a JSON file"
    )
    parser.add_argument(
        "--fixture-json",
        type=Path,
        metavar="PATH",
        help="read normalized package data from JSON instead of querying Fedora",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.dot is None and args.json_path is None:
        parser.error("at least one of --dot or --json is required")
    if (
        args.dot is not None
        and args.json_path is not None
        and _paths_collide(args.dot, args.json_path)
    ):
        parser.error("--dot and --json must refer to different files")
    if args.fixture_json is not None:
        output_paths = [path for path in (args.dot, args.json_path) if path is not None]
        if any(_paths_collide(args.fixture_json, output_path) for output_path in output_paths):
            parser.error("fixture input and output paths must be different files")

    try:
        graph = load_fixture(args.fixture_json) if args.fixture_json else collect_system_graph()
        if args.dot is not None:
            _write_output(args.dot, graph_to_dot(graph))
        if args.json_path is not None:
            _write_output(args.json_path, graph_to_json(graph))
    except GraphError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    except OSError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())