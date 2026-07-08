---
name: junie-cli-docs
description: Complete documentation for using Junie CLI in the terminal. Use this skill when the user asks about Junie itself, its features, configuration, where agent sessions/settings/logs are located, or CLI commands.
---

# Junie CLI documentation

Use this skill when you need complete Junie CLI documentation.
The full documentation bundle is embedded below

**IMPORTANT**: The agent cannot directly execute Junie CLI commands (such as `new`, `usage`, `model`, etc.).
The agent can only suggest to the user which commands to run.

## Full documentation

### Quickstart

# Quickstart

<show-structure for="chapter,procedure" depth="3"/>

**Junie CLI** is the agentic coding tool by JetBrains that provides an interactive terminal interface for developers to 
review, write, and modify code.

<procedure title="Supported operating systems" id="supported-operating-systems">
Junie CLI is available on Linux, macOS, and Windows.
</procedure>

## Step 1: Install Junie CLI {level="3"}

In the terminal or command prompt of your choice, run:

<tabs>
    <tab title="Linux / macOS">
        <code-block lang="Console">curl -fsSL https://junie.jetbrains.com/install.sh | bash</code-block>
    </tab>
    <tab title="Windows">
        <code-block lang="PowerShell">powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm 'https://junie.jetbrains.com/install.ps1')"</code-block>
    </tab>
</tabs>

