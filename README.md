# config

## Setup

### Repo

Git Filters (run once after cloning):
```bash
./setup.git-filters.sh
```

This configures two clean/smudge filters:
- `scrub-apikey` — redacts API keys in `junie/models/*.json` on commit
- `pkcs11-provider` — tokenizes PKCS#11 provider paths in `ssh/config.d/*` on
  commit (`@YKCS11@`, `@OPENSC@`) and resolves them to the current platform's
  real paths on checkout. Provider paths are defined in `ssh/providers.mac` and
  `ssh/providers.fedora`.

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