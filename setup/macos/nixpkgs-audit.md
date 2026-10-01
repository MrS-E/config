# Homebrew Brewfile to Nixpkgs audit

This document records the package-by-package comparison of `setup/macos/Brewfile` with Nixpkgs.

## Scope and method

- Audited on 2026-10-01 for `aarch64-darwin` (Apple Silicon), using the `nixpkgs` revision pinned in `nix/flake.lock`: `b6c8664de9b6cc07fe5666a29f91884ba81197c4`.
- Formulae were checked for attribute availability, `lib.meta.availableOn`, `meta.broken`, and derivation evaluation. Casks were checked for mapped attributes, target availability, and derivation evaluation.
- Metadata and derivation evaluation do **not** prove that every package builds or exactly replaces its Homebrew counterpart. Representative builds were run for `ripgrep` and `kitty`; the `kitty` output contains `Applications/kitty.app`.
- The VS Code extension inventory below is retained from the earlier catalog and was not rechecked against this pin; extensions are outside this migration.

| Brewfile entries | Total | Nixpkgs mappings | Current migration result |
|---|---:|---:|---:|
| Formulae | 105 | 100 | 98 usable; 2 unsupported; 5 without a usable mapping |
| Casks | 41 | 35 | 22 selected; 13 excluded or unusable; 6 without a mapping |
| VS Code extensions | 40 | Historical 21/19 catalog | Excluded from Nix |

## Found or mapped in Nixpkgs

### Formulae (100/105 mappings; 98 usable on `aarch64-darwin`)

- `openssl@3` → `openssl_3_6`; `llvm`; `afl++` → `aflplusplus` (**not Darwin-available**); `glib`; `pixman`; `libtiff`; `apktool`; `autoconf`; `automake`; `bat`; `biber`; `ccache`; `clamav`; `clang-format` → `clang-tools`; `cmake`; `libyaml`; `cocoapods`; `coreutils`; `cppcheck`; `curl`.
- `libusb` → `libusb1`; `dfu-util`; `direnv`; `dotnet` → `dotnet-sdk`; `fzf`; `gcc`; `git-lfs`; `libgcrypt`; `libksba`; `gnupg`; `gnuplot`; `go`; `pkgconf`; `gobject-introspection`; `gradle`; `openjdk@21` → `openjdk21`; `gradle@8` → `gradle_8`; `libtool`; `graphviz`; `grep` → `gnugrep`.
- `sdl2-compat`; `ffmpeg`; `pygobject3` → `python3Packages.pygobject3`; `gstreamer` → `gst_all_1.gstreamer`; `icu4c@76` → `icu76`; `icu4c@77` → `icu77`; `imagemagick`; `ios-deploy`; `ktlint`; `lazygit`; `lftp`; `libpq`; `libslirp`; `ltex-ls-plus`; `make` → `gnumake`; `mbpoll` (**not Darwin-available**); `mkcert`; `mosquitto`; `mysql-client` → `mariadb.client` (**MariaDB client, not Oracle MySQL**); `neovim`.
- `ninja`; `nmap`; `node` → `nodejs`; `node@24` → `nodejs_24`; `nss`; `openjdk@17` → `openjdk17`; `opensc`; `openssh`; `picocom`; `plantuml`; `podlet`; `podman`; `podman-compose`; `pulseaudio`; `python@3.13` → `python313`; `qemu`; `ripgrep`; `ruby@3.3` → `ruby_3_3`; `scrcpy`; `sevenzip` → `_7zz`.
- `shc`; `shellcheck`; `skopeo`; `socat`; `sound-touch` → `soundtouch`; `starship`; `swiftlint`; `tailscale`; `telnet` → `inetutils`; `tree`; `uv`; `wget`; `yarn`; `ykman` → `yubikey-manager`; `yubico-piv-tool`; `zlib`; `zsh-autocomplete`; `zsh-autosuggestions`; `zsh-syntax-highlighting`; `homebrew-ffmpeg/ffmpeg/ffmpeg` → `ffmpeg`.

Pinned versions for the versioned formulae: `openssl_3_6` 3.6.4; `icu76`/`icu77` 76.1/77.1; `gradle`/`gradle_8` 8.14.4; `openjdk17`/`openjdk21` 17.0.19/21.0.11; `nodejs`/`nodejs_24` 24.21.0; `python313` 3.13.15; and `ruby_3_3` 3.3.10. The default and versioned `gradle` and `nodejs` attributes resolve to identical derivations on this pin, so each is included once in the Home Manager profile.

Nixpkgs `ffmpeg` 9.0.1 already enables both `with-webp` and `with-xvid` equivalents (`withWebp` and `withXvid`); no override is needed. The two Brew FFmpeg entries map to this one Nix derivation.

### Casks (35/41 mappings; 22 selected)

