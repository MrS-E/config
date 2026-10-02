{
  description = "Nextcloud Virtual Files macOS application based on the Homebrew cask";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { self, nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

      version = "4.0.8";
      cask = {
        token = "nextcloud-vfs";
        name = [ "Nextcloud Virtual Files" ];
        desc = "Desktop sync client for Nextcloud software products";
        homepage = "https://nextcloud.com/";
        url = "https://github.com/nextcloud-releases/desktop/releases/download/v${version}/Nextcloud-${version}-macOS-vfs.pkg";
        inherit version;
        sha256 = "9cce6c6f08fab8ded66dd4e0530261f1113b74f26036d597307ddb441eab0fe3";
        auto_updates = true;
        depends_on = {
          macos = {
            ">=" = [ "12" ];
          };
        };
        conflicts_with = {
          cask = [ "nextcloud" ];
        };
        deprecated = true;
        deprecation_date = "2026-04-01";
        deprecation_reason = "discontinued";
        deprecation_replacement_cask = "nextcloud";
      };
      pkgFile = builtins.baseNameOf cask.url;

      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = package:
          builtins.elem (package.pname or package.name) [ "nextcloud-vfs" ];
      };
    in {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          nextcloudVfs = pkgs.stdenvNoCC.mkDerivation {
            pname = cask.token;
            inherit (cask) version;
            src = pkgs.fetchurl {
              name = pkgFile;
              inherit (cask) url sha256;
            };

            nativeBuildInputs = with pkgs; [ cpio gzip xar ];

            dontUnpack = true;
            dontBuild = true;
            dontFixup = true;

            installPhase = ''
              mkdir extracted
              ${pkgs.xar}/bin/xar -xf "$src" -C extracted

              mkdir payload
              (
                cd payload
                ${pkgs.gzip}/bin/gzip -dc ../extracted/Nextcloud.pkg/Payload \
                  | ${pkgs.cpio}/bin/cpio --extract --make-directories \
                    --preserve-modification-time --no-absolute-filenames
              )

              mkdir -p "$out/Applications"
              cp -R payload/Applications/Nextcloud.app "$out/Applications/"
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
          default = nextcloudVfs;
          nextcloud-vfs = nextcloudVfs;
        });

      homeManagerModules.default = import ./home-manager-module.nix self;
    };
}