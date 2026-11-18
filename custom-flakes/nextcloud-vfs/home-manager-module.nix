self:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.nextcloud-vfs;
in {
  options.programs.nextcloud-vfs = {
    enable = lib.mkEnableOption "Nextcloud Virtual Files";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.nextcloud-vfs;
      description = "The Nextcloud Virtual Files application package.";
    };

    appPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Applications/Home Manager Apps/Nextcloud.app";
      description = "Path to the linked Nextcloud.app bundle.";
    };

    extensionId = lib.mkOption {
      type = lib.types.str;
      default = "com.nextcloud.desktopclient.FinderSyncExt";
      description = "Bundle identifier of the Finder Sync extension.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    targets.darwin.linkApps.enable = lib.mkDefault true;

    home.activation.nextcloudVfsFinderSync =
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        app_path=${lib.escapeShellArg cfg.appPath}
        extension_path="$app_path/Contents/PlugIns/FinderSyncExt.appex"

        if [ ! -d "$extension_path" ]; then
          echo "Skipping Nextcloud Finder Sync registration; extension not found at $extension_path" >&2
        else
          if ! /usr/bin/pluginkit -a "$extension_path/"; then
            echo "Warning: failed to add the Nextcloud Finder Sync extension" >&2
          else
            /bin/sleep 10
          fi

          if ! /usr/bin/pluginkit -e use -i ${lib.escapeShellArg cfg.extensionId}; then
            echo "Warning: failed to enable the Nextcloud Finder Sync extension" >&2
          fi
        fi
      '';
  };
}