# config

Cross-platform dotfiles repository supporting **macOS**, **Fedora**, **Fedora Atomic**, and **Manjaro**.

## Quick Start

1. **Clone** the repo to `~/config`:
   ```bash
   git clone <repo-url> ~/config
   ```
2. **Run the setup script**:
   ```bash
   cd ~/config && ./setup.sh
   ```
   This detects your OS, discovers applicable step scripts, and runs them in order.

   **Selective runs**:
   ```bash
   ./setup.sh --list                          # list discovered steps
   ./setup.sh --only general/01-symlinks.sh   # run a single step
   ./setup.sh --exclude fedora/14-tailscale.sh # skip a step
   ./setup.sh --interactive                   # choose steps with fzf
   ```

## Supported Platforms

| OS | Step Directory | Package Managers | Status |
|---|---|---|---|
| **macOS** | `setup/macos/` | Nix (Home Manager + nix-darwin) | ✅ Active |
| **Fedora** | `setup/fedora/` | dnf, COPR, Flatpak | ✅ Active |
| **Fedora Atomic** | `setup/fedora-atomic/` | rpm-ostree, Flatpak, Toolbx | ✅ Tested (only Test Suit) |
| **Manjaro** | `setup/manjaro/` | pacman, AUR (yay) | ✅ Tested (only Test Suit) |

## Repository Layout

```
config/
├── .gitattributes              # Git filter assignments (PKCS11, API keys)
├── .gitignore
├── README.md
├── Makefile                    # Podman + bats-core test harness
├── setup.sh                    # Orchestration-only runner (OS detect + step dispatch)
├── setup/                      # Numbered step scripts + manifests
│   ├── general/                # OS-agnostic steps (symlinks, git filters, vim base)
│   │   ├── common.bash         # Platform-neutral helper library (non-executable)
│   │   ├── 01-symlinks.sh
│   │   ├── 02-git-filters.sh
│   │   └── 03-vim-base.sh
│   ├── macos/                  # macOS steps + Brewfile audit inventory
│   ├── fedora/                 # Fedora steps + dnf/flatpak/copr manifests
│   ├── fedora-atomic/          # Fedora Atomic steps + rpm-ostree/toolbox manifests
│   └── manjaro/                # Manjaro steps + pacman/aur manifests
├── nix/                        # Pinned macOS package flake and reusable modules
├── custom-flakes/              # Standalone custom Nix flakes
├── tests/                      # Podman + bats-core test matrix
├── zshrc                       # ZSH shell configuration
├── gitconfig                   # Git global configuration
├── vimrc                       # Vim configuration
├── vim/                        # Vim custom color scheme + persistent undo
├── nvim/                       # Neovim (lazy.nvim, 27 plugins, LSP)
├── kitty/                      # Kitty terminal emulator
├── ghostty/                    # Ghostty terminal emulator
├── lazygit/                    # Lazygit TUI keybinding overrides
├── vscodium/                   # VSCodium (base+overlay settings pattern)
├── ssh/                        # SSH config, host stanzas, YubiKey PKCS11
├── scripts/                    # Custom CLI tools (nixvm, project, work-finder)
├── Nextcloud/                  # Nextcloud desktop client config
└── junie/                      # Junie AI assistant settings
```

| Path | Purpose |
|---|---|
| `setup.sh` | Orchestration-only runner. Detects OS, discovers numbered step scripts under `setup/general/` and `setup/<os>/`, applies selection filters (`--all`, `--only`, `--exclude`, `--interactive`), and runs each step as a separate process via `presteps` then `run`. No setup logic lives here. |
| `setup/general/` | OS-agnostic steps that run first on every platform: symlink dotfiles, register git filters, create shared editor directories. `common.bash` provides platform-neutral primitives (logging, symlink helpers, git clone guards, manifest parsing). |
| `setup/<os>/` | Platform-specific numbered steps with companion manifests and a `common.bash` helper library. Steps are idempotent — safe to run repeatedly. |
| `nix/` | Pinned Nix flake: nix-darwin activates the Apple Silicon host, and Home Manager manages only the selected package profile. |
| `custom-flakes/` | Standalone custom Nix flakes, kept separate from the system package flake. |
| `zshrc` | ZSH config: OS/hardware detection, history settings, aliases, platform-aware clip/clippaste helpers, completion system, Starship prompt with custom fallback, version managers (bun), ZSH plugins, custom script shell-integration. |
| `gitconfig` | Git config: GPG SSH signing, codium/vscode as difftool/mergetool, LFS, pull rebase, credential cache. |
| `vimrc` | Vim config: persistent undo, custom theme, indentation, whitespace display, statusline. |
| `vim/` | Vim custom color scheme (`cyberpunk_scarlet_protocol_adjusted.vim`) and persistent undo directory. |
| `nvim/` | Neovim config: `lazy.nvim` package manager, 27 plugins (LSP, Telescope, Treesitter, lualine, nvim-tree, harpoon, trouble, which-key, vimtex, Java JDTLS, Godot LSP, GPTModels, etc.). |
| `kitty/` | Kitty terminal emulator: preferred cross-platform terminal for macOS, GNOME, and KDE with Cyberpunk Scarlet Protocol theme, xterm-compatible `TERM`, Swiss-friendly shortcuts, tabs, splits, clipboard, and shell integration. |
| `ghostty/` | Ghostty terminal emulator: appearance, Swiss keyboard keybindings, custom Cyberpunk Scarlet Protocol theme. |
| `lazygit/` | Lazygit TUI: custom keybinding overrides. |
| `vscodium/` | VSCodium: base+overlay settings (`settings.base.json` + platform-specific overlays), extensions list, `code export`/`code import` zsh functions. |
| `ssh/` | SSH config: `config` entry point (Include, ControlMaster, keychain), `config.d/*` host stanzas (private, homelab, infra, zhaw), YubiKey PKCS11 provider filter. |
| `scripts/` | Custom CLI tools: `nixvm` (Nix-backed Java, Ruby, and Python versions), `project` (project directory switcher), and `work-finder` (git/file activity scanner). They use `--shell-integration` where a Zsh wrapper is needed. |
| `Nextcloud/` | Nextcloud desktop client config (`nextcloud.cfg`) and sync-exclude patterns (`sync-exclude.lst`). |
| `junie/` | Junie AI assistant: `settings.json`, model configs with API key scrub filter. |

