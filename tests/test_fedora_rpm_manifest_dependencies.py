#!/usr/bin/env python3
"""Unit tests for the Fedora RPM manifest dependency annotation CLI."""

import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
GRAPH_SCRIPT_PATH = REPO_ROOT / "scripts" / "fedora-rpm-dependency-graph.py"
SCRIPT_PATH = REPO_ROOT / "scripts" / "fedora-rpm-manifest-dependencies.py"
FIXTURE_PATH = REPO_ROOT / "tests" / "fixtures" / "fedora-rpm-dependency-graph.json"

sys.dont_write_bytecode = True
GRAPH_SPEC = importlib.util.spec_from_file_location(
    "fedora_rpm_dependency_graph", GRAPH_SCRIPT_PATH
)
GRAPH_TOOL = importlib.util.module_from_spec(GRAPH_SPEC)
sys.modules[GRAPH_SPEC.name] = GRAPH_TOOL
GRAPH_SPEC.loader.exec_module(GRAPH_TOOL)
SPEC = importlib.util.spec_from_file_location(
    "fedora_rpm_manifest_dependencies", SCRIPT_PATH
)
TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TOOL
SPEC.loader.exec_module(TOOL)


def graph_data():
    return {
        "schema_version": 1,
        "nodes": [
            {
                "id": "alpha@1",
                "name": "alpha",
                "version": "1",
                "architectures": ["x86_64"],
                "reason": "user-installed",
            },
            {
                "id": "beta@1",
                "name": "beta",
                "version": "1",
                "architectures": ["x86_64"],
                "reason": "user-installed",
            },
            {
                "id": "shared@1",
                "name": "shared",
                "version": "1",
                "architectures": ["x86_64"],
                "reason": "dependency",
            },
            {
                "id": "intermediate@1",
                "name": "intermediate",
                "version": "1",
                "architectures": ["x86_64"],
                "reason": "dependency",
            },
            {
                "id": "transitive@1",
                "name": "transitive",
                "version": "1",
                "architectures": ["x86_64"],
                "reason": "dependency",
            },
        ],
        "edges": [
            {"from": "alpha@1", "to": "shared@1"},
            {"from": "beta@1", "to": "shared@1"},
            {"from": "alpha@1", "to": "intermediate@1"},
            {"from": "intermediate@1", "to": "transitive@1"},
        ],
    }


