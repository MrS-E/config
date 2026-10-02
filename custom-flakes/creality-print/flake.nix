{
  description = "Creality Print macOS application based on the Homebrew cask";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      cask = {
        token = "creality-print";
        name = [ "Creality Print" ];
        desc = "Slicer and cloud services for some Creality FDM 3D printers";
        homepage = "https://www.creality.com/pages/download-software";
        version = "7.2.2.5483,7.2.1";
        url = "https://github.com/CrealityOfficial/CrealityPrint/releases/download/v7.2.1/CrealityPrint-7.2.2.5483-macx-arm64-Release.dmg";
        sha256 = "86c611740afc797a3f55d1c7f3f1e34ce0c3bf55cf5bcc6b93febe32d5b7df63";
        auto_updates = null;
        depends_on = {
          macos = { };
        };
        app = "Creality Print.app";
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
          crealityPrint = pkgs.stdenvNoCC.mkDerivation {
            pname = cask.token;
            inherit (cask) version;
            src = pkgs.fetchurl {
              name = builtins.baseNameOf cask.url;
              inherit (cask) url sha256;
            };

            nativeBuildInputs = [ pkgs.findutils ];

            dontUnpack = true;
            dontBuild = true;
            dontFixup = true;

            installPhase = ''
              mount_point="$TMPDIR/dmg"
              mkdir -p "$mount_point"
              /usr/bin/hdiutil attach -quiet -readonly -nobrowse -mountpoint "$mount_point" "$src"
              trap '/usr/bin/hdiutil detach -quiet "$mount_point" || true' EXIT

              app_path="$(${pkgs.findutils}/bin/find "$mount_point" -type d -name ${pkgs.lib.escapeShellArg cask.app} -print -quit)"
              if [ -z "$app_path" ]; then
                echo "Could not find ${cask.app} in the Creality Print DMG" >&2
                exit 1
              fi

              mkdir -p "$out/Applications"
              /usr/bin/ditto --rsrc --extattr "$app_path" "$out/Applications/${cask.app}"
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
          default = crealityPrint;
          creality-print = crealityPrint;
        });
    };
}