## Git Filters

This repo uses four git clean/smudge filters, registered by `setup/general/02-git-filters.sh`:

- **`scrub-apikey`** — redacts API keys in `junie/models/*.json` on commit (clean only; smudge passes through unchanged).
- **`junie-settings`** — stores only `stepsLimit`, `shareAnonymousStatistics`, `subagentsMode`, `diffViewMode`, and `toolbarVisibility` from `junie/settings.json`; other settings are cached locally under `.git` and restored on checkout.
- **`junie-mcp`** — omits each server's `enabled` key from the Git version of `junie/mcp/mcp.json`; local values are cached under `.git` and restored on checkout.
- **`pkcs11-provider`** — tokenizes PKCS#11 provider paths in `ssh/config.d/*` on commit (`@YKCS11@`, `@OPENSC@`) and resolves them to the current platform's real paths on checkout. Provider paths are defined in `ssh/providers.mac` and `ssh/providers.fedora`.

The Junie JSON filters use Python 3. After enabling them, run `git add --renormalize junie/settings.json junie/mcp/mcp.json` once to normalize the existing index contents and seed the local caches. Git may still show these paths as modified in `git status` after local-only edits; `git diff` and committed content use the normalized filters. Running `git add` on these paths refreshes their filtered index state and saves current local-only values.

### PKCS#11 Provider Filter

The PKCS#11 provider injection works through a **git clean/smudge filter** rather
than a runtime script. There is no separate "active file" generation step — the
live `~/.ssh/config.d/*` files *are* the working tree, and git transparently
rewrites provider paths on commit/checkout.

#### The pieces

1. **`.gitattributes`** — declares which files get filtered:
   ```
   ssh/config.d/* filter=pkcs11-provider
   ```
   Any path under `ssh/config.d/` is piped through the `pkcs11-provider` filter
   on its way in/out of the object database.

2. **`setup/general/02-git-filters.sh`** — run once per clone (also called by `setup.sh`).
   It registers the filter with git:
   ```
   git config filter.pkcs11-provider.clean  "ssh/pkcs11-filter.sh clean"
   git config filter.pkcs11-provider.smudge "ssh/pkcs11-filter.sh smudge"
   git config filter.pkcs11-provider.required true
   ```
   `required true` means git will fail rather than silently skip the filter.

3. **`ssh/providers.mac` / `ssh/providers.fedora`** — pure key=value path tables,
   no hosts:
   ```
   # providers.mac
   YKCS11=/Users/simeon.stix/.nix-profile/lib/libykcs11.dylib
   OPENSC=/Users/simeon.stix/.nix-profile/lib/opensc-pkcs11.so
   ```
   ```
   # providers.fedora
   YKCS11=TODO_VERIFY_FEDORA_YKCS11_PATH
   OPENSC=TODO_VERIFY_FEDORA_OPENSC_PATH
   ```

4. **`ssh/pkcs11-filter.sh`** — the actual filter, invoked by git with the file
   content on stdin. It takes one argument, `clean` or `smudge`.

#### The two directions

**`clean` (working tree → commit):** tokenizes real paths into placeholders.
- Reads *both* `providers.mac` and `providers.fedora`, builds a sed script of
  `s|<real path>|@VAR@|g` rules (one per `VAR=path` line, comments/blank lines
  skipped).
- Pipes the file through that sed. So
  `/Users/simeon.stix/.nix-profile/lib/libykcs11.dylib` becomes `@YKCS11@`, and any Fedora path
  (once filled in) would also collapse to `@YKCS11@`.
- Result: the committed blob contains only portable `@YKCS11@` / `@OPENSC@`
  tokens, regardless of which platform last edited it.

**`smudge` (commit → working tree):** resolves tokens to the *current* platform's
real paths.
- Detects OS via `uname -s` → picks `providers.mac` (Darwin) or
  `providers.fedora` (Linux).
- Sources that file to get `YKCS11` / `OPENSC`, then runs
  `sed -e "s|@YKCS11@|$YKCS11|g" -e "s|@OPENSC@|$OPENSC|g"`.
- Fallback: if the providers file isn't present yet (fresh-clone race where the
  filter runs before the file is checked out), it uses the current macOS user's
  Home Manager profile paths on Darwin, and on any other OS passes content
  through unchanged.
- Result: the file on disk has real, SSH-usable paths for whatever machine you're
  on.

#### Why this works given `~/.ssh` is a symlink to the repo

`~/.ssh` → `/Users/simeon.stix/config/ssh`, so `ssh/config.d/*` is read directly
by SSH. The committed content holds tokens (portable across mac/linux), but the
*working-tree* content always holds resolved real paths (live for SSH). Git is
the only thing that ever rewrites them — there's no separate "active" output
directory anymore, and no host duplication. Host stanzas live once in
`config.d/*`; only the `PKCS11Provider` line gets rewritten.

#### Practical flow

- **Edit a host stanza** → working tree has real paths, SSH works immediately.
- **`git add`/`git commit`** → clean filter swaps real paths → tokens in the
  stored blob.
