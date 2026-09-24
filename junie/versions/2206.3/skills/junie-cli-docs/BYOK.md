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
