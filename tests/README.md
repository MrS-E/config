# Test Harness

A Podman + [bats-core](https://github.com/bats-core/bats-core) matrix validates the
OS setup system for **Fedora**, **Manjaro**, **Fedora Atomic**, and **macOS**.

## Layout

```
tests/
├── work-finder.bats                 # standalone work-finder test suite
├── containers/
│   ├── Containerfile.fedora         # real Fedora image + bats
│   ├── Containerfile.manjaro        # real Manjaro image + bats
│   ├── Containerfile.fedora-atomic  # Fedora + mocked rpm-ostree/toolbox (fallback)
│   └── Containerfile.macos-mock     # Fedora + mocked macOS identity/desktop/SSH commands
├── bats/
│   ├── helpers/
│   │   ├── common.bash              # run_setup, platform_script, env
│   │   └── assertions.bash          # symlink / manifest / package assertions
│   ├── smoke.bats                   # setup.sh runs + creates symlinks
│   ├── idempotency.bats             # second run is a safe no-op
│   ├── git-filters.bats             # filter bootstrap and provider migration
│   ├── assertions-fedora.bats
│   ├── fedora-packages.bats         # Fedora package manifest filtering
│   ├── assertions-manjaro.bats
│   ├── assertions-fedora-atomic.bats
│   ├── migrate-brew-to-nix.bats     # mocked one-shot Homebrew migration safeguards
│   └── assertions-macos.bats
└── baselines/                       # recorded pre-migration results (see README.md)
```

## Usage

```bash
make build               # build all container images
make test-fedora         # run Fedora bats
make test-manjaro        # run Manjaro bats
make test-fedora-atomic  # run Fedora Atomic bats (mocked rpm-ostree)
make test-macos          # run mocked macOS bats
make test                # run the full matrix, including work-finder tests
make shellcheck          # lint maintained Bash sources
make baseline            # record current results under tests/baselines/
make compare-baseline    # re-run and diff against the recorded baseline
```

The repo is bind-mounted at `/workspace` inside each container; the test user is
`tester` with `HOME=/home/tester` and passwordless `sudo`.

The Fedora test target checks package manifests and exercises the DNF,
Flatpak, and Zsh-plugin setup steps with command stubs, in addition to the
retained Fedora package filter and standalone `tests/work-finder.bats` suite.
This verifies manifest forwarding without installing the full desktop package
set or downloading Flatpak apps in CI. `make shellcheck` checks `setup.sh`,
shell scripts under `setup/`, executable helpers under `scripts/`, and `.bash`
test helpers; it excludes Zsh configuration and Bats DSL files.

## Strategy & known limitations

The container matrix tests real Fedora and Manjaro detection, with command
stubs at system-changing or network-dependent boundaries so CI remains
repeatable:

- **macOS** cannot run natively in Podman. `test-macos` uses a Linux container
  with mocked `uname` (returns `Darwin`), `open`, `ssh-agent`, and `ssh-add`;
  individual Nix and Homebrew migration tests provide their own mocks. The
  container has no real `brew` command and does not perform real nix-darwin
  activation or Homebrew uninstallation.
- **Fedora Atomic** has no practical rpm-ostree-capable Podman image. The
  container ships a documented mock `rpm-ostree` and mock `toolbox`; Flatpak
  setup calls are covered with mocks.
- Fedora package, Flatpak, and Zsh-plugin tests stub `sudo`, `dnf`, `flatpak`,
  and `git`, avoiding full package installations and external downloads.
- Manjaro tests use the packages installed in the test image for `pacman -Q`
  checks; the AUR bootstrap, AUR manifest, and Zsh-plugin paths use command
  stubs instead of building packages or cloning external repositories.
- The observational baseline can still exercise integrations limited in
  containers, including `chsh`, `systemctl enable --now`, Tailscale, CUPS,
  firewall, ClamAV, and external network installers. It records their output
  and status without making these integrations blocking CI checks.

`make baseline` is an observational, non-blocking snapshot that records each
target's output and exit status. The CI workflow runs `make test` separately
and treats its failures as blocking.