- **`git checkout`/`git clone` on another machine** → smudge filter swaps tokens
  → that machine's real paths in the working tree.
- **Switch platforms** → run `./setup.sh --only general/02-git-filters.sh` (or the full `./setup.sh`) and `git checkout -- ssh/config.d/` to re-smudge with the new platform's paths.

#### Caveats

- `providers.fedora` still holds `TODO_VERIFY_*` placeholders; until real Fedora
  paths are filled in, smudge on Linux would inject those literal `TODO_...`
  strings, which SSH would then fail to load. Verify on real hardware.
- The filter is `required`, so if `pkcs11-filter.sh` is missing or errors, git
  operations on `config.d/*` will fail loudly rather than corrupting content.

## Setup System

### Architecture

The setup system uses a **numbered step-script architecture**. The root `setup.sh` is an orchestration-only runner — it detects the OS, discovers step scripts, and dispatches them. No setup logic lives in the runner itself.

**Execution order**: `setup/general/` steps run first (OS-agnostic), then the detected OS-specific directory (`setup/<os>/`). Within each directory, scripts are sorted lexically by filename.

### Step Contract

Every step script dispatches on `$1` to three functions:

- **`presteps`** — validate prerequisites (fail fast with actionable messages). Never mutates state.
- **`help`** — print a short description of what the step does.
- **`run`** — idempotent setup logic. Safe to run repeatedly.

Steps are executed as separate processes (`./step.sh presteps` then `./step.sh run`). Helper files (`common.bash`) are non-executable and are not discovered as steps.

### CLI Selection Modes

| Flag | Behavior |
|---|---|
| (default) / `--all` | Run all discovered steps |
| `--only SEL,...` | Run exactly the selected step IDs |
| `--exclude SEL,...` | Run all discovered steps except selected |
| `--interactive` | Choose steps with `fzf --multi` (falls back to flags if fzf absent) |
| `--list` | List discovered steps with help text |
| `--help` | Show usage |

Selectors match in order: `<scope>/<filename>`, `<filename>`, `<basename>`. Examples:
```bash
./setup.sh --only general/01-symlinks.sh
./setup.sh --only fedora/06-flatpak-apps.sh,fedora/08-zsh-plugins.sh
./setup.sh --exclude fedora/14-tailscale.sh
```

### Idempotency

Every step is **idempotent** — running the full setup or any subset on an already-configured system is safe:
- Symlinks are only changed when the target differs; backups are created once.
- Package steps query installed state before installing (`dnf install -y`, `pacman -S --needed`, `flatpak list --app`).
- Git clones skip existing directories.
- Download/install steps check for the final binary before downloading.
- Service steps check current state before calling `systemctl`.

### General Steps (`setup/general/`)

OS-agnostic steps that run first on every platform:

| Step | Description |
|---|---|
| `01-symlinks.sh` | Symlink dotfiles (zshrc, vimrc, gitconfig, nvim, lazygit, kitty, ghostty, ssh, etc.) into `$HOME` |
| `02-git-filters.sh` | Register `pkcs11-provider` and `scrub-apikey` git clean/smudge filters |
| `03-vim-base.sh` | Create shared editor directories (`~/.vim/undo`) |

`common.bash` provides platform-neutral primitives: `ensure_symlink`, `ensure_dir`, `ensure_git_clone`, `ensure_git_config`, `ensure_line_present`, `read_manifest`, `command_exists`, `require_command`.

### macOS Steps (`setup/macos/`)

| Step | Description |
|---|---|
| `03-ssh-agent.sh` | Start ssh-agent if not running |
| `04-ssh-keychain.sh` | Add SSH keys to Apple keychain |
| `05-vim-theme.sh` | Clone Dracula vim theme |
| `06-junie.sh` | Install Junie CLI |
| `07-waveforms.sh` | Download and install Digilent WaveForms from the official `.dmg` as a separate vendor installer (falls back to the browser if Cloudflare blocks `curl`) |
| `08-kitty-permissions.sh` | Open macOS Privacy & Security settings for Kitty permissions |
| `09-nix.sh` | Install Nix using the official installer and enable `nix-command` + flakes |
| `10-nix-darwin.sh` | Activate the pinned repository flake in `nix/`; supports an explicit external flake override |

`nix-darwin` handles macOS activation and system settings; Home Manager is
integrated only for the selected user package profile and GUI app links. The
app bundles are linked under `~/Applications/Home Manager Apps`.
The profile includes the Nextcloud VFS, BetterMouse, Figma, Texifier, and Proton
Drive apps defined in `custom-flakes/nextcloud-vfs`,
`custom-flakes/bettermouse`, `custom-flakes/figma`, `custom-flakes/texifier`,
and `custom-flakes/proton-drive`; Home Manager exposes them through those
user-level links. Nextcloud Finder Sync registration runs during Home Manager
activation. BetterMouse's and Figma's first-run setup, Texifier's and Proton
Drive's additional first-launch setup (if needed), and macOS privacy permissions
remain manual.
The checked-in `nix/flake.nix` pins Nixpkgs, nix-darwin, and Home Manager, and
currently defines only `aarch64-darwin`. It does not manage dotfiles,
`~/.config`, VSCodium, or editor settings/extensions. See the
[Brewfile-to-Nixpkgs audit](setup/macos/nixpkgs-audit.md) for selected
replacements and manual/vendor exceptions.

Since `brew bundle` is retired, clean setup no longer installs VSCodium or its
extensions; they remain outside this migration.

