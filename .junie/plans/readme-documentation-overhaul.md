---
sessionId: session-260702-111018-163h
---

# Requirements

### Overview & Goals

The user wants a comprehensive README.md that documents the **entire config directory** — every component, script, config file, and pattern. The current README only covers the git filter setup and PKCS#11 provider filter; everything else (zshrc, nvim, vim, ghostty, vscodium, setup scripts, scripts/, packages/, Nextcloud, junie, lazygit, gitconfig, ssh) is undocumented.

Additionally, the user wants:
1. **Guidelines for the future** — conventions and patterns to follow when extending the config.
2. **Recommendations for improvements** — concrete suggestions to make the config better.

### Scope

**In Scope:**
- Rewrite/expand `README.md` with detailed documentation of every component in the repo.
- Add a guidelines section documenting conventions (how to add packages, hosts, plugins, scripts).
- Add a recommendations section with concrete improvement suggestions.
- Update the existing TODO section to reflect current state.

**Out of Scope:**
- Implementing any of the recommendations (documentation only).
- Modifying any config files other than `README.md`.
- Documenting junie logs (user explicitly said to skip logs).

### User Stories

- As the repo owner, I want a single reference document so I can understand my own setup months later.
- As a future me on a new machine, I want to know exactly what `./setup.sh` does and what to expect.
- As a developer extending the config, I want guidelines so I follow existing patterns consistently.

# Technical Design

### Current Implementation

The repo is a cross-platform dotfiles repository supporting **macOS**, **Fedora**, **Fedora Atomic**, and **Manjaro**. Key architectural patterns:

