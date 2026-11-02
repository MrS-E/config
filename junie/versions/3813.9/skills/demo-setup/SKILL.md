---
name: demo-setup
description: "Fill in a project's `/demo` configuration by inspecting the project: complete the `.junie/vms/<vm>/Dockerfile` and the launch command in `.junie/demo.md`. TRIGGER when: the user asks to set up, configure, or finish `/demo`; the user asks you to fill in `.junie/demo.md` or a `.junie/vms/*/Dockerfile`; a `/demo` run stopped because its setup is unfinished — either it just seeded the starter files, or it found an earlier seed still sitting there with no launch command in `.junie/demo.md`. DO NOT TRIGGER when: `/demo` is already configured and the user only wants to run it, or when editing application code unrelated to demo setup."
---

# Setting up `/demo` for a project

`/demo` drives the project's app inside a VM and records it. It stays blocked
until two starter files are filled in — they may have been seeded just now, or
in an earlier session and left untouched:

- `.junie/demo.md` — the guide the demo agent reads before driving the app.
- `.junie/vms/template-vm/Dockerfile` — the VM image the app runs in.

Anything already written in them is the user's — build on it, don't overwrite it.
The user has already agreed to let you set this up. Full reference:
https://junie.jetbrains.com/docs/junie-cli-demo.html

## The algorithm — follow it in order

> **1. Research** — inspect the repo: the launch command, runtime versions,
>   runtime services, auth gates, required secrets.
> **2. Confirm with the user** — present the whole plan as one batch of
>   questions. Write NOTHING yet.
> **3. Only then do it** — write `demo.md` (and `mounts` if agreed), then the
>   Dockerfile, and verify.

This is a hard sequence, not a suggestion. **Never modify any file without the
user confirming the change first.** Do not edit `demo.md` or the Dockerfile
until step 2 is done and the user has approved what you intend to write. Your
first file edit must come *after* the user has answered, never before. If you
catch yourself about to edit a file without an explicit confirmation — stop and
ask first.

## 1. Research the repo

Form the full picture before asking anything. Five things to find:

### The launch command

- **The dev/start command** — `scripts` in `package.json` (`dev`, `start`,
  `preview`), or the equivalent for the project's stack. This is the field that
  breaks the demo when wrong, so it's the thing to get right.
- **The runtime & package manager** — from the lockfile / manifest
  (`pnpm-lock.yaml`, `yarn.lock`, `requirements.txt`, `pyproject.toml`, `go.mod`,
  `Gemfile`, etc.).
- **The port and a ready signal** — the port from the script, framework
  default, or config, plus how to tell the app is actually up (an HTTP URL that
  responds 200, a log line). Both go into `demo.md`.

Be skeptical of scripts you find (`start-*.sh`, `run.sh`, Makefile targets):
one may exist for the project's own infrastructure, not for launching the app
the demo should show. Don't assume a script is the launch command just because
it looks like one.

### Runtime versions the base image must satisfy

The command runs on the base image's runtimes, and "the base ships Node" is
not "the base ships the Node this app requires". Collect the project's version
demands — `engines` in `package.json`, `packageManager`, `.nvmrc`,
`.python-version`, `go.mod`, toolchain files — and compare against the base
(e.g. `docker run --rm <base-image> node --version`). A mismatch means a
Dockerfile layer pinning the right version; version mismatches are the most
common way a confirmed command still dies at demo time.

### Runtime services

Inventory every service the app needs at runtime: `docker-compose.yaml`,
`.env.example`, `DATABASE_URL`/`REDIS_URL`-style variables, ORM and framework
configs, `Procfile`, `devcontainer.json`, README. For each one pick a candidate
strategy to propose in step 2:

- **Same image** — the VM is a plain Debian container, so `postgresql`,
  `redis` and the like can be apt-installed as Dockerfile layers and started
  by the launch command before the app.
- **Embedded / in-memory profile** — sqlite, H2, a dev flag, if the app
  supports one.
- **The user runs it on the host** — the VM reaches the host as
  `host.docker.internal`. Requires a preflight check in `demo.md` so the demo
  fails fast instead of clicking against a dead backend.
- **An external / staging instance** — only on the user's explicit choice,
  never your default recommendation: CORS, auth, and private networks make it
  fail more often than it works.
- **Narrow the demo** — scope it to scenarios that don't need the service.

The one thing that cannot work: Docker inside the VM. There is no Docker
daemon, so `docker compose up` is never the answer — "run the services in
Docker too" always means "in the same image".

### Auth gates

If the app has a login wall, the demo hits it mid-run, when it's too late.
Detect it now — login routes/middleware, OAuth config, seed users in fixtures
or migrations, e2e-auth helpers, dev-bypass flags — and research concrete ways
in, to offer in step 2:

- a test user (login/password) written into `demo.md` — test users are
  legitimate `demo.md` content, not secrets;
- a dev mode or auth-bypass flag;
- a seed script run at startup;
- a session or token supplied from the host via the `mounts` file;
- scoping the demo to screens before the login wall.

### Secrets and tokens

Find anything install or launch refuses to run without: private registries in
the lockfile or `.npmrc`, `*_TOKEN`/`*_KEY` variables read by build scripts,
license checks. For each, locate where the value already lives on the host
(`.env.local`, `~/.npmrc`, shell profile) and plan how the VM gets it — a line
in `.junie/vms/<vm>/mounts`, or an env assignment in the launch command reading
a mounted file. **Never write a secret value into `demo.md` or the Dockerfile —
both get committed; `mounts` keeps the value on the host.** Solving this is
your job: never hand back with a TODO like "make sure $TOKEN is available in
the VM".

