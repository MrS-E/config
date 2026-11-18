{
  description = "macOS package profile managed with nix-darwin and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    sstix-tools = {
      url = "github:sstix-tools/registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    custom-flakes = {
      url = "path:../custom-flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nix-darwin,
    home-manager,
    mac-app-util,
    custom-flakes,
    sstix-tools,
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
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          custom-flakes.darwinModules.default
          ./packages/unfree.nix
          {
            nixpkgs.hostPlatform = system;
            nix.registry.sstix-tools = {
              from = {
                id = "sstix-tools";
                type = "indirect";
              };
              to = {
                owner = "sstix-tools";
                repo = "registry";
                type = "github";
              };
            };
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

            home-manager.sharedModules = [
              mac-app-util.homeManagerModules.default
            ];
            home-manager.useGlobalPkgs = true;
            home-manager.extraSpecialArgs = {
              sstix-tools = sstix-tools.packages.${system};
            };
            home-manager.users."simeon.stix" = {
              imports = [
                ./home-manager/packages.nix
              ];
              targets.darwin.copyApps.enable = false;
            };
          }
        ];
      };
    };
}