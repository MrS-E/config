{
  description = "Proton Drive macOS application based on the Homebrew cask";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      cask = rec {
        token = "proton-drive";
        name = [ "Proton Drive" ];
        desc = "Client for Proton Drive";
        homepage = "https://proton.me/drive";
        version = "3.0.3";
        url = "https://proton.me/download/drive/macos/${version}/ProtonDrive-${version}.dmg";
        sha256 = "e89c467632a91815d5edace10917f8db19a712d7c44dbcc0dbf167b274e63951";
        auto_updates = true;
        depends_on = {
          macos = {
            ">=" = [ "13" ];
          };
        };
        app = "Proton Drive.app";
      };

      sevenZipFor = pkgs: pkgs.stdenvNoCC.mkDerivation {
        pname = "7zz";
        version = "26.03";
        src = pkgs.fetchurl {
          name = "7z2603-mac.tar.xz";
          url = "https://github.com/ip7z/7zip/releases/download/26.03/7z2603-mac.tar.xz";
          sha256 = "5ca87677072c59f5602e5c49baa27d4694bacd2259b4e507f0094249d4281480";
        };

        sourceRoot = ".";
        dontBuild = true;
        dontFixup = true;

        installPhase = ''
          mkdir -p "$out/bin"
          cp 7zz "$out/bin/7zz"
          chmod +x "$out/bin/7zz"
        '';
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
          sevenZip = sevenZipFor pkgs;
          protonDrive = pkgs.stdenvNoCC.mkDerivation {
            pname = cask.token;
            inherit (cask) version;
            src = pkgs.fetchurl {
              name = builtins.baseNameOf cask.url;
              inherit (cask) url sha256;
            };

            nativeBuildInputs = [ sevenZip pkgs.findutils ];

            dontUnpack = true;
            dontBuild = true;
            dontFixup = true;

            installPhase = ''
              mkdir extracted
              ${sevenZip}/bin/7zz x -y "$src" -oextracted

              app_path="$(${pkgs.findutils}/bin/find extracted -type d -name ${pkgs.lib.escapeShellArg cask.app} -print -quit)"
              if [ -z "$app_path" ]; then
                echo "Could not find ${cask.app} in the Proton Drive DMG" >&2
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
          default = protonDrive;
          proton-drive = protonDrive;
        });
    };
}