{
  description = "Zotero macOS application based on the Homebrew cask";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = package:
          builtins.elem (package.pname or package.name) [ "zotero" ];
      };
    in {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          generatedSources = if builtins.pathExists ./_sources/generated.nix
            then import ./_sources/generated.nix {
              inherit (pkgs) fetchgit fetchurl fetchFromGitHub dockerTools;
            }
            else {};
          generated = generatedSources.zotero or null;
          cask = {
            token = "zotero";
            name = [ "Zotero" ];
            desc = "Collect, organise, cite, and share research sources";
            homepage = "https://www.zotero.org/";
            version = if generated != null then generated.version else "10.0.5";
            url = if generated != null then generated.src.url else "https://download.zotero.org/client/release/10.0.5/Zotero-10.0.5.dmg";
            sha256 = if generated != null then generated.src.outputHash else "82f10f8e9fd0c2910dca70aae3213d609274a2fa3356c18cbc3203ee128dfa85";
            auto_updates = true;
            depends_on = {
              macos = { };
            };
            app = "Zotero.app";
          };
          zotero = pkgs.stdenvNoCC.mkDerivation {
            pname = cask.token;
            inherit (cask) version;
            src = if generated != null then generated.src else pkgs.fetchurl {
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
                echo "Could not find ${cask.app} in the Zotero DMG" >&2
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
          default = zotero;
          zotero = zotero;
        });
    };
}