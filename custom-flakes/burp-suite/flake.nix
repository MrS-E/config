{
  description = "Burp Suite Community Edition macOS application based on the Homebrew cask";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      cask = rec {
        token = "burp-suite";
        name = [ "Burp Suite Community Edition" ];
        desc = "Web security testing toolkit";
        homepage = "https://portswigger.net/burp/";
        version = "2026.8";
        url = "https://portswigger-cdn.net/burp/releases/download?product=desktop&version=${version}&type=MacOsArm64";
        sha256 = "638ff9d9c3026838798f5659904e3e9cba00ee0b26f3d616f93b1967f275d2ce";
        intelUrl = "https://portswigger-cdn.net/burp/releases/download?product=desktop&version=${version}&type=MacOsx";
        intelSha256 = "6c6f0f8450179d1c3e99538fcdad7d1d764a5d7e290c8c48b9070018e08c9411";
        auto_updates = null;
        depends_on = {
          macos = { };
        };
        app = "Burp Suite.app";
        conflicts_with = {
          cask = [ "burp-suite@early-adopter" ];
        };
      };

      archiveVersion = builtins.replaceStrings [ "." ] [ "_" ] cask.version;
      artifactFor = system:
        if system == "aarch64-darwin" then {
          name = "burpsuite_macos_arm64_v${archiveVersion}.dmg";
          inherit (cask) url sha256;
        } else {
          name = "burpsuite_macos_x64_v${archiveVersion}.dmg";
          url = cask.intelUrl;
          sha256 = cask.intelSha256;
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
          artifact = artifactFor system;
          burpSuite = pkgs.stdenvNoCC.mkDerivation {
            pname = cask.token;
            inherit (cask) version;
            src = pkgs.fetchurl {
              inherit (artifact) name url sha256;
            };

            nativeBuildInputs = [ pkgs.findutils pkgs.gawk pkgs.p7zip ];

            dontUnpack = true;
            dontBuild = true;
            dontFixup = true;

            installPhase = ''
              mkdir extracted
              ${pkgs.p7zip}/bin/7z x -snl -y "$src" -oextracted
              ${pkgs.p7zip}/bin/7z l -slt "$src" > archive-listing.txt
              ${pkgs.gawk}/bin/awk '
                BEGIN { RS = ""; FS = "\n" }
                {
                  path = "";
                  mode = "";
                  for (i = 1; i <= NF; i++) {
                    if ($i ~ /^Path = /) path = substr($i, 8);
                    if ($i ~ /^Mode = /) mode = substr($i, 8);
                  }
                  if (mode ~ /^l/) print path;
                }
              ' archive-listing.txt > symlink-paths.txt
              if [ ! -s symlink-paths.txt ]; then
                echo "No symbolic links found in the Burp Suite DMG listing" >&2
                exit 1
              fi

              app_path="$(${pkgs.findutils}/bin/find extracted -type d -name ${pkgs.lib.escapeShellArg cask.app} -print -quit)"
              if [ -z "$app_path" ]; then
                echo "Could not find ${cask.app} in the Burp Suite DMG" >&2
                exit 1
              fi

              restored_symlinks=0
              while IFS= read -r archive_path || [ -n "$archive_path" ]; do
                case "$archive_path" in
                  /*|..|../*|*/../*|*/..)
                    echo "Unsafe symlink path in Burp Suite DMG: $archive_path" >&2
                    exit 1
                    ;;
                esac

                link_path="extracted/$archive_path"
                case "$link_path" in
                  "$app_path"/*) ;;
                  *) continue ;;
                esac

                if [ ! -f "$link_path" ] || [ -L "$link_path" ]; then
                  echo "Could not read symlink target for $archive_path" >&2
                  exit 1
                fi

                target=""
                IFS= read -r target < "$link_path" || true
                if [ -z "$target" ]; then
                  echo "Empty symlink target in Burp Suite DMG: $archive_path" >&2
                  exit 1
                fi

                rm "$link_path"
                ln -s "$target" "$link_path"
                restored_symlinks=$((restored_symlinks + 1))
              done < symlink-paths.txt

              if [ "$restored_symlinks" -eq 0 ]; then
                echo "No app symlinks restored from the Burp Suite DMG" >&2
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
          default = burpSuite;
          burp-suite = burpSuite;
        });
    };
}