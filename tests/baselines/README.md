# Baselines

This directory holds recorded pre-migration test results produced by
`make baseline`. Each file (`fedora.txt`, `manjaro.txt`, `fedora-atomic.txt`,
`macos.txt`) contains the TAP output of the corresponding `make test-<os>`
target plus an `# exit=` marker.

`make compare-baseline` re-runs the matrix into `current/` and diffs the two.

Baseline files are intentionally committed as comparison artifacts; they are
**not** expected to be all-passing for the current (pre-migration) scripts.

## Pre-migration baseline findings (recorded 2026-07-02)

Summary of the recorded baseline across all four targets:

- **Symlink layer is healthy and idempotent.** `setup.sh` creates the core
  dotfile symlinks (`~/.zshrc`, `~/.vimrc`, `~/.gitconfig`, `~/.config/nvim`,
  `~/.config/lazygit`, `~/.junie`, `~/.config/ghostty`, `~/.ssh/config`) and a
  second run is a safe no-op (no new backups, stable link targets). This holds
  for every OS target.
- **Platform scripts are not executable.** `setup.macos.sh`, `setup.fedora.sh`,
  `setup.atomic-fedora.sh`, and `setup.manjaro.sh` are committed without the
  executable bit. `setup.sh` guards each dispatch with `[[ -x ... ]]` and
  silently `return 0`s when the bit is missing, so **no platform setup runs at
  all** in the current state. This is the dominant baseline failure and the
  primary thing migration must repair.
- **Consequence: no packages, Flatpaks, ZSH plugins, or services are
  installed** by `setup.sh` in any container. All package/Flatpak/ZSH-plugin
  assertion tests therefore fail in the baseline.
- **macOS mock** validates OS detection (`uname -s` → `Darwin`), dispatch path,
  Brewfile presence, and mocked `brew`/`ssh-agent`/`ssh-add` availability.
- **Fedora Atomic mock** validates `rpm-ostree`/`toolbox` mock presence and
  manifest/toolbox-file discovery; real layering cannot happen in containers.
- **Flatpak is not initialized** in any container (`/var/lib/flatpak/repo`
  absent), so Flatpak remote/app assertions fail; this is a container
  limitation, not a script defect.

### Known container limitations (annotated, non-blocking)
- `chsh`, `systemctl enable --now`, Tailscale, CUPS, firewall, ClamAV are
  limited inside unprivileged containers.
- External network installers (JetBrains Toolbox, Proton Bridge, Bun, Junie,
  Joplin, Jabba, Dracula vim theme) are not exercised in the baseline.
- `manjarolinux/base` is "Manjaro ARM" and lacks `/etc/manjaro-release`; the
  container creates it so `setup.sh` detects Manjaro.
- Fedora Atomic uses mocked `rpm-ostree`/`toolbox` (no rpm-ostree-capable
  Podman image exists).
- macOS uses mocked `uname`/`brew`/`ssh-agent`/`ssh-add` (no real macOS in
  Podman).
