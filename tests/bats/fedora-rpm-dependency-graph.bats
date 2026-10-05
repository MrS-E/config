#!/usr/bin/env bats

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

setup() {
  require_os fedora
}

@test "Fedora RPM dependency graph CLI documents its outputs and fixture input" {
  run "$REPO_DIR/scripts/fedora-rpm-dependency-graph.py" --help

  assert_success
  assert_output_partial "--dot PATH"
  assert_output_partial "--json PATH"
  assert_output_partial "--fixture-json PATH"
}

@test "Fedora RPM dependency graph CLI exports a fixture without querying the host" {
  local dot="$BATS_TEST_TMPDIR/dependency-graph.dot"
  local json="$BATS_TEST_TMPDIR/dependency-graph.json"

  run "$REPO_DIR/scripts/fedora-rpm-dependency-graph.py" \
    --fixture-json "$REPO_DIR/tests/fixtures/fedora-rpm-dependency-graph.json" \
    --dot "$dot" \
    --json "$json"

  assert_success
  run python3 -c '
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
nodes = {node["name"]: node for node in data["nodes"]}
assert len(nodes) == 3
assert nodes["editor"]["reason"] == "user-installed"
assert nodes["editor"]["architectures"] == ["i686", "x86_64"]
assert len(data["edges"]) == 3
dot = open(sys.argv[2], encoding="utf-8").read()
assert "digraph rpm_dependencies" in dot
assert "user-installed" in dot
' "$json" "$dot"
  assert_success
}

@test "Fedora RPM dependency graph CLI reads installed package metadata" {
  local json="$BATS_TEST_TMPDIR/live-dependency-graph.json"

  run "$REPO_DIR/scripts/fedora-rpm-dependency-graph.py" --json "$json"

  assert_success
  run python3 -c '
import json
import sys

graph = json.load(open(sys.argv[1], encoding="utf-8"))
ids = {node["id"] for node in graph["nodes"]}
assert ids
assert any(node["reason"] == "user-installed" for node in graph["nodes"])
assert all(edge["from"] in ids and edge["to"] in ids for edge in graph["edges"])
' "$json"
  assert_success
}

@test "Fedora RPM dependency graph fixture unit tests pass" {
  run python3 "$REPO_DIR/tests/test_fedora_rpm_dependency_graph.py"

  assert_success
}