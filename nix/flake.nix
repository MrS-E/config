{
  description = "macOS package profile managed with nix-darwin and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nextcloud-vfs.url = "path:../custom-flakes/nextcloud-vfs";
    bettermouse.url = "path:../custom-flakes/bettermouse";
    figma.url = "path:../custom-flakes/figma";
    texifier.url = "path:../custom-flakes/texifier";
    proton-drive.url = "path:../custom-flakes/proton-drive";
    burp-suite.url = "path:../custom-flakes/burp-suite";
    proton-mail-bridge.url = "path:../custom-flakes/proton-mail-bridge";
  };

  outputs = {
    nix-darwin,
    home-manager,
    nextcloud-vfs,
    bettermouse,
    figma,
    texifier,
    proton-drive,
    burp-suite,
    proton-mail-bridge,
    ...
  }:
    let
      system = "aarch64-darwin";
    in {
      packages.${system}.darwin-rebuild =
        nix-darwin.packages.${system}.darwin-rebuild;

      darwinConfigurations."aarch64-darwin" = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          home-manager.darwinModules.home-manager
          {
            nixpkgs.hostPlatform = system;
            nixpkgs.config.allowUnfreePredicate = package:
              builtins.elem (package.pname or package.name) [
                "google-chrome"
                "jetbrains-toolbox"
                "mqtt-explorer"
                "obsidian"
                "postman"
                "proxyman"
                "raycast"
                "slack"
                "spotify"
                "tailscale-gui"
              ];
            nix.settings.experimental-features = "nix-command flakes";
            # Don't forward macOS-specific LC_* values to remote hosts.
            programs.ssh.extraConfig = ''
              Host *
                SendEnv -LC_*
            '';
            ids.gids.nixbld = 350;
            system.stateVersion = 4;

            # Home Manager needs user metadata; leave this account out of users.knownUsers.
            users.users."simeon.stix" = {
              uid = 501;
              home = builtins.toPath "/Users/simeon.stix";
            };

            home-manager.useGlobalPkgs = true;
            home-manager.extraSpecialArgs = {
              betterMouse = bettermouse.packages.${system}.bettermouse;
              figma = figma.packages.${system}.figma;
              texifier = texifier.packages.${system}.texifier;
              protonDrive = proton-drive.packages.${system}.proton-drive;
              burpSuite = burp-suite.packages.${system}.burp-suite;
              protonMailBridge = proton-mail-bridge.packages.${system}.proton-mail-bridge;
            };
            home-manager.users."simeon.stix" = {
              imports = [
                ./home-manager/packages.nix
                nextcloud-vfs.homeManagerModules.default
              ];
              programs.nextcloud-vfs.enable = true;
              targets.darwin.copyApps.enable = false;
            };
          }
        ];
      };
    };
}