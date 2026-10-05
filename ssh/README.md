# SSH Configuration

`config` is the SSH entry point and includes `~/.ssh/config.d/*`. The general
SSH configuration and host-specific files are kept in this directory; the
setup symlink step links it to `~/.ssh`.

## Portable PKCS#11 Provider Paths

Git clean/smudge filters make the PKCS#11 provider paths portable across
platforms. `.gitattributes` applies the `pkcs11-provider` filter to
`ssh/config.d/*`, and `setup/general/02-git-filters.sh` registers the filter
for the repository. Run that setup step once per clone before working with
filtered SSH files:

```bash
./setup.sh --only general/02-git-filters.sh
```

The `clean` filter replaces known provider paths with `@YKCS11@` and
`@OPENSC@` tokens in committed content. The `smudge` filter expands those
tokens using the provider table for the current platform. The tables are
`providers.mac` and `providers.fedora`; update them when provider locations
change rather than duplicating host entries.

Current provider values are:

| Platform | `YKCS11` | `OPENSC` |
|---|---|---|
| macOS | `/opt/homebrew/lib/libykcs11.dylib` | `/opt/homebrew/lib/opensc-pkcs11.so` |
| Fedora | `/usr/lib64/pkcs11/opensc-pkcs11.so` | `/usr/lib64/pkcs11/opensc-pkcs11.so` |

The filter is required by Git, so Git operations on the filtered files fail
rather than silently skipping it if the filter is unavailable.