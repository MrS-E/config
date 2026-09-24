---
name: demo-setup
description: "Fill in a project's `/demo` configuration by inspecting the project: complete the `.junie/vms/<vm>/Dockerfile` and the launch command in `.junie/demo.md`. TRIGGER when: the user asks to set up, configure, or finish `/demo`; the user asks you to fill in `.junie/demo.md` or a `.junie/vms/*/Dockerfile`; a first `/demo` run just seeded starter files and aborted. DO NOT TRIGGER when: `/demo` is already configured and the user only wants to run it, or when editing application code unrelated to demo setup."
---

# Setting up `/demo` for a project

`/demo` drives the project's app inside a VM and records it. When a project has
no demo configuration, two starter files are seeded:

- `.junie/demo.md` — the guide the demo agent reads before driving the app.
- `.junie/vms/template-vm/Dockerfile` — the VM image the app runs in.

The user has already agreed to let you set this up. Full reference:
https://junie.jetbrains.com/docs/junie-cli-demo.html

## The algorithm — follow it in order

> **1. Research** — inspect the repo and form your best candidate launch command.
> **2. Confirm with the user** — show that candidate and ask. Write NOTHING yet.
> **3. Only then do it** — write `demo.md` with the confirmed command, then the Dockerfile.

This is a hard sequence, not a suggestion. **Never modify any file without the
user confirming the change first.** Do not edit `demo.md` or the Dockerfile
until step 2 is done and the user has approved what you intend to write. Your
first file edit must come *after* the user has answered, never before. If you
catch yourself about to edit a file without an explicit confirmation — stop and
ask first.

## 1. Find the candidate launch command

Inspect the repo and form your best candidate for how to start the app:

- **The dev/start command** — `scripts` in `package.json` (`dev`, `start`,
  `preview`), or the equivalent for the project's stack. This is the field that
  breaks the demo when wrong, so it's the thing to get right.
- **The runtime & package manager** — from the lockfile / manifest
  (`pnpm-lock.yaml`, `yarn.lock`, `requirements.txt`, `pyproject.toml`, `go.mod`,
  `Gemfile`, etc.).
- **The port** — from the script, framework default, or config. The agent needs
  it for the health check.

Be skeptical of scripts you find (`start-*.sh`, `run.sh`, Makefile targets):
one may exist for the project's own infrastructure, not for launching the app
the demo should show. Don't assume a script is the launch command just because
it looks like one.

## 2. Propose the command and get the user's feedback

**Do not write anything yet.** Present your candidate launch command (and the
port) to the user and ask them to confirm or correct it — use your ask-the-user
tool. Make clear it's a guess from inspecting the repo, not a fact.

Only proceed once the user has confirmed or given you the right command. If they
correct it, use their command verbatim. The point of this step is that you reach
step 3 *knowing* what to run, instead of committing a best guess.

## 3. Write `demo.md` with the confirmed command

`demo.md` documents **only how to launch the app**, nothing else (no auth keys,
licenses, or unrelated setup — those belong in VM scripts or mounts). Fill:

- **`vm:`** — the VM template directory name (default `template-vm`).
- **The launch command** under `## Running inside the VM` — the command the user
  confirmed, run from `/workspace`. **Background it** (`&` or `nohup … &`) so the
  agent can proceed, and bind to `0.0.0.0` if the framework defaults to
  localhost-only.

Delete the seeded explanatory HTML comments once the file is filled in.

Example body:

```markdown
vm: template-vm

## Running inside the VM

Install deps and start the dev server (Nuxt, port 3000):

    pnpm install
    pnpm dev --host 0.0.0.0 &
```

## 4. Derive the Dockerfile from that command

Now that the launch command is settled, make the VM able to run it. The template
extends the official demo base image:

```dockerfile
FROM registry.jetbrains.team/p/junie-cli/containers/demo-base:2
```

The base **already ships Chromium, Node.js, xterm, a window manager, and an
ffmpeg recorder**. Rules:

- **Only add layers on top of the base. Never replace the `FROM` line.** Add
  only the runtimes/packages the confirmed command actually needs that the base
  lacks (e.g. a specific Python, a pinned Node via corepack, system libs).
- For a plain Node/JS app the base is often enough — leave the Dockerfile as-is
  rather than adding noise.
- If the command needs services or tooling the base can't provide (a Docker
  daemon, a database, a multi-service orchestrator), that won't work in the VM —
  go back to the user rather than papering over it.

## 5. Build the image to verify the Dockerfile

**If you added any layers to the Dockerfile** (a `RUN`, `COPY`, extra runtime,
etc.), build it now so a mistake — a wrong package name, an unavailable apt
package — surfaces here instead of failing later when the user runs `/demo`.
`/demo` builds with the project root as the build context and the template's
Dockerfile, so reproduce that exactly, from the project root:

    DOCKER_BUILDKIT=1 docker build -f .junie/vms/<vm>/Dockerfile -t junie-demo-<vm>-verify .

- If the build **fails**, only fix it when the cause is clear and your fix is
  certain (e.g. an obviously wrong package name). Otherwise **don't keep guessing
  and rebuilding** — that's the same guesswork this skill exists to avoid. After
  one or two confident fixes at most, if it still won't build or you're unsure
  why, stop, show the user the build error, and ask them how to proceed. Either
  way, do not touch the launch command — the user already confirmed it.
- If `docker` isn't available or the base image can't be pulled (the base lives
  in a registry that may need auth), **don't treat that as a Dockerfile error** —
  skip the build, say you couldn't verify it and why, and still hand back.
- If you added **no** layers (the Dockerfile is the untouched base), skip this —
  there's nothing of yours to validate and `/demo` pulls the base anyway.

This only builds the image to validate it. It is not running the demo — do not
start the VM or record anything.

## 6. Hand back

- Both essentials present: `vm:` resolves to an existing `.junie/vms/<name>/`
  directory, and the confirmed launch command exists under `## Running inside
  the VM`.
- Summarize what you set up (and whether the image built), then tell the user to
  review the two files and re-run `/demo` — do not run `/demo` yourself. The
  `.junie/` folder is the user's; the generated config is a starting point they
  confirm.
