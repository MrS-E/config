let
  system = "aarch64-darwin";
  baseNames = [
    "android-tools" "firefox" "google-chrome" "imhex" "jetbrains-toolbox"
    "kitty" "texliveFull" "meshlab" "mqtt-explorer" "obsidian" "openscad"
    "postman" "proton-pass" "protonmail-bridge" "proton-vpn" "proxyman"
    "slack" "spotify" "thunderbird" "wireshark" "vscodium"
  ];
  customNames = [
    "bettermouse" "figma" "texifier" "proton-drive" "burp-suite"
    "creality-print" "prusa-slicer" "proton-mail-bridge" "raspberry-pi-imager"
    "nordic-nrf-command-line-tools" "aflplusplus" "mbpoll" "adb-enhanced"
    "zotero"
  ];
  named = prefix: names: builtins.listToAttrs (map (name: {
    inherit name;
    value = prefix + name;
  }) names);
  pkgs = (named "pkgs:" (baseNames ++ [ "segger-jlink" "rectangle" ])) // {
    stdenv.hostPlatform.system = system;
  };
  custom-flakes.packages.${system} = named "custom:" customNames;
  sstix-tools = named "sstix:" [ "git-clone-remote" "project" "nixvm" ];
  home = import ../nix/home-manager/packages.nix {
    inherit pkgs custom-flakes sstix-tools;
    config = {};
    lib = {};
  };
  expected =
    map (name: "pkgs:" + name) baseNames
    ++ map (name: "custom:" + name) (builtins.genList (i: builtins.elemAt customNames i) 13)
    ++ [ "pkgs:segger-jlink" "custom:zotero" "sstix:git-clone-remote" "sstix:project" "sstix:nixvm" "pkgs:rectangle" ];
  packages = home.home.packages;
  offset = builtins.length packages - builtins.length expected;
  actual = builtins.genList (i: builtins.elemAt packages (offset + i)) (builtins.length expected);
in
assert home.programs.nextcloud-vfs.enable;
assert actual == expected;
true