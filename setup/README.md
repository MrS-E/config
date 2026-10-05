# System Setup

The repository-root `setup.sh` detects the current platform and runs the
applicable setup steps. General steps run first, followed by steps for the
detected platform. Use `./setup.sh --list` to see the steps currently
available on your system; this avoids maintaining a duplicate, easily stale
step inventory here.

## Supported Platforms

| Platform | Package sources and manifests |
|---|---|
| macOS | Homebrew (`macos/Brewfile`) |
| Fedora | DNF, COPR, and Flatpak (`fedora/`) |
| Fedora Atomic | rpm-ostree, Flatpak, and Toolbx (`fedora-atomic/`) |
| Manjaro | pacman and AUR (`manjaro/`) |

Each platform directory contains its setup steps and any package manifests.
Fedora Atomic also keeps per-toolbox package manifests in
`fedora-atomic/toolboxes/`.

## Runner Options

Run these commands from the repository root:

```bash
./setup.sh
./setup.sh --list
./setup.sh --only SELECTOR[,SELECTOR...]
./setup.sh --exclude SELECTOR[,SELECTOR...]
./setup.sh --interactive
./setup.sh --help
```

`--only` runs only matching steps; `--exclude` runs all steps except those
selected. Selectors can be a full scope and filename, a filename, or a basename
without `.sh`; each selector must match exactly one step. `--interactive`
requires `fzf`.

The runner discovers executable `*.sh` files directly under `general/` and the
detected platform directory. Helper files and Markdown documentation are not
setup steps. The runner invokes each selected step's `presteps` and `run`
actions as separate processes; `--list` displays its help text.

See [`../tests/README.md`](../tests/README.md) for the setup test matrix and
test commands.