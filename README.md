# config

A cross-platform dotfiles repository for macOS, Fedora, Fedora Atomic, and
Manjaro. It brings personal shell, Git, editor, terminal, SSH, and application
settings together with platform-aware setup.

## Quick Start

Clone the repository into `~/config`, then run the setup script:

```sh
git clone <repo-url> ~/config
cd ~/config
./setup.sh
```

The setup runner detects the current platform and applies the relevant setup.
See the [setup guide](setup/README.md) for more information.

## Install from a tagged archive

GitHub automatically provides `.tar.gz` and `.zip` source archives for each
tag. Download either archive from the tag page, extract it, and place or rename
its top-level `<repository>-<tag>` directory to `~/config`. Keep the complete
tree together so `setup.sh` and the `setup/` directory are both directly inside
`~/config`, then run:

```sh
cd ~/config
./setup.sh
```

No custom release asset or GitHub Packages artifact is needed for this install
path.

## Supported platforms

- macOS
- Fedora
- Fedora Atomic
- Manjaro

## Repository layout

| Area | Files |
|---|---|
| Shell and prompt | `zshrc`, `starship.toml` |
| Git | `gitconfig` |
| Editors | `vimrc`, `vim/`, `nvim/` |
| Terminal apps | `kitty/`, `ghostty/`, `lazygit/` |
| SSH | `ssh/` |
| VSCodium | `vscodium/` |
| Nextcloud | `Nextcloud/` |
| Junie | `junie/` |
| Setup | `setup.sh`, `setup/` |
| Helper scripts | `scripts/` |
| Tests | `Makefile`, `tests/` |

## Setup and tests

Setup detects the platform and chooses its applicable steps.

Run `make test` to exercise the setup test suite with Podman and Bats. Some
platform behavior is mocked or constrained in containers; see the test guide
for the documented limitations.

## Further reading

- [Setup](setup/README.md) — supported platforms and setup overview.
- [Scripts](scripts/README.md) — command-line helpers and their usage.
- [SSH](ssh/README.md) — SSH configuration and portable provider paths.
- [Tests](tests/README.md) — test matrix and known limitations.
