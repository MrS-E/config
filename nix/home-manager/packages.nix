{ config, lib, pkgs, betterMouse, figma, texifier, protonDrive, burpSuite, crealityPrint, prusaSlicer, protonMailBridge, raspberryPiImager, nordicNrfCommandLineTools, aflPlusPlus, mbpoll, adbEnhanced, zoteroPackage, ... }:
{
  home.stateVersion = "26.05";

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
      adbEnhanced
      pkgs.segger-jlink
      zoteroPackage
      pkgs.rectangle
    ];
}