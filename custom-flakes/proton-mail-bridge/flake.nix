{
  description = "Proton Mail Bridge macOS application based on the Homebrew cask";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      cask = rec {
        token = "proton-mail-bridge";
        name = [ "Proton Mail Bridge" ];
        desc = "Bridges Proton Mail to email clients supporting IMAP and SMTP protocols";
        homepage = "https://proton.me/mail/bridge";
        version = "3.27.0";
        url = "https://github.com/ProtonMail/proton-bridge/releases/download/v${version}/Bridge-Installer.dmg";
        sha256 = "44152e90108ae4280aafec86604b7871697bd514633c2afb911038f9ab50fe3e";
        auto_updates = true;
        depends_on = {
          macos = { };
        };
        app = "Proton Mail Bridge.app";
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
          protonMailBridge = pkgs.stdenvNoCC.mkDerivation {
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
                echo "Could not find ${cask.app} in the Proton Mail Bridge DMG" >&2
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
          default = protonMailBridge;
          proton-mail-bridge = protonMailBridge;
        });
    };
}