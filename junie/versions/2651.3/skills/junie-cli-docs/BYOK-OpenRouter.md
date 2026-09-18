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
