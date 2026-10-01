#!/usr/bin/env python3
"""Git clean/smudge filters for Junie JSON configuration."""

import json
import os
import subprocess
import sys
import tempfile


TRACKED_SETTINGS = (
    "stepsLimit",
    "shareAnonymousStatistics",
    "subagentsMode",
    "diffViewMode",
    "toolbarVisibility",
)
TRACKED_SETTINGS_SET = set(TRACKED_SETTINGS)
SETTINGS_CACHE = "junie-settings-local.json"
MCP_CACHE = "junie-mcp-local.json"


def clean_settings(value):
    if not isinstance(value, dict):
        raise ValueError("Junie settings must be a JSON object")
    return {key: value[key] for key in TRACKED_SETTINGS if key in value}


def clean_mcp(value):
    if not isinstance(value, dict):
        raise ValueError("Junie MCP configuration must be a JSON object")

    normalized = dict(value)
    servers = value.get("mcpServers")
    if isinstance(servers, dict):
        normalized_servers = {}
        for name, server in servers.items():
            if isinstance(server, dict):
                server = dict(server)
                server.pop("enabled", None)
            normalized_servers[name] = server
        normalized["mcpServers"] = normalized_servers
    return normalized


def local_settings(value):
    return {
        key: item
        for key, item in value.items()
        if key not in TRACKED_SETTINGS_SET
    }


def local_mcp_enabled(value):
    servers = value.get("mcpServers")
    if not isinstance(servers, dict):
        return {}
    return {
        name: {
            "present": "enabled" in server,
            "value": server.get("enabled"),
        }
        for name, server in servers.items()
        if isinstance(server, dict)
    }


def cache_path(name):
    git_dir = subprocess.check_output(
        ["git", "rev-parse", "--absolute-git-dir"], text=True
    ).strip()
    return os.path.join(git_dir, name)


def read_cache(name):
    try:
        with open(cache_path(name), encoding="utf-8") as cache_file:
            return json.load(cache_file)
    except FileNotFoundError:
        return None


def write_cache(name, value):
    path = cache_path(name)
    directory = os.path.dirname(path)
    descriptor, temporary_path = tempfile.mkstemp(
        prefix=".junie-filter-", dir=directory
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as cache_file:
            json.dump(value, cache_file, ensure_ascii=False, sort_keys=True)
            cache_file.write("\n")
        os.replace(temporary_path, path)
    except Exception:
        try:
            os.unlink(temporary_path)
        except FileNotFoundError:
            pass
        raise


def read_working_copy(path):
    if not path:
        return None
    try:
        with open(path, encoding="utf-8") as working_file:
            return json.load(working_file)
    except FileNotFoundError:
        return None


def smudge_settings(value, working_copy):
    if not isinstance(value, dict):
        raise ValueError("Junie settings must be a JSON object")
    if not isinstance(working_copy, dict):
        return value

    merged = {
        key: item
        for key, item in working_copy.items()
        if key not in TRACKED_SETTINGS_SET
    }
    merged.update(value)
    return merged


def restore_mcp_enabled(value, local_values):
    if not isinstance(value, dict):
        raise ValueError("Junie MCP configuration must be a JSON object")
    servers = value.get("mcpServers")
    if not isinstance(servers, dict) or not isinstance(local_values, dict):
        return value

    for name, local_value in local_values.items():
        server = servers.get(name)
        if not isinstance(server, dict) or not isinstance(local_value, dict):
            continue
        if local_value.get("present"):
            server["enabled"] = local_value.get("value")
        else:
            server.pop("enabled", None)
    return value


def main():
    if len(sys.argv) not in (2, 3):
        print(
            "usage: junie-json-filter.py "
            "{clean-settings|smudge-settings|clean-mcp|smudge-mcp} [path]",
            file=sys.stderr,
        )
        return 2

    operation = sys.argv[1]
    if operation not in {
        "clean-settings",
        "smudge-settings",
        "clean-mcp",
        "smudge-mcp",
    }:
        print("unknown Junie JSON filter operation: " + operation, file=sys.stderr)
        return 2

    try:
        value = json.load(sys.stdin)
        if operation == "clean-settings":
            result = clean_settings(value)
            write_cache(SETTINGS_CACHE, local_settings(value))
        elif operation == "clean-mcp":
            result = clean_mcp(value)
            write_cache(MCP_CACHE, local_mcp_enabled(value))
        else:
            working_copy = read_working_copy(sys.argv[2] if len(sys.argv) == 3 else None)
            if operation == "smudge-settings":
                local_values = read_cache(SETTINGS_CACHE)
                if local_values is None:
                    local_values = working_copy
                result = smudge_settings(value, local_values)
            else:
                local_values = read_cache(MCP_CACHE)
                if local_values is None:
                    local_values = (
                        local_mcp_enabled(working_copy)
                        if isinstance(working_copy, dict)
                        else None
                    )
                result = restore_mcp_enabled(value, local_values)

        json.dump(result, sys.stdout, ensure_ascii=False, indent=4, sort_keys=True)
        sys.stdout.write("\n")
    except (
        json.JSONDecodeError,
        OSError,
        subprocess.CalledProcessError,
        ValueError,
    ) as error:
        print("Junie JSON filter failed: " + str(error), file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())