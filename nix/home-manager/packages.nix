{ config, lib, pkgs, betterMouse, figma, texifier, protonDrive, burpSuite, crealityPrint, protonMailBridge, raspberryPiImager, nordicNrfCommandLineTools, aflPlusPlus, mbpoll, zoteroPackage, ... }:
{
  home.stateVersion = "26.05";
  targets.darwin.linkApps.enable = true;
  home.file."Applications/Home Manager Apps".source = lib.mkForce "${pkgs.buildEnv {
    name = "home-manager-applications-zotero";
    paths = config.home.packages;
    pathsToLink = [ "/Applications" ];
  }}/Applications";

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
      protonMailBridge
      raspberryPiImager
      nordicNrfCommandLineTools
      aflPlusPlus
      mbpoll
      pkgs.segger-jlink
      zoteroPackage
    ];
}