class FedoraRpmManifestDependenciesTest(unittest.TestCase):
    def test_cli_marks_direct_in_manifest_dependencies_and_preserves_source(self):
        manifest = (
            "# Description: Alpha package\n"
            "alpha\n"
            "# Description: Beta package\n"
            "beta\n"
            "# Description: Shared package\n"
            "shared\n"
            "# Description: Transitive package\n"
            "transitive\n"
            "# Description: Package absent from graph\n"
            "missing\n"
        )
        expected = (
            "# Description: Alpha package\n"
            "alpha\n"
            "# Description: Beta package\n"
            "beta\n"
            "# Description: Shared package\n"
            "shared\n"
            "# Required by manifest packages: alpha, beta\n"
            "# Description: Transitive package\n"
            "transitive\n"
            "# Description: Package absent from graph\n"
            "missing\n"
        )
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            graph_path = directory / "graph.json"
            manifest_path = directory / "dnf.txt"
            output_path = directory / "dnf-annotated.txt"
            graph_json = json.dumps(graph_data())
            graph_path.write_text(graph_json, encoding="utf-8")
            manifest_path.write_text(manifest, encoding="utf-8")
            stderr = io.StringIO()
            stdout = io.StringIO()

            with contextlib.redirect_stderr(stderr), contextlib.redirect_stdout(stdout):
                result = TOOL.main(
                    [
                        "--graph-json",
                        str(graph_path),
                        "--manifest",
                        str(manifest_path),
                        "--output",
                        str(output_path),
                    ]
                )

            self.assertEqual(result, 0)
            self.assertEqual(output_path.read_text(encoding="utf-8"), expected)
            self.assertEqual(manifest_path.read_text(encoding="utf-8"), manifest)
            self.assertEqual(graph_path.read_text(encoding="utf-8"), graph_json)
            self.assertIn("annotated 1 package(s)", stdout.getvalue())
            self.assertIn(
                "manifest packages absent from graph: missing", stderr.getvalue()
            )

    def test_cli_annotates_fixture_export_in_the_exported_edge_direction(self):
        manifest = "# Description: Editor\neditor\n# Description: Library\nlibeditor\n"
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            graph_path = directory / "graph.json"
            manifest_path = directory / "dnf.txt"
            output_path = directory / "dnf-annotated.txt"
            manifest_path.write_text(manifest, encoding="utf-8")
            self.assertEqual(
                GRAPH_TOOL.main(
                    ["--fixture-json", str(FIXTURE_PATH), "--json", str(graph_path)]
                ),
                0,
            )

            self.assertEqual(
                TOOL.main(
                    [
                        "--graph-json",
                        str(graph_path),
                        "--manifest",
                        str(manifest_path),
                        "--output",
                        str(output_path),
                    ]
                ),
                0,
            )
            self.assertEqual(
                output_path.read_text(encoding="utf-8"),
                "# Description: Editor\n"
                "editor\n"
                "# Description: Library\n"
                "libeditor\n"
                "# Required by manifest packages: editor\n",
            )

    def test_cli_refuses_to_overwrite_an_input_manifest(self):
        manifest = "alpha\n"
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            graph_path = directory / "graph.json"
            manifest_path = directory / "dnf.txt"
            graph_path.write_text(json.dumps(graph_data()), encoding="utf-8")
            manifest_path.write_text(manifest, encoding="utf-8")
            stderr = io.StringIO()

            with contextlib.redirect_stderr(stderr):
                with self.assertRaises(SystemExit) as error:
                    TOOL.main(
                        [
                            "--graph-json",
                            str(graph_path),
                            "--manifest",
                            str(manifest_path),
                            "--output",
                            str(manifest_path),
                        ]
                    )

            self.assertEqual(error.exception.code, 2)
            self.assertIn("--output must be different", stderr.getvalue())
            self.assertEqual(manifest_path.read_text(encoding="utf-8"), manifest)

    def test_annotation_adds_a_separate_comment_after_unterminated_package_line(self):
        rendered, packages, annotated = TOOL.annotate_manifest(
            "shared", {"shared": {"alpha"}}
        )

        self.assertEqual(
            rendered, "shared\n# Required by manifest packages: alpha\n"
        )
        self.assertEqual(packages, {"shared"})
        self.assertEqual(annotated, {"shared"})

    def test_load_graph_rejects_malformed_and_invalid_graphs(self):
        invalid_graphs = [
            ("malformed.json", "{", "cannot read graph JSON"),
            (
                "unsupported.json",
                json.dumps({"schema_version": 2, "nodes": [], "edges": []}),
                "unsupported schema_version 2",
            ),
            (
                "missing-field.json",
                json.dumps(
                    {
                        "schema_version": 1,
                        "nodes": [
                            {
                                "id": "alpha@1",
                                "name": "alpha",
                                "architectures": ["x86_64"],
                                "reason": "user-installed",
                            }
                        ],
                        "edges": [],
                    }
                ),
                "nodes[0].version",
            ),
            (
                "invalid-edge.json",
                json.dumps(
                    {
                        "schema_version": 1,
                        "nodes": graph_data()["nodes"][:1],
                        "edges": [{"from": "alpha@1", "to": "unknown@1"}],
                    }
                ),
                "references unknown node id 'unknown@1'",
            ),
        ]
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            for filename, content, expected_message in invalid_graphs:
                with self.subTest(filename=filename):
                    graph_path = directory / filename
                    graph_path.write_text(content, encoding="utf-8")

                    with self.assertRaises(TOOL.ManifestDependencyError) as error:
                        TOOL.load_graph(graph_path)

                    self.assertIn(expected_message, str(error.exception))


if __name__ == "__main__":
    unittest.main()