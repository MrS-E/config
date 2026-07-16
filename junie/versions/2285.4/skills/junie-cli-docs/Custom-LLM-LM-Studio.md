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
