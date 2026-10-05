# Custom Scripts

The scripts in this directory provide small command-line utilities. See each
executable's usage output for its command syntax.

| Script | Purpose |
|---|---|
| `project` | Store and look up named project paths, with optional Zsh navigation and completion integration. |
| `work-finder` | Find recent Git and filesystem activity across selected directories; supports Zsh integration. |
| `filter-fedora-packages` | Capture, filter, and add descriptions to Fedora package manifests; requires Fedora, `dnf`, and `rpm`. |
| `git-clone-remote` | Push repository branches and tags to a new remote named `new-origin`, or use `--pull-all` to fetch remotes and create local tracking branches. |
| `yubikey-piv-rsa` | Generate an RSA-4096 PIV key, self-signed certificate, and OpenSSH public key; requires `yubico-piv-tool` and `ssh-keygen`. |

## Zsh Integration

When `zshrc` loads, it adds this directory to `PATH` and checks executable
files for `--shell-integration`, evaluating any output they produce. `project`
and `work-finder` provide Zsh functions and completions this way. Other tools
are not sourced as shell code. The Junie JSON filter helper lives in
[`../junie/junie-json-filter.py`](../junie/junie-json-filter.py) and is invoked
by Git's configured filters.

This README is documentation, not an executable script. The Zsh loop checks
for executable files, so it will not invoke or source `README.md`.