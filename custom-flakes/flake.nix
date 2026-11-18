{
  description = "Custom macOS Nix flakes bundle and Home Manager integration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nextcloud-vfs = {
      url = "path:./nextcloud-vfs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bettermouse = {
      url = "path:./bettermouse";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    figma = {
      url = "path:./figma";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    texifier = {
      url = "path:./texifier";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    proton-drive = {
      url = "path:./proton-drive";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    burp-suite = {
      url = "path:./burp-suite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    creality-print = {
      url = "path:./creality-print";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    proton-mail-bridge = {
      url = "path:./proton-mail-bridge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    raspberry-pi-imager = {
      url = "path:./raspberry-pi-imager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nordic-nrf-command-line-tools = {
      url = "path:./nordic-nrf-command-line-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aflplusplus = {
      url = "path:./aflplusplus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mbpoll = {
      url = "path:./mbpoll";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    adb-enhanced = {
      url = "path:./adb-enhanced";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zotero = {
      url = "path:./zotero";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    prusa-slicer = {
      url = "path:./prusa-slicer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nextcloud-vfs,
    bettermouse,
    figma,
    texifier,
    proton-drive,
    burp-suite,
    creality-print,
    proton-mail-bridge,
    raspberry-pi-imager,
    nordic-nrf-command-line-tools,
    aflplusplus,
    mbpoll,
    adb-enhanced,
    zotero,
    prusa-slicer,
    ...
  }:
    let
      system = "aarch64-darwin";
    in {
      packages.${system} = {
        bettermouse = bettermouse.packages.${system}.bettermouse;
        figma = figma.packages.${system}.figma;
        texifier = texifier.packages.${system}.texifier;
        proton-drive = proton-drive.packages.${system}.proton-drive;
        burp-suite = burp-suite.packages.${system}.burp-suite;
        creality-print = creality-print.packages.${system}.creality-print;
        proton-mail-bridge = proton-mail-bridge.packages.${system}.proton-mail-bridge;
        raspberry-pi-imager = raspberry-pi-imager.packages.${system}.raspberry-pi-imager;
        nordic-nrf-command-line-tools = nordic-nrf-command-line-tools.packages.${system}.nordic-nrf-command-line-tools;
        aflplusplus = aflplusplus.packages.${system}.aflplusplus;
        mbpoll = mbpoll.packages.${system}.mbpoll;
        adb-enhanced = adb-enhanced.packages.${system}.adb-enhanced;
        zotero = zotero.packages.${system}.zotero;
        prusa-slicer = prusa-slicer.packages.${system}.prusa-slicer;
      };

      darwinModules.default = {
        home-manager.sharedModules = [
          nextcloud-vfs.homeManagerModules.default
        ];
        home-manager.extraSpecialArgs.custom-flakes = self;
      };
    };
}