For a Mac that still has Homebrew installed, the opt-in one-shot migration is
`scripts/migrate-macos-brew-to-nix.sh`. It writes a unique, persistent
`Brewfile.backup-*` under `~/` by default (or in a directory selected with
`--backup-dir`), verifies the installed formula/cask counts, removes every
formula and cask reported as installed by Homebrew, runs Homebrew's official
uninstaller, and then runs the normal `setup.sh` flow, including Nix bootstrap
and nix-darwin activation. It is not part of automatic setup. The script asks
you to type `REMOVE HOMEBREW`; use `--yes` only when explicitly authorizing a
non-interactive run. If `~/nix-darwin-config/flake.nix` exists, set
`NIX_DARWIN_CONFIG_DIR` explicitly so the migration knows which flake to use.
For example, `NIX_DARWIN_CONFIG_DIR="$PWD/nix"` selects this repository's
Apple Silicon configuration. Run it from the repository checkout with
`./scripts/migrate-macos-brew-to-nix.sh`.

The script locates Homebrew through `PATH` or the standard locations:
`/opt/homebrew/bin/brew` on Apple Silicon and `/usr/local/bin/brew` on Intel.
This does not require Homebrew initialization in `zshrc`. For a custom install,
set `MIGRATION_BREW_BIN` to the executable path.

The backup is a package inventory, not a copy of applications, service state,
settings, or application data. In particular, an installed VSCodium cask is
removed; its settings and extensions are not backed up or managed by Nix. The
migration script never overwrites or deletes the backup; keep it. If you later
choose to restore Homebrew, reinstall Homebrew and use
`brew bundle --file /path/to/Brewfile.backup-<timestamp>` to attempt to
reinstall the recorded bundle. The backup directory must be outside the
Homebrew prefix so the official uninstaller cannot remove it.

`setup/macos/10-nix-darwin.sh` activates the repository flake by default. Set
`NIX_DARWIN_CONFIG_DIR` explicitly to use an external flake, and optionally set
`NIX_DARWIN_HOSTNAME` to choose its `darwinConfigurations` output. The step
never initializes, edits, or locks an external configuration. If
`~/nix-darwin-config/flake.nix` already exists and no override is selected, the
step stops with instructions rather than silently abandoning it. The reduced
`setup/macos/Brewfile` remains only as audit inventory; setup no longer installs
Homebrew or runs `brew bundle`.

The step passes the required Nix feature flags to user and root commands. Known
conflicting files at `/etc/nix/nix.conf`, `/etc/bashrc`, and `/etc/zshrc` are
moved to matching `.before-nix-darwin` backups before activation; inspect those
backups before deleting them. Tailscale and other optional services are not
enabled automatically. After activation, apply repository-flake changes with
`sudo darwin-rebuild switch --flake "git+file://$HOME/config?dir=nix#aarch64-darwin"`.
Open a new shell after activation; `zshrc` adds
`/run/current-system/sw/bin` and `~/.nix-profile/bin` when they exist, exposing
system commands and Home Manager packages.

### Runtime Versions (`nixvm`)

`nixvm` manages global Java JDK, Ruby, and Python selections on macOS. It
requires Nix with the `nix-command` and `flakes` features enabled; the existing
`setup/macos/09-nix.sh` step installs Nix and enables those features. `nixvm`
does not bootstrap Nix or modify the nix-darwin configuration. It uses the
configured `nixpkgs` flake to discover versioned JDK (`jdk21`), Ruby
(`ruby_3_3`), and Python (`python312`) package attributes instead of maintaining
a hardcoded version list. Availability follows the current Mac architecture
and Nixpkgs revision; arbitrary upstream patch releases without a corresponding
Nixpkgs attribute are not selectable. Run `nixvm list --available` to see the
current choices.

```bash
nixvm list                         # installed and available versions
nixvm list python --installed      # only installed Python versions
nixvm list --available             # available versions for all runtimes
nixvm install java 21
nixvm install ruby 3.3
nixvm install python 3.12
nixvm use java 21
nixvm remove python 3.12
```

The existing Zsh script loader activates the shell integration automatically:
`use` adds the selected runtime's `bin` directory to the current shell's
`PATH`, sets `JAVA_HOME` for Java, and persists one global selection per
runtime for later Zsh sessions. Install references and active selections live
under `${XDG_DATA_HOME:-$HOME/.local/share}/nixvm`. Removing a version drops only
the manager-owned reference (and clears it if active); it does not delete a
Nix store path directly. Nix garbage collection can reclaim outputs that no
longer have other references.

### Fedora Steps (`setup/fedora/`)

| Step | Description |
|---|---|
| `01-system-update.sh` | `sudo dnf -y upgrade --refresh` |
| `02-copr-repos.sh` | Enable COPR repos from `copr.txt` |
| `03-dnf-packages.sh` | Install dnf packages from `dnf.txt` |
| `04-copr-packages.sh` | Install COPR-dependent packages (lazygit, scrcpy, codium, steam, proton-vpn) |
| `05-flatpak-runtime.sh` | Install Flatpak + ensure Flathub remote |
| `06-flatpak-apps.sh` | Install Flatpak apps from `flatpak.txt` |
| `07-default-shell.sh` | Change default shell to zsh |
| `08-zsh-plugins.sh` | Clone ZSH plugins (autosuggestions, syntax-highlighting, autocomplete) |
| `09-tealdeer.sh` | Create tealdeer config + update tldr cache |
| `10-jetbrains-toolbox.sh` | Download JetBrains Toolbox |
| `11-proton-bridge.sh` | Install Proton Mail Bridge RPM |
| `12-bun.sh` | Install Bun via official installer |
| `13-junie.sh` | Install Junie CLI |
| `14-tailscale.sh` | Enable and start Tailscale |

### Fedora Atomic Steps (`setup/fedora-atomic/`)

