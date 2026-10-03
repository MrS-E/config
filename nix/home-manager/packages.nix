{ config, lib, pkgs, betterMouse, figma, texifier, protonDrive, burpSuite, crealityPrint, prusaSlicer, protonMailBridge, raspberryPiImager, nordicNrfCommandLineTools, aflPlusPlus, mbpoll, zoteroPackage, ... }:
{
  home.stateVersion = "26.05";
  targets.darwin.linkApps.enable = true;
  home.file."Applications/Home Manager Apps".source = lib.mkForce "${pkgs.buildEnv {
    name = "home-manager-applications-zotero";
    paths = config.home.packages;
    pathsToLink = [ "/Applications" ];
  }}/Applications";
  home.activation.registerHomeManagerApps = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    apps_dir="$HOME/Applications/Home Manager Apps"
    lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

    if [ -d "$apps_dir" ]; then
      ${pkgs.findutils}/bin/find -L "$apps_dir" -mindepth 1 -maxdepth 1 -type d -name '*.app' \
        -exec "$lsregister" -f {} \;
    fi
  '';

  home.packages =
    (import ../packages/common.nix { inherit pkgs; })
    ++ (import ../packages/darwin.nix { inherit pkgs; })
    ++ (import ../packages/aarch64-darwin.nix { inherit pkgs; })
    ++ [
      betterMouse
      figma
      texifier
      protonDrive
      burpSuite
      crealityPrint
      prusaSlicer
      protonMailBridge
      raspberryPiImager
      nordicNrfCommandLineTools
      aflPlusPlus
      mbpoll
      pkgs.segger-jlink
      zoteroPackage
    ];
}