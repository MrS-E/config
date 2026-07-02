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

- `ssh/config.d/dienstwerk` is gitignored, so the filter never touches it — it
  keeps whatever real paths are on disk (currently macOS).
- `providers.fedora` still holds `TODO_VERIFY_*` placeholders; until real Fedora
  paths are filled in, smudge on Linux would inject those literal `TODO_...`
  strings, which SSH would then fail to load. Verify on real hardware.
- The filter is `required`, so if `pkcs11-filter.sh` is missing or errors, git
  operations on `config.d/*` will fail loudly rather than corrupting content.

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