- `android-platform-tools` → `android-tools` (**selected**); `arduino-ide` (**Linux-only**); `burp-suite` → `burpsuite` (**not usable: its FHS environment pulls Linux-only glibc**); `figma` → `figma-linux` (**unofficial, Linux-only**); `firefox` (**selected**); `freecad` (**no Darwin support**); `google-chrome` (**selected**); `imhex` (**selected**); `jetbrains-toolbox` (**selected**); `kitty` (**selected**).
- `mactex` → `texliveFull` (**selected; TeX Live, not the MacTeX GUI bundle**); `meshlab` (**selected**); `mqtt-explorer` (**selected**); `nextcloud-vfs` → `nextcloud-client` (**Linux-only; no macOS VFS equivalent**); `nordic-nrf-command-line-tools` → `nrf-command-line-tools` (**Linux-only**); `obsidian` (**selected**); `openscad` (**selected**); `postman` (**selected**); `proton-mail-bridge` → `protonmail-bridge` (**selected**); `protonvpn` → `proton-vpn` (**selected**).
- `proxyman` (**selected**); `prusaslicer` → `prusa-slicer` (**excluded: its WebKitGTK dependency is marked broken**); `raspberry-pi-imager` → `rpi-imager` (**no Darwin support**); `raycast` (**selected**); `segger-jlink` (**excluded: Nix requires explicit acceptance of SEGGER's non-free license**); `segger-ozone` (**Linux-only**); `slack` (**selected**); `spotify` (**selected**); `tailscale-app` → `tailscale-gui` (**selected**); `temurin@8` → `temurin-bin-8` (**Intel macOS only**).
- `thunderbird` (**selected**); `vlc` (**Linux-only**); `vscodium` (**available but explicitly excluded from this migration**); `wireshark-app` → `wireshark` (**selected**); `zotero` (**selected**).

### VS Code extensions (21/40)

- `anweber.vscode-httpyac`; `davidanson.vscode-markdownlint`; `esbenp.prettier-vscode`; `foxundermoon.shell-format`; `james-yu.latex-workshop`; `jebbs.plantuml`; `llvm-vs-code-extensions.vscode-clangd`.
- `ltex-plus.vscode-ltex-plus`; `mads-hartmann.bash-ide-vscode`; `ms-azuretools.vscode-containers`; `ms-azuretools.vscode-docker`; `ms-python.python`; `ms-python.vscode-python-envs`; `ms-vscode.cmake-tools`.
- `ms-vscode.hexeditor`; `redhat.vscode-xml`; `shd101wyy.markdown-preview-enhanced`; `tecosaur.latex-utilities`; `timonwong.shellcheck`; `waderyan.gitblame`; `yzhang.markdown-all-in-one`.

## No package mapping found in Nixpkgs

### Formulae (5/105)

- `adb-enhanced` — Nixpkgs has standard ADB through `android-tools`, but not this enhanced tool.
- `cmake-docs` — no separate package attribute was found; `cmake` itself is available.
- `kin`.
- `openssl@1.1` — removed from Nixpkgs as end-of-life.
- `thefuck` — removed from Nixpkgs due to maintenance and Python compatibility issues; `pay-respects` is an alternative, not an identical replacement.

### Casks (6/41)

- `bettermouse`; `creality-print`; `diffmerge`; `macdroid`; `proton-drive`; `texifier`.

### VS Code extensions (19/40)

- `ddorch.codium-devcontainer`; `dreamcatcher45.podmanager`; `efoerster.texlab`; `espressif.esp-idf-extension`; `hangxingliu.vscode-systemd-support`; `jeanp413.open-remote-ssh`; `jeff-hykin.better-shellscript-syntax`; `jeffersonqin.latex-snippets-jeff`; `lordimmaculate.platformio-ide`; `mjpvs.latex-previewer`.
- `phil294.git-log--graph`; `philosowaffle.openapi-designer`; `pinage404.bash-extension-pack`; `repreng.csv`; `rpinski.shebang-snippets`; `sndst00m.vscode-native-svg-preview`; `solomonkinard.compare-text`; `sr-team.clang-tidy-sr-team-fork`; `torn4dom4n.latex-support`.

Nixpkgs has `ms-vscode-remote.remote-ssh` as an alternative to `jeanp413.open-remote-ssh`; it is a different extension identifier.

## Migration notes

- The Brewfile contains seven taps: `can1357/tap`, `finestructure/tap`, `grishka/grishka`, `homebrew-ffmpeg/ffmpeg`, `jetbrains/junie`, `jundot/omlx`, and `nikitabobko/tap`. Taps are package sources rather than package entries, so they are not included in the counts above; their other contents were not audited.
- `nix/packages/common.nix` represents the 95 portable formula mappings with 93 distinct package declarations; `gradle_8` and `nodejs_24` resolve to the same derivations as their defaults, and duplicate Brew FFmpeg entries are collapsed. `darwin.nix` adds Darwin-only `cocoapods` and `ios-deploy`; `aarch64-darwin.nix` contains the 22 selected cask replacements. No Fedora or Intel Darwin output is defined.
- The locked Nixpkgs revision does not advertise `x86_64-darwin` as a supported system. Adding Intel macOS later will require a compatible Nixpkgs revision and a fresh platform audit; the architecture-specific module keeps that extension point separate.
- The Home Manager configuration allows unfree packages only by predicate for `google-chrome`, `jetbrains-toolbox`, `mqtt-explorer`, `obsidian`, `postman`, `proxyman`, `raycast`, `slack`, `spotify`, and `tailscale-gui`. No formulae are unfree.
- `burpsuite` cannot evaluate for Darwin because its FHS environment needs Linux `glibc`; `prusa-slicer` pulls a broken WebKitGTK dependency. Both remain manual/vendor exceptions. `segger-jlink` is excluded until its SEGGER license terms are explicitly accepted; no acceptance flag is set.
- The cask `vscodium`, its extensions/settings, and the un-audited tap contents are not added to Nix. The Brewfile has no standalone `npm` entry; npm remains bundled with the selected Node.js packages. WaveForms remains in its independent vendor installer.
- Re-audit when updating `nix/flake.lock`; package names, versions, licenses, and platform support can change.