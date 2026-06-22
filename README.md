# config

## Setup

### Repo

Git Filters:
```bash
git config filter.scrub-apikey.clean \
  "sed -E 's/(\"apiKey\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"/\\1\"REDACTED\"/'"
git config filter.scrub-apikey.smudge cat
git config filter.scrub-apikey.required true
```

## TODO

### Mac

- [x] setup script (untested)
- [x] neovim in setup
- [x] dependency install
- [x] dependency list
- [x] ssh config
- [x] git config
- [x] zsh config
- [x] vim config
- [x] terminal config (ghostty)
- [x] vscode(ium) config
- [x] neovim

### Linux

#### Fedora

- [x] setup script (untested)
- [x] dependency install
- [x] dependency list
- [x] ssh config
- [x] git config
- [x] zsh config
- [x] vim config
- [ ] terminal config
- [x] vscode(ium) config
- [ ] ufw (firewall) and clamav config / firewalld
- [x] neovim config

#### Fedora Atomic (Untested)

- [x] setup script (untested)
- [x] dependency install
- [x] dependency list
- [x] ssh config
- [x] git config
- [x] zsh config
- [x] vim config
- [ ] terminal config
- [x] vscode(ium) config
- [ ] ufw (firewall) and clamav config / firewalld
- [x] neovim config

#### Manjaro (Untested)

- [x] setup script (untested)
- [x] dependency install
- [x] dependency list
- [x] ssh config
- [x] git config
- [x] zsh config
- [x] vim config
- [ ] terminal config
- [x] vscode(ium) config
- [ ] ufw (firewall) and clamav config / firewalld
- [x] neovim config