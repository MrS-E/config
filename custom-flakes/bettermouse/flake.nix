{
  description = "BetterMouse macOS application based on the Homebrew cask";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      version = "1.7,8995";
      cask = {
        token = "bettermouse";
        name = [ "BetterMouse" ];
        desc = "Utility improving 3rd party mouse performance and functionalities";
        homepage = "https://better-mouse.com/";
        url = "https://better-mouse.com/wp-content/uploads/BetterMouse.1.7.8995.zip";
        sha256 = "4f9f5245eb4f2ef872c8bbff6899144a77ad540db1ebb5ec0ddeb57ff45f28c8";
        inherit version;
        auto_updates = true;
        depends_on = {
          macos = {
            ">=" = [ "12" ];
          };
        };
      };
      archiveFile = builtins.baseNameOf cask.url;

      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = package:
          builtins.elem (package.pname or package.name) [ cask.token ];
      };
    in {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          bettermouse = pkgs.stdenvNoCC.mkDerivation {
            pname = cask.token;
            inherit version;
            src = pkgs.fetchurl {
              name = archiveFile;
              inherit (cask) url sha256;
            };

            nativeBuildInputs = [ pkgs.unzip ];

            dontUnpack = true;
            dontBuild = true;
            dontFixup = true;

            installPhase = ''
              mkdir extracted
              ${pkgs.unzip}/bin/unzip -q "$src" -d extracted

              mkdir -p "$out/Applications"
              cp -R extracted/BetterMouse.app "$out/Applications/"
            '';

            passthru = { inherit cask; };

            meta = {
              description = cask.desc;
              homepage = cask.homepage;
              license = pkgs.lib.licenses.unfree;
              platforms = darwinSystems;
            };
          };
        in {
          default = bettermouse;
          bettermouse = bettermouse;
        });
    };
}