## 2. Confirm the plan with the user

**Do not write anything yet.** Present everything step 1 found as one
consolidated batch of parallel questions — not a multi-round interrogation:

- the launch command, port, and ready signal;
- one question per runtime service, its researched strategies as options,
  your recommended one first;
- the way past the auth gate, if you found one;
- the mount/env line for each secret, if any;
- the Dockerfile layers you intend to add, if any.

Make clear these are guesses from inspecting the repo, not facts. For a static
frontend with no services, no auth and no secrets this collapses into a single
question about the launch command — don't invent questions the research didn't
raise.

Only proceed once the user has answered. If they correct something, use their
answer verbatim. If a later step surfaces something new — a failed build, a
service you missed — come back and confirm **only the delta**; never re-ask
what's already confirmed.

## 3. Write `demo.md` with the confirmed plan

`demo.md` documents how to launch the app and what the demo agent must know to
drive it — never secret values (the file gets committed; secrets go through
`mounts`). Fill:

- **`vm:`** — the VM template directory name (default `template-vm`).
- **The launch command** under `## Running inside the VM` — the command the user
  confirmed, run from `/workspace`, with confirmed same-image services started
  before the app. **Background the app** (`&` or `nohup … &`) so the agent can
  proceed, and bind to `0.0.0.0` if the framework defaults to localhost-only.
- **The ready signal** — e.g. `# ready when http://localhost:3000 responds 200`.
  Without it the agent starts clicking into a half-started app.
- **A preflight check** for every service the user runs on the host, e.g.
  `curl -sf http://host.docker.internal:9400/health` — fail fast, don't trust.
- **Confirmed test users and known quirks**, if the user approved any in step 2.

If a secret needs mounting, also write the confirmed line into
`.junie/vms/<vm>/mounts`.

Delete the seeded explanatory HTML comments once the file is filled in.

Example body:

```markdown
vm: template-vm

## Running inside the VM

Install deps and start the dev server (Nuxt, port 3000):

    pnpm install
    pnpm dev --host 0.0.0.0 &
    # ready when http://localhost:3000 responds 200
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
  only what the confirmed plan actually needs that the base lacks: a pinned
  runtime when step 1 found a version mismatch (corepack, apt, a toolchain
  download), system libs, and the confirmed same-image services
  (`postgresql`, `redis-server`, …) via apt.
- For a plain Node/JS app whose version demands the base already satisfies,
  the base is often enough — leave the Dockerfile as-is rather than adding
  noise.
- If the command needs a Docker daemon or a multi-container orchestrator, that
  won't work in the VM — go back to the user rather than papering over it.

## 5. Verify — build the image, smoke-test the plan

**If you added any layers to the Dockerfile** (a `RUN`, `COPY`, extra runtime,
etc.), build it now so a mistake — a wrong package name, an unavailable apt
package — surfaces here instead of failing later when the user runs `/demo`.
`/demo` builds with the project root as the build context and the template's
Dockerfile, so reproduce that exactly, from the project root:

    DOCKER_BUILDKIT=1 docker build -f .junie/vms/<vm>/Dockerfile -t junie-demo-<vm>-verify .

Then smoke-test the parts of the plan that can fail without running a demo.
"I added no layers" is **not** "nothing can be wrong" — what needs validating
is the confirmed command against the image, not just your Dockerfile edits:

- runtimes match what step 1 demanded:
  `docker run --rm <image> node --version`
- an installed service starts:
  `docker run --rm <image> bash -c 'service postgresql start && pg_isready'`
- the install step survives — catches a too-old runtime, a missing token, or
  registry auth before the user ever runs `/demo`:
  `docker run --rm -v "$PWD":/workspace <image> bash -c 'cd /workspace && corepack pnpm install --frozen-lockfile'`
  (attach the confirmed mounts with extra `-v` flags when the install needs
  them).

Rules:

- If the build **fails**, only fix it when the cause is clear and your fix is
  certain (e.g. an obviously wrong package name). Otherwise **don't keep guessing
  and rebuilding** — that's the same guesswork this skill exists to avoid. After
  one or two confident fixes at most, if it still won't build or you're unsure
  why, stop, show the user the build error, and ask them how to proceed. Either
  way, do not touch the launch command — the user already confirmed it.
- If a smoke test **fails**, treat it as a discovered delta: fix it when the
  fix is certain (pin the runtime, add the mount), otherwise show the user the
  failure and re-confirm only that piece.
- If `docker` isn't available or the base image can't be pulled (the base lives
  in a registry that may need auth), **don't treat that as a Dockerfile error** —
  skip the build and the smoke tests, say you couldn't verify and why, and
  still hand back.

This only validates the image and the command. It is not running the demo — do
not start the VM or record anything.

## 6. Hand back

- Both essentials present: `vm:` resolves to an existing `.junie/vms/<name>/`
  directory, and the confirmed launch command exists under `## Running inside
  the VM`.
- **No unresolved preconditions**: never end with "make sure X is available in
  the VM". Every token, service, and login the demo needs is either solved in
  the files you wrote or explicitly deferred by the user in step 2.
- Summarize what you set up and what you verified, then tell the user to
  review the files and re-run `/demo` — do not run `/demo` yourself. The
  `.junie/` folder is the user's; the generated config is a starting point they
  confirm.
