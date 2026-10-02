# Homebrew Inventory to Nixpkgs Audit

This document records the package-by-package audit of the reduced Homebrew
inventory against Nixpkgs. No source `setup/macos/Brewfile` is maintained; the
counts below are historical audit data and are not consumed by setup.

## Scope and method

- Audited on 2026-10-01 for `aarch64-darwin` (Apple Silicon), using the `nixpkgs` revision pinned in `nix/flake.lock`: `b6c8664de9b6cc07fe5666a29f91884ba81197c4`.
- Formulae were checked for attribute availability, `lib.meta.availableOn`, `meta.broken`, and derivation evaluation. Casks were checked for mapped attributes, target availability, and derivation evaluation.
- Metadata and derivation evaluation do **not** prove that every package builds or exactly replaces its Homebrew counterpart. Representative builds were run for `ripgrep` and `kitty`; the `kitty` output contains `Applications/kitty.app`.
- The VS Code extension inventory below is retained from the earlier catalog and was not rechecked against this pin; extensions are outside this migration.

| Audited inventory entries | Total | Nixpkgs mappings | Current migration result |
|---|---:|---:|---:|
| Formulae | 60 | 57 | 54 installed directly; `biber` supplied by `texliveFull`; 2 unsupported; 3 without a usable mapping |
| Casks | 37 | 31 | 20 Nixpkgs-selected; 4 Homebrew-managed exceptions; 10 other mapped entries excluded or unusable; 3 unmapped and unselected |
| VS Code extensions | 40 | Historical 21/19 catalog | Excluded from Nix |

## Found or mapped in Nixpkgs

### Formulae (57/60 mappings; 55 usable on `aarch64-darwin`)

- `apktool`; `automake`; `bat`; `biber`; `clamav`; `clang-format` → `clang-tools`; `cmake`; `coreutils`; `cppcheck`; `curl`; `dfu-util`; `direnv`; `dotnet` → `dotnet-sdk`; `fzf`; `gcc`; `git-lfs`; `gnuplot`; `go`; `gradle`; `grep` → `gnugrep`.
- `gstreamer` → `gst_all_1.gstreamer`; `imagemagick`; `ios-deploy`; `ktlint`; `lazygit`; `lftp`; `ltex-ls-plus`; `make` → `gnumake`; `mkcert`; `mysql-client` → `mariadb.client` (**MariaDB client, not Oracle MySQL**); `neovim`; `ninja`; `nmap`; `opensc`; `openssh`; `picocom`; `plantuml`.
- `podlet`; `podman-compose`; `qemu`; `ripgrep`; `scrcpy`; `sevenzip` → `_7zz`; `shellcheck`; `socat`; `starship`; `swiftlint`; `telnet` → `inetutils`; `tree`; `uv`; `wget`; `yarn`; `ykman` → `yubikey-manager`; `yubico-piv-tool`; `zlib`.

`afl++` → `aflplusplus` and `mbpoll` → `mbpoll` both have Nixpkgs attributes, but neither supports Darwin. The other retained formulae without a usable Nixpkgs mapping are listed below. The retained `gradle` attribute is version 8.14.4; `mariadb.client` is 11.4.12 and is not Oracle MySQL. The audited reduced inventory omitted the former version-pinned formulae and both FFmpeg entries. The standalone `biber` package is omitted from Home Manager because the selected `texliveFull` package already provides `bin/biber`; including both causes a conflicting-subpath failure while building `home-manager-path`.

### Casks (31/37 Nixpkgs mappings; 20 selected from Nixpkgs)

