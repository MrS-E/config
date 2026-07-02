# config

Cross-platform dotfiles repository supporting **macOS**, **Fedora**, **Fedora Atomic**, and **Manjaro**.

## Quick Start

1. **Clone** the repo to `~/config`:
   ```bash
   git clone <repo-url> ~/config
   ```
2. **Configure git filters** (required before any other git operations):
   ```bash
   cd ~/config && ./setup.git-filters.sh
   ```
3. **Run the setup script**:
   ```bash
   ./setup.sh
   ```
   This symlinks config files into `$HOME`, installs packages, and runs platform-specific setup.

## Supported Platforms

| OS | Setup Script | Package Managers | Status |
|---|---|---|---|
| **macOS** | `setup.macos.sh` | Homebrew | ✅ Active |
| **Fedora** | `setup.fedora.sh` | dnf, COPR, Flatpak |  ✅ Active |
| **Fedora Atomic** | `setup.atomic-fedora.sh` | rpm-ostree, Flatpak, Toolbx | 🧪 Untested |
| **Manjaro** | `setup.manjaro.sh` | pacman, AUR (yay) | 🧪 Untested |

## Repository Layout

```
config/
├── .gitattributes              # Git filter assignments (PKCS11, API keys)
├── .gitignore
├── README.md
├── setup.sh                    # Main entry point: symlinks + platform dispatch
├── setup.macos.sh              # macOS: Homebrew, SSH agent, keychain
├── setup.fedora.sh             # Fedora: dnf, Flatpak, ZSH plugins, toolbox
├── setup.atomic-fedora.sh      # Fedora Atomic: rpm-ostree, toolboxes
├── setup.manjaro.sh            # Manjaro: pacman, AUR, printer, firewall
├── setup.git-filters.sh        # One-shot git clean/smudge filter registration
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
├── packages/                   # Per-platform package manifests
├── Nextcloud/                  # Nextcloud desktop client config
└── junie/                      # Junie AI assistant settings
```

| Path | Purpose |
|---|---|
| `setup.sh` | Main entry point. Creates symlinks from repo to `$HOME` (e.g. `zshrc` → `~/.zshrc`, `nvim/` → `~/.config/nvim`), detects OS via `uname -s` and `/etc/*-release`, then delegates to the matching platform script. |
| `setup.macos.sh` | macOS setup: installs Homebrew + Brewfile packages, configures SSH agent with `ssh-add -A`, sets up keychain for SSH passphrases, installs vim theme. |
| `setup.fedora.sh` | Fedora setup: installs dnf groups + Flatpaks + COPR repos, ZSH plugins (autosuggestions, syntax-highlighting), tealdeer, toolbox, protonmail bridge, bun, junie, tailscale. |
| `setup.atomic-fedora.sh` | Fedora Atomic setup: rpm-ostree layering, Flatpaks, toolbox containers with per-toolbox package manifests (cli-dev, cpp-dev, latex, mobile). |
| `setup.manjaro.sh` | Manjaro setup: pacman + AUR via yay, ZSH plugins, CUPS printer, firewall (ufw), clamav, external install scripts (JetBrains Toolbox, Jabba, Joplin, Cisco, Celeste). |
| `setup.git-filters.sh` | Registers `scrub-apikey` and `pkcs11-provider` git clean/smudge filters. Called automatically by `setup.sh`. Run manually after a fresh clone before any other git operations. |
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
| `packages/` | Per-platform package manifests: `macos/Brewfile`, `fedora/` (dnf, flatpak, copr), `fedora-atomic/` (rpm-ostree, flatpak, toolboxes/), `manjaro/` (pacman, aur, external/). |
| `Nextcloud/` | Nextcloud desktop client config (`nextcloud.cfg`) and sync-exclude patterns (`sync-exclude.lst`). |
| `junie/` | Junie AI assistant: `settings.json`, model configs with API key scrub filter. |

## Git Filters

This repo uses two git clean/smudge filters, registered by `setup.git-filters.sh`:

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