| Step | Description |
|---|---|
| `01-system-upgrade.sh` | `sudo rpm-ostree upgrade` |
| `02-host-packages.sh` | Layer host packages from `rpm-ostree.txt` |
| `03-default-shell.sh` | Change default shell to zsh |
| `04-zsh-plugins.sh` | Clone ZSH plugins |
| `05-tealdeer.sh` | Create tealdeer config + update tldr cache |
| `06-flatpak-remote.sh` | Ensure Flatpak + Flathub remote |
| `07-flatpak-apps.sh` | Install Flatpak apps from `flatpak.txt` |
| `08-toolbox-create.sh` | Create toolboxes from `toolboxes.txt` |
| `09-toolbox-packages.sh` | Install packages in each toolbox |
| `10-toolbox-latex.sh` | Install LTEX LS in latex toolbox |
| `11-toolbox-mobile.sh` | Install ktlint + SwiftLint in mobile toolbox |
| `99-reboot-notice.sh` | Print reboot reminder |

### Manjaro Steps (`setup/manjaro/`)

| Step | Description |
|---|---|
| `01-system-update.sh` | `sudo pacman -Syu --noconfirm` |
| `02-pacman-packages.sh` | Install pacman packages from `pacman.txt` |
| `03-yay-bootstrap.sh` | Bootstrap yay (AUR helper) |
| `04-aur-packages.sh` | Install AUR packages from `aur.txt` |
| `05-default-shell.sh` | Change default shell to zsh |
| `06-zsh-plugins.sh` | Clone ZSH plugins |
| `07-printing.sh` | Enable CUPS printing service |
| `08-firewall.sh` | Enable nftables + ufw |
| `09-clamav.sh` | Enable ClamAV freshclam |
| `10-jetbrains-toolbox.sh` | Download JetBrains Toolbox |
| `11-joplin.sh` | Install Joplin note-taking app |
| `12-cisco-note.sh` | Cisco AnyConnect VPN note |
| `13-celeste-note.sh` | Celeste cloud sync note |

### Package Manifests

Fedora and Manjaro manifests live alongside their step scripts; the macOS package profile is defined in `nix/`.

| Manifest | Format | Export command |
|---|---|---|
| `nix/flake.nix` and `nix/packages/*.nix` | Pinned Nix flake and package modules | `nix flake check path:./nix` |
| `setup/fedora/dnf.txt` | One package per line | `dnf repoquery --userinstalled --qf "%{name}\n" \| sort` |
| `setup/fedora/copr.txt` | One COPR repo per line | (manual) |
| `setup/fedora/flatpak.txt` | One app ID per line | `flatpak list --app --columns=application \| sort` |
| `setup/fedora-atomic/rpm-ostree.txt` | One package per line | `rpm-ostree status --json \| jq -r '.deployments[0]["requested-packages"][]'` |
| `setup/fedora-atomic/flatpak.txt` | One app ID per line | Same as Fedora flatpak |
| `setup/fedora-atomic/toolboxes.txt` | List of toolbox names | (manual) |
| `setup/fedora-atomic/toolboxes/*.txt` | Per-toolbox dnf packages | (manual per toolbox) |
| `setup/manjaro/pacman.txt` | One package per line | `pacman -Qqen \| sort` |
| `setup/manjaro/aur.txt` | One package per line | `pacman -Qqem \| sort` |

`setup/macos/Brewfile` is retained only as the source inventory for the
[Nixpkgs audit](setup/macos/nixpkgs-audit.md); the setup runner does not read it.

### Test Harness

A Podman + bats-core matrix validates the setup system. See `tests/README.md` for details.

```bash
make build               # build all container images
make test-fedora         # run Fedora tests
make test                # run the full matrix
```

## Shell Configuration (zshrc)

The `zshrc` is the most complex config file. It handles:

### OS and Hardware Detection

- Detects **OS**: `Darwin` (macOS) vs `Linux`
- Detects **CPU architecture**: Intel vs ARM (sets `$ARCH` to `arm64` or `x86_64`)
- Sets platform-specific environment variables (`$ANDROID_HOME`, etc.)
- Detects **hardware model** on macOS (sets `$HARDWARE_MODEL` based on `sysctl hw.model`)

### History

- Large history (1M lines) shared across all zsh sessions
- Ignores duplicates and commands starting with space

### Key Aliases

| Alias | Platform | Description |
|---|---|---|
| `clip` | macOS | Pipe to clipboard (`pbcopy`) |
| `clippaste` | macOS | Paste from clipboard (`pbpaste`) |
| `clip` / `clippaste` | Linux | Pipe via `xclip` |
| `o` | macOS | `open` (opens files/dirs/URLs) |
| `o` | Linux | `xdg-open` |
| `cat` | All | `bat` (syntax-highlighted cat, falls back to `cat`) |
| `ls` | All | `eza` with icons and colors (falls back to `ls`) |
| `l` / `ll` / `la` | All | Various `eza` shortcuts |

### Wrapper Functions

- **`adb`**: wraps Android Debug Bridge with `adb -H` for wireless, auto-starts adb server
- **`code` / `codium`**: wraps VSCodium, managing base+overlay settings via `export`/`import`
- **`git`**: extends git with additional aliases (see gitconfig section)
- **`idf.py`**: ESP-IDF wrapper with automatic environment setup

### Completion System

- Modern completion system with `menu select` and `list-colors`
- Auto-loads completions for: git, docker, kubectl, pip, npm, cargo, rustup

### Prompt

Uses **Starship** prompt with a full-featured `starship.toml` in this repo. Falls back gracefully to a custom prompt if Starship is not installed.

### Version Managers

All version managers are loaded lazily (only when their commands are invoked):

| Manager | Tool | Lazy-load Command |
|---|---|---|
| **bun** | JS runtime | `bun`, `bunx` |

### ZSH Plugins

Loaded via native zsh `source` (no plugin manager):

