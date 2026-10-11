{
  description = "Raspberry Pi Imager macOS application based on the Homebrew cask";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      cask = {
        token = "raspberry-pi-imager";
        name = [ "Raspberry Pi Imager" ];
        desc = "Imaging utility to install operating systems to a microSD card";
        homepage = "https://www.raspberrypi.com/software/";
        version = "2.0.11.1";
        url = "https://github.com/raspberrypi/rpi-imager/releases/download/v2.0.11.1/rpi-imager-v2.0.11.1.dmg";
        sha256 = "2b4c5324c5ff04aa3bfb216795ae9e01cb54400752727353e13fb21e66c528a9";
        auto_updates = null;
        depends_on = {
          macos = {
            ">=" = [ "13" ];
          };
        };
        app = "Raspberry Pi Imager.app";
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
          raspberryPiImager = pkgs.stdenvNoCC.mkDerivation {
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

              app_path="$(
                ${pkgs.findutils}/bin/find "$mount_point" -type d \
                  -name ${pkgs.lib.escapeShellArg cask.app} -print -quit
              )"
              if [ -z "$app_path" ]; then
                echo "Could not find ${cask.app} in the Raspberry Pi Imager DMG" >&2
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
          default = raspberryPiImager;
          raspberry-pi-imager = raspberryPiImager;
        });
    };
}