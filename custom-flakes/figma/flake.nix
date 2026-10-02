{
  description = "Figma macOS application based on the Homebrew cask";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      cask = {
        token = "figma";
        name = [ "Figma" ];
        desc = "Collaborative team software";
        homepage = "https://www.figma.com/";
        version = "126.9.11";
        auto_updates = true;
        depends_on = {
          macos = { };
        };
        app = "Figma.app";
        archives = {
          aarch64-darwin = {
            url = "https://desktop.figma.com/mac-arm/Figma-126.9.11.zip";
            sha256 = "0c93c31c79338e0c108b139dc08e3a1256699faaa7a3248042e7aa2c5fde3043";
          };
          x86_64-darwin = {
            url = "https://desktop.figma.com/mac/Figma-126.9.11.zip";
            sha256 = "667f016dcfdacbdfb288ee52d72f0054ca695f42da63bab2bf25655551433e93";
          };
        };
      };

      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = package:
          builtins.elem (package.pname or package.name) [ cask.token ];
      };
    in {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          archive = cask.archives.${system};
          figma = pkgs.stdenvNoCC.mkDerivation {
            pname = cask.token;
            inherit (cask) version;
            src = pkgs.fetchurl {
              name = builtins.baseNameOf archive.url;
              inherit (archive) url sha256;
            };

            nativeBuildInputs = [ pkgs.unzip ];

            dontUnpack = true;
            dontBuild = true;
            dontFixup = true;

            installPhase = ''
              mkdir extracted
              ${pkgs.unzip}/bin/unzip -q "$src" -d extracted

              mkdir -p "$out/Applications"
              cp -R extracted/${cask.app} "$out/Applications/"
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
          default = figma;
          figma = figma;
        });
    };
}