- **zsh-autosuggestions**: fish-style autosuggestions as you type
- **zsh-syntax-highlighting**: real-time command syntax coloring
- **zsh-autocomplete**: type-ahead completion in all contexts
- macOS sources the Nix profile packages when available; Fedora continues to install these plugins as Git clones under `~/.zsh`

### Additional Integrations

- **Home Manager package profile**: provides the selected macOS packages without managing dotfiles or editor settings
- **FZF**: fuzzy finder with fd integration, `Ctrl+T` / `Ctrl+R` / `Alt+C` bindings
- **Tailscale**: CLI completions outside macOS (the macOS GUI app is not invoked as a CLI)
- **TheFuck**: auto-correction tool (`eval $(thefuck --alias)`)
- **1Password CLI**: completions

### Custom Script Integration

Both `scripts/project` and `scripts/work-finder` support `--shell-integration`, which emits zsh wrapper functions + completions. `zshrc` sources these automatically:

```bash
source <(path/to/project --shell-integration)
source <(path/to/work-finder --shell-integration)
```

## Git Configuration (gitconfig)

### Identity & Signing

- GPG-based **SSH signing** enabled (`gpg.format = ssh`)
- Signing key: `~/.ssh/yubikey-9d.pub` (YubiKey resident key)
- Commits are signed automatically (`commit.gpgsign = true`)

### Core Settings

- **Editor**: VSCodium (`code --wait`) as default editor
- **Pull strategy**: rebase by default (`pull.rebase = true`)
- **Default branch**: `main`
- **Push**: `simple` (push current branch to matching upstream)

### Diff & Merge Tools

| Tool | Role | Command |
|---|---|---|
| **VSCodium** | Primary difftool | `code --wait --diff $LOCAL $REMOTE` |
| **Meld** | Visual merge tool | `meld $LOCAL $MERGED $REMOTE` |
| **DiffMerge** | Secondary difftool | `diffmerge $LOCAL $REMOTE` |
| **Neovim** | Terminal difftool | `nvim -d $LOCAL $REMOTE` |

### Other

- **LFS** enabled (`filter.lfs.clean/smudge`)
- **Credential cache**: macOS keychain (`osxkeychain`), Linux cache
- Color UI enabled

## SSH Configuration

### ssh/config (Main Entry Point)

- `Include config.d/*` — pulls in all host stanzas
- `ControlMaster auto` + `ControlPath` — connection multiplexing for faster reconnects
- `ControlPersist 10m` — keep master connections alive
- `AddKeysToAgent yes` — automatically add keys to ssh-agent
- `UseKeychain yes` (macOS) — store passphrases in keychain
- `IdentitiesOnly yes` — only use explicitly listed keys

### Host Groups (config.d/)

| File | Contains |
|---|---|
| `private` | Personal hosts: GitHub (`github.com` with YubiKey PKCS11), ZHAW Git (`github.zhaw.ch` with `id_zhaw` key) |
| `homelab` | Homelab devices: `minix`, `macminim4`, `debianmini`, `k3smaster`, `k3sslave1` (all via Tailscale, YubiKey PKCS11) |
| `infra` | Infrastructure: `debug-pi` (local dev board), `*.smoca.ch` hosts (both with OpenSC PKCS11 via YubiKey) |
| `zhaw` | ZHAW university: `github.zhaw.ch` (with `id_zhaw` SSH key) |

### YubiKey PKCS11

Two PKCS#11 modules are used depending on the host:

- **`libykcs11.dylib`**: YubiKey's own PKCS#11 module (used for personal/homelab hosts, slot 9d)
- **`opensc-pkcs11.so`**: OpenSC PKCS#11 module (used for infra/SMOCA hosts, slot 9a)

Provider paths are unified across macOS and Linux via the PKCS#11 git filter (see above).

#### Fedora Ed25519 YubiKey limitation

Ed25519 keys stored on a YubiKey are currently **not supported by the Fedora
setup**. Fedora's system `ssh` client cannot use `libykcs11.so.2` for these
keys. A separately fetched/user-local OpenSSH client was tested as a workaround,
but caused severe problems, including hangs and major slowdowns while
establishing SSH connections, so it must not be used as the default client.

The last state in which Ed25519 YubiKey keys were usable was commit
`70af199e` (`fix ssh yubikey import`), but that state still had the SSH hangs
and slowdowns described above. Fedora currently supports the OpenSC-backed
YubiKey hosts, but not Ed25519 YubiKey authentication through the standard
setup.

## Vim Configuration

### vimrc

- **Undo persistence**: undo history saved to `vim/undo/`, survives restarts
- **Theme**: `cyberpunk_scarlet_protocol_adjusted` (a custom dark theme)
- **Indentation**: 4 spaces for Python, 2 for JS/TS/JSON/YAML, auto-detection
- **Whitespace**: trailing whitespace highlighted, tabs displayed as `▸·`
- **Statusline**: always visible, shows file name, modified flag, line/column, file type
- **Search**: incremental, highlight all matches
- **Mouse**: enabled in all modes
- **Netrw**: tree-style file browser
- **Swap files**: stored in `~/.vim/swap//` (double-trailing-slash creates unique filenames)

### vim/ directory

- `colors/cyberpunk_scarlet_protocol_adjusted.vim` — custom dark color scheme
- `undo/` — persistent undo directory (needs `mkdir -p ~/.vim/undo` or setup script)

## Neovim Configuration

### Architecture

