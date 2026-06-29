# Hooks

<primary-label ref="nightly"/>

Hooks let you run shell commands automatically at well-defined points in a Junie CLI session.
Use them to launch a local proxy and refresh credentials at the start (`SessionStart`), validate or enrich a prompt before it is sent (`UserPromptSubmit`), gate task completion behind tests or other checks (`Stop`), or to flush logs and clean up resources when a session ends (`SessionEnd`).

> This feature is currently in the [Early Access Program](Junie-CLI-EAP.md). To try it,
> [install the Early Access version](Junie-CLI-EAP.md#install-eap) of Junie CLI.

## Configure a hook

Add a `hooks` object to your user `~/.junie/config.json` or to a file passed with `--config-location`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "aws sso login --profile dev",
            "timeout": 30
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.junie/scripts/check-prompt.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "clear|prompt_input_exit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.junie/scripts/flush-session-logs.sh"
          }
        ]
      }
    ]
  }
}
```

Each entry has a `matcher` and a list of `hooks` to run when the matcher matches.

Project-local hooks from `<project-root>/.junie/config.json` are ignored by default for safety.
Project configuration is repository-controlled, so Junie will not run shell commands from it automatically.
If you intentionally want to run hooks from a project file, pass that file explicitly with `--config-location`.

### Matcher entry fields

| Field | Required | Description |
|---|---|---|
| `matcher` | No | A regular expression matched against the event-specific value: the source for `SessionStart` (e.g. `startup`, `resume`, `clear`, `compact`) or the reason for `SessionEnd` (e.g. `clear`, `resume`, `prompt_input_exit`, `other`, `logout`). `UserPromptSubmit` and `Stop` do not support matchers — entries always run on every event. If omitted, the entry runs for every value. A configured matcher must match at least one supported value. |
| `hooks` | Yes | A list of hook commands to run when the matcher matches. |

### Hook command fields

| Field | Required | Description |
|---|---|---|
| `type` | Yes | The hook type. Only `command` is currently supported. |
| `command` | Yes | The shell command to run. Executed via `sh -c` on macOS/Linux and `cmd /c` on Windows. |
| `timeout` | No | Maximum execution time in seconds for a single command. Defaults to 10 for `SessionStart` and `UserPromptSubmit`, 600 for `Stop`, and 2 for `SessionEnd`. Note: for `SessionEnd`, the *total* dispatch budget across all matched entries is capped at 10 seconds. A per-command `timeout` larger than this remaining budget is effectively bounded by the overall budget. |
| `blockOnError` | No | `Stop` hooks only. When `true`, any non-zero exit code (other than the already-blocking `2`) is promoted to a block-with-retry, with the command's stdout+stderr fed back to the agent as the block reason. Defaults to `false`. Ignored for other events. |

## Triggering events

### SessionStart

Junie fires `SessionStart` once per session with one of the following sources:

| Source | When |
|---|---|
| `startup` | A fresh CLI session starts. |
| `resume` | An existing session is resumed within the same CLI process. |
| `clear` | A new session is started inside the same CLI process (for example, via the `/new` command). |
| `compact` | The agent triggers history compaction inside a running task (the SessionStart hook is dispatched on the synthetic compaction session). |

### UserPromptSubmit

Junie fires `UserPromptSubmit` every time the user submits a prompt in the interactive TUI, before the prompt is sent to the model. Hooks may add context, log the prompt, or block the prompt entirely.

Unlike `SessionStart` and `SessionEnd`, `UserPromptSubmit` has no source/reason, so it does not support a `matcher` — every configured entry runs on every prompt.

### Stop

Junie fires `Stop` synchronously right before the agent transitions a task to a successful submission, so a hook can let it proceed, block the submission with a textual reason that is fed back to the agent as context (causing a retry), or hard-halt the task.

Stop hooks do not run for chat-type tasks. They are enforced uniformly in both interactive and batch (`-p` / non-interactive) modes; the per-task block cap (see [Stop hook blocking and retries](#stop-hook-blocking-and-retries)) is the only safeguard against runaway loops.

Stop does not support `matcher` — every configured entry runs on every transition.

### SessionEnd

Junie fires `SessionEnd` whenever a session terminates, with one of the following reasons:

| Reason | When |
|---|---|
| `clear` | The current session is replaced by a new one in the same CLI process (`/new`). |
| `resume` | The current session is replaced by an existing session loaded from history (for example, `/history` → pick a past session). |
| `prompt_input_exit` | The interactive TUI is exiting (user pressed Ctrl+C, `/exit`, or `/quit`). |
| `other` | A batch (`-p`) or non-interactive task finishes. |
| `logout` | The user explicitly signs out from the TUI account screen ("Sign out"). The hook is dispatched in the background when sign-out is requested and does not block navigation — it may run concurrently with credential clearing, and any failure notifications surface after the fact. |

Hooks are currently triggered from the interactive TUI host (`SessionStart`, `UserPromptSubmit`, `Stop`, `SessionEnd`) and the batch host (`SessionStart`, `Stop`, `SessionEnd`). ACP and server hosts do not yet invoke any hooks; that integration is tracked separately.

You can scope a hook to a specific source or reason using `matcher`. For example, `"matcher": "startup"` runs the hook only on a fresh start, while `"matcher": "startup\|resume"` runs it on both. Omitting `matcher` is equivalent to matching every value.

## Hook input

Each hook receives a single line of JSON on standard input:

```json
{"hook_event_name":"SessionStart","source":"startup"}
```

For `UserPromptSubmit`, the payload carries the prompt text:

```json
{"hook_event_name":"UserPromptSubmit","prompt":"…"}
```

For `SessionEnd`, the payload uses `reason` instead of `source`:

```json
{"hook_event_name":"SessionEnd","reason":"prompt_input_exit"}
```

For `Stop`, the payload carries the agent's submission text and a retry flag:

```json
{"hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"…"}
```

`stop_hook_active` is `true` on every re-run that follows a previous Stop block in the same task; `false` on the first dispatch. When the agent's submission text is empty, `last_assistant_message` is sent as an empty string (not the literal word `Empty`).

This matches the input format used by Gemini and Codex hooks, so the same hook script can be shared between agents.

## Failure handling

Hook output and exit status do not block Junie startup:

* Standard output and standard error are captured and logged at debug level. If a hook fails, captured output can be included in TUI error details, but it is not stored in session history.
* A non-zero exit code is logged as a warning and shown as a TUI error message. Junie continues to start.
* If the command exceeds its `timeout`, it is force-killed, logged as a warning, and shown as a TUI error message. Junie continues to start.
* Invalid hook configuration, such as an unsupported `type`, invalid `matcher`, or non-positive `timeout`, is shown as a TUI error message. Junie continues to start.

Junie will not abort on hook failure; use the TUI system message and logs to diagnose failed hooks.

## Stop hook blocking and retries

A `Stop` hook can request the agent to retry submission by:

* Exiting with status code `2`. The command's stderr is fed back to the agent as the block reason; if stderr is empty, a generic "blocked with exit code 2" message is used.
* Printing `{"decision":"block","reason":"…"}` to stdout on a successful exit. The `reason` is appended to the agent's state as an observer message so the agent can address the issue and submit again.
* Setting `blockOnError: true` on the hook command and exiting with any non-zero exit code. The command's stderr is fed back to the agent as the block reason.

To guard against infinite block loops, the agent stops dispatching the Stop hook after 8 consecutive blocks within the same task and a system message is published. Override the limit with the `JUNIE_STOP_HOOK_BLOCK_CAP` environment variable; set it to `0` to disable the cap.

A `Stop` hook can request a hard halt (no retry, the task ends with a failure exit status) by printing `{"continue":false,"stopReason":"…"}` to stdout on a successful exit. `continue: false` takes precedence over `decision: "block"`. Hard halts apply uniformly in interactive and batch mode: the task ends with a failure exit status.

A `Stop` hook can send messages on a successful exit through two distinct JSON fields:

* `{"hookSpecificOutput":{"additionalContext":"…"}}` (or a top-level `additionalContext`) — agent-facing payload. Shown in the TUI as `Stop hook context: …` and, on block / hard-halt, folded into the agent's observer message on retry.
* `{"systemMessage":"…"}` — user-facing payload. Shown in the TUI as `Stop hook: …`.

Both fields are accumulated across all hooks that ran in the chain.

## Merging hooks across configuration files

When multiple configuration files define hook entries for the same event, all entries from all files are concatenated.
Higher-priority files do not override lower-priority files; their entries are appended.

Only trusted sources participate in hook merging: user configuration and explicit `--config-location` files.
Default project-local `hooks` entries are skipped and reported as a hook configuration warning.

For the configuration precedence order, see [Configuration files](Junie-CLI-configuration.md#configuration-precedence).

## Limitations

* The supported events are `SessionStart`, `UserPromptSubmit`, `Stop`, and `SessionEnd`.
* `UserPromptSubmit` is currently triggered only from the interactive TUI; batch, ACP, and server hosts do not invoke it.
* `SessionStart`, `Stop`, and `SessionEnd` are currently triggered from the interactive TUI and batch hosts; ACP and server hosts do not invoke them.
* Only `type: "command"` hooks are supported.
* Hooks within a single entry run sequentially. Parallel execution is not supported.
* `SessionEnd` hooks cannot block session termination, even if they return a non-zero exit code or `decision: block` in their stdout.
* `SessionEnd` dispatch has a total budget of 10 seconds across all matched entries combined; a longer per-command `timeout` will be effectively bounded by this overall budget.
* `Stop` hooks do not run for chat-type tasks.
* `blockOnError` is a Junie extension and is honoured for `Stop` hooks only. It is ignored on other events to avoid silently blocking prompt submission or session lifecycle.
* The `Stop` stdin contains only `hook_event_name`, `stop_hook_active`, and `last_assistant_message`.
* On `/new`, the new session's `SessionStart` hook runs in parallel with the outgoing session's `SessionEnd` hook. Order is not guaranteed: do not assume `SessionEnd` finishes before `SessionStart` starts.
* The `SessionStart`/`UserPromptSubmit`/`SessionEnd` executors log `continue: false` as a failure but do not yet halt the session, cancel the prompt, or abort startup. Only `Stop` maps `continue: false` to a real abort action.
* `additionalContext` on stdout — agent-facing. `UserPromptSubmit` prepends it to the prompt; `Stop` folds it into the agent's observer message on block / hard-halt retries. `SessionStart` ignores it; `SessionEnd` discards it.
* `systemMessage` on stdout — user-facing TUI info message. Currently honoured by the `Stop` executor only.
