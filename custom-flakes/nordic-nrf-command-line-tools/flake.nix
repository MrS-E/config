{
  description = "Nordic nRF Command Line Tools extracted from the Homebrew cask installer";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      cask = {
        token = "nordic-nrf-command-line-tools";
        name = [ "nRF Command Line Tools" ];
        desc = "Command-line tools for Nordic nRF Semiconductors";
        homepage = "https://www.nordicsemi.com/Software-and-Tools/Development-Tools/nRF-Command-Line-Tools";
        version = "10.24.2";
        url = "https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-24-2/nrf-command-line-tools-10.24.2-darwin.dmg";
        sha256 = "c7f24bb4234e3e99e408a3f7cca568898a51779f2f337604c2e8d60466939c2e";
        auto_updates = null;
        depends_on = {
          cask = [ "segger-jlink" ];
          macos = { };
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
          nrfCommandLineTools = pkgs.stdenvNoCC.mkDerivation {
            pname = cask.token;
            inherit (cask) version;

            src = pkgs.fetchurl {
              name = builtins.baseNameOf cask.url;
              inherit (cask) url sha256;
            };

            dontUnpack = true;
            dontBuild = true;
            dontFixup = true;

            installPhase = ''
              mount_point="$TMPDIR/dmg"
              expanded="$TMPDIR/expanded"
              mkdir -p "$mount_point"
              /usr/bin/hdiutil attach -quiet -readonly -nobrowse -mountpoint "$mount_point" "$src"
              trap '/usr/bin/hdiutil detach -quiet "$mount_point" || true' EXIT

              /usr/sbin/pkgutil --expand-full \
                "$mount_point/.nRF-Command-Line-Tools-${cask.version}-Darwin.pkg" \
                "$expanded"

              mkdir -p "$out/Applications/Nordic Semiconductor"
              for component in CMAKE MERGEHEX NRFJPROG; do
                component_payload="$expanded/nRF-Command-Line-Tools-${cask.version}-Darwin-$component.pkg/Payload/Applications/Nordic Semiconductor"
                if [ ! -d "$component_payload" ]; then
                  echo "Could not find the $component payload in the Nordic installer" >&2
                  exit 1
                fi
                /usr/bin/ditto --rsrc --extattr "$component_payload" "$out/Applications/Nordic Semiconductor"
              done

              mkdir -p "$out/bin"
              for tool in mergehex nrfjprog; do
                tool_path="$out/Applications/Nordic Semiconductor/bin/$tool"
                if [ ! -x "$tool_path" ]; then
                  echo "Could not find the $tool executable in the Nordic installer" >&2
                  exit 1
                fi
                ln -s "$tool_path" "$out/bin/$tool"
              done
            '';

            passthru = { inherit cask; };

            meta = {
              description = cask.desc;
              homepage = cask.homepage;
              license = pkgs.lib.licenses.unfree;
              mainProgram = "nrfjprog";
              platforms = darwinSystems;
            };
          };
        in {
          default = nrfCommandLineTools;
          nordic-nrf-command-line-tools = nrfCommandLineTools;
        });
    };
}