```
nvim/
├── init.lua                    # Entry point: requires main/init
├── lua/main/
│   ├── init.lua                # Core: lazy.nvim bootstrap
│   ├── settings.lua            # Editor settings
│   ├── keymaps.lua             # Key mappings
│   ├── lazy_init.lua           # lazy.nvim plugin manager setup
│   └── plugins/                # One file per plugin (27 plugins)
│       ├── catppucino.lua      # Colorscheme
│       ├── lsp.lua             # LSP configuration
│       ├── cmp.lua             # Autocompletion
│       ├── telescope.lua       # Fuzzy finder
│       ├── nvim-treesitter.lua # Syntax highlighting
│       ├── lualine.lua         # Statusline
│       ├── nvim-tree.lua       # File explorer
│       ├── harpoon.lua         # File quick-jump
│       ├── trouble.lua         # Diagnostics list
│       ├── which-key.lua       # Keybinding discoverability
│       ├── comment.lua         # Easy commenting
│       ├── vimtex.lua          # LaTeX support
│       ├── java.lua            # Java/JDTLS support
│       ├── GPTModels.lua       # AI model integration
│       ├── ...                 # (and 13 more)
│       └── (27 total plugins)
├── ftplugin/
│   └── java.lua                # Java-specific settings
└── gdscript.lua                # Godot Engine GDScript support
```

### Plugin Manager

Uses **lazy.nvim** — bootstrapped from `lazy_init.lua`, which auto-installs lazy.nvim if missing.

### Core Settings

- **Leader key**: `<Space>`
- **Colorscheme**: Catppuccin
- **Line numbers**: relative + absolute on current line
- **Tab**: 2 spaces, expand tabs
- **Search**: smart case, incremental
- **Clipboard**: system clipboard (`unnamedplus`)
- **Mouse**: enabled
- **Undo**: persistent undo directory (`~/.local/share/nvim/undo/`)

### Key Plugin Categories

| Category | Plugins |
|---|---|
| **LSP** | `nvim-lspconfig`, `mason.nvim`, `mason-lspconfig`, `lsp-saga` (UI enhancements) |
| **Completion** | `nvim-cmp` + sources (LSP, buffer, path, snippets) |
| **Navigation** | `telescope.nvim` (fuzzy finder), `nvim-tree` (file tree), `harpoon` (quick jump), `outline.nvim` (symbol outline) |
| **Editing** | `nvim-autopairs` (auto brackets), `comment.nvim` (comment toggle), `vim-maximizer` (zoom splits) |
| **UI** | `lualine.nvim` (statusline), `which-key.nvim` (keymap hints), `dressing.nvim` (better UI for vim.ui), `indent-blankline` (indent guides) |
| **Syntax** | `nvim-treesitter`, `markview.nvim` (Markdown preview) |
| **Languages** | `vimtex`, `java` (JDTLS), `GPTModels.nvim` (AI chat) |
| **DX** | `trouble.nvim` (diagnostics), `todo-comments.nvim` (highlight TODOs), `vim-illuminate` (word highlighting) |
| **Navigation between windows** | `tmux-navigator` (seamless vim/tmux pane switching) |

### Language-Specific Support

- **Java**: JDTLS via `mason`, configured in `plugins/java.lua`; `ftplugin/java.lua` with Java-specific keymaps
- **LaTeX**: `vimtex` with forward/inverse search
- **Godot**: GDScript language server configured in `gdscript.lua`

## Kitty Configuration

- **Preferred terminal**: cross-platform replacement for iTerm2 on macOS and the default GNOME/KDE terminals on Linux
- **Compatibility**: sets `TERM=xterm-256color` instead of `xterm-kitty` so SSH hosts, serial consoles, rescue shells, `vim`, `systemctl`, and other TUI tools work without Kitty terminfo installed remotely
- **Appearance**: custom Cyberpunk Scarlet Protocol theme matched to the existing Ghostty/Vim colors
- **Keyboard**: Apple-style tab/split/clipboard shortcuts, Swiss-friendly bindings for tab navigation and vertical splits, and Option/Alt word movement
- **Behavior**: shell integration, large scrollback, copy-on-select, quiet bell, tabs, splits, and fullscreen/edit-config shortcuts

## Ghostty Configuration

- **Appearance**: custom dark theme (Cyberpunk Scarlet Protocol), background opacity 0.95
- **Font**: JetBrains Mono, size 14, with ligatures
- **Window**: macOS tabs enabled, padding and window decorations configured
- **Keyboard**: Swiss German layout — remaps common shortcuts to work with Swiss keyboard (e.g. `@`, `#`, `~`, `[]`, `{}`)
- **Theme**: stored in `ghostty/themes/Cyberpunk Scarlet Protocol Adjusted`
- **Note**: Ghostty config path differs per platform — `setup.sh` handles the mapping

## Lazygit Configuration

Minimal overrides in `lazygit/config.yml`:

- **Keybindings**: custom key remappings for common actions
- Config is included from `~/.config/lazygit/config.yml` (Linux) or `~/Library/Application Support/lazygit/config.yml` (macOS)

## VSCodium Configuration

### Settings Architecture

Uses a **base + overlay** pattern to keep settings DRY across platforms:

| File | Purpose |
|---|---|
| `settings.base.json` | Shared settings (editor, theme, extensions) |
| `settings.macos.json` | macOS-specific overrides (paths, keybindings) |
| `settings.linux.json` | Linux-specific overrides (currently `{}`) |

### ZSH Integration

The `zshrc` provides two functions for managing settings and extensions. Run them from the repository root:

1. After changing VSCodium settings or extensions, run `code export vscodium`. This saves a full settings backup, splits shared and platform-specific settings into the base and OS overlay files, and exports the installed extension list.
2. On another machine, run `code import vscodium` to merge the base and current OS overlay into VSCodium's user settings and install the extensions listed in `vscodium/extensions`.

Both commands require the `codium` CLI; exporting and importing the base/overlay settings also requires `jq`.

### Extensions