2. **`setup.git-filters.sh`** — run once per clone (also called by `setup.sh`).
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
- **Switch platforms** → just re-run `./setup.git-filters.sh` (already in
  `setup.sh`) and `git checkout -- ssh/config.d/` to re-smudge with the new
  platform's paths.

#### Caveats

- `providers.fedora` still holds `TODO_VERIFY_*` placeholders; until real Fedora
  paths are filled in, smudge on Linux would inject those literal `TODO_...`
  strings, which SSH would then fail to load. Verify on real hardware.
- The filter is `required`, so if `pkcs11-filter.sh` is missing or errors, git
  operations on `config.d/*` will fail loudly rather than corrupting content.

## Setup System

### setup.sh

The main entry point. It performs two jobs:

1. **Symlink creation**: links repo files into `$HOME`:
   - `zshrc` → `~/.zshrc`
   - `gitconfig` → `~/.gitconfig`
   - `vimrc` → `~/.vimrc`
   - `nvim/` → `~/.config/nvim`
   - `vim/` → `~/.vim`
   - `ghostty/` → `~/Library/Application Support/com.mitchellh.ghostty/config` (macOS)
     or `~/.config/ghostty` (Linux)
   - `lazygit/` → `~/.config/lazygit` (Linux) or `~/Library/Application Support/lazygit` (macOS)
   - `vscodium/` → VSCodium/Code user config directory (platform-specific paths)
   - `ssh/` → `~/.ssh` (including `config`, `config.d/`, `known_hosts`)
   - `Nextcloud/` → Nextcloud config directory

2. **Platform dispatch**: detects OS and delegates to the appropriate platform script.

### setup.macos.sh

- Installs **Homebrew** if not present
- Installs packages from `packages/macos/Brewfile` (`brew bundle`)
- Configures **SSH agent** with `ssh-add -A` (adds all identities from keychain)
- Sets up **SSH keychain** integration via `UseKeychain yes` in `~/.ssh/config`
- Installs the **vim theme** (copies `cyberpunk_scarlet_protocol_adjusted.vim` to Homebrew vim colors)
- Runs `setup.git-filters.sh` (via `setup.sh`)

### setup.fedora.sh

