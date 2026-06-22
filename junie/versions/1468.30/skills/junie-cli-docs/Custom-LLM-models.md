# Custom LLMs

<primary-label ref="eap"/>

Junie CLI supports custom models defined via JSON profiles. This feature allows you to integrate with local providers 
(e.g., Ollama), enterprise proxies, or any LLM endpoint that follows the supported API formats.

> This feature is currently in the [Early Access program](Junie-CLI-EAP.md). To try it,
> [install the EAP build](Junie-CLI-EAP.md) of Junie CLI.

## Configuration

### Location and discovery

By default, custom models are discovered from JSON files located in:
- User-scope: `$JUNIE_HOME/models/*.json`.
- Project-scope: `.junie/models/*.json`.

The filename (without the `.json` extension) is used as the **profile identifier**.

You can control where Junie searches for custom models using the following command-line options:

| Option                                            | Default | Description                                                                              |
|---------------------------------------------------|---------|------------------------------------------------------------------------------------------|
| `--model-default-locations` | `true`  | Enable or disable adding custom models from default locations (per user / per project).  |
| `--model-location <path>`  | —       | Additional folders where custom models should be found. Can be specified multiple times. |
{width="800"}

You can also set these values in the `config.json` file. For details, see [Junie CLI configuration files](Junie-CLI-configuration.md).

### Profile structure

A custom model profile consists of a top-level configuration and two optional model roles:

1. **Top-level properties**: Serve as the default configuration (base URL, API key, API type, and extra headers) for the models in the profile.
2. **`primaryModel`**: The model used for main reasoning and code generation tasks.
3. **`fasterModel`**: The model used for internal helper tasks like summarizing context or classifying tasks.

If `primaryModel` or `fasterModel` is not explicitly defined, they inherit the top-level properties.

### Merging logic

Overrides in `primaryModel` or `fasterModel` are merged with the top-level defaults:
- **Simple fields** (ID, base URL, API key, API type) are replaced by the override if present.
- **Headers** (`extraHeaders`) are merged: headers defined in the override are added to the top-level headers.

### Supported API types

Junie supports the following API formats for custom models:
- `OpenAICompletion`
- `OpenAIResponses`
- `Google`
- `Anthropic`

## Example profile

Below is an example of a profile named `local-ollama.json`:

```json
{
  "baseUrl": "http://localhost:11434/v1/responses",
  "id": "qwen3-coder:latest",
  "apiType": "OpenAIResponses",
  "extraHeaders": {
    "X-Custom-Source": "Junie"
  },
  "fasterModel": {
    "id": "qwen2.5-coder:1.5b"
  }
}
```

In this example, the primary model will be `qwen3-coder:latest`, and the faster model will be `qwen2.5-coder:1.5b`. Both will use the same base URL, API type, and extra headers.

## Using custom models

Once a profile is created, you can select it using the `/model` command or the `--model` flag. Custom models are identified by a `custom:` prefix followed by the profile ID:

```bash
junie --model custom:local-ollama
```

In the interactive TUI, custom models appear in the model selection list after the built-in providers.
