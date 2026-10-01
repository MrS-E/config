# Homebrew Brewfile to Nixpkgs audit

This document records the package-by-package comparison of the reduced `setup/macos/Brewfile` with Nixpkgs.

## Scope and method

- Audited on 2026-10-01 for `aarch64-darwin` (Apple Silicon), using the `nixpkgs` revision pinned in `nix/flake.lock`: `b6c8664de9b6cc07fe5666a29f91884ba81197c4`.
- Formulae were checked for attribute availability, `lib.meta.availableOn`, `meta.broken`, and derivation evaluation. Casks were checked for mapped attributes, target availability, and derivation evaluation.
- Metadata and derivation evaluation do **not** prove that every package builds or exactly replaces its Homebrew counterpart. Representative builds were run for `ripgrep` and `kitty`; the `kitty` output contains `Applications/kitty.app`.
- The VS Code extension inventory below is retained from the earlier catalog and was not rechecked against this pin; extensions are outside this migration.

| Brewfile entries | Total | Nixpkgs mappings | Current migration result |
|---|---:|---:|---:|
| Formulae | 60 | 57 | 55 usable; 2 unsupported; 3 without a usable mapping |
| Casks | 37 | 31 | 21 selected; 10 excluded or unusable; 6 without a mapping |
| VS Code extensions | 40 | Historical 21/19 catalog | Excluded from Nix |

## Found or mapped in Nixpkgs

### Formulae (57/60 mappings; 55 usable on `aarch64-darwin`)

- `apktool`; `automake`; `bat`; `biber`; `clamav`; `clang-format` → `clang-tools`; `cmake`; `coreutils`; `cppcheck`; `curl`; `dfu-util`; `direnv`; `dotnet` → `dotnet-sdk`; `fzf`; `gcc`; `git-lfs`; `gnuplot`; `go`; `gradle`; `grep` → `gnugrep`.
- `gstreamer` → `gst_all_1.gstreamer`; `imagemagick`; `ios-deploy`; `ktlint`; `lazygit`; `lftp`; `ltex-ls-plus`; `make` → `gnumake`; `mkcert`; `mysql-client` → `mariadb.client` (**MariaDB client, not Oracle MySQL**); `neovim`; `ninja`; `nmap`; `opensc`; `openssh`; `picocom`; `plantuml`.
- `podlet`; `podman-compose`; `qemu`; `ripgrep`; `scrcpy`; `sevenzip` → `_7zz`; `shellcheck`; `socat`; `starship`; `swiftlint`; `telnet` → `inetutils`; `tree`; `uv`; `wget`; `yarn`; `ykman` → `yubikey-manager`; `yubico-piv-tool`; `zlib`.

`afl++` → `aflplusplus` and `mbpoll` → `mbpoll` both have Nixpkgs attributes, but neither supports Darwin. The other retained formulae without a usable Nixpkgs mapping are listed below. The retained `gradle` attribute is version 8.14.4; `mariadb.client` is 11.4.12 and is not Oracle MySQL. The reduced Brewfile no longer contains the former version-pinned formulae or either FFmpeg entry.

### Casks (31/37 mappings; 21 selected)