Extensions are listed in `vscodium/extensions` (one extension ID per line). Install with:
```bash
cat vscodium/extensions | xargs -L1 codium --install-extension
```

## Nextcloud Configuration

- **`nextcloud.cfg`**: Nextcloud desktop client configuration file
- **`sync-exclude.lst`**: patterns for files/folders to exclude from sync (e.g. `.DS_Store`, `node_modules`, `.git`, build directories)
- Symlinked into Nextcloud's config directory by `setup.sh`

## Junie Configuration

- **`settings.json`**: Junie AI assistant settings; only the five shared keys listed above are tracked, while other keys are held in the per-clone cache under `.git`
- **`mcp/mcp.json`**: MCP server configuration; `enabled` keys are omitted from Git, with local values held in the per-clone cache under `.git`
- **Model configs**: API keys in `junie/models/*.json` are protected by the `scrub-apikey` git filter — they never appear in commits (redacted to `REDACTED`)
- **Logs excluded** from repo (gitignored)

## Custom Scripts

### project

A **project directory switcher**. Scans configured project roots and provides fuzzy selection.

- Supports `--shell-integration` for zsh wrapper + completion
- Usage: `project <name>` to jump to a project directory
- Configure project roots by listing directories

### work-finder

A **Git and file activity scanner**. Finds recently active projects based on git activity or file modification times.

- Supports `--shell-integration` for zsh wrapper + completion
- Scans git repos for recent commits and modified files
- Useful for quickly finding what you were working on

Both scripts are auto-loaded by `zshrc` via shell integration, so their commands and completions are always available.

## Guidelines for Future Changes

### Adding Packages

1. Identify the correct platform manifest (see [Package Manifests](#package-manifests) table above).
2. For macOS, add a verified package attribute to the appropriate module in
   `nix/packages/` (`common.nix`, `darwin.nix`, or `aarch64-darwin.nix`) and
   update the [Nixpkgs audit](setup/macos/nixpkgs-audit.md). The reduced
   `Brewfile` remains an audit inventory and is not consumed by setup.
3. For Fedora, Flatpak, and Manjaro, add the package/app ID to the appropriate
   text file (one per line). After installing, use the platform export command:
   - Fedora: `dnf repoquery --userinstalled --qf "%{name}\n" | sort > setup/fedora/dnf.txt`
   - Fedora Flatpak: `flatpak list --app --columns=application | sort > setup/fedora/flatpak.txt`
   - Manjaro: `pacman -Qqen | sort > setup/manjaro/pacman.txt` (official) and `pacman -Qqem | sort > setup/manjaro/aur.txt` (AUR)

### Adding Setup Steps

1. Create a new numbered `.sh` file in the appropriate `setup/<os>/` directory.
2. Follow the step contract: implement `presteps()`, `help()`, and `run()`.
3. Source `setup/general/common.bash` for platform-neutral helpers; source your OS `common.bash` for platform-specific helpers.
4. Make the script executable (`chmod +x`).
5. Ensure `run()` is idempotent — check current state before every mutation.

### Adding SSH Hosts

1. **Choose the right `config.d/` file**: `private` (personal), `homelab` (home lab), `infra` (infrastructure), `zhaw` (university) or a new one.
2. Add the `Host` stanza. If using YubiKey PKCS11, use the token placeholders:
   - `@YKCS11@` — resolved to `libykcs11.dylib` on macOS, Fedora path on Linux
   - `@OPENSC@` — resolved to `opensc-pkcs11.so` on macOS, Fedora path on Linux
3. Commit — the git filter will automatically tokenize provider paths.

### Adding Neovim Plugins

1. Create a new file in `nvim/lua/main/plugins/<plugin-name>.lua`.
2. Follow the lazy.nvim convention used by existing plugins: return a spec table with `name`, `url`/`dir`, `dependencies`, `config`, `keys`, etc.
3. Example pattern:
   ```lua
   return {
     "author/plugin-name",
     dependencies = { "dep1", "dep2" },
     config = function()
       require("plugin-name").setup({})
     end,
   }
   ```
4. Keep one plugin per file — this makes it easy to disable individual plugins.

### Adding ZSH Functions/Aliases

1. Add aliases and functions to `zshrc`.
2. For platform-specific aliases: guard with `if [[ "$OS" = "Darwin" ]]` / `elif [[ "$OS" = "Linux" ]]`.
3. Consider whether a wrapper function is needed (like `code`/`codium`) — wrappers are for commands that need pre/post hooks.
4. If the function is substantial, consider moving it to `scripts/` and using `--shell-integration`.

### Adding Custom Scripts

1. Create the script in `scripts/`.
2. **Must support `--shell-integration`**: emit zsh wrapper function and completion to stdout. This is the pattern that `project` and `work-finder` follow.
3. Source the integration in `zshrc`:
   ```bash
   source <(path/to/script --shell-integration)
   ```

### Cross-Platform Patterns to Follow

| Pattern | How it works |
|---|---|
| **OS detection** | `zshrc` sets `$OS` to `Darwin` or `Linux`; `setup.sh` uses `uname -s` and `/etc/*-release` |
| **Platform-specific setup** | `setup.sh` discovers and runs numbered steps from `setup/general/` then `setup/<os>/` |
| **Step contract** | Every step implements `presteps` / `help` / `run`; helpers in `common.bash` |
| **Git filters for platform values** | Use clean/smudge filters (`pkcs11-provider` pattern) to keep platform-specific paths tokenized in commits, resolved in working trees |
| **Base + overlay settings** | `vscodium/` uses shared `settings.base.json` + platform-specific overlays |
| **Provider path tables** | `ssh/providers.mac` / `ssh/providers.fedora` hold only key=value pairs, never hosts |
