{
  description = "PrusaSlicer macOS application based on the Homebrew cask";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      cask = {
        token = "prusaslicer";
        name = [ "PrusaSlicer" ];
        desc = "G-code generator for 3D printers (RepRap, Makerbot, Ultimaker etc.)";
        homepage = "https://www.prusa3d.com/slic3r-prusa-edition/";
        version = "2.9.6";
        url = "https://github.com/prusa3d/PrusaSlicer/releases/download/version_2.9.6/PrusaSlicer-2.9.6.dmg";
        sha256 = "94fd7b8a9f87c9631e1c71739b15b184fc5f4c0ceabd69072f1c78f229a4fe40";
        auto_updates = null;
        depends_on = {
          macos = { };
        };
        app = "PrusaSlicer.app";
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
          prusaSlicer = pkgs.stdenvNoCC.mkDerivation {
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
                echo "Could not find ${cask.app} in the PrusaSlicer DMG" >&2
                exit 1
              fi

              mkdir -p "$out/Applications"
              /usr/bin/ditto --rsrc --extattr "$app_path" "$out/Applications/${cask.app}"
            '';

            passthru = { inherit cask; };

            meta = {
              description = cask.desc;
              homepage = cask.homepage;
              license = pkgs.lib.licenses.agpl3Plus;
              platforms = darwinSystems;
            };
          };
        in {
          default = prusaSlicer;
          prusa-slicer = prusaSlicer;
        });
    };
}