- `android-platform-tools` → `android-tools` (**selected**); `burp-suite` → `burpsuite` (**not usable: its FHS environment pulls Linux-only glibc**); `figma` → `figma-linux` (**unofficial, Linux-only**); `firefox` (**selected**); `google-chrome` (**selected**); `imhex` (**selected**); `jetbrains-toolbox` (**selected**); `kitty` (**selected**).
- `mactex` → `texliveFull` (**selected; TeX Live, not the MacTeX GUI bundle**); `meshlab` (**selected**); `mqtt-explorer` (**selected**); `nextcloud-vfs` → `nextcloud-client` (**Linux-only; no macOS VFS equivalent**); `nordic-nrf-command-line-tools` → `nrf-command-line-tools` (**Linux-only**); `obsidian` (**selected**); `postman` (**selected**); `proton-mail-bridge` → `protonmail-bridge` (**selected**); `protonvpn` → `proton-vpn` (**selected**); `proxyman` (**selected**).
- `prusaslicer` → `prusa-slicer` (**excluded: its WebKitGTK dependency is marked broken**); `raspberry-pi-imager` → `rpi-imager` (**no Darwin support**); `raycast` (**selected**); `segger-jlink` (**excluded: Nix requires explicit acceptance of SEGGER's non-free license**); `segger-ozone` (**Linux-only**); `slack` (**selected**); `spotify` (**selected**); `tailscale-app` → `tailscale-gui` (**selected**); `thunderbird` (**selected**); `vlc` (**Linux-only**); `vscodium` (**available but explicitly excluded from this migration**); `wireshark-app` → `wireshark` (**selected**); `zotero` (**selected**).

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

### VS Code extensions (19/40)

- `ddorch.codium-devcontainer`; `dreamcatcher45.podmanager`; `efoerster.texlab`; `espressif.esp-idf-extension`; `hangxingliu.vscode-systemd-support`; `jeanp413.open-remote-ssh`; `jeff-hykin.better-shellscript-syntax`; `jeffersonqin.latex-snippets-jeff`; `lordimmaculate.platformio-ide`; `mjpvs.latex-previewer`.
- `phil294.git-log--graph`; `philosowaffle.openapi-designer`; `pinage404.bash-extension-pack`; `repreng.csv`; `rpinski.shebang-snippets`; `sndst00m.vscode-native-svg-preview`; `solomonkinard.compare-text`; `sr-team.clang-tidy-sr-team-fork`; `torn4dom4n.latex-support`.

Nixpkgs has `ms-vscode-remote.remote-ssh` as an alternative to `jeanp413.open-remote-ssh`; it is a different extension identifier.

## Migration notes

### Evaluated Home Manager profile

The inventory and selection counts above describe only entries in the reduced Brewfile. Evaluation of the `aarch64-darwin` Home Manager profile in `nix/flake.nix` includes all 55 usable formula mappings and 21 selected cask mappings from that inventory, plus four packages that are not in the reduced Brewfile:

- Formula additions declared in `nix/packages/common.nix`: `pkgconf`, `ffmpeg`, and `podman`.
- Cask addition declared in `nix/packages/aarch64-darwin.nix`: `openscad`.

The evaluated profile therefore contains 58 formula packages, 22 cask packages, and the three Zsh plugins; Home Manager's generated support entries are not included in those counts. The package declarations are intentionally left as-is; this audit distinguishes profile-only additions from Brewfile-derived replacements.

- The reduced Brewfile contains seven taps: `can1357/tap`, `finestructure/tap`, `grishka/grishka`, `homebrew-ffmpeg/ffmpeg`, `jetbrains/junie`, `jundot/omlx`, and `nikitabobko/tap`. Taps are package sources rather than package entries, so they are not included in the counts above; their other contents were not audited. The FFmpeg tap remains listed, but the reduced Brewfile has no FFmpeg formula entry.
- `nix/packages/common.nix` contains 57 formula packages (54 Brewfile-derived plus the three profile-only additions) and the three Nix-managed Zsh plugins; `darwin.nix` adds Brewfile-derived `ios-deploy`, for 58 formula packages total. `aarch64-darwin.nix` contains 21 Brewfile-selected casks plus profile-only `openscad`, for 22 casks total. The reduced Brewfile retains `podman-compose` but not `podman`; the evaluated Nix profile supplies the Podman CLI, though a machine/socket still needs to be configured and running. No Fedora or Intel Darwin output is defined.
- The locked Nixpkgs revision does not advertise `x86_64-darwin` as a supported system. Adding Intel macOS later will require a compatible Nixpkgs revision and a fresh platform audit; the architecture-specific module keeps that extension point separate.
- The Home Manager configuration allows unfree packages only by predicate for `google-chrome`, `jetbrains-toolbox`, `mqtt-explorer`, `obsidian`, `postman`, `proxyman`, `raycast`, `slack`, `spotify`, and `tailscale-gui`. No formulae are unfree.
- `burpsuite` cannot evaluate for Darwin because its FHS environment needs Linux `glibc`; `prusa-slicer` pulls a broken WebKitGTK dependency. Both remain manual/vendor exceptions. `segger-jlink` is excluded until its SEGGER license terms are explicitly accepted; no acceptance flag is set.
- The cask `vscodium`, its extensions/settings, and the un-audited tap contents are not added to Nix. The reduced Brewfile has no Node.js or `npm` formula entry; WaveForms remains in its independent vendor installer. The three Zsh plugins are Nixpkgs packages available on `aarch64-darwin` and are declared in the Home Manager profile; Fedora keeps its Git-based installation.
- Re-audit when updating `nix/flake.lock`; package names, versions, licenses, and platform support can change.