1. **Symlink-based deployment** — `setup.sh` symlinks repo files into `$HOME` (e.g. `zshrc` → `~/.zshrc`, `nvim/` → `~/.config/nvim`).
2. **Platform dispatch** — `setup.sh` detects OS via `uname -s` and `/etc/*-release`, then delegates to `setup.macos.sh`, `setup.fedora.sh`, `setup.atomic-fedora.sh`, or `setup.manjaro.sh`.
3. **Package manifests** — `packages/<platform>/` directories hold plain-text package lists (dnf.txt, flatpak.txt, pacman.txt, aur.txt, Brewfile, rpm-ostree.txt, toolboxes/*.txt) consumed by the setup scripts.
4. **Git clean/smudge filters** — `setup.git-filters.sh` registers two filters: `scrub-apikey` (redacts API keys in junie models) and `pkcs11-provider` (tokenizes/resolves SSH PKCS#11 provider paths).
5. **Shell-integration scripts** — `scripts/project` and `scripts/work-finder` are standalone CLI tools that emit zsh wrappers + completions via `--shell-integration`, auto-loaded by `zshrc`.
6. **VSCodium base+overlay** — `vscodium/settings.base.json` holds shared settings; `settings.macos.json` / `settings.linux.json` hold platform-specific keys; `code export`/`code import` zsh functions manage the split.

### Proposed Changes

Rewrite `README.md` with the following structure:

```markdown

# config

## Quick Start
  - Clone, run setup.git-filters.sh, run setup.sh

## Supported Platforms
  - Table: OS | Setup script | Status

## Repository Layout
  - Annotated tree of all top-level dirs/files

## Setup System
  ### setup.sh (base: symlinks + platform dispatch)
  ### setup.macos.sh
  ### setup.fedora.sh
  ### setup.atomic-fedora.sh
  ### setup.manjaro.sh
  ### setup.git-filters.sh
  ### Package Manifests (packages/)

## Shell Configuration (zshrc)
  - OS/hardware detection, env vars
  - Aliases & functions (clip, o, adb, git, brew, code, idf wrappers)
  - Completion system
  - Prompt
  - Version managers (NVM, JABBA, PYENV, RBENV, bun)
  - ZSH plugins (autosuggestions, syntax-highlighting, autocomplete)
  - Custom scripts shell-integration pattern

## Git Configuration (gitconfig)
  - GPG SSH signing, difftools, mergetools, LFS

## SSH Configuration
  - ssh/config (Include, ControlMaster, keychain)
  - config.d/* host groupings
  - PKCS#11 provider filter (existing section, keep as-is)
  - providers.mac / providers.fedora

## Vim Configuration
  - vimrc settings, undo persistence, custom theme

## Neovim Configuration
  - init.lua entry, lazy.nvim bootstrap
  - Module structure (settings, keymaps, plugins/)
  - Plugin inventory (25+ plugins)
  - Language support (Java/JDTLS, Godot, LaTeX/VimTeX)

## Ghostty Configuration
  - Appearance, Swiss keyboard keybindings, custom theme

## Lazygit Configuration

## VSCodium Configuration
  - Base + overlay settings pattern
  - code export/import functions
  - Extensions list

## Nextcloud Configuration
  - Config file, sync-exclude patterns

## Junie Configuration
  - settings.json, API key scrub filter

## Custom Scripts
  - scripts/project (project switcher)
  - scripts/work-finder (git/file activity scanner)

## Git Filters
  - (existing section, keep as-is)

## Guidelines for Future Changes
  - Adding packages
  - Adding SSH hosts
  - Adding nvim plugins
  - Adding zsh functions/aliases
  - Adding custom scripts
  - Cross-platform patterns to follow

## Recommendations
  - Concrete improvement suggestions

## TODO
  - (updated existing section)
```

### Key Decisions

- **Keep existing PKCS#11 and Git Filters sections** — they are already well-written; integrate them into the new structure rather than rewriting.
- **Document from the user's perspective** — focus on "what does this do and how do I use it" rather than line-by-line code commentary.
- **Include export commands** — each package manifest section includes the export command (already in script headers) so the user can refresh lists.
- **Skip junie logs** — per user instruction.

# Testing

### Validation Approach

Since this is a documentation-only task, validation is:
- Verify all top-level files/directories in the repo are mentioned in the README.
- Verify the README structure is navigable (clear headings, consistent formatting).
- Verify no factual errors (e.g., wrong script names, wrong paths, wrong descriptions).
- Verify the guidelines and recommendations are concrete and actionable.

### Key Scenarios

- A reader can find documentation for any file in the repo by following the README structure.
- A reader can follow Quick Start to set up a new machine.
- A reader can follow Guidelines to add a new package, SSH host, or nvim plugin correctly.
- The TODO section accurately reflects current state (e.g., Fedora provider paths still TODO).

# Delivery Steps

### ✓ Step 1: Rewrite README with architecture overview and repo map
Rewrite the top of README.md into a structured overview.

- Add a repository tree diagram showing all top-level directories and key files.
- Add a **Supported Platforms** table (macOS, Fedora, Fedora Atomic, Manjaro) with setup script names and status.
- Add a **Quick Start** section: clone → `./setup.git-filters.sh` → `./setup.sh`.
- Add a **Repository Layout** table mapping each directory/file to a one-line purpose (setup.*, zshrc, gitconfig, vimrc, nvim/, vim/, ghostty/, lazygit/, vscodium/, ssh/, scripts/, packages/, Nextcloud/, junie/, .gitattributes, .gitignore).
- Keep the existing PKCS#11 Provider Filter section and Git Filters section in place (they are already well-documented).

### ✓ Step 2: Add per-component documentation sections
Add detailed documentation sections for each config component.

- **Setup Scripts**: document `setup.sh` (symlink creation + platform dispatch), `setup.macos.sh` (Homebrew, ssh-agent, keychain, vim theme), `setup.fedora.sh` (dnf, COPR, flatpak, zsh plugins, toolbox, proton bridge, bun, junie, tailscale), `setup.atomic-fedora.sh` (rpm-ostree layering, flatpak, toolboxes with per-toolbox package manifests, latex/mobile/cli-dev extras), `setup.manjaro.sh` (pacman, AUR via yay, zsh plugins, printer, firewall, clamav, external scripts).
- **Shell (zshrc)**: document OS/hardware detection, history config, aliases, clip/clippaste platform helpers, completion system, prompt, Homebrew/FZF/NVM/JABBA/PYENV/RBENV/bun/Tailscale/TheFuck integration, zsh plugin loading, custom script shell-integration pattern, adb/git/brew/code/idf wrapper functions.
- **Git (gitconfig)**: document GPG SSH signing, editor, difftool/mergetool configs (codium, meld, diffmerge, nvim), LFS, pull rebase, credential cache.
- **SSH**: document `ssh/config` (Include, ControlMaster, keychain), `config.d/*` host groupings (private/github, homelab, infra, zhaw, dienstwerk), YubiKey PKCS11 setup, providers.mac/providers.fedora.
- **Vim**: document vimrc settings (undo persistence, theme, indentation, whitespace display, statusline), custom color scheme.
- **Neovim**: document init.lua entry point, lazy.nvim bootstrap, module structure (settings, keymaps, plugins), plugin list summary (LSP, completion, telescope, treesitter, lualine, nvim-tree, harpoon, trouble, which-key, comment, vimtex, java JDTLS, Godot LSP, GPTModels, etc.), ftplugin/java.lua.
- **Ghostty**: document appearance, keybindings (Swiss keyboard layout), custom theme.
- **Lazygit**: document keybinding overrides.
- **VSCodium**: document base + platform overlay settings pattern, `code export`/`code import` zsh functions, extensions list.
- **Nextcloud**: document config file, sync-exclude patterns.
- **Junie**: document settings.json, models with API key scrub filter.
- **Scripts**: document `project` (project switcher with shell integration + zsh completion) and `work-finder` (git/file activity scanner with shell integration).
- **Package Manifests**: document per-platform package lists and export commands (already in script headers).

### ✓ Step 3: Add guidelines and recommendations section
Add forward-looking guidelines and improvement recommendations.

- **Contributing Guidelines**: conventions for adding new packages (edit the right manifest, use export commands), adding new SSH hosts (create/edit config.d/* files, PKCS11 tokens), adding new nvim plugins (one file per plugin in lua/main/plugins/), adding new zsh wrapper functions, adding new scripts (must support `--shell-integration`).
- **Cross-Platform Patterns**: document the established patterns — OS detection in zshrc, platform-specific setup scripts, git filters for platform-specific values, VSCodium base+overlay settings, providers.mac/providers.fedora for SSH.
- **Recommendations**:
  - Verify `providers.fedora` TODO placeholders on real Fedora hardware.
  - Consider unifying zsh plugin installation (currently duplicated across 3 Linux setup scripts) into a shared function in setup.sh.
  - Consider adding a `setup.linux-common.sh` for shared Linux steps (zsh plugins, tealdeer, vim undo dir).
  - `vscodium/settings.linux.json` is currently empty `{}` — populate with Linux-specific paths if needed.
  - `packages/macos/Brewfile.old*` backups could be cleaned up or gitignored.
  - Consider adding shellcheck CI or a pre-commit hook for setup scripts.
  - `ssh/known_hosts.old` and `vim/.netrwhist` are tracked but likely shouldn't be.
  - Consider documenting the `code export`/`code import` workflow more prominently.
  - The `VISUAL=3` env var in zshrc is unusual — document what `3` refers to or fix it.
  - Consider adding a `Makefile` or `justfile` for common operations (setup, export packages, update filters).
- Update the existing TODO section to reflect current state.