[//]: # (EAP channel:)

[//]: # (<code-block lang="Console">curl -fsSL https://junie.jetbrains.com/install-eap.sh | bash</code-block>)

## Step 2: Start Junie in your project {level="3"}

Navigate to the root directory of the project where you want to use Junie CLI and run `junie`:

```console
cd /path/to/your/project
```

```sh
junie
```

## Step 3: Authenticate {level="3"}

On the Junie welcome screen, select one of the available authentication options:

* **Log in with your JetBrains Account**

    Use Junie CLI as part of your subscription plan with JetBrains. When selecting this option, you'll be redirected to 
the JetBrains Junie login page in your browser.

* **Use `JUNIE_API_KEY`** 

    Run Junie CLI with usage-based billing. When selecting this option, you'll be prompted to provide an access 
token. To generate your `JUNIE_API_KEY` access token, go to [junie.jetbrains.com/cli](https://junie.jetbrains.com/cli).

* **[Bring Your Own Key (BYOK)](BYOK.md)**

    Use your own API keys or OAuth tokens from Anthropic, OpenAI, Google, or other third-party LLM providers.
    Junie CLI uses these API keys to send requests to LLMs directly without requiring a JetBrains AI subscription.

    BYOK can be used on its own or together with JetBrains Account authorization or Junie API key.
    If a model is available through both the BYOK API key and JetBrains AI subscription, the requests are billed to your BYOK provider directly.

[//]: # (> By authenticating with Junie CLI, you agree to [Junie Terms of Service]&#40;https://junie.jetbrains.com/tos-eap&#41;.)

[//]: # (> {style="note"})

## Step 4: Type your prompt {level="3"} 

Type the prompt in the interactive CLI, for example:

```Console
> give me an overview of this codebase
```

Use `@` to attach a file or folder from the current project to the request context. 
To see the list of available slash commands and use them, type `/`.

### Real-time follow-ups

You can type follow-up prompts while Junie CLI is working on the task without waiting for it to finish.
The added clarifications are appended to the initial prompt and taken into account by the agent immediately.

### Reference files and directories

Use `@` to quickly reference files or directories in your prompt.

[//]: # (When you include file paths directly in the prompt using the `@<path>` syntax, the CLI now validates those paths and sends only the ones that actually exist on your machine.)

[//]: # ()
[//]: # (- Non-existent paths are ignored silently and are not attached to the request.)

[//]: # (- Existing paths are attached and will be available to Junie during task processing.)

[//]: # (- Use your OS-native path format &#40;the CLI checks paths using the local filesystem&#41;.)

![](reference_files_and_folders.png){width="706"}

You can also drag and drop files and images into the terminal window to reference them.

### Image inputs

Drag and drop or reference screenshots or design specs in the prompt for Junie CLI to read the image details.
Junie CLI accepts all common image formats such as PNG and JPEG.

### Search the prompt history

Junie CLI preserves your prompt history across all sessions and application runs.

To search the prompt history, use `Ctrl+R`, and then navigate through the results using Up and Down arrow keys.

## Slash commands and shortcuts

Slash commands allow you to access various Junie CLI features directly from the prompt.
Type `/` in the prompt to see and use the [available slash commands](Slash-commands.md).

Some built-in slash commands accept user prompts as arguments. For example, `/new fix tests` [starts a new session](#clear-up-session-context) with
`fix tests` in the prompt, and `/plan refactor commands` enables [plan mode](#plan-mode) and submits `refactor commands` immediately.

In addition to the built-in commands, you can [add custom slash commands](Custom-slash-commands.md) for frequently used prompts and
repetitive tasks.

To see all available shortcuts, type `?`.

## Run shell commands

You can run shell commands without leaving Junie CLI by prefixing it with `!`, for example:

```
!ls -la
```

## Command approval

For running potentially sensitive actions, such as executing most of the terminal commands,
editing files outside the project, or invoking MCP tools, Junie CLI will ask for approval from the user.

### Action Allowlist

When Junie CLI stops for user approval, you can select the **→ Always allow** option to add
the indicated command to the Action Allowlist. Once on the Action Allowlist, the command will always be executed
without user approval in the future Junie CLI runs.

![](action_allowlist_junie_cli.png){width="706"}

The full list of allowed commands and command patterns is stored in the `~/.junie/allowlist.json` file. You can also
edit this file manually to add or remove allowed or restricted commands and patterns. For details, see
[Action Allowlist configuration](Action-Allowlist-Junie-CLI.md).

### Brave mode

Brave mode controls how much Junie CLI relies on user approval before running potentially sensitive actions.
It has three levels that you can cycle through with the `/brave` slash command or the `Ctrl+B` shortcut:

* **Off** – Junie CLI asks for approval for every potentially sensitive action that is not on the Action Allowlist.
  This is the most conservative behavior.
* **Auto** – Junie CLI classifies terminal commands with a safety check and automatically approves the ones it
  considers safe, while still asking for approval for risky or unrecognized commands and for other sensitive actions.
* **On** – Junie CLI executes all potentially sensitive actions without user approval.

![](brave_mode_on.png){width="706"}

## Plan mode

In plan mode, Junie CLI analyzes the codebase with read-only operations and produces a design document for the task
before any code is written. Toggle plan mode with the `Shift+Tab` shortcut or the `/plan` slash command.

You can also start Junie CLI directly in plan mode using the `--plan` flag:

```bash
junie --plan
junie --prompt "Refactor the commands module" --plan
```

For details, see [Plan mode](Junie-CLI-Plan-Mode.md).

## Debug mode

In debug mode, Junie CLI acts as an AI debugging assistant that manages breakpoints, inspects runtime state, and
evaluates expressions against a live debugger session in a connected JetBrains IDE. Toggle debug mode with the
`Shift+Tab+Tab` shortcut or the `/debug` slash command. For details, see [Debug Mode](Junie-CLI-Debug-Mode.md).

[//]: # (## Terminal mode)

[//]: # (You can run shell commands directly within Junie to inspect your project or run tests:)

[//]: # (1. Type `!` followed by your command &#40;e.g., `!./gradlew test`&#41;.)

[//]: # (2. Junie will execute the command and display the output.)

[//]: # (3. You can also type `/terminal` to enter a persistent terminal session.)

## Local code review {id="local-code-review"}

Use the `/review` slash command to run a code review of your local changes before you commit them. Junie CLI uses
the same review backend as [automated code reviews](Automated-code-reviews.md) on GitHub, so the feedback you get
locally is consistent with what would be reported on a pull request.

When you run `/review`, Junie CLI detects the git state of the project and offers a wizard with only the
review targets that make sense in the current state:

- **From Main**: review your current branch against `main`. Shown only when a `main` branch exists and you are
  not currently on it (there is nothing to compare if you are already on `main`).
- **Last Commit**: review the diff of the most recent commit. Always available as long as the project has at
  least one commit.
- **Unstaged Changes**: review changes that are not yet staged. Shown only when there are actual unstaged
  changes in the working tree.

Pick an option, and Junie CLI will start a review task that comments on the selected diff.

![](review_wizard.png){width="706"}

After the review is complete, Junie CLI presents the findings and lets you accept or dismiss individual comments.

![](review_results.png){width="706"}

> `/review` requires the current project to be a Git repository. If no `.git` directory is found, Junie CLI reports
> that no git repository was detected and does not start the wizard.
> {style="note"}

## Manage your account

Use the `/account` command to manage your credentials and API keys:

* Select **Junie Account** to authenticate with Junie CLI via JetBrains Account or a Junie API key.

  To generate a `JUNIE_API_KEY` access token, go to [junie.jetbrains.com/cli](https://junie.jetbrains.com/cli).

* Select **Bring Your Own Key (BYOK)** to add API keys for LLM providers like OpenAI, Anthropic, Google, or xAI.

  > BYOK can be used on its own or together with JetBrains Account authorization.
  > If a model is available through both the BYOK API key and JetBrains AI subscription,
  > the requests are billed directly to the model provider without consuming credits from your JetBrains account.

## Manage your session

### Clear up session context

Use `/new` to clear up the context of the current session and start a new session in Junie CLI interactive mode.
Use `/new <prompt>` to start a new session with the prompt text already filled in.

### View session transcript

To access the full transcript of the current session, including all previous prompts and the agent output,
use the `Ctrl+T` shortcut.
When in the Transcript view, use `Ctrl+N` to load older entries, or `Esc` to return to the main view.

### Resume previous sessions

To see the session history and resume one of the previous sessions, use `/history`.

Junie CLI stores the full session context, including LLM usage data and the history of user prompts and agent responses,
for the last 10 sessions.

### Quit the session

To exit the Junie CLI interactive mode without losing login credentials, use `/quit`.
Alternatively, you can exit Junie CLI by using `Ctrl+C` twice.

### Continue the session in a browser

Use `/remote` to share the running Junie CLI session with the Junie web app and continue working on the same task
from another device. For details, see [Remote Mode](Junie-CLI-Remote-Mode.md).

## Model and effort {id="model-and-effort"}

Use `/model` to select the LLM and, for supported models, the reasoning **effort level** used for the current
session. `Default` is the recommended pre-selected option that uses a dynamically set model with the best
price-quality ratio.

The selection of available models depends on your [authentication method](Junie-CLI.md#step-3-authenticate) with
Junie CLI. With BYOK, only the provider-specific models are available.

![](model_selection_with_effort.png){width="706"}

### Effort level

For models that support adjustable reasoning effort (for example, recent Claude, GPT-5, and Gemini models), you can
pick how hard the model thinks before answering. The set of supported effort levels (such as `Low`, `Medium`,
`High`, `XHigh`, `Max`) depends on the selected model.

You can change the effort level in two ways:

- Use the `/model` command and pick an effort level alongside the model.
- Use the dedicated `/effort` command to change only the effort level for the current model.

![](effort_level_selection.png){width="706"}

You can also set the default effort level for new sessions with the `--effort <level>` CLI flag or the
`JUNIE_EFFORT` environment variable. For details, see [Model selection](Junie-CLI-Model-selection.md).

> We recommend keeping the default model and effort settings. Higher effort levels do not always produce noticeably
> better results, but they can cost significantly more and make the model take noticeably longer to respond as it
> spends more time reasoning. Increase the effort only when you have observed that a specific task benefits from it.
> {style="note"}

## Token usage and costs

The `/usage` command shows the cost breakdown for the current session, including token usage, used models, and remaining balance.

![](check_session_cost.png){width="706"}

## Extend Junie CLI

* [Model Context Protocol (MCP)](Junie-CLI-MCP-configuration.md)
* [](Agent-Skills.md)
* [Subagents](Junie-CLI-subagents.md)
* [](Custom-slash-commands.md)
* [Guidelines and memory](Guidelines-and-memory.md)

## Non-interactive (headless) mode

You can run Junie CLI in headless mode, that is, programmatically without interactive UI, in CI/CD environments
and build pipelines. 

To add Junie to your CI/CD script:

```bash
# Install Junie CLI
curl -fsSL https://junie.jetbrains.com/install.sh | bash

# Authenticate and run a task
junie --auth="$JUNIE_API_KEY" "Fix any failing tests"

# Run a code review of the latest commit
junie --auth="$JUNIE_API_KEY" --review
```
The `junie` command takes [options](Parameters.md) and [environment variables](Parameters.md#environment-variables). 

For more information and examples, see [Headless mode](Junie-headless.md).

## Junie in CI/CD pipelines

* [Junie GitHub Action](Junie-on-GitHub.md)
* [Junie GitLab CI/CD](Junie-GitLab-CI-CD.md)

### Bring Your Own Key (BYOK)

# Bring Your Own Key (BYOK)

Junie CLI supports using your own API keys from third-party LLM providers. Instead of relying on a JetBrains AI subscription, you can connect directly to providers like OpenAI, Anthropic, Google, xAI, OpenRouter, or GitHub Copilot.

## How it works

With BYOK, Junie sends requests to LLMs using your API key directly. All usage is billed by the provider — no JetBrains AI subscription is required.

You can also combine BYOK with a JetBrains Account or Junie API key. If a model is available through both your BYOK key and your JetBrains subscription, the BYOK key takes priority, and the requests are billed to your provider.

## Connect an external LLM provider

1. Run the `/account` slash command in an active Junie session, or select **Use external LLM providers** on the welcome screen.

   ![Use external LLM providers](byok_use_external_llm.png){width="600"}

2. Select a provider from the list and paste your API key when prompted.

   ![Select a provider](byok_select_openrouter.png){width="600"}

3. Once connected, use `/model` to see and switch between available models.

## Supported providers

| Provider | Key type |
|---|---|
| OpenAI | API key |
| Anthropic | API key |
| Google | API key |
| xAI | API key |
| OpenRouter | API key |
| Custom Profiles | JSON file |
<!-- | GitHub Copilot | OAuth token | -->

For step-by-step setup instructions, see the provider-specific guides below.
- [Connect a custom LLM provider](Custom-LLM-models.md)

### OpenRouter

# OpenRouter

OpenRouter is a unified API that gives you access to models from multiple providers — including Anthropic, OpenAI, Google, xAI, and others — through a single API key.

## Prerequisites

- An OpenRouter account. Sign up at [openrouter.ai](https://openrouter.ai) if you don't have one.
- An OpenRouter API key. Generate one from your [OpenRouter dashboard](https://openrouter.ai/keys).

## Set up OpenRouter in Junie

1. Start Junie in your project directory:

   ```sh
   junie
   ```

2. Run the `/account` command and select **Use external LLM providers**.

   ![Select Use external LLM providers](byok_use_external_llm.png){width="600"}

3. Select **OpenRouter** from the provider list.

   ![Select OpenRouter](byok_select_openrouter.png){width="600"}

4. Paste your OpenRouter API key when prompted.

## Select a model

Once connected, run `/model` to see the available models and select one:

![Available models via OpenRouter](byok_openrouter_models.png){width="600"}

The model list shows models available through your OpenRouter key, along with pricing info. Use the arrow keys to navigate and press Enter to select a model.

## Additional resources

- [OpenRouter guide for coding agents](https://openrouter.ai/docs/guides/guides/coding-agents/junie)

### Early Access Program (EAP)

# Early Access Program (EAP)

<show-structure for="chapter" depth="2" />

The Early Access Program (EAP) gives you access to pre-release versions of Junie CLI with the latest features and improvements
before they are generally available.

> By participating in the EAP, you agree to the [JetBrains Junie Terms of Service](https://www.jetbrains.com/legal/docs/terms/jetbrains-junie/),
> including the EAP-specific terms. "EAP" means any of the pre-release versions of the product made available under these Terms
> as determined by JetBrains.
> {style="note"}

## Join the EAP {id="join-eap"}

The EAP is free to join and includes a monthly usage quota at no cost. To request access, fill out the [Contact Form](https://intellij-support.jetbrains.com/hc/en-us/requests/new?ticket_form_id=66731).

We are actively looking for developers working with the following languages and technologies:

- C and C++
- PHP
- Rust
- Java

If you work with any of these languages, we especially encourage you to apply.

## Install the Early Access version {id="install-eap"}

To install the Early Access version of Junie CLI, run the following command in your terminal:

<tabs>
    <tab title="Linux / macOS">
        <code-block lang="Console">curl -fsSL https://junie.jetbrains.com/install-eap.sh | bash</code-block>
    </tab>
    <tab title="Windows">
        <code-block lang="PowerShell">powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm 'https://junie.jetbrains.com/install-eap.ps1')"</code-block>
    </tab>
</tabs>

To verify the installation, restart your shell if needed and run:

<code-block lang="Console">junie --version</code-block>


## Switch between EAP and stable versions {id="switch-versions"}

To switch back to the stable version, remove the local Junie launcher first:

<tabs>
    <tab title="Linux / macOS">
        <code-block lang="Console">rm ~/.local/bin/junie</code-block>
    </tab>
    <tab title="Windows">
        <code-block lang="PowerShell">Remove-Item "$HOME\.local\bin\junie.bat"</code-block>
    </tab>
</tabs>

Then install the stable version using the standard installation command:

<tabs>
    <tab title="Linux / macOS">
        <code-block lang="Console">curl -fsSL https://junie.jetbrains.com/install.sh | bash</code-block>
    </tab>
    <tab title="Windows">
        <code-block lang="PowerShell">powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm 'https://junie.jetbrains.com/install.ps1')"</code-block>
    </tab>
</tabs>

For more details on the standard installation process, see the [Quickstart](Junie-CLI.md).

### Integration with JetBrains IDEs

# Integration with JetBrains IDEs

<show-structure for="chapter" depth="3" />

This page describes how Junie CLI integrates with JetBrains IDEs, what products are supported, which features depend on the JetBrains IDE connection, and how to inspect the connection with `/ide`.

## What JetBrains IDE integration does

When JetBrains IDE integration is available, Junie CLI can connect to the Junie plugin running inside a JetBrains IDE for the same project and use JetBrains IDE awareness for that session.

This improves features that depend on project understanding inside the IDE, such as symbol-aware search, safer code edits, code inspections, test workflows, and product-specific actions.

JetBrains IDE integration requires the Junie IDE plugin. For installation and setup details, see [Junie IDE plugin](Junie-IDE-plugin.md).

JetBrains IDE integration is passive from the CLI side:

- The IDE plugin becomes available automatically when you open the same project.
- The CLI discovers running IDE sessions automatically.
- The CLI selects the best matching JetBrains IDE for the current working directory.
- The CLI connects to the JetBrains IDE only when IDE-backed features are needed or when you inspect the state with `/ide`.

> Junie CLI currently supports only JetBrains IDEs for this integration. It does not connect to non-JetBrains editors or IDEs.
> {style="note"}

## Supported JetBrains IDEs

The current IDE discovery implementation supports these JetBrains IDEs:

- ![CLion](CLion_icon.png){width="25"} [CLion](https://www.jetbrains.com/clion/)
- ![GoLand](GoLand_icon.png){width="25"} [GoLand](https://www.jetbrains.com/go/)
- ![IntelliJ IDEA](IntelliJ_IDEA_icon.png){width="25"} [IntelliJ IDEA](https://www.jetbrains.com/idea/)
- ![PhpStorm](PhpStorm_icon.png){width="25"} [PhpStorm](https://www.jetbrains.com/phpstorm/)
- ![PyCharm](PyCharm_icon.png){width="25"} [PyCharm](https://www.jetbrains.com/pycharm/)
- ![Rider](Rider_icon.png){width="25"} [Rider](https://www.jetbrains.com/rider/)
- ![RubyMine](RubyMine_icon.png){width="25"} [RubyMine](https://www.jetbrains.com/ruby/)
- ![RustRover](RustRover_icon.png){width="25"} [RustRover](https://www.jetbrains.com/rust/)
- ![WebStorm](WebStorm_icon.png){width="25"} [WebStorm](https://www.jetbrains.com/webstorm/)

Support means that the CLI can detect installed and running instances of these products and match them to the current 
project when the [Junie plugin](Junie-IDE-plugin.md) is available.

## What features are affected

The JetBrains IDE connection affects user-visible features that benefit from the IDE understanding your project.

In practice, JetBrains IDE integration can improve tasks such as:

- Code search with symbol awareness and project indexes.
- Code edits that use the IDE understanding of your project structure.
- Code inspections and structure-aware analysis.
- Test discovery and test execution from the IDE project context.
- Refactorings and other project-aware changes.
- Product-specific workflows in IDEs such as CLion or Rider.

JetBrains IDE integration also improves `@` completions in the prompt. When the IDE is connected, Junie CLI can suggest not only project files and folders, but also classes and symbols known to the connected JetBrains IDE.

The CLI can also use JetBrains IDE context for the session, such as which files are currently open in the IDE.

If no JetBrains IDE is connected, Junie CLI can still work, but IDE-backed capabilities are unavailable.

## Requirements

For JetBrains IDE integration to work:

- Open the target project in a supported JetBrains IDE.
- Make sure the Junie plugin is installed and running.
- Open the same project so the IDE integration can start.
- Run Junie CLI from the same project or a child directory of that project.

If the project paths do not match, the CLI will not select that IDE session.

## Use the `/ide` command

Use `/ide` in Junie CLI to inspect the current JetBrains IDE integration state.

What `/ide` does:

- Lists running IDEs and their states.
- Allows you to switch between multiple IDEs and projects.
- Helps install the plugin if it is missing.

### Possible states

| State | Meaning |
|------|---------|
| `Connected` | The CLI is connected to that JetBrains IDE and can use JetBrains IDE-backed features |
| `Connecting…` | The CLI found a matching JetBrains IDE and is opening the connection |
| `Auth required` | The JetBrains IDE session is running, but the current connection is no longer authorized |
| `Error` | The JetBrains IDE was found, but the connection failed for another reason |
| `Ready` | The Junie plugin for that JetBrains IDE is available and can be selected |
| `Missing` | The Junie plugin is not installed for that JetBrains IDE |
| `Not responding` | The Junie plugin is installed, but it is not responding |
| `Unsupported` | That JetBrains IDE version is too old for Junie IDE integration |
{width="706"}

### Notes

- `/ide` is a status command. It does not start a JetBrains IDE or enable JetBrains IDE integration by itself.
- The available features depend on the connected JetBrains IDE, the open project, and which capabilities are available in that session.
- If several JetBrains IDEs are running, the CLI prefers the one whose project path matches the current working directory most closely.
- `/ide` reports only JetBrains IDE integration state. It does not represent support for other editors or IDEs.

## Troubleshooting

| Problem | What to check |
|---------|---------------|
| `/ide` shows `Missing` | Install the Junie plugin for that JetBrains IDE, then wait a moment and run `/ide` again |
| `/ide` shows `Auth required` | Restart the JetBrains IDE, then run `/ide` again. If the problem stays, inspect `~/.junie/logs/junie.log` |
| `/ide` shows `Not responding` | Check whether the Junie plugin is enabled and update it to the latest version if needed |
| `/ide` shows `Error` | Check `~/.junie/logs/junie.log` for the connection error and verify that the JetBrains IDE project path matches the CLI working directory |
| `/ide` shows `Unsupported` | Update that JetBrains IDE to version `2026.1` or newer |
| `/ide` shows few available features after connecting | Verify that the JetBrains IDE session is fully loaded for that project and that the required JetBrains IDE features are available for that product and project |
{width="706"}

## Related documentation

- [Using Junie in the terminal](Junie-CLI.md)
- [Junie for ACP clients](Junie-CLI-ACP.md)
- [Junie IDE plugin](Junie-IDE-plugin.md)

### config.json

# config.json

Junie CLI can load settings from JSON configuration files in addition to command-line flags and environment variables.
Configuration files are useful when you want to keep shared project defaults in the repository or define personal defaults once for all projects.

## Default configuration locations

By default, Junie CLI looks for `config.json` in these locations:

* **User scope**: `~/.junie/config.json`
* **Project scope**: `<project-root>/.junie/config.json`

The project-level configuration is intended for settings that should be shared with the whole team.
The user-level configuration is intended for personal defaults on your machine.

## Configuration precedence

When the same setting is defined in multiple places, Junie resolves it in this order
(highest priority first):

1. Command-line flags
2. User settings from `~/.junie/settings.json`
3. Project configuration from `<project-root>/.junie/config.json`
4. User configuration from `~/.junie/config.json`

For example, if `~/.junie/config.json` sets `"model": "sonnet"`, the project config sets `"model": "gpt"`,
and you run `junie --model opus`, the effective model is `opus`.

## Add extra configuration files

To load additional configuration files, use `--config-location`.
You can specify it multiple times:

```bash
junie \
  --config-location /opt/company/junie/config.json \
  --config-location ./configs/junie.local.json
```

To disable loading from the default user and project locations, use `--config-default-locations false`.

For CI, you can use the equivalent environment variables:

| Environment variable | CLI equivalent | Description |
|---|---|---|
| <code-block>JUNIE_CONFIG_LOCATION</code-block> | <code-block>--config-location</code-block> | Additional configuration file paths. Can be specified multiple times. |
| <code-block>JUNIE_CONFIG_DEFAULT_LOCATIONS</code-block> | <code-block>--config-default-locations</code-block> | Enable or disable loading `config.json` from the default user and project locations. Defaults to `true`. |

## Supported configuration fields

The following JSON fields are currently supported in `config.json`:

| Field | Description |
|---|---|
| `model` | Default model to use. For supported built-in model IDs and custom model profiles, see [Model selection](Junie-CLI-Model-selection.md) and [Custom LLM models](Custom-LLM-models.md). |
| `provider` | Default BYOK provider. For supported provider values, see [LLM providers](Junie-CLI-Model-selection.md#llm-providers). |
| `brave` | Enables brave mode by default. |
| `flags` | Additional feature flags. |
| `mcp-locations` | Extra folders where Junie should search for MCP configurations. |
| `mcp-default-locations` | Enable or disable the default MCP locations. |
| `skill-locations` | Extra folders where Junie should search for agent skills. |
| `skill-default-locations` | Enable or disable the default skill locations. |
| `command-locations` | Extra folders where Junie should search for custom slash commands. |
| `command-default-locations` | Enable or disable the default custom slash command locations. |
| `agent-locations` | Extra folders where Junie should search for custom agents. |
| `agent-default-location` | Enable or disable the default custom agent locations. |
| `model-locations` | Extra folders where Junie should search for custom model profiles. |
| `model-default-locations` | Enable or disable the default model locations. |
| `auto-update` | Enable or disable automatic update checks. |
| `guidelines-location` | Path to the guidelines file Junie should use. |
| `time-limit` | Default task time limit. |
| `byok` | Default BYOK API keys for supported providers. |
| `proxies` | Custom proxy endpoints for routing LLM traffic. |
| `hooks` | Shell commands to run on session lifecycle events. See [Hooks](Junie-CLI-hooks.md). |

Relative paths in `config.json` are resolved relative to the folder that contains that configuration file.

For safety, `hooks` from the default project configuration file are ignored.
Use `~/.junie/config.json` for personal hooks, or pass a hook config file explicitly with `--config-location`.

## Example configuration file

```json
{
  "model": "sonnet",
  "provider": "anthropic",
  "brave": false,
  "flags": ["copilot"],
  "mcp-locations": ["./mcp", "./shared/mcp"],
  "mcp-default-locations": true,
  "skill-locations": ["./skills"],
  "skill-default-locations": true,
  "command-locations": ["./commands"],
  "command-default-locations": true,
  "agent-locations": ["./agents"],
  "agent-default-location": true,
  "model-locations": ["./models"],
  "model-default-locations": true,
  "auto-update": true,
  "guidelines-location": "./team-guidelines.md",
  "time-limit": 3600,
  "byok": {
    "anthropic": "sk-ant-...",
    "openai": "sk-..."
  },
  "proxies": [
    {
      "name": "my-proxy",
      "kind": "Ingrazzio",
      "api-url": "https://my-ingrazzio-instance.example.com",
      "headers": ["X-Custom-Header: value"]
    }
  ],
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "aws sso login --profile dev" }
        ]
      }
    ]
  }
}
```

## How configuration combines with other features

Configuration files control discovery for several other Junie CLI features:

* [MCP configuration](Junie-CLI-MCP-configuration.md)
* [Agent skills](Agent-Skills.md)
* [Custom slash commands](Custom-slash-commands.md)
* [Custom LLM models](Custom-LLM-models.md)
* [Guidelines and memory](Guidelines-and-memory.md)
* [Hooks](Junie-CLI-hooks.md)

For the exact command-line flags, see [CLI reference](Parameters.md).

### Action Allowlist

# Add commands to Action Allowlist

If [brave mode](Junie-CLI.md#brave-mode) is not explicitly enabled, Junie CLI will ask for user approval before 
running terminal commands, MCP tools, and other [types of actions](Action-Allowlist.md#types-of-action-allowlist-rules) 
that are considered to be sensitive by the coding agent.

You can manually add or remove allowed commands by editing the `~/.junie/allowlist.json` file.

There are three types of actions that can be allowed with the `allowlist.json` file:

* `fileEditing`: editing files outside the project directory where Junie CLI is launched; editing build scripts outside 
    or inside the project directory.
* `executables`: running terminal commands, including execution of tests, running apps, or build actions.
* `mcpTools`: usage of Model Context Protocol (MCP) tools.
* `readOutsideProject`: reading files outside the current project directory where Junie CLI is launched.

An example `allowlist.json` file looks as follows:

```json
{
  "defaultBehavior": "ask",
  "allowReadonlyCommands": true,
  "rules": {
    "fileEditing": {
      "rules": [
        {
          "prefix": "src/main/kotlin/", // The path is relative to the current project directory. For absolute paths, start with `/`.
          "action": "allow"
        }
      ]
    },
    "executables": {
      "rules": [
        {
          "prefix": "git",
          "action": "allow"
        },
        {
          "pattern": "grep **",
          "action": "allow"
        },
        {
          "pattern": "npm [iur]*",
          "action": "ask"
        }
      ]
    },
    "mcpTools": {
      "rules": [
        {
          "prefix": "github-server:",
          "action": "allow"
        }
      ]
    },
    "readOutsideProject": {
      "rules": [
        { 
          "pattern": "/etc/**", 
          "action": "ask"
        }
      ]
    }
  }
}
```

Each rule must specify either a `prefix` or a `pattern`, along with an `action` (`allow` or `ask`).
Select the appropriate action type and edit its `rules` array:

| Field     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|-----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `prefix`  | Set a literal string to match all commands that start with it. <br><br>For example, indicating a `git` prefix allows all `git` commands (`git status`, `git commit`, `git push`, etc.).                                                                                                                                                                                                                                                                                                                                                      |
| `pattern` | Set a pattern using wildcard characters (Glob syntax): <list><li>`*` – Matches zero or more arbitrary characters, except for the path separator `/`.</li><li>`**` – Matches zero or more arbitrary characters, including the path separator `/`.</li><li>`?` – Matches exactly one arbitrary character, except for the path separator `/`.</li><li>`[abc]` – Matches any single character from the characters listed in brackets.</li><li>`[!abc]` – Matches any single character except for the characters listed in brackets.</li></list> |
| `action`  | The action to take for the command. Possible values: <list><li>`allow` – Execute automatically without user approval.</li><li>`ask` – Prompt for user approval before execution.</li></list>                                                                                                                                                                                                                                                                                                                                                 |
{width="706"}

Rules are evaluated top to bottom, with the first match taking precedence. Thus, in the following example, `npm install`
will ask for permission, but `npm test` will be allowed automatically:

```json
{                                                                                                                                                                                                             
     "rules": [                                                                                                                                                                                                  
       {                                                                                                                                                                                                         
         "pattern": "npm install *",                                                                                                                                                                              
         "action": "ask"                                                                                                                                                                                         
       },                                                                                                                                                                                                        
       {                                                                                                                                                                                                         
         "prefix": "npm",                                                                                                                                                                                        
         "action": "allow"                                                                                                                                                                                       
       }                                                                                                                                                                                                         
     ]                                                                                                                                                                                                           
   }
```

### Agent skills

# Agent skills

<show-structure for="chapter" depth="3"/>

Every project has patterns that shouldn't require explaining twice — naming conventions, test structure, deployment 
steps, code review rules. Agent skills let you codify these once and Junie follows them automatically whenever 
they're relevant.

Agent skills are folders with instructions, templates, scripts, and reference materials that provide Junie with 
task-specific context. Skills follow the open [Agent Skills](https://agentskills.io/specification) 
format and are portable across agents.

Unlike [guidelines](Guidelines-and-memory.md), which are applied with every prompt, agent skills are only invoked when they match
the needs of the current task. Junie follows the skill instructions, loading referenced materials or executing 
bundled scripts as needed.

Skills work in both [Junie CLI](Junie-CLI.md) and [Junie in JetBrains IDEs](Junie-IDE-plugin.md).

> Junie is included with your [JetBrains AI subscription](https://www.jetbrains.com/ai/). Open your IDE, press 
> <shortcut>Shift+Tab</shortcut>, and ask Junie to create a skill for your project.
> {style="tip" title="Try it now"}

## Why agent skills?

Think of skills as cheat sheets that Junie consults when working on specific types of tasks to produce better results.
The benefits of agent skills are:

* **Progressive disclosure**: each skill's name and description are available to Junie, so it knows what skills exist, 
but doesn't read the full content of a skill until it determines its relevance to the task.
* **Instructions with attached files**: instructions are bundled with reference materials such as templates or 
assets, so Junie has all the context it needs to complete the task.  
* **Portability**: if your project already has skill folders from other agents (`.cursor/skills/`, `.claude/skills/`, 
or `.codex/skills/`), Junie CLI will detect them and suggest importing into Junie's `.junie/skills/` directory.

## What you can do with skills

Here are real examples of what teams build with skills:

| Skill                 | What it does                                                                                            |
|-----------------------|---------------------------------------------------------------------------------------------------------|
| API scaffolding       | Creates REST endpoints with validation, tests, and OpenAPI docs that follow your project's conventions. |
| Code review           | Catches null safety issues, naming violations, and anti-patterns against your team's style guide.       |
| Database migration    | Generates Flyway or Liquibase scripts that follow your existing migration patterns.                     |
| Test coverage         | Identifies untested paths and generates tests matching your project's existing test style.              |
| CI/CD pipeline        | Builds GitHub Actions or GitLab CI configs that follow your deployment conventions.                     |
| Component templates   | Scaffolds UI components with your team's file structure, naming, and boilerplate.                       |
{width="706"}

Each skill is a folder you can check into version control and share across your team.


## How Junie CLI uses skills

Junie CLI invokes agent skills *automatically*. It scans folders inside `.junie/skills/` at the user and project 
levels and selects the skills that are relevant to the current task.

### Skill location

Junie CLI looks for skill folders in two locations:

* **Project scope**: `<projectRoot>/.junie/skills/<skill-name>/`. 

  Skills in this folder are available only in the current 
   project but can be checked into version control and shared across all team members. 
    
* **User scope**: `~/.junie/skills/<skill-name>/` on macOS/Linux or `%\USERPROFILE%\.junie\skills\<skill-name>\` on Windows. 

  Skills in this folder are available globally across all projects on your machine while remaining private to your user account.

[//]: # (> The default user-level path can be changed by setting the `JUNIE_HOME` environment)
[//]: # (> variable. In that case, skills are loaded from `$JUNIE_HOME/skills/` &#40;macOS/Linux&#41; or `%\JUNIE_HOME%\skills\` &#40;Windows&#41;.)

> If a project-level (`<projectRoot>/.junie/skills/<skill-name>/`) and a user-level (`~/.junie/skills/<skill-name>/`) 
> skills share the same name, the project-level skill takes precedence and the user-level skill is ignored.
> {style="note" title="Scope priority"}

[//]: # (When you add or update skills, Junie CLI notifies you at the start of the next session.)

### Skill directory structure

Each skill lives in its own folder under the `.junie/skills` directory:

```
.junie/skills/
├── my-skill/
│   ├── SKILL.md              # Required: Main skill documentation
│   ├── scripts/              # Optional: Executable scripts
│   │   └── setup.sh
│   ├── templates/            # Optional: Code or doc templates
│   │   └── component.kt
│   └── checklists/           # Optional: Detailed checklists
│       └── review.md
├── another-skill/
│   └── SKILL.md
```

- The `SKILL.md` file is **required**. A folder without it is not recognized as a skill.
- Subdirectories are optional and can contain any supporting files (checklists, scripts, templates, etc.) that Junie CLI
  can read when needed.

### `SKILL.md` format

The `SKILL.md` file uses Markdown with a YAML frontmatter header:

```Markdown
---
name: my-skill-name
description: A short description of what this skill provides
---

# My Skill Name

Use this skill when [describe when Junie should use this skill].

## Key Principles
- Principle 1
- Principle 2

## Guidelines
- Guideline 1
- Guideline 2

## Examples

[Include code examples, patterns, or references to project files]

## Checklist

See `checklists/review.md` for a detailed checklist.
```

#### Frontmatter fields

| Field         | Type   | Required | Description                                                                                    |
|---------------|--------|----------|------------------------------------------------------------------------------------------------|
| `name`        | String | **Yes**  | A unique identifier for the skill.                                                             |
| `description` | String | No       | A short summary that Junie CLI can use to determine the skill's relevance to the current task. |
{width="706"}

> If `description` is not provided in the frontmatter, Junie CLI extracts the first paragraph of the body content
> as the description. If the body is also empty or contains only headings, the skill will fail to load.
> For best results, always provide an explicit `description`. Accurate description helps Junie CLI trigger the skill at the right time.
> {style="note" title="Description fallback"}

#### Body content

The body (everything after the closing `---`) is the main skill documentation, which should contain actionable 
instructions that Junie CLI should follow along with the paths to relevant project files, templates, or additional 
materials within the skill folder.

## Adding a skill

### Prompt Junie to add a skill

The easiest way to add a skill is to ask Junie to create it for you. Describe what you want the skill to cover, 
and Junie will generate the skill folder, `SKILL.md`, and any supporting files.

<procedure>

**Example prompt:**

Create a skill that enforces our API design conventions: all REST endpoints must use kebab-case URLs, return JSON
responses wrapped in a `{ data, error }` envelope, and include request validation using our shared `ValidationUtils`
class. Add a checklist for reviewing new endpoints.

</procedure>

You can also create skills on the fly from your current task if the guidelines or patterns Junie followed 
could be reused in future tasks.

<procedure>

**Example prompt:**

The conventions we've been following for database migrations in this task are useful — create a skill from them so we
follow the same approach next time.

</procedure>

### Create your own skill

1. Create a `.junie/skills/` directory.

2. Add a skill folder to the `.junie/skills/` directory.

3. Add a `SKILL.md` file to the skill folder.

```Markdown
---
name: my-new-skill
description: Provides guidelines for [specific domain or task]
---

# My New Skill

Use this skill when [describe the trigger conditions].

## Key Principles

- [Actionable principle 1]
- [Actionable principle 2]

## Guidelines

- [Specific guideline with examples]
- [Reference to project files: `path/to/relevant/file.kt`]

## Code Patterns

    ```kotlin
    // Example of the preferred pattern
    fun example() {
        // ...
    }
    ```
## Additional Resources

- See `checklists/my-checklist.md` for a detailed checklist.
- Run `scripts/setup.sh` to configure the environment.
```
{collapsible="true" default-state="collapsed" collapsed-title=".junie/skills/my-new-skill/SKILL.md"}

4. (Optional) Add supporting files to the skill folder.

    If your skill needs additional resources, create subdirectories with supporting files.

5. Verify that the skill loads. 

    Ask Junie to list its available skills to confirm it loaded correctly.

[//]: # (Start a new Junie session. You should see a notification that a new skill was detected.)

### Add skills from public repositories

You can import skills shared by the community or your organization by copying them from public Git repositories into
your skills directory.

<tabs>
<tab title="macOS/Linux">

```bash
# Clone the repo (or download just the skill folder)
git clone https://github.com/JetBrains/skills.git /tmp/junie-skills

# Copy a specific skill to your project
cp -r /tmp/junie-skills/spring-kotlin-code-review .junie/skills/

# Or copy to your global skills for use across all projects
cp -r /tmp/junie-skills/spring-kotlin-code-review ~/.junie/skills/

# Clean up
rm -rf /tmp/junie-skills
```
</tab>

<tab title="Windows">

```powershell
# Clone the repo (or download just the skill folder)
git clone https://github.com/JetBrains/skills.git $env:TEMP\junie-skills

# Copy a specific skill to your project
Copy-Item -Recurse -Force $env:TEMP\junie-skills\spring-kotlin-code-review .junie\skills\

# Or copy to your global skills for use across all projects
Copy-Item -Recurse -Force $env:TEMP\junie-skills\spring-kotlin-code-review "$env:USERPROFILE\.junie\skills\"

# Clean up
Remove-Item -Recurse -Force $env:TEMP\junie-skills
```
</tab>
</tabs>

>Junie modifies your code and executes scripts, so it's important to make sure that the skills it uses are safe.
>Treat third-party skills with the same caution as you would with any third-party code you add to your project:
>
>* Only use skills from sources you trust.
>* Read the `SKILL.md` file and all supporting files carefully.
>* Prefer pinning to a specific commit or tag rather than pulling from a branch that may change.
> 
{title="Always review skills from external sources before using them" style="warning"}

## Best practices

* Be specific and actionable, and provide as many details as possible. 

  Avoid vague instructions like *Write good tests*. Instead, prefer:
  
  ```markdown
  Use the AAA pattern (Arrange, Act, Assert). 
  One assertion concept per test. 
  Use fakes instead of mocking libraries.
  ```

* Include examples and show the exact patterns you want Junie to follow. 
Skills with code examples are significantly more effective. 

* Reference project files. Point Junie to existing code that exemplifies the desired patterns:

    ```markdown
    See `src/test/kotlin/com/example/MyServiceTest.kt` for a reference 
    test implementation.
    ```

* Keep it focused. Each skill should cover one domain or concern. Don't create a single monolithic skill that covers 
everything – create multiple focused skills instead.

* Use subdirectories for complex skills. If a skill has extensive documentation, break it into multiple files:
    - Main `SKILL.md` provides an overview and links to sub-documents.
  - `checklists/` for step-by-step verification lists.
  - `scripts/` for automation scripts Junie can execute.
  - `templates/` for boilerplate code Junie can use as starting points.

* Write a clear description. The `description` field is what Junie uses to decide whether a skill is relevant.
Although the field is optional (Junie CLI can extract a description from the body content), providing an explicit 
`description` is recommended so Junie can match the skill to the right tasks without ambiguity.

## Troubleshooting

<procedure collapsible="true" default-state="collapsed" title="Junie not using a skill">

- Junie selects skills based on task relevance. If a skill isn't being used, it may not match the current task, 
or its description may be too vague or generic. Make sure the skill's `description` clearly communicates when it should be used.
- Try asking Junie to use a specific skill explicitly, for example: *Use the testing skill to write tests for this module.*
- Check for name conflicts: if a project-level and a user-level skills have the same name, the user-level skill will be skipped.
- Verify the [SKILL.md file format](#skill-md-format) is followed: proper YAML formatting (no tabs, correct indentation), 
the YAML frontmatter starts with `---`, contains at least the `name` field, and ends with `---`; 
if `description` is omitted, make sure the body contains at least one paragraph of text so Junie CLI can extract a description.
- Check file permissions and encoding (UTF-8) for file read errors.
</procedure>

## Example skill folder

Below is an example code review skill that contains the main `SKILL.md` file and a referenced checklist.

```
.junie/skills/code-review/
├── SKILL.md
└── checklists/
    └── kotlin.md
```

```Markdown
---
name: code-review
description: Provides guidelines and checklists for thorough Kotlin code reviews
---

# Code Review Skill

Use this skill when reviewing Kotlin code for quality, correctness, and maintainability.

## Review Priorities

1. **Correctness**: does the code do what it's supposed to?
2. **Error Handling**: are errors handled gracefully?
3. **Readability**: is the code easy to understand?
4. **Performance**: are there obvious performance issues?
5. **Testing**: are there adequate tests?

## Kotlin-specific checks

- Prefer `val` over `var`
- Use data classes for value objects
- Prefer early returns over nested `if` blocks
- Use sealed classes for restricted hierarchies

## Detailed Checklist

See `checklists/kotlin.md` for a comprehensive review checklist.
```
{collapsible="true" default-state="collapsed" collapsed-title=".junie/skills/code-review/SKILL.md"}

```Markdown
# Kotlin Code Review Checklist

## Naming
- [ ] Classes use PascalCase
- [ ] Functions and variables use camelCase
- [ ] Constants use SCREAMING_SNAKE_CASE

## Null Safety
- [ ] Avoid `!!` operator
- [ ] Use `?.let {}` or safe calls
- [ ] Nullable types are justified

## Error Handling
- [ ] Errors are handled gracefully
- [ ] Error propagation is clean and readable

## Testing
- [ ] New code has corresponding tests
- [ ] Edge cases are covered
- [ ] Tests follow AAA pattern
```
{collapsible="true" default-state="collapsed" collapsed-title=".junie/skills/code-review/checklists/kotlin.md"}

## What's next

- [Get started with Junie](Get-started-with-Junie.topic) — install Junie and run your first task.
- [Guidelines and memory](Guidelines-and-memory.md) — project-wide rules that apply to every prompt.
- [Junie CLI usage](Junie-CLI.md) — command reference and configuration.
- [Custom LLM models](Custom-LLM-models.md) — use your own models with BYOK.

### MCP

<show-structure depth="3"/>

# Add and configure MCP servers

You can connect Junie CLI to external tools via Model Context Protocol (MCP).
Junie CLI uses the same MCP JSON configuration as
[Junie in JetBrains IDEs](Junie-IDE-plugin.md#mcp-configuration).

The `/mcp` slash command shows the [list of configured MCP servers](#list-configured-mcp-servers) and the
[MCP Installation Assistant](#mcp-installation-assistant) to guide you through
adding, editing, or troubleshooting configs for MCP servers.

[//]: # (TODO: differentiation between inactive and failed statuses is not clear)

## MCP Installation Assistant

Junie's MCP Installation Assistant is an AI helper that streamlines and simplifies the process of adding new MCP servers.
It guides you through adding MCP servers from a registry of pre-configured servers or from scratch.

When adding a server from the registry, Junie CLI automatically configures the correct command or URL and prompts the user for 
any required secrets or environment variables.

When adding a server from scratch, it searches the [official MCP registry](https://registry.modelcontextprotocol.io/)
for the proper server configuration, prompts for parameters, env variables, secrets, or API tokens if needed, adds the server
configuration to the `mcp.json` file, and verifies the server startup.

![](mcp_installation_assistant.png){width=680}

### Add an MCP server

1. Use the `/mcp` command to open the MCP server configuration screen.

2. Press `Ctrl+A` to open and search the list of pre-configured MCP servers. 

    If the MCP server you need is not on the list, press `Ctrl+A` once again and follow Installation Assistant's prompts 
to set up the server configuration from scratch.

3. Select the server installation scope:

    * **Project scope**: MCP server configs are stored in the `.junie/mcp/mcp.json` file at the root of your project. This file
      can be checked into version control and shared across all team members.
        > For project-scope installations, avoid sharing secrets or sensitive environment variables 
      > if the `.junie/mcp/mcp.json` file is committed to version control. 
      > {title="Warning"}

    * **User scope**: user-scope MCP configs are stored in `~/.junie/mcp/mcp.json` and available across all projects
      on your machine while remaining private to your user account.

4. Select the server connection type:

    * **Remote**: connect to a hosted server via HTTP/HTTPS.

      Junie CLI connects to an MCP server hosted on a remote machine or service.

    * **Local**: run on your machine (Docker, npx, or binary).

      Junie CLI starts an MCP server instance locally, e.g.
      using the `npx` command or via Docker.

### OAuth authorization

Remote MCP servers that require OAuth authorization are added to the list of configured servers with 
an **Authorization required** status. Use MCP Installation Assistant to set up OAuth authorization:

1. Select the server on the list to open its configuration menu.

2. Select **→ Authorize** and then follow the steps to login in the respective server's browser page that opens.

3. Verify that the server's status has changed to **Active**.

## Add an MCP server from JSON configuration

If you have a JSON configuration for an MCP server, you can add it manually directly to the `.junie/mcp/mcp.json` file 
at the project or user scope. 

The `mcp.json` file uses the following JSON structure:

```json
{
  "mcpServers": {
    "Context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": {
        "ENV_VAR": "value"
      }
    },
    "RemoteServer": {
      "url": "https://mcp.example.com/v1",
      "headers": {
        "Authorization": "Bearer token"
      }
    }
  }
}
```
{collapsible="true" collapsed-title="mcp.json"}

Manually added configurations are imported to the list of MCP servers and enabled by default.
To verify that the server is available to Junie CLI and active, use the `/mcp` command.

## List configured MCP servers

To list all configured MCP servers, as well as disable/enable, modify,
or delete existing configurations, use the `/mcp` command. The list shows:

* MCP server name.
* Installation scope (project or user).
* Server status (Starting/Active/Inactive/Disabled/Failed/Authorization required).

> Servers that are neither *Active* nor *Disabled* can be either *Inactive* or *Failed*.
>
> The *Inactive* status indicates that the server is correctly configured and enabled but is not currently running.
>
> The *Failed* status indicates that an error occurred while attempting to connect to the server,
> the server cannot be started or crashes while running.
> This could be due to invalid configuration, authentication failure, missing dependencies, or server's runtime crash.
> {title="MCP server statuses"}

Configuration for MCP servers is stored in the `mcp.json` file at the following default locations:
* **Project scope**: `.junie/mcp/mcp.json` at the root of your project.
* **User scope**: `~/.junie/mcp/mcp.json` on your machine.

You can control where Junie searches for MCP configurations using the following command-line options:

| Option | Default | Description |
|---|---|---|
| `--mcp-default-locations` | `true` | Enable or disable adding MCP servers from default locations (per user / per project). |
| `--mcp-location <path>` | — | Additional folders where MCP servers should be found. Can be specified multiple times. |

## Enable or disable an MCP server

The MCP servers connected via MCP Installation Assistant or imported from the `mcp.json` file are enabled by default.

To disable a server, list all the configured servers with the `/mcp` command, select the necessary server,
and then select the **→ Disable** action. To enable a previously disabled server, use **→ Enable**.

### Extensions

<show-structure for="chapter" depth="3"/>

# Add and configure extensions

Extensions are reusable bundles that extend Junie CLI with project-specific or
domain-specific capabilities. A single extension can package any combination of:

* [Agent skills](Agent-Skills.md)
* [MCP servers](Junie-CLI-MCP-configuration.md)
* [Subagents](Junie-CLI-subagents.md)
* [Custom slash commands](Custom-slash-commands.md)
* [Guidelines](Guidelines-and-memory.md)

This makes extensions a convenient way to install a curated set of capabilities for a particular
technology stack (for example, an Android, Spring Boot, or SQL extension), share team-wide setups,
or distribute community-built integrations — without manually configuring each piece.

Run the `/extensions` slash command (aliases: `/plugin`, `/plugins`) to open the
extensions screen, where you can browse marketplaces, install, update and remove
extensions, and configure additional marketplaces.

## Marketplaces

Extensions are distributed via marketplaces. A marketplace exposes a manifest with a list of
available extensions and references to where their content is hosted. Junie CLI supports three
ways to host a marketplace:

* A git repository (GitHub, GitLab, self-hosted, any host).
* A local directory on your machine.
* A direct HTTP(S) URL pointing at a `marketplace.json` file.

Two manifest formats are supported in all three cases:

* The native Junie format at `.junie-extension/marketplace.json`.
* The [Claude plugin](https://docs.claude.com/) format at `.claude-plugin/marketplace.json`.

This means you can connect any Claude-compatible plugin marketplace to Junie CLI in addition to
Junie's native marketplaces.

### Built-in marketplace

Junie CLI ships with the official JetBrains marketplace pre-registered:

[https://github.com/JetBrains/junie-extensions](https://github.com/JetBrains/junie-extensions)

The marketplace contains a curated set of extensions maintained by the Junie team —
for example, extensions for Java, Kotlin, Android, Spring Boot, SQL, Redis, and others.

### Add a custom marketplace

To register an additional marketplace:

1. Run `/extensions` and switch to the **Marketplaces** tab.
2. Choose **Add marketplace** and provide one of the supported spec formats:

   | Spec | Recognized as |
   |------|---------------|
   | `https://github.com/owner/repo` | GitHub repository (clones locally) |
   | `owner/repo` | GitHub shorthand, expanded to `https://github.com/owner/repo` |
   | `git@github.com:owner/repo` | Git over SSH |
   | `https://gitlab.com/owner/repo` (or any other host) | Generic git repository |
   | `./relative/path`, `/abs/path`, `~/path`, `file:///…` | Local directory |
   | `https://example.com/marketplace.json` | Direct URL to a `marketplace.json` (HTTP-only, no clone). GitHub `/blob/` URLs are auto-rewritten to the raw form. |

   The source must contain either a `.junie-extension/marketplace.json` or a
   `.claude-plugin/marketplace.json` file at its root (for git / local sources). URL sources
   point directly at the manifest file.

3. Depending on the type, Junie CLI clones the repo, probes the local directory, or fetches the
   JSON, then lists its extensions in the catalog.

To remove a custom marketplace, select it in the **Marketplaces** tab and choose **Remove**.
The built-in JetBrains marketplace cannot be removed.

You can also drive the same actions inline via `/extensions <arg>`:

```text
/extensions marketplace add <spec>
/extensions marketplace remove
```

## Install an extension

1. Run `/extensions` to open the extensions screen.

2. Browse the catalog of available extensions across all registered marketplaces, or use search
   to find a specific extension.

3. Select an extension and choose the installation scope:

    * **Project scope**: the extension is enabled only in the current project. The reference is stored
      in `.junie/extensions.json` at the root of the project. This file can be checked into
      version control and shared with the team.

    * **User scope**: the extension is enabled across all projects on your machine. The reference is
      stored in `~/.junie/extensions/extensions.json` (or `%\USERPROFILE%\.junie\extensions\extensions.json` on Windows).

Extension content (skills, agents, commands, MCP configs, guidelines) is downloaded once into
the user-level cache directory `~/.junie/extensions/<marketplace>/<extension>/` and reused across
projects.

You can also pass a raw trailing argument directly to the `/extensions` command, for example:

```text
/extensions install <extension-name>
```

Newly installed extensions become available within the running session — there is no need to
restart Junie CLI.

## Remove an extension

To uninstall an extension:

1. Run `/extensions` and switch to the **Installed** tab.
2. Select the extension and choose **Remove**.

The reference is removed from the corresponding `extensions.json` file. Cached content under
`~/.junie/extensions/` may be reused if the extension is reinstalled later.

## Update an extension

To pull the latest version of an installed extension, select it in the **Installed** tab and
choose **Update**.

## Where extensions are stored

| Location                                | Purpose                                                                                          |
|-----------------------------------------|--------------------------------------------------------------------------------------------------|
| `~/.junie/extensions/`                  | Base directory for cached extension content.                                                     |
| `~/.junie/extensions/extensions.json`   | User-scope configuration: extensions enabled for the current user across all projects.           |
| `~/.junie/extensions/marketplaces.json` | Registry for registered marketplace repositories and their sync status.                          |
| `.junie/extensions.json`                | Project-scope configuration: extensions enabled for the current project; can be committed to VCS. |
| `~/.junie/extensions/marketplaces/`     | Per-marketplace caches: git clones, local-dir caches, fetched `marketplace.json` files.          |

Both `extensions.json` files share the same format: a flat JSON object that maps a marketplace
identifier to the list of installed extensions for that marketplace. A typed `source` is stored
alongside so a teammate who pulls the project can auto-register the marketplace without
configuring it manually:

```json
{
  "github-JetBrains-junie-extensions": { "extensions": ["context7"] },
  "github-myorg-myrepo": {
    "url": "https://github.com/myorg/myrepo",
    "source": { "type": "git", "url": "https://github.com/myorg/myrepo" },
    "extensions": ["my-ext"]
  },
  "local-my-dir-abc12345": {
    "source": { "type": "local", "path": "/Users/me/my-marketplace" },
    "extensions": ["my-local-ext"]
  },
  "url-github-anthropics-knowledge-work-plugins-xxxxxxxxxx": {
    "source": { "type": "url", "url": "https://raw.githubusercontent.com/anthropics/knowledge-work-plugins/main/.claude-plugin/marketplace.json" },
    "extensions": ["some-ext"]
  }
}
```

The legacy `url` field is kept populated for git sources so older Junie versions can still
downgrade-read the config.

You can override the base directory with the following command-line option:

| Option                                 | Default              | Description                                                                                                                                              |
|----------------------------------------|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `--extensions-default-location <path>` | `~/.junie/extensions` | Override the default extensions directory. Can also be set via the `JUNIE_EXTENSIONS_DEFAULT_LOCATION` environment variable. |

### Subagents

# Custom subagents

<show-structure for="chapter" depth="3" />

Subagents in Junie extend the built-in logic of the main agent with task-specific instructions that define a tailored system 
prompt, tool restrictions, and usage of models and [agent skills](Agent-Skills.md).

When Junie CLI runs across a task that matches a subagent’s name and description, it delegates this task to that subagent. 
The subagent then works independently in its own context and returns the result to the main agent.

This page describes the [benefits of using custom subagents](#why-subagents), 
[how custom subagents are invoked](#how-junie-cli-uses-subagents), 
[adding your own subagents](#creating-a-custom-subagent) to Junie CLI, and what [built-in tools](#supported-tool-groups) 
are supported.

## Why subagents?

With subagents, Junie CLI can extend the capabilities to the main agent by delegating tasks to the most appropriate handler 
based on the nature of the request. Subagents let you:

* **Break down complex tasks** into focused, single-purpose chunks that the main agent can delegate 
while keeping the subagent's context out of the main conversation.
* **Tailor and reuse agent's behaviour for specific tasks** by defining coding standards, checklists, procedures, or 
agent skills to invoke and reusing these instructions across projects.
* **Optimize performance and costs** by using lightweight models for simple repetitive tasks, or predefined models for
    specific types of tasks.
* **Enforce tool restrictions** for specific types of tasks, such as restricting the agent to read-only operations 
for security auditing and reviews.

## How Junie CLI uses subagents

Junie CLI invokes subagents *automatically*, informing the user which subagent has started 
working on the task.

The main agent discovers all available subagents, selects the relevant subagent by matching its [`name` and `description`](#frontmatter-fields) to the task at hand, 
runs it as a subtask, and brings the result back into the main session.

### Configure subagent usage

<primary-label ref="eap"/>

> This setting is currently in the [Early Access Program](Junie-CLI-EAP.md). To try it,
> [install the Early Access version](Junie-CLI-EAP.md#install-eap) of Junie CLI.

Use `/settings` → **Subagents** to choose the subagents model selection policy. The setting is saved in `~/.junie/settings.json`
and applies to new sessions.

| Mode | Behavior |
|------|----------|
| **SameModelOnly** | Junie CLI may use subagents only for independent work that can run in parallel and reduce elapsed time. Subagents always use the same model as the main agent. |
| **Auto** | Junie CLI may use SameModelOnly-style parallelism and may choose cheaper capable model tiers for suitable delegated work when it does not slow the session. This is the default mode. |

The **Subagents** setting appears only when subagents are enabled in the current environment.

> Unlike [custom slash commands](Custom-slash-commands.md), custom subagents cannot be invoked manually 
> via slash commands. They are only called automatically through delegation.

> If your project already has agent files from other tools (`.cursor/agents/`, `.claude/agents/`, or `.codex/agents/`),
> Junie CLI detects such files when opening the project and suggests importing them into Junie's `.junie/agents/` 
> directory automatically.
{title="Agent import"}

## Creating a custom subagent

Subagents are Markdown files with YAML metadata stored in the `.junie/agents/` or `.agents/` directory. For example, a simple 
subagent file for a changelog assistant (`.junie/agents/changelog.md`) looks as follows:

```yaml
---
name: "changelog"
description: "Write a changelog entry for a PR"
---

You are a changelog assistant.

Given the PR title and description, produce a short changelog entry.
```

### File location

Junie CLI looks for custom subagent `*.md` files in the following locations:

* *Project scope:* `<projectRoot>/.junie/agents/`.
* *Project scope:* `<projectRoot>/.agents/`.
* *User scope:* `~/.junie/agents/` on macOS/Linux or `%\USERPROFILE%\.junie\agents\` on Windows.
* *User scope:* `~/.agents/` on macOS/Linux or `%\USERPROFILE%\.agents\` on Windows.

### File format

Subagent files use YAML frontmatter for metadata, followed by the prompt body in Markdown for the system prompt. 

An example subagent file that uses the commonly used supported frontmatter fields looks as follows:

```markdown
---
description: "Review a change and propose a safe patch"
name: "code-review-helper"
tools: ["Read", "Grep", "Edit"]
disallowedTools: ["Bash", "WebSearch"]
mcpServers: ["github"]
model: "sonnet"
reasoningLevel: "high"
maxTurns: 20
skills: ["kotlin", "writerside"]
allowPromptArgument: true
---

You are a careful code reviewer.

Context:

- File: $path
- Focus area: $focus

Tasks:

1) Explain the issue concisely.
2) Propose a minimal fix.
3) If edits are needed, prepare a small patch.

If you need additional context, ask for it.
```

#### Frontmatter fields

| Field             | Type           | Required | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|-------------------|----------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`            | `String`       | no       | The subagent name. If missing, the file name (without extension) is used. <br><br>Must match: `[a-z][a-z0-9-]*` (lowercase letters, digits, hyphens).                                                                                                                                                                                                                                                                                                                   |
| `description`     | `String`       | yes      | The subagent description. Used by the main agent to decide when to delegate a task to this subagent.                                                                                                                                                                                                                                                                                                                                                                    |
| `tools`           | `List<String>` | no       | If present and non-empty: an allowlist of [tool groups](#supported-tool-groups).                                                                                                                                                                                                                                                                                                                                                                                        |
| `disallowedTools` | `List<String>` | no       | A denylist of [tool groups](#supported-tool-groups). Applied after the `tools` filtering.                                                                                                                                                                                                                                                                                                                                                                               |
| `mcpServers`      | `List<String>` | no       | If present and non-empty: an allowlist of MCP server names. Only tools from the listed servers are exposed to the subagent; all other configured MCP servers are hidden. An empty or omitted list keeps every configured MCP server available.                                                                                                                                                                                                                          |
| `model`           | `String`       | no       | Default model for this subagent (if supported by your environment). When set, this model is always used for this subagent. Accepted values depend on your environment; to see the model names currently available in your setup, start Junie and use `/model`, or use a name accepted by the `--model` CLI flag. Some builds also support aliases like `sonnet`, `opus`, `grok`, and custom model profile IDs in the `custom:<profile-id>` format. For more details, see [Model selection](Junie-CLI-Model-selection.md). |
| `reasoningLevel`  | `String`       | no       | Optional reasoning override for this subagent run. The `effort` key is accepted as an alias (and takes precedence if both are present). In most cases, use values such as `low`, `medium`, or `high`, but supported values can vary by model, so check the model's own documentation if in doubt. Junie maps the selected level to the provider-specific reasoning field for the effective model, including compatible custom model profiles.                                                                 |
| `maxTurns`        | `Int`          | no       | Optional cap on the number of steps (turns) the subagent may take before it must finish. Must be a positive integer. When set, it overrides the default step limit for this subagent.                                                                                                                                                                                                            |
| `skills`          | `List<String>` | no       | IDs/names of agent skills to load for the subagent worker (if supported by your environment).                                                                                                                                                                                                                                                                                                                                                                           |
| `allowPromptArgument` | `Boolean`  | no       | If `true`, Junie exposes an additional `$prompt` argument to the subagent prompt. When `$prompt` is not referenced explicitly in the prompt body, the delegated user request is appended automatically as `User Input: ...`.                                                                                                                                                                                                                                       |

#### Prompt body

In the prompt body, provide the set of instructions to guide the subagent’s behavior. This prompt will be added to the 
instructions delegated from the main agent.

#### Tips 

* Make delegated work items as independent as possible.
* Ask for specific outputs (for example, “return file paths and the exact symbol names”).
* If you want to keep changes small, say so (“no refactors”, “touch at most one module”, “prefer config-only fix”).

## Supported tool groups

Custom subagents can define which tool groups are allowed (`tools`) or forbidden (`disallowedTools`) during task execution. 

If the `tools` field in the YAML frontmatter is present and non-empty, **only the specified groups are allowed**,
with the rest being banned by default. There's no need to disallow them explicitly using the `disallowedTools` field. 

There are two types of tools that can be either allowed or banned:

* **Built-in tool groups**.
* **Tools provided by MCP servers** (if available in your environment).

The built-in tool group labels are:

| Built-in tool group label | What it enables                                         |                               
|---------------------------|---------------------------------------------------------|
| `Read`                    | Read-only file viewing actions (open/scroll).           |
| `Bash`                    | Running shell commands in the local environment.        |
| `Glob`                    | Searching for files by path pattern (`glob`).           |
| `Grep`                    | Searching for text by regular expression (`grep`).      |
| `Write`                   | Creating new files.                                     |
| `Edit`                    | Modifying existing files (search/replace, apply patch). | 
| `WebSearch`               | Searching the web for up-to-date information.           | 
| `AskUserQuestion`         | Asking the user for input or a choice.                  |

Example of a read-only subagent allowed to search for a text by regular expression:

```yaml
---
name: "symbol-finder"
description: "Find where a symbol is used and summarize"
tools: [ "Read", "Grep" ]
---
```

### Guidelines and memory

# Guidelines and memory

<show-structure depth="3" for="chapter"/>

## Guidelines

Guidelines allow you to provide persistent, reusable context to the agent. Junie CLI reads guidelines 
from the `AGENTS.md` file and adds this context to every task it works on.

Additionally, Junie CLI checks for any guidelines or memory files from other AI agents when it opens the project
for the first time. If such files are detected, it will suggest importing the instructions into `.junie/AGENTS.md`.

### AGENTS.md

[AGENTS.md](https://agents.md/) is an open file format for guiding coding agents. It's a standard Markdown file 
with headings, lists, and plain text that the agents can parse to add to the prompt context. 

[//]: # (For user-defined instructions and project context, Junie CLI reads the `.junie/AGENTS.md` file at the root of your project.)

### How Junie CLI discovers guidelines

When Junie CLI starts a task, it looks for guidelines in the following order:

1. `.junie/AGENTS.md` file in the project root.
2. `AGENTS.md` file in the project root.
3. `.junie/guidelines.md` file or `.junie/guidelines/` folder – Junie's legacy format for guidelines (still supported).

### Global guidelines {id="global-guidelines"}

In addition to project-level guidelines, Junie CLI also supports **global guidelines** from `~/.junie/AGENTS.md`.
On Windows, the global guidelines path is `&#37;USERPROFILE&#37;\.junie\AGENTS.md`.
This file lets you define personal preferences or organization-wide rules that apply to all your projects 
without duplicating them in every repository.

**How it works:**

- If only global or only project guidelines exist, Junie uses whichever is available — no extra annotations are added.
- If both global and project guidelines exist, Junie includes both and marks them clearly. 
  **Project-level guidelines always take precedence** over global ones when they conflict.
- If the global and project guidelines have identical content, Junie automatically deduplicates and uses the content only once.

<procedure title="Examples of guidelines">

An `AGENTS.md` file can include project-specific context such as tech stacks, conventions, or rules.
Providing this information helps Junie better understand your environment, avoid incompatible libraries,
and follow your project's specific architectural patterns.

Below are some examples of what you can include:

* **Quick-start checklist:**

```markdown
# A short bullet list of the most critical rules the agent must follow before doing anything

- [ ] Read this file and `README.md` before acting.
- [ ] Update `CHANGELOG.md` for user-facing changes.
```

* **Local development commands**:

```markdown
# A table or list of project-specific commands for install, lint, test, build, and span dev server

| Task                 | Command        |
|----------------------|----------------|
| Install dependencies | `pnpm install` |
| Start dev server     | `pnpm dev`     |
| Run unit tests       | `pnpm test`    |
```

* **Feature development and decision making:**

```markdown
# Feature development and decision making

- Make small, targeted changes instead of building for hypothetical future needs.
- If something is unclear, ask before making assumptions.
```

* **UI and architecture:**

```markdown
# UI and architecture guidelines

- Use existing design system components.
- Avoid inline styles.
- Follow current domain boundaries.
- Prefer extending existing services.
```

* **Security and data handling:**

```markdown
# Security and data handling

- Never log tokens or sensitive data.
- Sanitize all user input and use existing auth middleware.
```

* **Testing and contribution:**

```markdown
# Testing and contribution

- Add unit tests for new business logic.
- Keep changes minimal and avoid large refactors in feature tasks.
- Do not rename files without a valid technical reason.
```

* **Non-goals for agents:**

```markdown
# Explicit prohibitions what agents must NOT do 

- Do not bump major versions of core dependencies without a dedicated PR and discussion.
- Do not change database schema without a corresponding migration file.
```

For more technology-specific examples of guidelines with explanations, see the 
[junie-guidelines](https://github.com/JetBrains/junie-guidelines) catalog.
</procedure>


[//]: # (## Memory)

[//]: # ()
[//]: # (TBD)

### Custom slash commands

# Custom slash commands

Junie CLI supports custom slash commands that you can create to quickly execute frequently used prompts or
repetitive tasks. Custom commands are added to the list of built-in slash commands that is shown when you type `/`.

[//]: # (![]&#40;custom-slash-command.png&#41;{width="706"})

To create a custom command:

1. Use `/commands` → `Create New Command` and provide the command name and description.

2. Select the command scope:
    * *Project-specific commands* are stored as Markdown files in the `.junie/commands` folder at your project’s root directory.
      You can commit this folder to version control to ensure that all team members can use it.
    * *User commands* are stored as Markdown files in the `~/.junie/commands` folder on your machine, making them
      available across all projects you open locally.

3. Enter and save the prompt.

To view, modify, or delete the added custom commands, use `/commands`.

### Use arguments in the command prompt

You can use special keywords `$argumentName` in the prompt text to pass parameter values when invoking
the custom slash command.

For example, if you create a command named *explain* and set the prompt as `Explain the code in $file and suggest improvements`,
the `/explain` slash command should be used with the `file` argument when invoked as follows:

```
/explain file=src/main.kt
```
Argument values may be either unquoted or quoted with double or single quotes.

> A custom slash command will only be executed when all arguments from the command template are provided.
>
> Junie CLI shows inline hints for missing arguments. To autocomplete the missing argument name, use `Tab`.

Custom slash commands do not accept optional prompts as arguments the same way as [some built-in slash commands](Slash-commands.md#optional-text-as-arguments).
Only named arguments defined in the command template are supported.

### Slash command file format

Each custom slash command is saved as a separate Markdown file with YAML frontmatter that defines the command metadata.
The file name is taken from the command name.

For example, a file for the `/explain` command will be named `explain.md` and look as follows:


```markdown

---

description: Explains code in a given file

---


Explain the code in $file and suggest improvements.

```

### Custom proxies

# Custom proxies

<primary-label ref="nightly"/>

Custom proxies let you route Junie's LLM traffic through a self-hosted or third-party proxy endpoint instead of the default JetBrains AI service.
This is useful when your organization runs its own inference gateway, needs to add custom authentication headers, or wants to use a private Ingrazzio-compatible deployment.

> This feature is currently in the [Early Access Program](Junie-CLI-EAP.md). To try it,
> [install the Early Access version](Junie-CLI-EAP.md#install-eap) of Junie CLI.

## About the Ingrazzio proxy {id="about-ingrazzio"}

Ingrazzio is JetBrains' internal proxy protocol that Junie uses to communicate with LLM providers.
The production Ingrazzio endpoint is `https://ingrazzio-cloud-prod.labs.jb.gg`.

When Junie connects through an Ingrazzio proxy, it uses the base URL to access several sub-endpoints:

- **LLM chat** — the base path handles streaming chat completion requests.
- **Web search** — the `/search` path provides web search capabilities.
- **URL extraction** — the `/extract` path fetches and extracts content from URLs.

When using the default JetBrains provider, Junie authenticates automatically via JetBrains Account (JBA).
When using a custom proxy, JBA authentication is bypassed — you must supply any required credentials (such as `Authorization: Bearer <token>`) through the proxy's `headers` field.

## Configure a proxy

Add a `proxies` array to your `config.json`. Each entry describes a named proxy endpoint:

```json
{
  "proxies": [
    {
      "name": "my-proxy",
      "kind": "Ingrazzio",
      "api-url": "https://ingrazzio-cloud-prod.labs.jb.gg",
      "headers": [
        "Authorization: Bearer <your-token>"
      ]
    }
  ]
}
```

### Proxy fields

| Field | Required | Description |
|---|---|---|
| `name` | Yes | A unique name for this proxy. Used to reference it from the `provider` field. |
| `kind` | No | The proxy protocol type. Defaults to `Ingrazzio` if omitted. See [Supported proxy kinds](#supported-proxy-kinds). |
| `api-url` | Yes | The base URL of the proxy endpoint. |
| `headers` | No | A list of extra HTTP headers to send with every request. Each entry uses the format `Header-Name: Header-Value`. |

## Select a proxy as the active provider

To make Junie use a configured proxy, set the `provider` field to the proxy name:

```json
{
  "proxies": [
    {
      "name": "corp-proxy",
      "kind": "Ingrazzio",
      "api-url": "https://ingrazzio-cloud-prod.labs.jb.gg",
      "headers": [
        "Authorization: Bearer <your-token>"
      ]
    }
  ],
  "provider": "corp-proxy",
  "model": "sonnet"
}
```

You can also override the provider at runtime with the `--provider` CLI flag:

```bash
junie --provider corp-proxy
```

When a proxy is selected as the provider, Junie does **not** use JetBrains AI authentication.
All authentication must be handled through the `headers` you configure on the proxy entry.

## Supported proxy kinds {id="supported-proxy-kinds"}

The `kind` field determines which protocol Junie uses to communicate with the proxy.

| Kind | Status | Description |
|---|---|---|
| `Ingrazzio` | **Supported** | Junie's native proxy protocol. Compatible with JetBrains Ingrazzio deployments. This is the default when `kind` is omitted. |
| `OpenAI` | Planned | OpenAI-compatible API. |
| `Anthropic` | Planned | Anthropic-compatible API. |
| `JetBrainsAI` | Planned | JetBrains AI Gateway. |
| `OpenRouter` | Planned | OpenRouter-compatible API. |

> Currently, only the `Ingrazzio` kind is functional. Selecting any other kind will result in an error at startup.

## Quick setup example

1. Create a configuration file (for example, `my-config.json`):

```json
{
  "proxies": [
    {
      "name": "my-ing",
      "kind": "Ingrazzio",
      "api-url": "https://ingrazzio-cloud-prod.labs.jb.gg",
      "headers": [
        "Authorization: Bearer <your-token>"
      ]
    }
  ],
  "provider": "my-ing",
  "model": "opus"
}
```

2. Run Junie with the custom config:

```bash
junie --config-location="/path/to/my-config.json"
```

You can still override the model at runtime with the `--model` flag:

```bash
junie --config-location="/path/to/my-config.json" --model sonnet
```

## Merging proxies across configuration files

When multiple configuration files define proxies, they are merged by name:

* If two files define a proxy with the same `name`, the higher-priority file's fields override the lower-priority file's fields on a per-field basis.
* Headers from both files are combined (deduplicated).
* Proxies with different names are all included in the final list.

For the configuration precedence order, see [Configuration files](Junie-CLI-configuration.md#configuration-precedence).

## Limitations

* Only the `Ingrazzio` proxy kind is currently supported. Other kinds are reserved for future use.
* Proxy configuration is only available through `config.json`. There are no dedicated CLI flags for defining proxy entries.
* When using a proxy provider, JetBrains AI authentication is bypassed entirely. You must supply any required credentials via the `headers` field.

### Custom LLMs

# Custom LLMs

Junie CLI supports custom models defined via JSON profiles. This feature allows you to integrate with local providers 
(e.g., Ollama), enterprise proxies, or any LLM endpoint that follows the supported API formats.

## Choosing a capable model {id="choosing-a-capable-model"}

Junie is an agentic tool: it drives a task by calling tools, following multi-step instructions, and reasoning over a
large context (your prompt, file contents, tool output, and the running plan). This places much higher demands on a
model than a plain chat completion.

Smaller or heavily quantized models often cannot keep up. With a weak model you may see Junie:

- ignore or partially follow instructions, or drift away from the task;
- emit malformed or incomplete tool calls, so edits and commands fail;
- loop, repeat itself, or stop before the task is finished;
- lose track of earlier steps once the context grows.

> This is a limitation of the underlying model, not a defect in Junie. The same setup with a more capable model
> typically resolves it.
>
> For agentic use, prefer models with strong instruction following and reliable tool/function calling, a coding-oriented
> training focus, and a large context window. Very small or aggressively quantized variants are best kept for the
> `fasterModel` role (summarization, classification) rather than as the `primaryModel`.
>
> {style="note"}

## Configuration

### Location and discovery

By default, custom models are discovered from JSON files located in:
- User-scope: `$JUNIE_HOME/models/*.json`.
- Project-scope: `.junie/models/*.json`.

The filename (without the `.json` extension) is used as the **profile identifier**.

You can control where Junie searches for custom models using the following command-line options:

| Option                      | Default | Description                                                                              |
|-----------------------------|---------|------------------------------------------------------------------------------------------|
| `--model-default-locations` | `true`  | Enable or disable adding custom models from default locations (per user / per project).  |
| `--model-location <path>`   | —       | Additional folders where custom models should be found. Can be specified multiple times. |
{width="800"}

You can also set these values in the `config.json` file. For details, see [Junie CLI configuration files](Junie-CLI-configuration.md).

### Profile structure

A custom model profile consists of a top-level configuration and two optional model roles:

1. **Top-level properties**: Serve as the default configuration (base URL, API key, API type, and extra headers) for the models in the profile.
2. **`primaryModel`**: The model used for main reasoning and code generation tasks.
3. **`fasterModel`**: The model used for internal helper tasks like summarizing context or classifying tasks.

If `primaryModel` or `fasterModel` is not explicitly defined, they inherit the top-level properties.

### Top-level parameters

These parameters appear at the root of the JSON profile and define the defaults shared by both model roles.

| Parameter      | Type   | Required | Description                                                                                                                                  |
|----------------|--------|----------|----------------------------------------------------------------------------------------------------------------------------------------------|
| `id`           | String | Yes      | The model identifier as expected by the API endpoint (for example, `gpt-4o` or `qwen3-coder:latest`).                                        |
| `baseUrl`      | String | Yes      | The full URL of the LLM API endpoint (for example, `http://localhost:11434/v1/responses`).                                                   |
| `apiType`      | String | Yes      | The API format to use when communicating with the endpoint. See [Supported API types](#supported-api-types) for the list of accepted values. |
| `apiKey`       | String | No       | The API key for authenticating with the endpoint. If omitted, requests are sent without an `Authorization` header.                           |
| `extraHeaders` | Object | No       | A key-value map of additional HTTP headers to include in every request to the endpoint.                                                      |
| `temperature`  | Number | No       | The sampling temperature to use for requests. If omitted, the provider's default temperature is used. See [Temperature](#temperature).       |
| `primaryModel` | Object | No       | Role-specific overrides for the primary model. See [Role-specific parameters](#role-specific-parameters).                                    |
| `fasterModel`  | Object | No       | Role-specific overrides for the faster model. See [Role-specific parameters](#role-specific-parameters).                                     |

### Role-specific parameters

`primaryModel` and `fasterModel` accept the same set of parameters. Any parameter specified here overrides the corresponding top-level value for that model role. Omitted parameters fall back to the top-level defaults.

| Parameter | Type | Description |
|---|---|---|
| `id` | String | Override for the model identifier used for this role. |
| `baseUrl` | String | Override for the API endpoint URL used for this role. |
| `apiType` | String | Override for the API format used for this role. |
| `apiKey` | String | Override for the API key used for this role. |
| `extraHeaders` | Object | Additional headers for this role. Merged with (not replaced by) the top-level `extraHeaders`. |
| `temperature` | Number | Override for the sampling temperature used for this role. |

### Merging logic

Overrides in `primaryModel` or `fasterModel` are merged with the top-level defaults:
- **Simple fields** (`id`, `baseUrl`, `apiKey`, `apiType`, `temperature`) are replaced by the override value when present.
- **Headers** (`extraHeaders`) are merged: headers defined in the override are added to the top-level headers. If the same header key appears in both, the role-level value takes precedence.

### Supported API types {id="supported-api-types"}

The `apiType` field controls which request format Junie uses when calling the endpoint.

| Value | Description |
|---|---|
| `OpenAICompletion` | OpenAI Chat Completions API (`/v1/chat/completions`). Compatible with most self-hosted and third-party OpenAI-compatible endpoints. |
| `OpenAIResponses` | OpenAI Responses API (`/v1/responses`). Use this for endpoints that implement the newer Responses API format. |
| `Google` | Google Gemini API format. Use this for Google AI Studio or Vertex AI endpoints. |
| `Anthropic` | Anthropic Messages API format. Use this for Anthropic Claude endpoints. |

## Temperature {id="temperature"}

By default, Junie does not send a temperature value for custom models, allowing the provider to use its own default.
You can set a specific temperature at the top level (shared by both model roles) or override it per role.

Recommended temperature values vary by model. For example:

| Model | Recommended temperature |
|---|---|
| DeepSeek | 0 |
| Gemini | 1 |
| Kimi | 0.6–1 |
| GLM | 0.7 |
| Qwen | 0.6 |
| MiMo | 0.3 |

> Consult your model provider's documentation for the optimal temperature value.
> Setting temperature to 0 may cause looping behavior with some models.

## Example profiles

### Basic profile

Below is an example of a profile named `local-ollama.json`:

```json
{
  "baseUrl": "http://localhost:11434/v1/chat/completions",
  "id": "qwen3-coder:latest",
  "apiType": "OpenAICompletion",
  "extraHeaders": {
    "X-Custom-Source": "Junie"
  },
  "fasterModel": {
    "id": "qwen2.5-coder:1.5b"
  }
}
```

In this example, the primary model will be `qwen3-coder:latest`, and the faster model will be `qwen2.5-coder:1.5b`. Both will use the same base URL, API type, and extra headers.

> The `baseUrl` is used as the complete endpoint URL — Junie does not append a path to it. Set it to the full endpoint
> for your chosen `apiType` (for example, `/v1/chat/completions` for `OpenAICompletion`).

### Profile with temperature

Below is an example that sets a default temperature and overrides it for the primary model:

```json
{
  "baseUrl": "http://localhost:11434/v1/chat/completions",
  "id": "qwen3-coder:latest",
  "apiType": "OpenAICompletion",
  "temperature": 0.6,
  "primaryModel": {
    "id": "qwen3-coder:latest",
    "temperature": 0.3
  },
  "fasterModel": {
    "id": "qwen2.5-coder:1.5b"
  }
}
```

In this example, the primary model uses temperature `0.3` (overridden), while the faster model inherits the top-level temperature `0.6`.

## Using custom models

Once a profile is created, you can select it using the `/model` command or the `--model` flag. Custom models are identified by a `custom:` prefix followed by the profile ID:

```bash
junie --model custom:local-ollama
```

In the interactive TUI, custom models appear in the model selection list after the built-in providers.

## Provider guides

For common local and proxy providers, you can connect interactively (no JSON profile required) and let Junie discover
the available models. The following guides cover both the interactive setup and a manual profile:

- [Ollama](Custom-LLM-Ollama.md)
- [LM Studio](Custom-LLM-LM-Studio.md)
- [LiteLLM](Custom-LLM-LiteLLM.md)

### Ollama

# Ollama

[Ollama](https://ollama.com) runs open-weight models locally and exposes an OpenAI-compatible API.
Junie CLI can connect to a local Ollama server, automatically discover the models it serves, and make them available in
the model picker.

## Prerequisites

- Ollama installed and running. By default it listens on `http://localhost:11434`.
- At least one model pulled locally, for example:

  ```sh
  ollama pull qwen3-coder:latest
  ```

## Connect Ollama (recommended)

The simplest way to use Ollama is to point Junie at the server and let it discover the available models — no JSON
profile required.

1. In an active Junie session, run the `/account` command (or select **Use external LLM providers** on the welcome
   screen).
2. Open **Custom models and endpoints**.
3. Select **Ollama**.
4. Confirm or edit the **Base URL**. The default is `http://localhost:11434`.

   > Enter the server's base URL (host and port only), for example `http://localhost:11434`. Junie probes
   > `<baseUrl>/v1/models` to discover models and sends requests to `<baseUrl>/v1/chat/completions`. Do not append a
   > path yourself.

Junie probes the endpoint and adds every discovered model to the picker.

## Select a model

Run `/model` and pick a discovered Ollama model from the list. Discovered local models appear after the built-in
providers.

> Local models vary widely in capability. Small or heavily quantized models may struggle with Junie's agentic workflow
> (tool calls, multi-step instructions, long context). See [Choosing a capable model](Custom-LLM-models.md#choosing-a-capable-model).
>
> {style="note"}

## Advanced: define a profile manually

If you need full control — a non-default API type, extra headers, a per-role `fasterModel`, or a custom temperature —
define a [custom model profile](Custom-LLM-models.md) instead. For a manual Ollama profile, use the OpenAI Chat
Completions endpoint and set `baseUrl` to the full path:

```json
{
  "baseUrl": "http://localhost:11434/v1/chat/completions",
  "id": "qwen3-coder:latest",
  "apiType": "OpenAICompletion",
  "fasterModel": {
    "id": "qwen2.5-coder:1.5b"
  }
}
```

> Ollama implements the OpenAI **Chat Completions** API, not the Responses API. Use `apiType: "OpenAICompletion"`.
> Unlike the interactive flow, a JSON profile's `baseUrl` is the full endpoint URL, so include `/v1/chat/completions`.

For the full profile schema, see [Custom LLMs](Custom-LLM-models.md).

### LM Studio

# LM Studio

[LM Studio](https://lmstudio.ai) is a desktop app for running local models that exposes an OpenAI-compatible server.
Junie CLI can connect to it, automatically discover the loaded models, and make them available in the model picker.

## Prerequisites

- LM Studio installed, with at least one model downloaded.
- The local server started (**Developer** tab → **Start Server**). By default it listens on `http://localhost:1234`.

## Connect LM Studio (recommended)

The simplest way to use LM Studio is to point Junie at the server and let it discover the available models — no JSON
profile required.

1. In an active Junie session, run the `/account` command (or select **Use external LLM providers** on the welcome
   screen).
2. Open **Custom models and endpoints**.
3. Select **LM Studio**.
4. Confirm or edit the **Base URL**. The default is `http://localhost:1234`.

   > Enter the server's base URL (host and port only), for example `http://localhost:1234`. Junie probes
   > `<baseUrl>/v1/models` to discover models and sends requests to `<baseUrl>/v1/chat/completions`. Do not append a
   > path yourself.

Junie probes the endpoint and adds every discovered model to the picker.

## Select a model

Run `/model` and pick a discovered LM Studio model from the list. Discovered local models appear after the built-in
providers.

> Local models vary widely in capability. Small or heavily quantized models may struggle with Junie's agentic workflow
> (tool calls, multi-step instructions, long context). See [Choosing a capable model](Custom-LLM-models.md#choosing-a-capable-model).
>
> {style="note"}

## Advanced: define a profile manually

If you need full control — extra headers, a per-role `fasterModel`, or a custom temperature — define a
[custom model profile](Custom-LLM-models.md) instead. For a manual LM Studio profile, use the OpenAI Chat Completions
endpoint and set `baseUrl` to the full path:

```json
{
  "baseUrl": "http://localhost:1234/v1/chat/completions",
  "id": "qwen/qwen3-coder-30b",
  "apiType": "OpenAICompletion"
}
```

> LM Studio implements the OpenAI **Chat Completions** API. Use `apiType: "OpenAICompletion"`.
> Unlike the interactive flow, a JSON profile's `baseUrl` is the full endpoint URL, so include `/v1/chat/completions`.

For the full profile schema, see [Custom LLMs](Custom-LLM-models.md).

### LiteLLM

# LiteLLM

[LiteLLM](https://docs.litellm.ai) is a proxy server that exposes 100+ LLM providers behind a single OpenAI-compatible
API. Junie CLI can connect to a LiteLLM proxy, automatically discover the models it serves, and make them available in
the model picker.

## Prerequisites

- A running LiteLLM proxy. By default it listens on `http://localhost:4000`.
- The proxy API key, if your proxy enforces authentication (LiteLLM keys typically start with `sk-`). Optional for
  self-hosted proxies that do not require authentication.

## Connect LiteLLM (recommended)

Connect interactively and let Junie discover the available models — no JSON profile required.

1. In an active Junie session, run the `/account` command (or select **Use external LLM providers** on the welcome
   screen).
2. Open **Custom models and endpoints**.
3. Select **LiteLLM proxy**.
4. **Step 1 — LiteLLM URL.** Enter the proxy base URL. The default is `http://localhost:4000`.
5. **Step 2 — API key.** Paste your LiteLLM API key, or leave it blank if the proxy does not require one.

Junie probes the proxy and adds every discovered model to the picker.

## Connect LiteLLM from the command line

You can configure the proxy non-interactively with CLI flags or environment variables — useful for CI or scripted
setups:

| Flag | Environment variable | Description |
|---|---|---|
| `--litellm-url` | `JUNIE_LITELLM_URL` | LiteLLM proxy base URL (for example, `http://localhost:4000`). |
| `--litellm-api-key` | `JUNIE_LITELLM_API_KEY` | LiteLLM proxy API key. Optional for proxies that do not require authentication. |

```sh
junie --litellm-url http://localhost:4000 --litellm-api-key sk-1234
```

These flags connect the proxy and make its models available, but they do not change the active model on their own.
Select a LiteLLM model with `/model` after startup, or set it directly with `--model`:

```sh
junie --litellm-url http://localhost:4000 --litellm-api-key sk-1234 --model my-coder-model
```

## Select a model

Run `/model` and pick a discovered model from the list.

## Advanced: define a profile manually

If you need full control — extra headers, a per-role `fasterModel`, or a custom temperature — define a
[custom model profile](Custom-LLM-models.md) instead. For a manual LiteLLM profile, target the proxy's OpenAI Chat
Completions route and set `baseUrl` to the full path. The `id` is the `model_name` defined in your LiteLLM
configuration, and the master key is passed via `apiKey` (sent as `Authorization: Bearer <apiKey>`):

```json
{
  "baseUrl": "http://localhost:4000/v1/chat/completions",
  "id": "my-coder-model",
  "apiType": "OpenAICompletion",
  "apiKey": "sk-1234"
}
```

For the full profile schema, see [Custom LLMs](Custom-LLM-models.md).

### Hooks

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

### Reference

# Reference

Complete reference for the slash commands (`/`) and shortcuts available in Junie CLI (interactive mode).

## Built-in slash commands

> Commands shown with `<...>` accept optional raw trailing text: Junie CLI passes everything after the command token 
> as one argument. 
> 
> For example, `/new fix failing tests` opens a new session with `fix failing tests` in the prompt. `/plan refactor commands`
> enables plan mode and submits `refactor commands` immediately. 
> 
> Commands without `<...>` do not accept arguments.

{id="optional-text-as-arguments"}

| Command                  | Description                                                                                                                                                                                                                                                                                                                                                      |
|--------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/account`               | Manage your Junie Accounts and Junie API keys, or connect your own API key from Anthropic, OpenAI, and other OpenAI API-compatible providers.                                                                                                                                                                                                                    | 
| `/brave`                 | Cycle through the [brave mode](Junie-CLI.md#brave-mode) levels (Off, Auto, On) that control how much Junie CLI relies on user approval before running potentially sensitive actions.                                                                                                                                                                              |
| `/commands`              | Create and manage custom slash commands.                                                                                                                                                                                                                                                                                                                         |
| `/debug`                 | Toggle [debug mode](Junie-CLI-Debug-Mode.md), in which Junie CLI acts as an AI debugging assistant against a live debugger session in a connected JetBrains IDE. Shortcut: `Shift+Tab+Tab`.                                                                                                                                                                      |
| `/demo <arg>`            | Launch a [visual demo](Junie-CLI-demo.md) of a feature inside a disposable VM.                                                                                                                                                                                                                                                                                   |
| `/effort`                | Set the reasoning [effort level](Junie-CLI.md#model-and-effort) for the current model. The set of supported effort levels depends on the selected model.                                                                                                                                                                                                         |
| `/extensions <arg>`      | Browse, install, update, and manage [Junie CLI extensions](Junie-CLI-Extensions.md) — bundles of agent skills, MCP servers, subagents, custom commands, and guidelines.                                                                                                                                                                                          |
| `/feedback <prompt>`     | Share feedback about the current session with the Junie team. If you provide `<prompt>`, Junie opens the feedback screen with that text as an editable draft. <tip>A ZIP file with the current session logs is automatically attached to the submitted feedback response. </tip>                                                                                 |
| `/history`               | See the session history and resume one of the previous sessions.                                                                                                                                                                                                                                                                                                 |
| `/ide`                   | Show the current JetBrains IDE connection status and the JetBrains IDE features available to the current session. For details, see [Junie CLI and JetBrains IDE integration](Junie-CLI-JetBrains-IDE-integration.md).                                                                                                                                            |
| `/install-github-action` | Launch an interactive wizard for installing and configuring [Junie GitHub Action](Junie-on-GitHub.md) in the current GitHub repository.                                                                                                                                                                                                                          |
| `/import`                | Import user- or project-level configs from other coding agents. <br><br>Junie CLI detects and suggests import of guidelines, agent skills, slash commands, or MCP server configurations from other coding agents like Claude Code, Codex, or Cursor.                                                                                                             |
| `/mcp`                   | Connect MCP servers to Junie CLI and manage the connections.                                                                                                                                                                                                                                                                                                     |
| `/model`                 | Select the main Large Language Model (LLM) to be used by Junie CLI and, for supported models, the reasoning [effort level](Junie-CLI.md#model-and-effort). <br><br>`Default` is the recommended pre-selected option with the best price quality ratio. The model behind the `Default` option is set dynamically and may change as new models are released. |
| `/new <prompt>`          | Clear up the context and start a new session. If you provide `<prompt>`, Junie opens the new session with that text in the prompt.                                                                                                                                                                                                                               |
| `/plan <prompt>`         | Toggle [plan mode](Junie-CLI-Plan-Mode.md). If you provide `<prompt>`, Junie enables plan mode and submits the prompt immediately.                                                                                                                                                                                                                               |
| `/remote`                | Open the current Junie CLI session in a web browser. For details, see [Remote Mode](Junie-CLI-Remote-Mode.md).                                                                                                                                                                                                                                                   |
| `/review`                | Start a [local code review](Junie-CLI.md#local-code-review) of your changes (compared to `main`, the last commit, or unstaged changes) before you commit them. Requires a git repository.                                                                                                                                                                  |
| `/settings`              | Change Junie settings, including theme, notifications, step limit, subagents mode, and diff view mode.                                                                                                                                                                                                                                                           |
| `/quit`                  | Exit Junie CLI interactive mode while staying logged in.                                                                                                                                                                                                                                                                                                         |
| `/update`                | Check for updates and install if available.                                                                                                                                                                                                                                                                                                                      |
| `/usage`                 | See the cost breakdown for the current session, including token usage and used models.                                                                                                                                                                                                                                                                           |
| `/worktree`              | Open the worktree menu to create or switch to an isolated git worktree for parallel work. See [Worktrees](Junie-CLI-Worktrees.md).                                                                                                                                                                                                                               |
{width="800"}

You can also add your own slash commands to Junie CLI. For details, see [Custom slash commands](Custom-slash-commands.md).

## Navigation

| Shortcut       | Description                                                             |
|----------------|-------------------------------------------------------------------------|
| `Ctrl+C` twice | Quit Junie CLI interactive mode.                                        |
| `!`            | Run a shell command in the embedded terminal. Example: `!ls`.           |
| `@`            | Search for a file or folder in your project to attach it to the prompt. |
| `/`            | Open the slash command suggestion menu.                                 |
| `?`            | Open the help menu to see all available shortcuts.                      |


## Modes and features

| Shortcut    | Description                                                                                   |
|-------------|-----------------------------------------------------------------------------------------------|
| `Shift+Tab` | Toggle between default mode and [plan mode](Junie-CLI-Plan-Mode.md).                          |
| `Ctrl+B`    | Cycle through the [brave mode](Junie-CLI.md#brave-mode) levels (Off, Auto, On).         |
| `Ctrl+R`    | Search the prompt history.                                                                    |
| `Ctrl+T`    | Open the full transcript of the current session.                                              |
| `Ctrl+N`    | Navigate the transcript of the current session after opening it (`Ctrl+T`).                   |

## Text editing

| Shortcut                    | Description                           |
|-----------------------------|---------------------------------------|
| `Shift+Enter` (or `Ctrl+J`) | Insert a new line in the prompt.      |
| `Ctrl+A`                    | Move cursor to the start of the line. |
| `Ctrl+E`                    | Move cursor to the end of the line.   |
| `Alt+B`                     | Move cursor one word backward.        |
| `Alt+F`                     | Move cursor one word forward.         |
| `Ctrl+U`                    | Delete the entire line.               |
| `Ctrl+W`                    | Delete the word before the cursor.    |

### Plan mode

# Plan mode

<show-structure for="chapter" depth="3" />

<tldr>
  Shortcut to toggle Plan mode: <code>Shift+Tab</code>
</tldr>

In Plan mode, Junie CLI analyzes the codebase with read-only operations and produces a design document for the task
before any code is written. You can review the plan, push back on assumptions, and adjust the scope — and only then
let Junie CLI implement it.

## How Plan mode works

When Plan mode is enabled, Junie CLI focuses on understanding the task and shaping a concrete implementation plan rather
than modifying the project:

- Junie CLI uses read-only operations to explore the codebase, configuration, and any context attached to the prompt.
- Instead of editing files, Junie CLI produces a plan that captures the scope, key decisions, and the reasoning behind
  them.
- The plan is treated as a living design document: when requirements change in the same session, the plan is
  updated alongside them.
- Once the plan is confirmed, Junie switches to implementation and applies the changes described in the plan.

Plan mode is most useful for non-trivial tasks where alignment on intent and approach matters more than producing
code as fast as possible.

## Enable Plan mode

You can enable Plan mode in the following ways:

- Press `Shift+Tab` in the prompt area to toggle between the default mode and Plan mode.
- Run the `/plan` slash command to toggle Plan mode. To start in Plan mode with your prompt submitted immediately,
  type `/plan <prompt>`, for example:

    ```
    > /plan refactor commands
    ```

- Use the `--plan` command-line flag to start Junie CLI directly in Plan mode. Combine it with `--prompt`
  to auto-submit a prompt in plan mode:

    ```bash
    junie --plan
    junie --prompt "Refactor the commands module" --plan
    ```

![](plan_mode_enabled.png){width="706"}

When Plan mode is active, the prompt area shows a corresponding indicator, and the agent's behavior changes to
plan-first.

## Review and refine the plan

After Junie CLI proposes a plan, the session pauses and waits for your input. The prompt area shows a set of actions
you can pick from:

- **Confirm and implement**: accept the plan and let Junie CLI proceed with the implementation using the agreed-upon
  scope and decisions.
- **View the entire plan** (`Ctrl+P`): open the dedicated plan view with the full design document.
- **Open `<plan-file>`**: open the saved plan file (Markdown) in your default editor or viewer.
- **Save the plan and stop**: keep the plan file on disk and end the session without implementing it.

![](plan_actions.png){width="706"}

You can iterate on the plan as many times as needed before implementation starts. This keeps course corrections
cheap — adjusting a plan is much faster than reverting code that does not match your intent.

## Plan view

Press `Ctrl+P` at any time during a plan-mode session to open the dedicated plan view. The plan view shows the
proposed design document split into tabs. The exact set of tabs depends on the task and may vary between sessions,
but typically you will see something like:

- **Requirements**: what the change should achieve: goals, scope, user stories, functional and non-functional
  requirements.
- **Technical design**: how the change is going to be implemented: the affected modules, key decisions,
  data flows, and trade-offs.
- **Testing**: the test strategy and specific test cases that will verify the implementation.
- **Delivery steps**: the concrete steps Junie CLI plans to take during implementation, in order.

Simple tasks may have fewer sections, while more complex tasks may include additional design sections alongside
the delivery steps.

![](plan_view_tabs.png){width="706"}

Use `Tab` or the arrow keys to switch between tabs. Press `Ctrl+P` again to return to the chat.

## Related documentation

- [Quickstart](Junie-CLI.md)
- [Slash commands reference](Slash-commands.md)

### Debug mode

# Debug mode

<show-structure for="chapter" depth="3" />

<tldr>
  Slash command to switch to Debug mode: <code>/debug</code>
</tldr>

Debug mode turns Junie CLI into an AI debugging assistant. Instead of editing source code, Junie CLI launches or
attaches to a running program, manages breakpoints, inspects runtime state, and evaluates expressions in the
currently paused execution frame.

Use Debug mode for problems that are easier to investigate at runtime than by reading code — flaky behavior,
unexpected variable values, or tracking down where execution actually goes.

## How Debug mode works

In Debug mode, Junie CLI operates against a live debugger session connected to a JetBrains IDE. The agent uses a
specialized set of tools focused on runtime inspection and execution control rather than source code modification:

- **Session control:** Launch a new debug session, attach to an existing process, resume execution, or step through
  code (step over, step into, step out).
- **Breakpoint management:** Set line and exception breakpoints, remove existing ones, and list all active
  breakpoints in the project.
- **State inspection:** Inspect variables in the current scope, view the call stack for all threads, and switch
  between threads and frames.
- **Expression evaluation:** Evaluate expressions or code fragments in the context of the currently paused frame.

Junie CLI does not modify source code while in Debug mode unless you explicitly ask for a change that is compatible
with the current execution state.

### Example interactions

- _"Why is `x` null?"_ — Junie CLI inspects the current paused frame, retrieves the value of `x` and the surrounding
  context (call stack, related variables), and explains the state.
- _"Stop at line 42 in `Main.kt`."_ — Junie CLI sets a line breakpoint at the requested location.
- _"What is `list.size()`?"_ — Junie CLI evaluates the expression in the current frame and reports the result.

## Requirements

Debug mode is only useful when Junie CLI can talk to a debugger. Make sure the following is in place before
enabling Debug mode:

- Junie CLI is connected to a JetBrains IDE with debugging support. For details on the IDE integration, see
  [Junie CLI and JetBrains IDE integration](Junie-CLI-JetBrains-IDE-integration.md).
- The IDE has a debug session active, or you are ready to ask Junie to start or attach to one.

If no IDE with debugging support is connected when you try to enable Debug mode, Junie CLI reports that
"Debug mode requires an IDE with debugging support connected" and stays in the default mode.

## Enable Debug mode

To toggle Debug mode, use the `Shift+Tab+Tab` shortcut or run the `/debug` slash command in the Junie CLI prompt:

```
> /debug
```

Using the same shortcut or running `/debug` again disables Debug mode and returns Junie CLI to the default mode.

## Related documentation

- [Junie CLI and JetBrains IDE integration](Junie-CLI-JetBrains-IDE-integration.md)
- [Using Junie in the terminal](Junie-CLI.md)
- [Slash commands reference](Slash-commands.md)

### Remote mode

# Remote mode

<show-structure for="chapter" depth="3" />

<tldr>
  Slash command to switch to Remote mode: <code>/remote</code>
</tldr>

Remote mode lets you open your running Junie CLI session in a web browser and keep working on the same task from
another device. The Junie CLI process keeps running in your terminal — Remote mode adds a synchronized web UI on top
of it.

## How Remote mode works

When you start Remote mode, Junie CLI opens a secure tunnel to the Junie web app and streams the session into a
web UI:

- The CLI session continues to run in your terminal, on your machine.
- The web UI shows the same chat history, progress, interactive prompts, and task status.
- Anything you send from the web UI — prompts, replies to approval requests, plan refinements — is routed
  back to the same running session.

Both the terminal and the web UI work against a single shared session, so you can switch between them at any time
without losing context.

> Your machine must stay awake while a remote session is active. If the computer goes to sleep, the CLI process is
> suspended and the web UI cannot communicate with it until you wake the machine.
> {style="note"}

## Requirements

Remote mode requires a Junie subscription:

- Sign in with your JetBrains Account, or
- Use a `JUNIE_API_KEY` access token.

[Bring Your Own Key (BYOK)](BYOK.md) on its own is not enough — Remote mode itself goes through the Junie service
and requires one of the two options above.

> Remote mode is not available when Junie CLI is signed in through **JetBrains AI Enterprise**. To use Remote
> Mode, sign in with your JetBrains Account or a `JUNIE_API_KEY` instead. See
> [Manage your account](Junie-CLI.md#manage-your-account).
> {style="warning"}

## Start a remote session

1. In Junie CLI, in a new or running session, run the `/remote` command.

    ```
    > /remote
    ```

2. On the **Remote mode** screen, select **Start Remote Session**.

    Junie CLI creates the tunnel and prints a confirmation message with the connection URL.

3. Open [`junie.jetbrains.com/remote`](https://junie.jetbrains.com/remote) in your browser.

    The web app connects to your running CLI session and replays the chat history. After that, the terminal and
    the browser stay in sync.

> Run `/remote` again to see the status of the active remote session, including connection state and the option to
> stop it.

## What you can do from the web UI

The web UI exposes the most common actions for continuing a task:

- Send a new prompt to the agent.
- Reply to interactive requests (approve or decline an action, answer a question, pick an option).
- Cancel the current task.
- Continue the task after the step limit is reached.
- Toggle [brave mode](Junie-CLI.md#brave-mode).
- Refine a proposed plan in [plan mode](Junie-CLI-Plan-Mode.md), or confirm a plan and ask the agent to
  implement it.

## Limitations

The web UI is intentionally narrower than the terminal. It is built to keep working on an existing CLI session,
not to fully replace the terminal:

- Slash commands such as `/new`, `/history`, `/account`, `/model`, `/usage`, `/ide`, `/mcp`, `/quit`, and custom
  slash commands are available only in the terminal.
- Shell commands invoked with `!` in the prompt are terminal-only.
- File and folder picking with `@` is not available in the web UI.
- Drag-and-drop of files and images is not available in the web UI.
- Prompt history search (`Ctrl+R`) and the session transcript view (`Ctrl+T`) are terminal-only.
- Only one web client can be connected to a remote session at a time. Opening the URL from another tab or device
  takes over the connection from the previous client.

If you need any of these features, switch back to the terminal — the session is the same, and your changes from
the web UI are already there.

## Stop a remote session

To stop sharing the current session with the web app:

1. Run `/remote` in the terminal.
2. On the status screen, select **Stop Remote Session**.

Stopping a remote session does not affect the underlying CLI session — you can continue working in the terminal
or start a new remote session later.

## Related documentation

- [Using Junie in the terminal](Junie-CLI.md)
- [Slash commands reference](Slash-commands.md)
- [Quickstart](Junie-CLI.md)

### Worktrees

# Worktrees

<show-structure for="chapter" depth="3" />

<tldr>
  Slash command to open the worktree menu: <code>/worktree</code>
</tldr>

Junie CLI integrates with [Git worktrees](https://git-scm.com/docs/git-worktree) to help you work on multiple
tasks in the same repository without branch conflicts. You can use existing worktrees, create new ones with
predefined names, and switch between them — all without leaving Junie.

A Git worktree is a linked checkout of the same repository in a separate directory. Each worktree has its own
working tree and index, so you can have different branches checked out simultaneously. Junie CLI makes it easy to
manage worktrees and switch the agent between them.

## The /worktree command

Run `/worktree` to open the worktree menu. From there you can:

- **Switch to an existing worktree**: select one of the worktrees already created for this repository.
- **Create a new worktree**: Junie creates a new Git worktree with a predefined name
  (`<project>-junie-wt-01`, `-02`, and so on) as a sibling directory of your project.
- **Switch back to the original project**: return to the main working directory.

After switching, the agent completely resets its state to the new worktree. This makes `/worktree` ideal for
use before starting a new task.

### Typical workflow

1. Pre-create a few worktrees so that build caches are ready in each one.
2. When you start a new task, run `/worktree` and switch to one of the prepared worktrees.
3. Prompt Junie to create a branch and rebase to fresh `main`.
4. Work on the task in the worktree while the original directory stays untouched.

### Transferring uncommitted changes

If your current working directory has uncommitted changes when you switch to a worktree, Junie asks whether to
transfer them or start clean:

- **Transfer changes**: Junie uses `git stash` to move uncommitted changes from the source directory to the
  target worktree.
- **Start clean**: the worktree starts with no uncommitted changes.

If the stash cannot be applied cleanly (for example, due to conflicts), Junie reports the issue and leaves the
changes in the stash so you can resolve them manually.

## Concurrent session detection

When a second Junie instance starts on the same project directory, Junie detects the conflict and reminds you
about possible issues with two agents operating on the same files. It then offers to switch to a worktree so
each instance works in its own isolated directory.

This serves two purposes:

- **Workspace management**: prevents two agents from making conflicting changes to the same files.
- **Onboarding**: helps you discover worktree support in Junie CLI if you haven't used it before.

## Auto worktree detection

If the agent navigates to a worktree directory during a session — whether because you prompted it to or a shell
command changed the working directory — Junie detects the switch and offers to restart with a clean task in the
new worktree.

Accepting the restart:

- Prevents the agent from continuing to operate on files in the old worktree.
- Switches the Junie project to the new directory, which affects where Junie looks for the `.junie` folder,
  loads skills, reads MCP configurations, and so on.

## Limitations

- Worktree support requires a git repository. It is not available for projects that are not tracked by git.
- Worktree directories are created as siblings of the project directory (for example,
  `../my-project-junie-wt-01`). Make sure the parent directory is writable.

### Code review agent

# Code review agent

<show-structure for="chapter" depth="3" />

<tldr>Slash command to invoke local code review: <code>/review</code></tldr>

Junie's code review feature uses a tailored subagent with optimized resource consumption for code review tasks:
instead of running a full agent session, it uses a more focused system prompt and a subset of read-only tools,
focusing on the changed lines of code.

> Local code review can only be run on projects in Git repositories.
> {style="note"}

Use local code review when you want to get a quick sanity check before opening a pull request,
review your own changes after a long coding session, or review your current branch against `main`.


## How it works

To run a local review of code changes, Junie CLI:

* **Loads the relevant code diff** according to the user-defined request scope.
* **Uses a focused prompt and toolset**: the agent can open files and search the project to understand context, but it never edits files, runs builds or tests, creates files, or commits and pushes changes.
* **Follows your guidelines and skills**: the agent reads project guidelines and any code-review-related [agent skills](Agent-Skills.md) and applies their instructions.
* **Supports follow-ups**: the review runs as its own session that can be resumed, so you can ask follow-up questions such as *"Is the fix I just pushed good enough?"* without re-explaining the context.


## Usage

### Standard checks

When you invoke the `/review` slash command, Junie CLI detects the Git state of your project and opens a wizard with available review targets:

- **From Main**: compares your current branch against `main`. Shown only when a `main` branch exists, and you are not currently on it.
- **Last Commit**: reviews the changes introduced in the most recent commit.
- **Unstaged Changes**: reviews the code you have modified but not yet committed.

![](review_wizard.png){width="706" border-effect="line"}

### Custom instructions

You can scope the review to a specific concern or set of changes by adding plain-text instructions after the command:

```console
/review focusing on performance and memory leaks
```

```console
/review the last two commits
```

Junie CLI will prioritize your instructions while still performing its standard review checks.

## Navigating review results

Junie CLI presents the findings in a dedicated review screen where you can:

* Browse the list of suggestions grouped by file.
* View the relevant code context for each of the suggestions.
* Accept or dismiss suggestions one by one, or select several suggestions and accept or dismiss them at once.

Critical findings, such as security vulnerabilities, crashes, data loss, or correctness issues that break functionality,
are prefixed with a `[CRITICAL]` label. When a fix is simple and safe, Junie CLI includes a ready-to-apply code suggestion.

Closing the review screen finishes the review and returns you to the task screen, keeping the review as part of the same
session history.

## Also available in

- **Headless mode**: Use the `--review` flag with the `junie` command in your terminal. You can optionally provide
  a natural language description to guide the review.

  ```console
  # Review current changes in the repository
  junie --review
  
  # Review changes with specific instructions
  junie --review "Check for potential null pointer exceptions in the new logic"
  
  # Compare with a specific branch
  junie --review "Compare my changes with the develop branch"
  ```
- **GitHub CI/CD pipelines**: To trigger Junie's code review agent on opened or updated GitHub pull requests, use the
  [Junie GitHub Action](Junie-on-GitHub.md) for automated code reviews.
  See the [cookbook](Automated-code-reviews.md) for details.

### Demo agent

# Demo agent

<show-structure for="chapter" depth="3" />

<tldr>Slash command to invoke the demo agent: <code>/demo</code></tldr>

The `/demo` slash command launches a **visual demo** of your project. Junie CLI
spins up a disposable virtual machine, builds and starts your app inside it,
and then drives the running UI — clicking, typing, and taking screenshots — to show
that a feature or recent change works. The result is a structured Markdown
answer in the TUI plus a folder of [output artifacts](#output-artifacts) —
screenshots, a screen recording, and a self-contained HTML report — that you
can share or attach to a PR.

Think of it as **'show me, don't tell me'**: instead of asking Junie to read
code and explain a change, you ask Junie to *use* the app and prove the change
is real on screen.

## Prerequisites

`/demo` requires:

* **Docker running on your machine.** This is the most important prerequisite —
  the demo VM is a Docker container, and `/demo` will not start without a
  working Docker daemon. If `docker ps` doesn't work in your terminal,
  `/demo` won't work either. Start Docker Desktop before running `/demo`.
* **A model with Computer Use support.** Right now only **GPT‑5.4 and newer**
  (GPT‑5.4, GPT‑5.5) are supported. More models will be added later as
  Computer Use becomes available on them. If your active model doesn't
  qualify, `/demo` refuses to start and shows the supported list. See
  [Junie CLI Model selection](Junie-CLI-Model-selection.md).
* **A demo VM image** at `.junie/vms/<name>/Dockerfile`, layered on top of
  the base image `registry.jetbrains.team/p/junie-cli/containers/demo-base:2`.
  The base is Debian bookworm and ships Chromium, Node.js, xterm, ffmpeg,
  xdotool, screenshot tooling and a headless Xvfb desktop with a window
  manager — everything Computer Use needs to drive a desktop or web app.
  The first time `/demo` runs in a project with no VM template, Junie
  seeds a starter one for you — see [First-run setup](#first-run-setup).
  Add the runtimes your app needs on top, as shown in
  [Customizing the demo](#customizing-the-demo).

## Quick start

You have two ways to set up `/demo` for a project: **author the files by
hand** as shown below, or **skip authoring** and let `/demo` create
starter versions for you on the first run (see
[First-run setup](#first-run-setup)).

For projects that need anything beyond "open a browser at localhost", you'll
typically set up three things in your repo:

1. **A custom image on top of `demo-base`.** Create
   `.junie/vms/<your-vm>/Dockerfile` that starts with
   `FROM registry.jetbrains.team/p/junie-cli/containers/demo-base:2` and adds
   the runtimes your app needs (JDK, Node, Python, system packages…). The
   base already handles the display stack — don't reinstall it.

   Node example:

   ```dockerfile
   # .junie/vms/node-vm/Dockerfile
   FROM registry.jetbrains.team/p/junie-cli/containers/demo-base:2
   RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm
   ```

   Python example:

   ```dockerfile
   # .junie/vms/python-vm/Dockerfile
   FROM registry.jetbrains.team/p/junie-cli/containers/demo-base:2
   RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-pip
   ```

2. **Mounts (optional).** The project root is always mounted at `/workspace`
   automatically — you don't need to configure that. For extra bind mounts
   (host credentials, fixture data, prebuilt artifacts on the host), create
   a text file at `.junie/vms/<your-vm>/mounts` (no extension, **not a
   directory**) with one mount per line:

   ```text
   # <hostPath>:<guestPath>[:ro|:rw]
   # $HOME and ${HOME} are expanded from the environment.
   # Lines starting with # are ignored.
   $HOME/.config/my-app:/root/.config/my-app:ro
   /tmp/my-fixtures:/workspace/fixtures
   ```

   Missing host paths are skipped with a warning — Junie won't refuse to
   start the VM because of a stale mount line.

3. **A `.junie/demo.md` file** telling the agent which VM to use and how to
   build/launch the app. The **`vm:` value must match the subdirectory name
   you created in step 1** — that's how Junie binds the file to your
   Dockerfile.

   Node project — `vm: node-vm` matches `.junie/vms/node-vm/`:

   ```markdown
   # My web app

   vm: node-vm

   ## Build inside the VM
       npm install && npm run build

   ## Launch
       npm run start &
       # ready when http://localhost:3000 responds 200
   ```

   Python project — `vm: python-vm` matches `.junie/vms/python-vm/`:

   ```markdown
   # My Python app

   vm: python-vm

   ## Build inside the VM
       pip install -r requirements.txt

   ## Launch
       python app.py &
       # ready when http://localhost:5000 responds 200
   ```

   Shortcut: if you only ever need one VM, you can skip the subdirectory and
   put the Dockerfile straight at `.junie/vms/Dockerfile`. Then reference it
   in `.junie/demo.md` as `vm: default`.

Now `/demo` will pick up your custom image, mounts, and launch instructions
automatically.

## Basic usage

The syntax is:

```text
/demo [what to demo]
```

The argument is free‑form natural language describing what you want to see.
Everything after `/demo ` is passed to the demo agent verbatim.

### With no arguments

```text
/demo
```

If you don't pass anything, `/demo` **picks up the previous context of the
current session automatically** — the messages you exchanged, the files
Junie touched, the task it just finished. You don't have to repeat what was
done; the demo agent already sees it. Junie then demos whatever stands out
from that history. If nothing stands out — for example you've just opened
a fresh project — Junie demos the app's main functionality.

This is the most common way to use `/demo`: you've just had Junie implement
or fix something, and you want to *see* it working before you commit. Just
type `/demo` and hit Enter.

### With a specific request

```text
/demo show the new dark-theme toggle in Settings
/demo open the search dialog and find 'TODO'
/demo log in as user@example.com and open the profile page
```

The more concrete the request, the tighter the demo. A request like
`/demo show X` is treated as self‑contained — Junie won't go hunting through
git history to find unrelated context.

### Demoing a specific feature from scratch

```text
/demo the file-tree drag-and-drop in the sidebar
```

When you want a demo of an existing feature (not a recent change), name the
feature explicitly. Junie will resolve how to reach it (menu item, hotkey,
URL, etc.) and walk through it.

## What happens when you run `/demo`

A `/demo` run goes through four phases. Knowing the phases helps you interpret
what's on screen at any moment.

### 1. Plan

Before any VM starts, Junie writes a short **visible demo plan** —
an ordered list of user‑visible milestones, e.g.:

```text
1. Launch the app — main window shows the file tree.
2. Open Settings via the gear icon — Settings dialog appears.
3. Toggle "Dark theme" — UI re-renders in dark colors.
4. Close Settings — main window remains in dark mode.
```

The plan is your contract with the agent. If a step looks wrong, interrupt
with <kbd>Esc</kbd> and adjust the request before the VM starts.

### 2. Build and launch

Junie:

1. (Optionally) builds artifacts on **your host machine** — but only if
   `.junie/demo.md` explicitly asks for it. By default nothing is built on the
   host.
2. Starts the VM (`vm_start`). Your project root is mounted at `/workspace`
   inside it.
3. Builds the project inside the VM (commands come from `.junie/demo.md`
   if present, otherwise Junie figures them out).
4. Launches the app in the background and waits for it to be ready
   (health endpoint, log line, or just a visual wait).

A blank screen right after `vm_start` is normal — the app hasn't started yet.

### 3. Demonstrate

Junie drives the running app via Computer Use: clicks, keystrokes,
screenshots. The TUI shows a `Working… esc to stop` indicator while the agent
is acting. Each action is followed by an automatic screenshot, so you'll see
the run progress step by step.

If a visual attempt fails 2–3 times and Junie can't figure out the next step
from the screen, it falls back to **targeted code lookups** (grep + open
file). This is allowed but rare — the primary source of truth is the running
app, not the source code.

### 4. Finish

Junie CLI shuts down the VM (`vm_stop`) and writes a structured Markdown report
with two main sections:

* **What has been tested**: the steps that ran and what was visible.
* **Result**: pass / fail / partial, plus any issues spotted.

The screenshots, video, and HTML report from the run are saved alongside
the session — see [Output artifacts](#output-artifacts) for the exact paths.

## Stopping a demo

* Press <kbd>Esc</kbd> while the `Working…` indicator is visible to interrupt
  the agent. The VM is shut down cleanly.
* The agent won't launch the VM twice in one session unless you explicitly
  ask.

## Output artifacts

After a `/demo` run finishes, you get a folder of artifacts on disk that you
can share, attach to a PR, or rewatch later. They live under your Junie home
directory, grouped by session:

```text
~/.junie/sessions/<session-id>/demo/
├── screenshots/         PNG screenshots captured during the run
│   └── shot_20260520_120005_000.png …
├── demo.mp4             screen recording of the VM (if recording finished)
├── captions.vtt         caption track aligned to the video
└── report.html          self-contained HTML report
```

What each one contains:

* **`report.html`**: the main artifact. A single self-contained page with the
  user request, the agent's Markdown answer ('What has been tested' + result),
  the embedded video, and the screenshots inline. This is what you usually
  attach to a PR or send to a teammate.
* **`demo.mp4`**: the screen recording. Only present if the recorder
  started and was stopped cleanly before VM teardown. Embedded inside
  `report.html` too.
* **`captions.vtt`**: WebVTT caption track generated from screenshot
  timestamps. Used by `report.html` to label moments in the video.
* **`screenshots/`**: every screenshot Computer Use took during the run,
  one PNG per `computer` call.

The Markdown answer the agent shows in the TUI is **not written to a
separate file** — it lives in the session transcript and inside
`report.html`. If you want the raw text, copy it from the TUI or open the
report.

**Persistence:** artifacts are kept across sessions — nothing is auto-cleaned.
If you want them gone, delete the session folder under `~/.junie/sessions/`
manually.

## Customizing the demo

`.junie/demo.md` tells the demo agent project‑specific build and launch
commands. Use it when 'how to start the app' isn't obvious from the source
tree. The [Quick start](#quick-start) above shows the basic structure; this
section lists the kinds of things you can usefully put inside.

Common things to put in `.junie/demo.md`:

* **`vm: <name>`** — required. The agent passes this value to `vm_start` as
  the template name, and the action fails if it's missing. The name must
  resolve to a Dockerfile under `.junie/vms/`: either a subdirectory
  (`.junie/vms/<name>/Dockerfile`) or the literal value `default` for the
  top-level `.junie/vms/Dockerfile`.
* The exact build command(s) to run inside the VM.
* The launch command — always background it (`&` or `nohup … &`).
* A health check Junie can wait on before interacting with the UI.
* Whether the jar/binary should be built on the host first (and the exact
  `bash` command to do it — Junie will only run it if you explicitly ask).

## First-run setup

If you haven't configured `/demo` for this project yet — meaning no
`.junie/vms/<name>/Dockerfile` exists — the first run won't start a real
demo. Instead, Junie seeds a starter configuration for you and asks how
you want to proceed. Two files appear in your project:

### What gets seeded

* **`.junie/demo.md`** — the project-level guide that tells the demo agent
  which VM to use and how to launch your app. The file is free-form
  Markdown; the agent reads it as instructions before doing anything. Two
  things in it are essential:

    - **`vm:`**: the name of a subdirectory under `.junie/vms/`. The
      seeded file already has `vm: template-vm` wired up.
    - **The launch command**: how to start your app inside the VM. Goes
      under the `## Running inside the VM` section.

  Everything else is optional. Useful things to grow `demo.md` with later
  include: host-side build steps you want Junie to run, environment
  variables, test users, known quirks, or links to other docs.

* **`.junie/vms/template-vm/Dockerfile`** — the VM image. Extends
  `registry.jetbrains.team/p/junie-cli/containers/demo-base:2` — see
  [Prerequisites](#prerequisites) for what the base ships. Add the apt
  packages and language runtimes your app needs on top.

### Filling it in

Right after seeding, Junie shows you the two files and offers a choice
(navigate with the arrow keys, `enter` to pick):

* **Yes, fill them in for me** — Junie inspects your project (package
  manager, dev/start command, port, extra runtimes) and fills in the launch
  command in `demo.md` and the `Dockerfile` for you. Review what it wrote,
  then re-run `/demo`.
* **No, I'll do it myself** — Junie leaves the seeded files untouched so you
  can edit them by hand.

You can also trigger the automatic fill-in later — ask Junie to "set up
`/demo`", or invoke the `demo-setup` skill with `$demo-setup`. Either way
Junie only edits `demo.md` and the VM `Dockerfile`, and leaves the final
review and the real demo run to you.

### After editing

Once both files are filled in, re-run `/demo`. Junie will pick up the new
VM template and start a real demo run. The seed only fires when no VM
template exists yet — once `.junie/vms/` has any Dockerfile, your
configuration is treated as authoritative and Junie leaves it alone.

If you mess something up and want to start over, delete `.junie/vms/`
(and optionally `.junie/demo.md`) and re-run `/demo` — the seed will fire
again.

> **Note:** the seeded `demo.md` carries explanatory HTML comments at the
> top describing what each section is for. Once your file is in good
> shape, delete those comments so the agent context isn't bloated by
> generator boilerplate it doesn't need.

If you'd rather author `.junie/demo.md` and the Dockerfile from scratch
without using the seeded starter, just create them yourself before the
first `/demo` run — the seed only fires when nothing is there.

## Multiple VM templates in one project

`.junie/vms/` is a directory — you can put **as many VM subdirectories
under it as you want**, each with its own Dockerfile (and optionally its
own `mounts` file). A typical layout for a project that ships several
VMs side by side:

```text
.junie/
├── demo.md
└── vms/
    ├── backend-vm/
    │   ├── Dockerfile
    │   └── mounts
    ├── frontend-vm/
    │   └── Dockerfile
    └── cli-vm/
        └── Dockerfile
```

All templates discovered under `.junie/vms/` are listed to the demo agent
on every `/demo` run, so it can pick the right one according to the
instructions in `.junie/demo.md`.

## Examples

### Verify a fix you just made

```text
> fix the bug where the search box loses focus after typing one character
…Junie edits files, runs tests…
> /demo
```

Junie picks up the change from the current session, opens the search box,
types several characters, and shows that focus stays.

### Demo a feature in a fresh repo

```text
/demo open the project, run the example notebook, show the chart it produces
```

Useful for onboarding videos or PR descriptions.

### Compare a 'before / after' change

```text
> /demo show the old behavior, then the new behavior of the export button
```

If the session history doesn't contain a clear "before" state, Junie will
note that in the report instead of inventing one.

## Troubleshooting

**'Demo agent requires access to a model with computer use support…'**
: Your active model isn't on the supported list. Today that list is
GPT‑5.4 and GPT‑5.5; more models will land later. Switch via
[Junie CLI Model selection](Junie-CLI-Model-selection.md).

**The VM starts but the screen stays blank**
: Normal in the first few seconds after `vm_start`. If it persists, the app
probably failed to launch — check `.junie/demo.md` for the right build/launch
commands, or add a health check Junie can wait on.

**Junie keeps reading source files instead of clicking**
: This usually means the entry path (how to reach the feature) isn't obvious.
Tell Junie directly in the request: `/demo open Settings via Cmd+, and toggle X`.

**`/demo` is disabled / greyed out**
: Either Docker isn't running, or no Computer Use model is available for
your account.

## Related

* [Slash commands](Slash-commands.md) — full list of slash commands.
* [Junie CLI Model selection](Junie-CLI-Model-selection.md) — picking a model
  that supports Computer Use.

### Junie CLI: What is stored on the user's disk

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
  inspect the full stdout/stderr when important details are outside the displayed tail

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
- `~/.junie/misc/`
- `~/.junie/mcp/mcp.json`
- `~/.junie/models/`
- `~/.junie/agent-skills/`
- `~/.junie/secure_credentials.json` — only if system secure storage is unavailable

The most sensitive locations are:

- `secure_credentials.json`, if fallback storage is used
- the contents of `sessions/`, because they may contain work history and agent state
- user model profiles in `models/`, if they contain keys or custom headers


