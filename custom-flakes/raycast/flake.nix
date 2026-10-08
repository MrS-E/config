{
  description = "Raycast macOS application";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      cask = {
        token = "raycast";
        name = [ "Raycast" ];
        desc = "Control your tools with a few keystrokes";
        homepage = "https://www.raycast.com";
        version = "2.7.0.0";
        auto_updates = true;
        app = "Raycast.app";
        archive = {
          url = "https://x-r2.raycast-releases.com/Raycast_2.7.0.0_fec845450d_arm64.dmg";
          hash = "sha256-iWUY/Qj306Y5YxLXf3+M7xGy33kqu+45RawdvbyXQBQ=";
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
          raycast = pkgs.stdenvNoCC.mkDerivation {
            pname = cask.token;
            inherit (cask) version;
            src = pkgs.fetchurl {
              name = "Raycast.dmg";
              inherit (cask.archive) url hash;
            };

            nativeBuildInputs = [ pkgs.undmg ];

            sourceRoot = cask.app;
            dontPatch = true;
            dontConfigure = true;
            dontBuild = true;
            dontFixup = true;

            installPhase = ''
              runHook preInstall

              mkdir -p "$out/Applications/${cask.app}"
              cp -R . "$out/Applications/${cask.app}"
              mkdir -p "$out/bin"
              ln -s "$out/Applications/${cask.app}/Contents/MacOS/Raycast" "$out/bin/raycast"

              runHook postInstall
            '';

            passthru = { inherit cask; };

            meta = {
              description = cask.desc;
              homepage = cask.homepage;
              license = pkgs.lib.licenses.unfree;
              mainProgram = "raycast";
              platforms = darwinSystems;
              sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];
            };
          };
        in {
          default = raycast;
          raycast = raycast;
        });
    };
}
