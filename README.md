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
| **macOS** | `setup/macos/` | Homebrew | ✅ Active |
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
│   ├── macos/                  # macOS steps + Brewfile
│   ├── fedora/                 # Fedora steps + dnf/flatpak/copr manifests
│   ├── fedora-atomic/          # Fedora Atomic steps + rpm-ostree/toolbox manifests
│   └── manjaro/                # Manjaro steps + pacman/aur manifests
├── tests/                      # Podman + bats-core test matrix
├── zshrc                       # ZSH shell configuration
├── gitconfig                   # Git global configuration
├── vimrc                       # Vim configuration
├── vim/                        # Vim custom color scheme + persistent undo
├── nvim/                       # Neovim (lazy.nvim, 27 plugins, LSP)
├── ghostty/                    # Ghostty terminal emulator
├── lazygit/                    # Lazygit TUI keybinding overrides
├── vscodium/                   # VSCodium (base+overlay settings pattern)
├── ssh/                        # SSH config, host stanzas, YubiKey PKCS11
├── scripts/                    # Custom CLI tools (project, work-finder)
├── Nextcloud/                  # Nextcloud desktop client config
└── junie/                      # Junie AI assistant settings
```

| Path | Purpose |
|---|---|
| `setup.sh` | Orchestration-only runner. Detects OS, discovers numbered step scripts under `setup/general/` and `setup/<os>/`, applies selection filters (`--all`, `--only`, `--exclude`, `--interactive`), and runs each step as a separate process via `presteps` then `run`. No setup logic lives here. |
| `setup/general/` | OS-agnostic steps that run first on every platform: symlink dotfiles, register git filters, create shared editor directories. `common.bash` provides platform-neutral primitives (logging, symlink helpers, git clone guards, manifest parsing). |
| `setup/<os>/` | Platform-specific numbered steps with companion manifests and a `common.bash` helper library. Steps are idempotent — safe to run repeatedly. |
| `zshrc` | ZSH config: OS/hardware detection, history settings, aliases, platform-aware clip/clippaste helpers, completion system, starship prompt, version managers (NVM, JABBA, PYENV, RBENV, bun), ZSH plugins, custom script shell-integration. |
| `gitconfig` | Git config: GPG SSH signing, codium/vscode as difftool/mergetool, LFS, pull rebase, credential cache. |
| `vimrc` | Vim config: persistent undo, custom theme, indentation, whitespace display, statusline. |
| `vim/` | Vim custom color scheme (`cyberpunk_scarlet_protocol_adjusted.vim`) and persistent undo directory. |
| `nvim/` | Neovim config: `lazy.nvim` package manager, 27 plugins (LSP, Telescope, Treesitter, lualine, nvim-tree, harpoon, trouble, which-key, vimtex, Java JDTLS, Godot LSP, GPTModels, etc.). |
| `ghostty/` | Ghostty terminal emulator: appearance, Swiss keyboard keybindings, custom Cyberpunk Scarlet Protocol theme. |
| `lazygit/` | Lazygit TUI: custom keybinding overrides. |
| `vscodium/` | VSCodium: base+overlay settings (`settings.base.json` + platform-specific overlays), extensions list, `code export`/`code import` zsh functions. |
| `ssh/` | SSH config: `config` entry point (Include, ControlMaster, keychain), `config.d/*` host stanzas (private, homelab, infra, zhaw), YubiKey PKCS11 provider filter. |
| `scripts/` | Custom CLI tools: `project` (project directory switcher), `work-finder` (git/file activity scanner). Both support `--shell-integration` for zsh wrapper + completion generation. |
| `Nextcloud/` | Nextcloud desktop client config (`nextcloud.cfg`) and sync-exclude patterns (`sync-exclude.lst`). |
| `junie/` | Junie AI assistant: `settings.json`, model configs with API key scrub filter. |

## Git Filters

This repo uses two git clean/smudge filters, registered by `setup/general/02-git-filters.sh`:

- **`scrub-apikey`** — redacts API keys in `junie/models/*.json` on commit (clean only; smudge passes through unchanged).
- **`pkcs11-provider`** — tokenizes PKCS#11 provider paths in `ssh/config.d/*` on commit (`@YKCS11@`, `@OPENSC@`) and resolves them to the current platform's real paths on checkout. Provider paths are defined in `ssh/providers.mac` and `ssh/providers.fedora`.

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
   git config filter.pkcs11-provider.clean  "$REPO_DIR/ssh/pkcs11-filter.sh clean"
   git config filter.pkcs11-provider.smudge "$REPO_DIR/ssh/pkcs11-filter.sh smudge"
   git config filter.pkcs11-provider.required true
   ```
   `required true` means git will fail rather than silently skip the filter.

3. **`ssh/providers.mac` / `ssh/providers.fedora`** — pure key=value path tables,
   no hosts:
   ```
   # providers.mac
   YKCS11=/opt/homebrew/lib/libykcs11.dylib
   OPENSC=/opt/homebrew/lib/opensc-pkcs11.so
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
  `/opt/homebrew/lib/libykcs11.dylib` becomes `@YKCS11@`, and any Fedora path
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
  filter runs before the file is checked out), it hardcodes the macOS Homebrew
  paths on Darwin, and on any other OS passes content through unchanged.
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
| `01-symlinks.sh` | Symlink dotfiles (zshrc, vimrc, gitconfig, nvim, lazygit, ghostty, ssh, etc.) into `$HOME` |
| `02-git-filters.sh` | Register `pkcs11-provider` and `scrub-apikey` git clean/smudge filters |
| `03-vim-base.sh` | Create shared editor directories (`~/.vim/undo`) |

`common.bash` provides platform-neutral primitives: `ensure_symlink`, `ensure_dir`, `ensure_git_clone`, `ensure_git_config`, `ensure_line_present`, `read_manifest`, `command_exists`, `require_command`.

### macOS Steps (`setup/macos/`)

| Step | Description |
|---|---|
| `01-homebrew.sh` | Install Homebrew if not present |
| `02-brew-bundle.sh` | Install packages from `setup/macos/Brewfile` via `brew bundle` |
| `03-ssh-agent.sh` | Start ssh-agent if not running |
| `04-ssh-keychain.sh` | Add SSH keys to Apple keychain |
| `05-vim-theme.sh` | Clone Dracula vim theme |

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
| `12-toolbox-cli-dev.sh` | Install Jabba, Pyenv, NVM in cli-dev toolbox |
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
| `11-jabba.sh` | Install Jabba (Java version manager) |
| `12-joplin.sh` | Install Joplin note-taking app |
| `13-cisco-note.sh` | Cisco AnyConnect VPN note |
| `14-celeste-note.sh` | Celeste cloud sync note |

### Package Manifests

Each platform's manifests live alongside their step scripts in `setup/<os>/`.

| Manifest | Format | Export command |
|---|---|---|
| `setup/macos/Brewfile` | Homebrew Bundle | `brew bundle dump --file=setup/macos/Brewfile --force` |
| `setup/fedora/dnf.txt` | One package per line | `dnf repoquery --userinstalled --qf "%{name}\n" \| sort` |
| `setup/fedora/copr.txt` | One COPR repo per line | (manual) |
| `setup/fedora/flatpak.txt` | One app ID per line | `flatpak list --app --columns=application \| sort` |
| `setup/fedora-atomic/rpm-ostree.txt` | One package per line | `rpm-ostree status --json \| jq -r '.deployments[0]["requested-packages"][]'` |
| `setup/fedora-atomic/flatpak.txt` | One app ID per line | Same as Fedora flatpak |
| `setup/fedora-atomic/toolboxes.txt` | List of toolbox names | (manual) |
| `setup/fedora-atomic/toolboxes/*.txt` | Per-toolbox dnf packages | (manual per toolbox) |
| `setup/manjaro/pacman.txt` | One package per line | `pacman -Qqen \| sort` |
| `setup/manjaro/aur.txt` | One package per line | `pacman -Qqem \| sort` |

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
- Sets platform-specific environment variables (`$HOMEBREW_PREFIX`, `$ANDROID_HOME`, etc.)
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
- **`brew`**: wraps Homebrew with automatic Brewfile update after `brew install`/`remove`
- **`git`**: extends git with additional aliases (see gitconfig section)
- **`idf.py`**: ESP-IDF wrapper with automatic environment setup

### Completion System

- Modern completion system with `menu select` and `list-colors`
- Auto-loads completions for: git, brew, docker, kubectl, pip, npm, cargo, rustup

### Prompt

Uses **Starship** prompt (`starship.toml` not in this repo). Falls back gracefully if not installed.

### Version Managers

All version managers are loaded lazily (only when their commands are invoked):

| Manager | Tool | Lazy-load Command |
|---|---|---|
| **NVM** | Node.js | `nvm`, `node`, `npm`, `yarn`, `pnpm` |
| **JABBA** | Java/JDK | `jabba`, `java`, `javac` |
| **PYENV** | Python | `pyenv`, `python`, `pip` |
| **RBENV** | Ruby | `rbenv`, `ruby`, `gem` |
| **bun** | JS runtime | `bun`, `bunx` |

### ZSH Plugins

Loaded via native zsh `source` (no plugin manager):

- **zsh-autosuggestions**: fish-style autosuggestions as you type
- **zsh-syntax-highlighting**: real-time command syntax coloring
- **zsh-autocomplete**: type-ahead completion in all contexts

### Additional Integrations

- **Homebrew**: shellenv + completions on macOS
- **FZF**: fuzzy finder with fd integration, `Ctrl+T` / `Ctrl+R` / `Alt+C` bindings
- **Tailscale**: completions
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

The `zshrc` provides two functions for managing settings:

- **`code export`**: writes current VSCodium settings back to the repo:
  - Shared settings → `settings.base.json`
  - Platform-specific settings → `settings.macos.json` / `settings.linux.json`
- **`code import`**: merges repo settings into VSCodium:
  - Symlinks `settings.base.json` + platform overlay → VSCodium user settings

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

- **`settings.json`**: Junie AI assistant settings (local-only; not tracked by git — each machine keeps its own copy)
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
2. Add the package name to the appropriate text file (one per line).
3. After installing on the target machine, run the export command to keep the manifest in sync:
   - macOS: `brew bundle dump --file=setup/macos/Brewfile --force`
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
3. Consider whether a wrapper function is needed (like `code`/`codium` or `brew`) — these are for commands that need pre/post hooks.
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

## Recommendations

These are concrete suggestions to improve the config over time. None are blockers — just ideas worth pursuing.

### High Priority

- **Verify Fedora provider paths**: `ssh/providers.fedora` has `TODO_VERIFY_*` placeholders. Verify `/usr/lib64/pkcs11/libykcs11.so` and `/usr/lib64/pkcs11/opensc-pkcs11.so` on real Fedora hardware with the `ykcs11` and `opensc` packages installed.
- **Populate `settings.linux.json`**: `vscodium/settings.linux.json` is empty `{}`. Add Linux-specific VSCodium settings (e.g. paths, terminal profiles).
- **Resolve `VISUAL=3` in zshrc**: The env var `VISUAL=3` is set in `zshrc` — the value `3` is unclear. Either document what it does or fix it (likely meant to be `VISUAL=nvim` or similar).

### Medium Priority

- **Add shellcheck CI**: All setup scripts are shell (`sh`/`bash`). A pre-commit hook or CI step running `shellcheck` would catch common issues.
- **Untrack `known_hosts.old` and `.netrwhist`**: These auto-generated files are tracked in git but are ephemeral data, not config. Consider removing from tracking or adding to `.gitignore`.
- **Document `code export`/`code import` workflow**: The VSCodium settings sync flow is powerful but not obvious. Consider a dedicated section showing end-to-end usage.
- **Write a `starship.toml`**: The zshrc references Starship prompt but the `starship.toml` isn't in this repo. Adding it would make the prompt portable.

## TODO

### Mac

- [x] setup script (tested on M1/M2)
- [x] dependency install (Homebrew)
- [x] dependency list (Brewfile)
- [x] ssh config (including PKCS11 filter)
- [x] git config (GPG SSH signing)
- [x] zsh config (starship prompt)
- [x] vim config (cyberpunk theme)
- [x] terminal config (ghostty)
- [x] vscode(ium) config (base + overlay)
- [x] neovim (lazy.nvim, 27 plugins)
- [ ] Nordic Connect Desktop setup (`setup/macos/08-nrf-connect.sh`)
- [ ] Xcode Additional Tools setup (`setup/macos/11-xcode-additional-tools.sh`)
- [ ] Segger SystemView setup
- [ ] Nordic SDK directories

### Linux

#### Fedora

- [x] setup script (untested on hardware)
- [x] dependency install (dnf + Flatpak + COPR)
- [x] dependency list
- [x] ssh config (PKCS11 filter)
- [x] git config
- [x] zsh config
- [x] vim config
- [ ] terminal config (ghostty Linux path)
- [x] vscode(ium) config
- [ ] verify PKCS11 provider paths (`providers.fedora`)
- [x] neovim config

#### Fedora Atomic (Tested in containers)

- [x] setup script (untested on hardware)
- [x] dependency install (rpm-ostree + Flatpak + Toolbx)
- [x] dependency list
- [x] ssh config (PKCS11 filter)
- [x] git config
- [x] zsh config
- [x] vim config
- [ ] terminal config (ghostty Linux path)
- [x] vscode(ium) config
- [ ] verify PKCS11 provider paths (`providers.fedora`)
- [x] neovim config

#### Manjaro (Tested in containers)

- [x] setup script (untested on hardware)
- [x] dependency install (pacman + AUR)
- [x] dependency list
- [x] ssh config (PKCS11 filter)
- [x] git config
- [x] zsh config
- [x] vim config
- [ ] terminal config (ghostty Linux path)
- [x] vscode(ium) config
- [ ] verify PKCS11 provider paths (`providers.fedora`)
- [x] neovim config
