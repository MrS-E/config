{
  nixpkgs.config.allowUnfreePredicate = package:
    builtins.elem (package.pname or package.name) [
      "google-chrome"
      "jetbrains-toolbox"
      "lmstudio"
      "mqtt-explorer"
      "obsidian"
      "postman"
      "proxyman"
      "segger-jlink"
      "slack"
      "spotify"
    ];
  nixpkgs.config.segger-jlink.acceptLicense = true;
}
