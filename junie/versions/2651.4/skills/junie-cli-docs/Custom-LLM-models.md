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
| `apiKey`       | String | No       | The API key for authenticating with the endpoint. If omitted, requests are sent without an `Authorization` header. Supports [environment variable references](#environment-variables). |
| `extraHeaders` | Object | No       | A key-value map of additional HTTP headers to include in every request to the endpoint. Values support [environment variable references](#environment-variables). |
| `extraBody`    | Object | No       | A JSON object merged into the body of every request to the endpoint. See [Extra body](#extra-body).                                          |
| `temperature`  | Number | No       | The sampling temperature to use for requests. If omitted, the provider's default temperature is used. See [Temperature](#temperature).       |
| `maxContextLength` | Integer | No   | The maximum context length supported by the model, in tokens.                                                                                |
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
| `extraBody` | Object | Additional request body fields for this role. Merged with (not replaced by) the top-level `extraBody`. |
| `temperature` | Number | Override for the sampling temperature used for this role. |
| `maxContextLength` | Integer | Override for the maximum context length supported by this role, in tokens. |

### Merging logic

Overrides in `primaryModel` or `fasterModel` are merged with the top-level defaults:
- **Simple fields** (`id`, `baseUrl`, `apiKey`, `apiType`, `temperature`, `maxContextLength`) are replaced by the override value when present.
- **Headers** (`extraHeaders`) are merged: headers defined in the override are added to the top-level headers. If the same header key appears in both, the role-level value takes precedence.
- **Body fields** (`extraBody`) are merged recursively: entries defined in the override are added to the top-level `extraBody`. If the same key appears in both and both values are nested objects, those objects are merged recursively (rather than the override replacing the whole subtree). For any other conflicting value, the role-level value takes precedence.

### Environment variables {id="environment-variables"}

Custom model profiles are often committed to a project repository and shared with a team (for example, to share a
custom `baseUrl` or model routing). To avoid leaking secrets, you can reference environment variables inside the
`apiKey` field and inside `extraHeaders` values instead of hardcoding them.

Use the `${VAR_NAME}` syntax. Junie resolves each reference against the corresponding environment variable when it
loads the profile:

```json
{
  "baseUrl": "https://openrouter.ai/api/v1/chat/completions",
  "id": "your-model",
  "apiType": "OpenAICompletion",
  "apiKey": "${OPENROUTER_API_KEY}",
  "extraHeaders": {
    "X-Custom-Auth": "${CUSTOM_AUTH_TOKEN}"
  }
}
```

A reference must match `${NAME}`, where `NAME` starts with a letter or underscore and contains only letters, digits,
and underscores. Values without any `${...}` reference are used as-is, so existing literal keys keep working unchanged.

If a referenced environment variable is not set, the profile fails to load and Junie reports an error identifying
the missing variable. Set the variable before starting Junie (or replace the reference with a literal value) to
resolve it.

### Supported API types {id="supported-api-types"}

The `apiType` field controls which request format Junie uses when calling the endpoint.

| Value | Description |
|---|---|
| `OpenAICompletion` | OpenAI Chat Completions API (`/v1/chat/completions`). Compatible with most self-hosted and third-party OpenAI-compatible endpoints. |
| `OpenAIResponses` | OpenAI Responses API (`/v1/responses`). Use this for endpoints that implement the newer Responses API format. |
| `Google` | Google Gemini API format. Use this for Google AI Studio or Vertex AI endpoints. |
| `Anthropic` | Anthropic Messages API format. Use this for Anthropic Claude endpoints. |

## Extra body {id="extra-body"}

Some providers and proxies accept additional, non-standard fields in the request body — for example, routing
metadata or tags. Use the `extraBody` parameter to merge a JSON object into the body of every request Junie sends to
the endpoint.

You can set `extraBody` at the top level (shared by both model roles) or override it per role. A common use case is
tagging requests for a proxy such as LiteLLM:

```json
{
  "baseUrl": "http://localhost:4000/v1/chat/completions",
  "id": "my-proxy-model",
  "apiType": "OpenAICompletion",
  "extraBody": {
    "tags": ["user:alice", "department:engineering"]
  }
}
```

The `extraBody` entries are merged into the top level of the request JSON. If a key conflicts with a field Junie
already sets (for example, `model` or `messages`), the `extraBody` value takes precedence, so use it with care.

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
