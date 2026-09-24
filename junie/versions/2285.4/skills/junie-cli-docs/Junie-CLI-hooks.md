# Hooks

<primary-label ref="nightly"/>

Hooks let you run shell commands automatically at well-defined points in a Junie CLI session.
Use them to launch a local proxy and refresh credentials at the start (`SessionStart`), validate or enrich a prompt before it is sent (`UserPromptSubmit`), inspect or block a tool call before it runs (`PreToolUse`), gate task completion behind tests or other checks (`Stop`), alert / page / clean up when the agent loop ends due to an LLM/API error (`StopFailure`), or to flush logs and clean up resources when a session ends (`SessionEnd`), or automatically allow or deny sensitive action permission requests without manual confirmation (`PermissionRequest`).

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
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.junie/hooks/check-bash-command.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "prompt_input_exit|logout",
        "hooks": [
          {
            "type": "command",
            "command": "~/.junie/scripts/flush-session-logs.sh"
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.junie/scripts/check-bash-permission.sh"
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

| Field | Required | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|---|---|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `matcher` | No | A regular expression matched against the event-specific value: the source for `SessionStart` (e.g. `startup`, `resume`, `clear`, `compact`), the reason for `SessionEnd` (e.g. `prompt_input_exit`, `other`, `logout`), , or the tool name for `PermissionRequest` (e.g. `Bash`, `Edit`, `Read`), or the tool name for `PreToolUse` (e.g. `Bash`, `Write`, `Read`), or the `error` for `StopFailure` (see the [StopFailure](#stopfailure) section for the full 9-value list, e.g. `rate_limit`, `server_error`, `model_refused`). `UserPromptSubmit` and `Stop` do not support matchers — entries always run on every event. If omitted, the entry runs for every value. A configured matcher must match at least one supported value. |
| `hooks` | Yes | A list of hook commands to run when the matcher matches.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |

### Hook command fields

| Field | Required | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|---|---|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type` | Yes | The hook type. Only `command` is currently supported.                                                                                                                                                                                                                                                                                                                                                                                                               |
| `command` | Yes | The shell command to run. Executed via `sh -c` on macOS/Linux and `cmd /c` on Windows.                                                                                                                                                                                                                                                                                                                                                                              |
| `timeout` | No | Maximum execution time in seconds for a single command. Defaults to 10 for `SessionStart`, `UserPromptSubmit`, and `PermissionRequest`; 600 for `Stop`, 60 for `StopFailure`, and 2 for `SessionEnd`. Note: for `SessionEnd`, the *total* dispatch budget across all matched entries is capped at 10 seconds; for `StopFailure` it is capped at 60 seconds. A per-command `timeout` larger than this remaining budget is effectively bounded by the overall budget. |
| `blockOnError` | No | `Stop` hooks only. When `true`, any non-zero exit code (other than the already-blocking `2`) is promoted to a block-with-retry, with the command's stdout+stderr fed back to the agent as the block reason. Defaults to `false`. Ignored for other events.                                                                                                                                                                                                          |
| `async` | No | When `true`, the hook runs in the background and cannot block or affect the triggering action. `systemMessage` is shown to the user only; `additionalContext` is queued and prepended to the agent prompt on the next user submit; `decision` / `permissionDecision` / `continue` are logged and ignored. See [Run hooks in the background](#run-hooks-in-the-background). Defaults to `false`. |

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

### PreToolUse

Junie fires `PreToolUse` before each tool call, after the action request is parsed but before the tool executes.
The hook can inspect or modify the tool input, add context for the model, request user confirmation, or block the tool entirely.

The `matcher` is matched against the **tool name** as seen by the model (e.g. `Bash`, `Write`, `Read`, `Edit`, `Glob`, `Grep`).
Omitting the matcher runs the hook for every tool call.

#### Hook output for PreToolUse

A `PreToolUse` hook may return a JSON object on standard output to influence what happens next:

```json
{
  "decision": "allow",
  "reason": "human-readable reason shown to the user on block or ask",
  "updatedInput": { "command": "ls -la" },
  "additionalContext": "text added to the model context window"
}
```

Supported decisions:

| Decision | Effect |
|---|---|
| `allow` (or omitted) | The tool runs with its original (or updated) input. |
| `ask` | Junie pauses and asks the user to confirm before the tool runs. `reason` and `updatedInput` are forwarded to the confirmation prompt. |
| `block` or `deny` | The tool is not executed. The model receives an error message with the `reason`. |

If the hook exits with code `2`, the tool is blocked regardless of any output.
Other non-zero exit codes are logged as a warning and the tool proceeds normally.

`updatedInput` replaces the tool's input with the provided JSON object.
`additionalContext` injects additional text into the model context for that turn.
If the hook output is not valid JSON, the raw stdout is treated as `additionalContext`.

### Stop

Junie fires `Stop` synchronously right before the agent transitions a task to a successful submission, so a hook can let it proceed, block the submission with a textual reason that is fed back to the agent as context (causing a retry), or hard-halt the task.

Stop hooks do not run for chat-type tasks. They are enforced uniformly in both interactive and batch (`-p` / non-interactive) modes; the per-task block cap (see [Stop hook blocking and retries](#stop-hook-blocking-and-retries)) is the only safeguard against runaway loops.

Stop does not support `matcher` — every configured entry runs on every transition.

### PermissionRequest

Junie fires `PermissionRequest` whenever it is about to show a permission dialog asking the user to approve a sensitive action. Hooks can suppress the dialog by automatically allowing or denying the action.

The matcher is evaluated against the **tool name** for the action:

| Tool name | Actions |
|---|---|
| `Bash` | Terminal commands, run tests, run app, preview, build, clear app data |
| `Edit` | Editing files (build scripts, config files, general file modifications) |
| `Read` | Reading files outside the project or secret files |
| MCP tool name | MCP tool calls (matched against the tool name, e.g. `github`) |

A hook that exits successfully (exit code 0) without a blocking decision **automatically approves** the action — the permission dialog is skipped.
A hook that blocks (exit code 2 or `decision: "block"` / `decision: "deny"` in stdout) **automatically denies** the action.
If no hook matches, or a hook fails with a non-zero exit (other than 2), Junie falls back to showing the normal permission dialog (with a warning notification if the hook failed).

`PermissionRequest` supports matchers — use them to scope hooks to specific tools.

### StopFailure

Junie fires `StopFailure` once per agent turn when the LLM/API call backing that turn ends in a documented failure (rate limit, billing error, authentication failure, model refusal, etc.). Use it to send alerts, page on-call, log the event, or run cleanup scripts.

`StopFailure` is **observability-only**: it has no decision control. Output and exit code from the hook process are ignored — `decision: block` and `continue: false` are demoted to TUI failure notifications and **cannot** retry or abort the agent (which is already exiting). Stdin carries `hook_event_name`, `error` (the matcher target), and `error_details` (the underlying failure description); the field names follow Claude Code's `StopFailure` wire protocol so a Claude-style hook script can be reused.

Catch-all LLM failure wrappers map to `unknown`. Tool-execution failures, project pre-flight / shell-setup failures, and user-cancellations do **not** trigger `StopFailure`; tool errors will be covered by a future `PostToolUseFailure` hook. The catch-all `unknown` bucket also covers internal `UnexpectedException` wrappers, so it is possible (though rare) for a Junie-side bug — not a real provider failure — to fire `StopFailure` with `error=unknown`; alerting rules that page on `unknown` should account for this.

Dispatch is non-blocking only in the interactive TUI host: there `StopFailure` is fire-and-forget — the agent surfaces the failure to the user immediately and the hook (bounded by the 60s overall budget) runs in the background. In the batch (`-p` / non-interactive) and server hosts the agent is already exiting, so there is no scope to launch into; the hook runs **synchronously** and the process waits up to 60s for it to finish (or be killed by `withTimeoutOrNull`) before the failing exception is re-thrown. Long-running on-call / paging hooks must therefore not exceed this budget if you rely on them completing before the batch process exits.

`StopFailure` is matched against the `error` wire value. The 9 values are:

| `error` | When |
|---|---|
| `rate_limit` | The provider returned a rate-limit error (typically HTTP 429). |
| `authentication_failed` | The provider rejected the API key or token (typically HTTP 401). |
| `billing_error` | The account billing state prevents the call (payment required, cost cap hit, etc.). |
| `invalid_request` | The provider rejected our request shape (malformed JSON, unsupported parameter, …). |
| `server_error` | The provider returned a 5xx, timed out, or the connection was dropped. |
| `max_output_tokens` | The model hit its output token / context limit. |
| `unknown` | An LLM-side failure that did not match any of the above. |
| `model_refused` | The model declined to complete the request (safety mechanisms). Junie-specific. |
| `country_forbidden` | The provider refused the call because of the caller's country. Junie-specific. |

A `matcher` like `"rate_limit"` runs only on rate-limit failures; `"rate_limit|server_error|model_refused"` runs on all three; omitting `matcher` runs on every error type.

### SessionEnd

Junie fires `SessionEnd` whenever a session terminates, with one of the following reasons:

| Reason | When |
|---|---|
| `prompt_input_exit` | The interactive TUI is exiting (user pressed Ctrl+C, `/exit`, or `/quit`). |
| `other` | A batch (`-p`) or non-interactive task finishes. |
| `logout` | The user explicitly signs out from the TUI account screen ("Sign out"). The hook is dispatched in the background when sign-out is requested and does not block navigation — it may run concurrently with credential clearing, and any failure notifications surface after the fact. |

> In the interactive TUI, switching away from a session — via `/new`, a `/history` selection, or any other session switch — does **not** end the outgoing session: it continues running in the background and its `SessionEnd` hook is **not** fired on the switch. `SessionEnd` is dispatched only when the session actually terminates (`prompt_input_exit`, `logout`, or `other` for batch). The `clear` and `resume` reasons are reserved in the `SessionEndHookReason` enum but are not currently dispatched in any host.

Hooks are currently triggered from the interactive TUI host (`SessionStart`, `UserPromptSubmit`, `PreToolUse`, `Stop`, `StopFailure`, `SessionEnd`, `PermissionRequest`) and the batch host (`SessionStart`, `PreToolUse`, `Stop`, `StopFailure`, `SessionEnd`). ACP and server hosts do not yet invoke any hooks; that integration is tracked separately.

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

For `PreToolUse`, the payload carries the tool name and its full input:

```json
{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"sleep 60","run_in_background":false,"timeout":30}}
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

For `PermissionRequest`, the payload describes the action that triggered the permission dialog:

```json
{"hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{}}
```

`tool_name` is the tool category (`Bash`, `Edit`, `Read`, or an MCP tool name). `tool_input` contains the full serialized action.

For `StopFailure`, the payload carries the matched error class and the underlying failure description:

```json
{"hook_event_name":"StopFailure","error":"rate_limit","error_details":"429 Too Many Requests"}
```

`error` is the matcher target (one of the 9 values listed in the [StopFailure](#stopfailure) section). `error_details` is always present, but its source depends on the underlying failure category: for `rate_limit` it is the dynamic provider response (e.g. the body of a 429), for `model_refused` and `country_forbidden` it is the model-refusal / refusal text, and for failure categories that do not carry a runtime message (`authentication_failed`, `billing_error` from `CostExceeded`, `invalid_request`, `server_error` from `InferenceServerTimeout` / `BadResponseException`, `max_output_tokens`, `unknown` from `UnexpectedException`) it is a static description of the failure class rather than a provider-supplied string.

The field names match Claude Code's `StopFailure` wire protocol, so the same hook script can be shared between agents.


## Run hooks in the background

By default, a hook blocks the triggering action until it completes — the prompt waits for `UserPromptSubmit`, the tool waits for `PreToolUse`, and so on. For long-running tasks (test suites, deployments, external API calls) set `"async": true` on the hook command to run it in the background while the agent keeps working.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${HOME}/.junie/hooks/run-tests-async.sh",
            "async": true,
            "timeout": 300
          }
        ]
      }
    ]
  }
}
```

### How async hooks behave

* The triggering action proceeds **immediately**; the hook starts in the background. The agent never waits for it.
* `decision`, `permissionDecision`, and `continue` in the hook's output have **no effect** — by the time the hook finishes, the action it would have controlled has already happened. They are logged and ignored.
* `systemMessage` is shown in the TUI as `<Event> hook: <message>` when the hook completes, but it is **not** delivered to the agent.
* `additionalContext` is **queued in memory** and prepended to the agent prompt on the **next user submit** (matching Claude Code's "delivered on the next conversation turn" semantics). It is not retroactively injected into the in-flight task. If the session ends or the user starts a new session before the next submit, queued context for that session is lost.
* If the hook process times out (`timeout` field) or exits with a non-zero code, the failure is published as a TUI notification — async hooks are not silent.
* The `timeout` field is honoured the same as for sync hooks; the default is 10 seconds when omitted (600 seconds for `Stop`).
* If the `UserPromptSubmit` hook blocks the prompt (`decision: block`), already-queued async context from previous turns is restored and will reach the next successful submit.

### When not to use it

Use async only when the hook is genuinely advisory and the agent should not wait for its verdict. A `PreToolUse` lint check that you want to **block** a write on must stay synchronous: async cannot deny the tool.

> `SessionStart`, `SessionEnd`, and `StopFailure` already run in the background at the executor level — Junie never waits for them. The `async` field has no effect on these events: setting `async: false` does **not** make them synchronous, and setting `async: true` does **not** change their behaviour either.

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

* `{"hookSpecificOutput":{"additionalContext":"…"}}` (or a top-level `additionalContext`) — agent-facing payload. Always shown in the TUI as `Stop hook context: …`. It is also delivered to the agent as observer-message feedback in three cases: a `block` (retry), a `continue: false` hard-halt, **and** on a plain successful exit — in the latter case the conversation continues as non-error feedback (Claude parity). When the hook only emits `additionalContext` without `decision: block`, the agent runs one extra step with the context attached and then submits. The shared `JUNIE_STOP_HOOK_BLOCK_CAP` counter bounds runaway continuations the same way it bounds blocks.
* `{"systemMessage":"…"}` — user-facing payload. Shown in the TUI as `Stop hook: …`.

Both fields are accumulated across all hooks that ran in the chain.

## Merging hooks across configuration files

When multiple configuration files define hook entries for the same event, all entries from all files are concatenated.
Higher-priority files do not override lower-priority files; their entries are appended.

Only trusted sources participate in hook merging: user configuration and explicit `--config-location` files.
Default project-local `hooks` entries are skipped and reported as a hook configuration warning.

For the configuration precedence order, see [Configuration files](Junie-CLI-configuration.md#configuration-precedence).

## Limitations

* The supported events are `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `Stop`, `StopFailure`, `PermissionRequest`, and `SessionEnd`.
* `UserPromptSubmit` is currently triggered only from the interactive TUI; batch, ACP, and server hosts do not invoke it.
* `SessionStart`, `PreToolUse`, `Stop`, `StopFailure`, `PermissionRequest`, and `SessionEnd` are currently triggered from the interactive TUI and batch hosts; ACP and server hosts do not invoke them.
* `StopFailure` is observability-only — it cannot block, retry, or abort the agent. Output and exit code are ignored; `decision: block` and `continue: false` are demoted to TUI failure notifications.
* `StopFailure` fires only on classified LLM/API failures (the 9 `error` values listed in the [StopFailure](#stopfailure) section). Tool-execution failures, project pre-flight / shell-setup failures, and user-initiated cancellations do not fire it; the tool-error surface will be covered by a future `PostToolUseFailure` hook.
* Only `type: "command"` hooks are supported.
* Hooks within a single entry run sequentially. Parallel execution is not supported.
* `SessionEnd` hooks cannot block session termination, even if they return a non-zero exit code or `decision: block` in their stdout.
* `SessionEnd` dispatch has a total budget of 10 seconds across all matched entries combined; a longer per-command `timeout` will be effectively bounded by this overall budget.
* `Stop` hooks do not run for chat-type tasks.
* `blockOnError` is a Junie extension and is honoured for `Stop` hooks only. It is ignored on other events to avoid silently blocking prompt submission or session lifecycle.
* The `Stop` stdin contains only `hook_event_name`, `stop_hook_active`, and `last_assistant_message`.
* On `/new` or any other interactive session switch, the outgoing session is not terminated — it continues running in the background, so its `SessionEnd` hook is **not** dispatched on the switch. Only the incoming session's `SessionStart` hook fires (with `source: clear` for a fresh `/new`, `source: resume` for a cold-loaded resumed id). Re-foregrounding a session that is already live in the same CLI process fires no hooks at all — neither `SessionStart` nor `SessionEnd`.
* Hook output is discarded for `SessionEnd`. For `PreToolUse`, `additionalContext` is added to the model context and `updatedInput` can replace the tool's input for that call.
* The `SessionStart`/`UserPromptSubmit`/`SessionEnd` executors log `continue: false` as a failure but do not yet halt the session, cancel the prompt, or abort startup. Only `Stop` maps `continue: false` to a real abort action.
* `additionalContext` on stdout — agent-facing. For **sync** hooks: `UserPromptSubmit` prepends it to the prompt; `Stop` folds it into the agent's observer message on block / hard-halt retries **and** on a plain successful exit (Claude-style continue, see [Stop hook blocking and retries](#stop-hook-blocking-and-retries)); `PreToolUse` adds it to the model context for that tool step; `SessionStart`, `SessionEnd`, and `PermissionRequest` ignore it. For **async** hooks (`async: true`): the field is queued and prepended to the next user submit regardless of the originating event.
* `systemMessage` on stdout — user-facing TUI info message. For sync hooks, currently honoured by the `Stop` executor only. For async hooks, published on completion as `<Event> hook: <message>` for any event that supports `async: true`.
* `PermissionRequest` hooks fire for all permission dialogs regardless of whether the agent triggered the action autonomously or the user requested it directly.
