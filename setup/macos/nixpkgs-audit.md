# Homebrew Brewfile to Nixpkgs audit

This document records the package-by-package comparison of `setup/macos/Brewfile` with Nixpkgs.

## Scope and method

- Audited on 2026-10-01 for `aarch64-darwin` (Apple Silicon).
- Used the locally resolved `nixpkgs` flake, fingerprint `4d0edca337b3a7b807b53c82a3fcb416785e1e5b813df01285d553539e0ec675`.
- A match means a Nixpkgs package attribute or a clear package mapping was found. It does **not** guarantee that the package builds on this platform or fully replaces the Homebrew package; platform and equivalence caveats are marked below.
- The audit checked Nixpkgs metadata and attribute availability, not actual installs or builds.

| Brewfile entries | Total | Found or mapped | No match found |
|---|---:|---:|---:|
| Formulae | 105 | 100 | 5 |
| Casks | 41 | 35 | 6 |
| VS Code extensions | 40 | 21 | 19 |

## Found or mapped in Nixpkgs

### Formulae (100/105)

- `openssl@3` → `openssl_3_6`; `llvm`; `afl++` → `aflplusplus` (**Linux-only**); `glib`; `pixman`; `libtiff`; `apktool`; `autoconf`; `automake`; `bat`; `biber`; `ccache`; `clamav`; `clang-format` → `clang-tools`; `cmake`; `libyaml`; `cocoapods`; `coreutils`; `cppcheck`; `curl`.
- `libusb` → `libusb1`; `dfu-util`; `direnv`; `dotnet` → `dotnet-sdk`; `fzf`; `gcc`; `git-lfs`; `libgcrypt`; `libksba`; `gnupg`; `gnuplot`; `go`; `pkgconf`; `gobject-introspection`; `gradle`; `openjdk@21` → `openjdk21`; `gradle@8` → `gradle_8`; `libtool`; `graphviz`; `grep` → `gnugrep`.
- `sdl2-compat`; `ffmpeg`; `pygobject3` → `python3Packages.pygobject3`; `gstreamer` → `gst_all_1.gstreamer`; `icu4c@76` → `icu76`; `icu4c@77` → `icu77`; `imagemagick`; `ios-deploy`; `ktlint`; `lazygit`; `lftp`; `libpq`; `libslirp`; `ltex-ls-plus`; `make` → `gnumake`; `mbpoll` (**Linux-only**); `mkcert`; `mosquitto`; `mysql-client` → `mariadb.client` (Nixpkgs also has `mysql84`); `neovim`.
- `ninja`; `nmap`; `node` → `nodejs`; `node@24` → `nodejs_24`; `nss`; `openjdk@17` → `openjdk17`; `opensc`; `openssh`; `picocom`; `plantuml`; `podlet`; `podman`; `podman-compose`; `pulseaudio`; `python@3.13` → `python313`; `qemu`; `ripgrep`; `ruby@3.3` → `ruby_3_3`; `scrcpy`; `sevenzip` → `_7zz`.
- `shc`; `shellcheck`; `skopeo`; `socat`; `sound-touch` → `soundtouch`; `starship`; `swiftlint`; `tailscale`; `telnet` → `inetutils`; `tree`; `uv`; `wget`; `yarn`; `ykman` → `yubikey-manager`; `yubico-piv-tool`; `zlib`; `zsh-autocomplete`; `zsh-autosuggestions`; `zsh-syntax-highlighting`; `homebrew-ffmpeg/ffmpeg/ffmpeg` → `ffmpeg`.

### Casks (35/41)

- `android-platform-tools` → `android-tools`; `arduino-ide` (**Linux-only**); `burp-suite` → `burpsuite`; `figma` → `figma-linux` (**unofficial, Linux-only**); `firefox`; `freecad` (**no Darwin support**); `google-chrome`; `imhex`; `jetbrains-toolbox`; `kitty`.
- `mactex` → `texliveFull` (TeX Live, not the MacTeX GUI bundle); `meshlab`; `mqtt-explorer`; `nextcloud-vfs` → `nextcloud-client` (**Linux-only; no macOS VFS equivalent**); `nordic-nrf-command-line-tools` (**Linux-only**); `obsidian`; `openscad`; `postman`; `proton-mail-bridge` → `protonmail-bridge`; `protonvpn` → `proton-vpn`.
- `proxyman`; `prusaslicer` → `prusa-slicer`; `raspberry-pi-imager` → `rpi-imager`; `raycast`; `segger-jlink`; `segger-ozone` (**Linux-only**); `slack`; `spotify`; `tailscale-app` → `tailscale-gui`; `temurin@8` → `temurin-bin-8` (**Intel macOS only**).
- `thunderbird`; `vlc` (**Linux-only**); `vscodium`; `wireshark-app` → `wireshark`; `zotero`.

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
- The custom FFmpeg formula requests `with-webp` and `with-xvid`. The Nixpkgs `ffmpeg` mapping does not by itself confirm those build options are enabled.
- Treat the Linux-only, unsupported-Darwin, and Intel-only entries as **not usable replacements on this Apple Silicon Mac**, even though a Nixpkgs package attribute exists.
- Re-run the comparison against the intended pinned Nixpkgs revision before migrating; package names, versions, and platform support can change.