- `android-platform-tools` → `android-tools` (**selected**); `burp-suite` → `burpsuite` (**not usable: its FHS environment pulls Linux-only glibc**); `figma` → `figma-linux` (**unofficial, Linux-only**); `firefox` (**selected**); `google-chrome` (**selected**); `imhex` (**selected**); `jetbrains-toolbox` (**selected**); `kitty` (**selected**).
- `mactex` → `texliveFull` (**selected; TeX Live, not the MacTeX GUI bundle**); `meshlab` (**selected**); `mqtt-explorer` (**selected**); `nextcloud-vfs` → `nextcloud-client` (**Linux-only; no macOS VFS equivalent; Homebrew-managed exception**); `nordic-nrf-command-line-tools` → `nrf-command-line-tools` (**Linux-only**); `obsidian` (**selected**); `postman` (**selected**); `proton-mail-bridge` → `protonmail-bridge` (**selected**); `protonvpn` → `proton-vpn` (**selected**); `proxyman` (**selected**).
- `prusaslicer` → `prusa-slicer` (**excluded: its WebKitGTK dependency is marked broken**); `raspberry-pi-imager` → `rpi-imager` (**no Darwin support**); `raycast` (**selected**); `segger-jlink` (**excluded: Nix requires explicit acceptance of SEGGER's non-free license**); `segger-ozone` (**Linux-only**); `slack` (**selected**); `spotify` (**selected**); `tailscale-app` → `tailscale-gui` (**selected**); `thunderbird` (**selected**); `vlc` (**Linux-only**); `vscodium` (**available but explicitly excluded from this migration**); `wireshark-app` → `wireshark` (**selected**); `zotero` (**available but temporarily excluded: the pinned `10.0.2` build fails its `AboutTranslations` source check**).

### VS Code extensions (21/40)

- `anweber.vscode-httpyac`; `davidanson.vscode-markdownlint`; `esbenp.prettier-vscode`; `foxundermoon.shell-format`; `james-yu.latex-workshop`; `jebbs.plantuml`; `llvm-vs-code-extensions.vscode-clangd`.
- `ltex-plus.vscode-ltex-plus`; `mads-hartmann.bash-ide-vscode`; `ms-azuretools.vscode-containers`; `ms-azuretools.vscode-docker`; `ms-python.python`; `ms-python.vscode-python-envs`; `ms-vscode.cmake-tools`.
- `ms-vscode.hexeditor`; `redhat.vscode-xml`; `shd101wyy.markdown-preview-enhanced`; `tecosaur.latex-utilities`; `timonwong.shellcheck`; `waderyan.gitblame`; `yzhang.markdown-all-in-one`.

## No package mapping found in Nixpkgs

### Formulae (3/60)

- `adb-enhanced` — Nixpkgs has standard ADB through `android-tools`, but not this enhanced tool.
- `cmake-docs` — no separate package attribute was found; `cmake` itself is available.
- `kin`.

### Casks (6/37)

- `bettermouse`; `creality-print`; `diffmerge`; `macdroid`; `proton-drive`; `texifier`.

The Homebrew-managed exceptions without a usable macOS Nixpkgs replacement are
`macdroid`, `nextcloud-vfs`, `proton-drive`, and `bettermouse`. `macdroid`,
`proton-drive`, and `bettermouse` have no Nixpkgs attribute mapping;
`nextcloud-vfs` maps only to the Linux-only `nextcloud-client`. The repository
declares these four under `homebrew.casks` in `nix/flake.nix`; setup bootstraps
Homebrew if needed before activating that flake, and nix-darwin applies the
declared casks. The remaining unmapped casks, `creality-print`, `diffmerge`,
and `texifier`, are unselected.

### VS Code extensions (19/40)

- `ddorch.codium-devcontainer`; `dreamcatcher45.podmanager`; `efoerster.texlab`; `espressif.esp-idf-extension`; `hangxingliu.vscode-systemd-support`; `jeanp413.open-remote-ssh`; `jeff-hykin.better-shellscript-syntax`; `jeffersonqin.latex-snippets-jeff`; `lordimmaculate.platformio-ide`; `mjpvs.latex-previewer`.
- `phil294.git-log--graph`; `philosowaffle.openapi-designer`; `pinage404.bash-extension-pack`; `repreng.csv`; `rpinski.shebang-snippets`; `sndst00m.vscode-native-svg-preview`; `solomonkinard.compare-text`; `sr-team.clang-tidy-sr-team-fork`; `torn4dom4n.latex-support`.

Nixpkgs has `ms-vscode-remote.remote-ssh` as an alternative to `jeanp413.open-remote-ssh`; it is a different extension identifier.

## Migration notes

### Evaluated Home Manager profile

The inventory and selection counts above describe only the former reduced Homebrew inventory audited here. The evaluated `aarch64-darwin` Home Manager profile includes 54 usable formula packages directly; the remaining usable formula, `biber`, is provided by the selected `texliveFull` package. The Nixpkgs-managed profile includes 20 selected cask replacements from that inventory. Separately, `nix/flake.nix` declares the four Homebrew-managed exceptions listed above. The architecture-specific Nixpkgs Darwin module declares 23 package entries: those 20 replacements plus `openscad`, `proton-pass`, and `vscodium`. `proton-pass` is not in the audited inventory, and `vscodium` remains declared despite being explicitly excluded from this migration.

- Formula additions declared in `nix/packages/common.nix`: `pkgconf`, `ffmpeg`, and `podman`.
- Other Darwin package declarations: `openscad` and `proton-pass` are not in the audited inventory; `vscodium` is in that inventory but is currently present in the module despite its exclusion.

The evaluated Nixpkgs profile therefore contains 57 formula packages, 23 Darwin package entries, and the three Zsh plugins; Home Manager's generated support entries and the four separate Homebrew casks are not included in those counts. Zotero is temporarily omitted because the pinned `10.0.2` build fails to find its expected `AboutTranslations` block in `ActorManagerParent.sys.mjs`. Burp Suite is omitted because its pinned Nixpkgs package is not usable on Darwin. This audit distinguishes profile-only additions from inventory-derived replacements.

- The audited inventory listed seven taps: `can1357/tap`, `finestructure/tap`, `grishka/grishka`, `homebrew-ffmpeg/ffmpeg`, `jetbrains/junie`, `jundot/omlx`, and `nikitabobko/tap`. Taps are package sources rather than package entries, so they are not included in the counts above; their other contents were not audited. The historical inventory listed the FFmpeg tap but no FFmpeg formula entry.
- `nix/packages/common.nix` contains 56 formula packages (53 inventory-derived plus the three profile-only additions) and the three Nix-managed Zsh plugins; `darwin.nix` adds inventory-derived `ios-deploy`, for 57 formula packages total. `aarch64-darwin.nix` currently contains 23 Nixpkgs package entries: 20 selected cask replacements plus `openscad`, `proton-pass`, and `vscodium`; the four Homebrew casks are declared separately in `nix/flake.nix`. The former inventory included `podman-compose` but not `podman`; the evaluated Nix profile supplies the Podman CLI, though a machine/socket still needs to be configured and running. No Fedora or Intel Darwin output is defined.
- The locked Nixpkgs revision does not advertise `x86_64-darwin` as a supported system. Adding Intel macOS later will require a compatible Nixpkgs revision and a fresh platform audit; the architecture-specific module keeps that extension point separate.
- The Home Manager configuration allows unfree packages only by predicate for `google-chrome`, `jetbrains-toolbox`, `mqtt-explorer`, `obsidian`, `postman`, `proxyman`, `raycast`, `slack`, `spotify`, and `tailscale-gui`. No formulae are unfree.
- `burpsuite` cannot evaluate for Darwin because its FHS environment needs Linux `glibc`; it was removed from the Home Manager profile rather than added to the unfree-package predicate. `prusa-slicer` pulls a broken WebKitGTK dependency. Both remain manual/vendor exceptions. `segger-jlink` is excluded until its SEGGER license terms are explicitly accepted; no acceptance flag is set.
- VSCodium and its extensions/settings remain outside the intended migration, but `vscodium` is currently still declared in the Darwin package module and should be removed if that entry was not intentional. Un-audited tap contents are not added to Nix. The audited inventory had no Node.js or `npm` formula entry; WaveForms remains in its independent vendor installer. The three Zsh plugins are Nixpkgs packages available on `aarch64-darwin` and are declared in the Home Manager profile; Fedora keeps its Git-based installation.
- Re-audit when updating `nix/flake.lock`; package names, versions, licenses, and platform support can change.