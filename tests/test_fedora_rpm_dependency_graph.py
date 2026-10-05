#!/usr/bin/env python3
"""Unit tests for the Fedora RPM dependency graph CLI."""

import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = REPO_ROOT / "scripts" / "fedora-rpm-dependency-graph.py"
FIXTURE_PATH = REPO_ROOT / "tests" / "fixtures" / "fedora-rpm-dependency-graph.json"

sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location("fedora_rpm_dependency_graph", SCRIPT_PATH)
GRAPH_TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = GRAPH_TOOL
SPEC.loader.exec_module(GRAPH_TOOL)


class FedoraRpmDependencyGraphTest(unittest.TestCase):
    def test_build_graph_traverses_closure_merges_arches_and_handles_cycles(self):
        graph = GRAPH_TOOL.load_fixture(FIXTURE_PATH)
        nodes = {node.id: node for node in graph.nodes}

        self.assertEqual(
            set(nodes),
            {
                "editor@1:2.0-1.fc40",
                "libeditor@0.9-2.fc40",
                "glibc@2.39-1.fc40",
            },
        )
        self.assertEqual(
            nodes["editor@1:2.0-1.fc40"].architectures, ("i686", "x86_64")
        )
        self.assertEqual(nodes["editor@1:2.0-1.fc40"].reason, "user-installed")
        self.assertEqual(nodes["libeditor@0.9-2.fc40"].reason, "dependency")
        self.assertEqual(len(graph.edges), 3)
        self.assertNotIn(
            GRAPH_TOOL.GraphEdge("glibc@2.39-1.fc40", "glibc@2.39-1.fc40"),
            graph.edges,
        )

    def test_build_graph_rejects_user_installed_root_missing_from_rpm_data(self):
        with self.assertRaisesRegex(
            GRAPH_TOOL.GraphError, "missing from installed RPM data"
        ):
            GRAPH_TOOL.build_graph([], {("missing", "1-1")})

    def test_load_fixture_reports_malformed_json(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            fixture_path = Path(temporary_directory) / "malformed.json"
            fixture_path.write_text("{", encoding="utf-8")

            with self.assertRaisesRegex(
                GRAPH_TOOL.GraphError, "could not read fixture"
            ):
                GRAPH_TOOL.load_fixture(fixture_path)

    def test_json_and_dot_export_the_same_nodes_and_edges(self):
        graph = GRAPH_TOOL.load_fixture(FIXTURE_PATH)
        json_data = json.loads(GRAPH_TOOL.graph_to_json(graph))
        dot_data = GRAPH_TOOL.graph_to_dot(graph)

        self.assertEqual(
            {node["id"] for node in json_data["nodes"]},
            {node.id for node in graph.nodes},
        )
        self.assertEqual(
            {(edge["from"], edge["to"]) for edge in json_data["edges"]},
            {(edge.source, edge.target) for edge in graph.edges},
        )
        self.assertIn('"editor@1:2.0-1.fc40" -> "libeditor@0.9-2.fc40";', dot_data)
        self.assertIn("user-installed", dot_data)
        self.assertIn("arch: i686, x86_64", dot_data)

    def test_cli_writes_both_named_outputs_from_fixture(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            output_directory = Path(temporary_directory)
            dot_path = output_directory / "graph.dot"
            json_path = output_directory / "graph.json"

            result = GRAPH_TOOL.main(
                [
                    "--fixture-json",
                    str(FIXTURE_PATH),
                    "--dot",
                    str(dot_path),
                    "--json",
                    str(json_path),
                ]
            )

            self.assertEqual(result, 0)
            self.assertTrue(dot_path.is_file())
            self.assertTrue(json_path.is_file())
            self.assertEqual(
                len(json.loads(json_path.read_text(encoding="utf-8"))["nodes"]), 3
            )

    def test_cli_reports_unwritable_output_path(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            json_path = Path(temporary_directory) / "missing-directory" / "graph.json"
            stderr = io.StringIO()

            with contextlib.redirect_stderr(stderr):
                result = GRAPH_TOOL.main(
                    ["--fixture-json", str(FIXTURE_PATH), "--json", str(json_path)]
                )

            self.assertEqual(result, 1)
            self.assertIn("cannot write", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()