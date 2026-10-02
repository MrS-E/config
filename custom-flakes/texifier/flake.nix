{
  description = "Texifier macOS application based on the Homebrew cask";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      cask = {
        token = "texifier";
        name = [ "Texifier" ];
        desc = "LaTeX editor";
        homepage = "https://www.texifier.com/mac";
        version = "1.9.33,855,ddb6e02";
        url = "https://download.texifier.com/apps/osx/updates/Texifier_1_9_33__855__ddb6e02.dmg";
        sha256 = "4361dacc275a5e4a786899ef3e3e63abf650d5ec2c4746303d6dfd14761b813e";
        auto_updates = true;
        depends_on = {
          macos = {
            ">=" = [ "14" ];
          };
        };
        app = "Texifier.app";
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
          texifier = pkgs.stdenvNoCC.mkDerivation {
            pname = cask.token;
            inherit (cask) version;
            src = pkgs.fetchurl {
              name = builtins.baseNameOf cask.url;
              inherit (cask) url sha256;
            };

            nativeBuildInputs = [ pkgs.findutils pkgs.undmg ];

            sourceRoot = ".";
            dontBuild = true;
            dontFixup = true;

            installPhase = ''
              app_path="$(${pkgs.findutils}/bin/find . -type d -name ${pkgs.lib.escapeShellArg cask.app} -print -quit)"
              if [ -z "$app_path" ]; then
                echo "Could not find ${cask.app} in the Texifier DMG" >&2
                exit 1
              fi

              mkdir -p "$out/Applications"
              cp -R "$app_path" "$out/Applications/"
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
          default = texifier;
          texifier = texifier;
        });
    };
}