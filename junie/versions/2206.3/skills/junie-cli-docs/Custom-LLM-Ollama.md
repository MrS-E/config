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
