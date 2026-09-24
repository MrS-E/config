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
- **Authentication** — the `/auth/test` and `/auth/reset` paths validate the token and license state.

When using the default JetBrains provider, Junie authenticates automatically via JetBrains Account (JBA).
When using a custom proxy, JBA authentication is bypassed — you must supply any required credentials (such as `Authorization: Bearer <token>`) through the proxy's `headers` field.
All the sub-endpoints above, including authentication, are routed through the selected proxy with those headers.

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

## Legacy: the INGRAZZIO_URL environment variable {id="ingrazzio-url-env"}

> `INGRAZZIO_URL` is a legacy compatibility mechanism (kept for existing AIR deployments) and will
> eventually be removed. Declare an `Ingrazzio` proxy in `config.json` instead.

Setting the `INGRAZZIO_URL` environment variable creates an implicit `Ingrazzio`-kind proxy named `ingrazzio-env` pointing at that URL — no `config.json` entry is required:

```bash
INGRAZZIO_URL="http://127.0.0.1:53367" junie
```

The synthetic proxy behaves like a proxy declared in `config.json`:

* All requests — LLM chat, web search, URL extraction, and authentication (`/auth/test`, `/auth/reset`) — are routed through the given URL, and it appears in the model selector next to configured proxies.
* It automatically becomes the default provider unless another `provider` is selected via the CLI (`--provider`) or `config.json`.
* If `config.json` declares any `Ingrazzio`-kind proxy, that configuration takes precedence and `INGRAZZIO_URL` is ignored entirely.
* If an ingrazzio token is supplied via the environment (for example, `JUNIE_API_KEY` or `EJ_AUTH_INGRAZZIO_TOKEN`), it is sent as the `Authorization` header of the proxy's requests; otherwise Junie falls back to the JetBrains Account token.

## Supported proxy kinds {id="supported-proxy-kinds"}

The `kind` field determines which protocol Junie uses to communicate with the proxy.

| Kind | Status | Description |
|---|---|---|
| `Ingrazzio` | **Supported** | Junie's native proxy protocol. Compatible with JetBrains Ingrazzio deployments. This is the default when `kind` is omitted. |
| `Bedrock` | **Supported** | Anthropic models served through an AWS Bedrock-compatible gateway. Requires the additional Bedrock fields described below. |
| `OpenAI` | Planned | OpenAI-compatible API. |
| `Anthropic` | Planned | Anthropic-compatible API. |
| `JetBrainsAI` | Planned | JetBrains AI Gateway. |
| `OpenRouter` | Planned | OpenRouter-compatible API. |

## Bedrock proxies {id="bedrock-proxies"}

A `Bedrock` proxy routes Anthropic models through an AWS Bedrock-compatible gateway. Requests are sent to
`<api-url>/model/<wire-name>/invoke`, where `<wire-name>` is the provider-side model id with Bedrock's default
cross-region inference prefix.

Because Bedrock model ids differ from Junie's model ids, a Bedrock proxy needs one extra field beyond the common ones:

| Field | Required | Description |
|---|---|---|
| `available-models` | Yes | JetBrains model ids this proxy exposes (for example, `anthropic-claude-4-6-sonnet`). At least one is required. |

If the proxy's `headers` include an `Authorization` header, it is used as-is; otherwise Junie falls back to the JetBrains Account token.

```json
{
  "proxies": [
    {
      "name": "corp-bedrock",
      "kind": "Bedrock",
      "api-url": "https://bedrock-gateway.example",
      "available-models": ["anthropic-claude-4-6-sonnet", "anthropic-claude-4-8-opus"],
      "headers": [
        "Authorization: Bearer <your-token>"
      ]
    }
  ],
  "provider": "corp-bedrock",
  "model": "sonnet"
}
```

> The `Ingrazzio` and `Bedrock` kinds are functional. The remaining kinds are reserved for future use and will result in an error at startup.

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

* Only the `Ingrazzio` and `Bedrock` proxy kinds are currently supported. Other kinds are reserved for future use.
* Proxy configuration is only available through `config.json`. There are no dedicated CLI flags for defining proxy entries.
* When using a proxy provider, JetBrains AI authentication is bypassed entirely. You must supply any required credentials via the `headers` field.
