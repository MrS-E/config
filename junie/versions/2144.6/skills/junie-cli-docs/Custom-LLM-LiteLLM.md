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