- Installs **dnf** packages from `packages/fedora/dnf.txt`
- Enables **COPR** repos from `packages/fedora/copr.txt`
- Installs **Flatpak** packages from `packages/fedora/flatpak.txt` (Flathub)
- Installs **ZSH plugins**: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-autocomplete`
- Installs **tealdeer** (simplified man pages) and updates its cache
- Sets up **toolbox** container for CLI dev
- Installs **protonmail bridge** (dnf + initial setup)
- Installs **bun** (JavaScript runtime) via curl
- Installs **junie** CLI
- Enables and starts **tailscaled**
- Sets up **vim undo** directory

### setup.atomic-fedora.sh

- **rpm-ostree** layering from `packages/fedora-atomic/rpm-ostree.txt`
- **Flatpak** packages from `packages/fedora-atomic/flatpak.txt`
- **Toolbox** containers with per-toolbox manifests:
  - `cli-dev` — CLI development tools (`packages/fedora-atomic/toolboxes/cli-dev.txt`)
  - `cpp-dev` — C++ development tools (`packages/fedora-atomic/toolboxes/cpp-dev.txt`)
  - `latex` — LaTeX toolchain (`packages/fedora-atomic/toolboxes/latex.txt`)
  - `mobile` — Mobile development tools (`packages/fedora-atomic/toolboxes/mobile.txt`)
- **1Password** and **1Password CLI** (rpm-ostree)
- Sets up **vim undo** directory

### setup.manjaro.sh

- Installs **pacman** packages from `packages/manjaro/pacman.txt`
- Installs **AUR** packages via **yay** from `packages/manjaro/aur.txt`
- Installs **ZSH plugins** (same as Fedora)
- Enables and starts **CUPS** (printing)
- Configures **firewall** (ufw) with basic rules (SSH, KDE Connect, syncthing, printing)
- Installs **clamav** (antivirus) and updates virus definitions
- Runs **external scripts** from `packages/manjaro/external/`:
  - `10-jetbrains-toolbox.sh` — JetBrains Toolbox
  - `20-jabba.sh` — Jabba JDK version manager
  - `30-joplin.sh` — Joplin note-taking app
  - `40-cisco-note.sh` — Cisco Packet Tracer
  - `50-celeste-note.sh` — Celeste sync client
- Sets up **vim undo** directory

### Package Manifests (packages/)

Each platform has its own package list files. The setup scripts read these to install packages.

| Manifest | Format | Export command |
|---|---|---|
| `packages/macos/Brewfile` | Homebrew Bundle | `brew bundle dump --file=packages/macos/Brewfile --force` |
| `packages/fedora/dnf.txt` | One package per line | `rpm -qa --qf "%{NAME}\n" \| grep -v -f <(rpm -qa --qf "%{NAME}\n" --group "Core") \| sort > packages/fedora/dnf.txt` |
| `packages/fedora/copr.txt` | One COPR repo per line | (manual) |
| `packages/fedora/flatpak.txt` | One app ID per line | `flatpak list --app --columns=application \| tail -n +1 > packages/fedora/flatpak.txt` |
| `packages/fedora-atomic/rpm-ostree.txt` | One package per line | `rpm-ostree status --json \| jq -r '.deployments[0]["requested-packages"][]'` |
| `packages/fedora-atomic/flatpak.txt` | One app ID per line | Same as Fedora flatpak |
| `packages/fedora-atomic/toolboxes.txt` | List of toolbox names | (manual) |
| `packages/fedora-atomic/toolboxes/*.txt` | Per-toolbox dnf packages | (manual per toolbox) |
| `packages/manjaro/pacman.txt` | One package per line | `pacman -Qqen \| sort > packages/manjaro/pacman.txt` |
| `packages/manjaro/aur.txt` | One package per line | `pacman -Qqem \| sort > packages/manjaro/aur.txt` |

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

1. Identify the correct platform manifest (see [Package Manifests](#package-manifests-packages) table above).
2. Add the package name to the appropriate text file (one per line).
3. After installing on the target machine, run the export command to keep the manifest in sync:
   - macOS: `brew bundle dump --file=packages/macos/Brewfile --force`
   - Fedora: `rpm -qa --qf "%{NAME}\n" | grep -v -f <(rpm -qa --qf "%{NAME}\n" --group "Core") | sort > packages/fedora/dnf.txt`
   - Fedora Flatpak: `flatpak list --app --columns=application | tail -n +1 > packages/fedora/flatpak.txt`
   - Manjaro: `pacman -Qqen | sort > packages/manjaro/pacman.txt` (official) and `pacman -Qqem | sort > packages/manjaro/aur.txt` (AUR)

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
| **OS detection** | `zshrc` sets `$OS` to `Darwin` or `Linux`; scripted files use `uname -s` |
| **Platform-specific setup** | `setup.sh` dispatches to `setup.<platform>.sh` |
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

- **Unify ZSH plugin installation**: The same three plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-autocomplete`) are installed separately in `setup.fedora.sh`, `setup.atomic-fedora.sh`, and `setup.manjaro.sh` with duplicate code. Extract into a shared function in `setup.sh` or a `setup.linux-common.sh`.
- **Create `setup.linux-common.sh`**: Shared Linux steps (ZSH plugins, tealdeer, vim undo dir creation, Ghostty Linux config path) are duplicated across the three Linux setup scripts. Extract them into a single file.
- **Clean up Brewfile backups**: `packages/macos/Brewfile.old*` files are tracked. Either delete them or add to `.gitignore`.

### Low Priority / Nice to Have

- **Add shellcheck CI**: All setup scripts are shell (`sh`/`bash`). A pre-commit hook or CI step running `shellcheck` would catch common issues.
- **Untrack `known_hosts.old` and `.netrwhist`**: These auto-generated files are tracked in git but are ephemeral data, not config. Consider removing from tracking or adding to `.gitignore`.
- **Add `Makefile` or `justfile`**: A single entry point for common operations:
  - `make setup` / `just setup`
  - `make export-packages` / `just export-packages`
  - `make update-filters` / `just update-filters`
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

#### Fedora Atomic (Untested)

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

#### Manjaro (Untested)

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
