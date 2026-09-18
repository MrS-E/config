# Junie CLI: What is stored on the user's disk

This document describes what data the `junie` CLI stores on the user's disk, where it is stored, and what it is used for.

## Base `junieHome` directory

The main user directory for the CLI is `junieHome`.

The path is resolved in this order:

1. the `JUNIE_HOME` environment variable
2. the `junie.home` system property
3. the default directory `~/.junie`

Examples:

- macOS / Linux: `~/.junie`
- Windows: `%USERPROFILE%/.junie`

## What is stored inside `junieHome`

### `logs/`

Directory for CLI logs. It is created when the application starts.

### `settings.json`

File with CLI user settings.

At the moment, it stores values such as:

- `braveMode`
- `modelForLaunch`
- `selectedTheme`
- `sessionCount`
- `junieId`
- `shareAnonymousStatistics`

Format: JSON.

### `sessions/`

Directory with saved CLI sessions.

Structure:

- `sessions/index.jsonl` — session index, one JSON record per line
- `sessions/<sessionId>/events.jsonl` — session event stream
- `sessions/<sessionId>/state.json` — latest saved agent state
- `sessions/<sessionId>/<taskId>/` — task-bound cache data
- `sessions/<sessionId>/<taskId>/terminal-output/` — retained full stdout/stderr files for large terminal command output

Notes:

- some environment variables inside `state.json` and state events are encrypted through `EnvEncryptionService`
- the index and events are used to restore the history and state of interactive sessions
- terminal command output is buffered in memory and only written to a `terminal-output/` file once it grows past the
  session event output cap (64 KB); smaller output is kept inline in the event stream and never creates a file. This means
  small/internal commands (for example the local code review availability probe) leave no files behind, and internal
  shell-state markers (which can include environment variables) are never written to disk for such output
- terminal output files are task-bound and referenced from terminal transcript events only when output is larger than the
  session event output cap
- unreferenced generated terminal output files are cleaned up from the task folder when that task reaches a terminal state
- truncated terminal command results start with the corresponding retained `terminal-output/` file path so the agent can
  inspect the full stdout/stderr when important details are outside the displayed output; the in-memory bounded view of
  oversized output keeps its beginning and end with an explicit middle-truncation marker between them

Format:

- `index.jsonl` and `events.jsonl` — JSONL
- `state.json` — JSON
- `<taskId>/terminal-output/` — text files

### `misc/`

Directory for small internal CLI files.

Here, `junie` stores small internal files as separate key-based entries.

#### `misc/config_hashes.json`

Hashes of local custom skill configurations.

Used to track new, updated, and problematic local skill file configurations.

#### `misc/migration_state.json`

Migration state for user and project settings imported from other products.

Contains the list of already processed projects.

### `secure_credentials.json`

Fallback secret storage file.

It is used only when system secure storage is unavailable:

- macOS Keychain
- Windows Credential Manager
- Linux Secret Service

If fallback storage is enabled, secrets are stored in this file as JSON.

This is sensitive data.

Project trust keys are never stored in this fallback file. Junie stores one random authentication key in native macOS Keychain, Windows Credential Manager, or Linux Secret Service, and falls back to an owner-only `trust/authentication-key` file when native secure storage is unavailable, locked, failing, or holds invalid key material. A trust selection is kept in memory for the current process only if even that file cannot be written.

### `trust/`

Directory containing one JSON marker per trusted exact-project or parent-directory scope. Marker filenames are SHA-256 hashes derived from the marker kind and canonical path. Marker contents include the version, marker kind, and canonical path plus an HMAC-SHA256 integrity code authenticated by the project trust key. The directory may also hold `authentication-key`, the owner-only fallback copy of that key used when native secure storage cannot hold it.

Junie ignores malformed, renamed, symlinked, oversized, or incorrectly authenticated markers. Marker writes are atomic and use owner-only permissions on POSIX systems. Deleting an exact marker revokes that project; deleting a parent marker revokes inherited trust for its descendant projects on the next process launch. Choosing **Keep untrusted** does not write a marker. Separate markers also prevent one stale scope or concurrent Junie process from replacing unrelated trust decisions.

Interactive UI launches always use these markers and prompt when no valid exact-project or ancestor marker exists, except for a verified linked git worktree of an already trusted project, which inherits that trust automatically without writing its own marker. Non-interactive JSON, ACP, and Gateway tasks are always trusted and do not consult these markers, because they cannot ask for a decision. The user home directory is never trusted: options that would trust it (directly or through a recursive parent scope containing it) are not offered and are refused by the resolver.

### `mcp/mcp.json`

User MCP server configuration.

### `models/`

Custom user model profiles.

The CLI scans this directory for `*.json` files and loads model profiles from them.

### `agent-skills/`

User agent skills.

The CLI reads skills from:

- `<project>/.junie/agent-skills`
- `<junieHome>/agent-skills`

User files inside `junieHome` are stored in this directory.

## What may be stored outside `junieHome`

### `<project>/.junie/mcp/mcp.json`

Project-level MCP configuration.

It belongs to a specific project rather than global user state.

### `<project>/.junie/models`

Project-level custom model profiles.

These take priority over user profiles from `<junieHome>/models`.

## Short summary

If you only look at the CLI's global user data, the main locations are:

- `~/.junie/settings.json`
- `~/.junie/sessions/`
- `~/.junie/logs/`
- `~/.junie/trust/`
- `~/.junie/misc/`
- `~/.junie/mcp/mcp.json`
- `~/.junie/models/`
- `~/.junie/agent-skills/`
- `~/.junie/secure_credentials.json` — only if system secure storage is unavailable

The most sensitive locations are:

- `secure_credentials.json`, if fallback storage is used
- the contents of `sessions/`, because they may contain work history and agent state
- user model profiles in `models/`, if they contain keys or custom headers