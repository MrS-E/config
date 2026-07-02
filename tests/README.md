# Test Harness

A Podman + [bats-core](https://github.com/bats-core/bats-core) matrix validates the
OS setup system for **Fedora**, **Manjaro**, **Fedora Atomic**, and **macOS**.

## Layout

```
tests/
├── containers/
│   ├── Containerfile.fedora           # real Fedora image + bats
│   ├── Containerfile.manjaro          # real Manjaro image + bats
│   ├── Containerfile.fedora-atomic    # Fedora + mocked rpm-ostree/toolbox (fallback)
│   └── Containerfile.macos-mock       # Fedora + mocked uname/brew/ssh (macOS mock)
├── bats/
│   ├── helpers/
│   │   ├── common.bash                # run_setup, platform_script, env
│   │   └── assertions.bash            # symlink / manifest / package assertions
│   ├── smoke.bats                     # setup.sh runs + creates symlinks
│   ├── idempotency.bats               # second run is a safe no-op
│   ├── assertions-fedora.bats
│   ├── assertions-manjaro.bats
│   ├── assertions-fedora-atomic.bats
│   └── assertions-macos.bats
└── baselines/                         # recorded pre-migration results (see README.md)
```

## Usage

```bash
make build               # build all container images
make test-fedora         # run Fedora bats
make test-manjaro        # run Manjaro bats
make test-fedora-atomic  # run Fedora Atomic bats (mocked rpm-ostree)
make test-macos          # run mocked macOS bats
make test                # run the full matrix
make baseline            # record current results under tests/baselines/
make compare-baseline    # re-run and diff against the recorded baseline
```

The repo is bind-mounted at `/workspace` inside each container; the test user is
`tester` with `HOME=/home/tester` and passwordless `sudo`.

## Strategy & known limitations

Per the migration plan, the harness favors **real package-manager execution**
inside disposable Linux containers wherever practical. The following are
documented limitations of the container environment and are recorded (not
hidden) by the baseline:

- **macOS** cannot run natively in Podman. `test-macos` uses a Linux container
  with mocked `uname` (returns `Darwin`), `brew`, `ssh-agent`, and `ssh-add`.
  This validates dispatch paths and contract behavior, not real Homebrew.
- **Fedora Atomic** has no practical rpm-ostree-capable Podman image. The
  container ships a documented mock `rpm-ostree` and mock `toolbox`; Flatpak
  tests remain real where feasible.
- **`chsh`**, **`systemctl enable --now`**, Tailscale, CUPS, firewall, and
  ClamAV are limited inside unprivileged containers and may fail in the
  baseline. These are annotated, not blocking.
- **External network installers** (JetBrains Toolbox, Proton Bridge, Bun,
  Junie, Joplin, Jabba, Dracula vim theme) are slow/flaky and may fail; the
  baseline records their pass/fail/skip status.

The baseline is intentionally **non-blocking**: current scripts are not yet
fully idempotent or container-safe, so baseline failures are expected and are
used only as a comparison point for the post-migration re-run.
