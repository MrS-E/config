{ config, lib, pkgs, betterMouse, figma, texifier, protonDrive, burpSuite, crealityPrint, prusaSlicer, protonMailBridge, raspberryPiImager, nordicNrfCommandLineTools, aflPlusPlus, mbpoll, adbEnhanced, zoteroPackage, ... }:
{
  home.stateVersion = "26.05";
  targets.darwin.linkApps.enable = true;
  home.file."Applications/Home Manager Apps".source = lib.mkForce "${pkgs.buildEnv {
    name = "home-manager-applications-zotero";
    paths = config.home.packages;
    pathsToLink = [ "/Applications" ];
  }}/Applications";
  home.activation.registerHomeManagerApps = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    apps_dir="$HOME/Applications/Home Manager Apps"
    applications_dir="$HOME/Applications"
    lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    app_alias_target_attribute="org.nix-darwin.home-manager-app-target"

    create_home_manager_app_alias() {
      local app="$1"
      local applications_dir="$2"
      local app_name="$3"
      local app_target="$4"
      local staging_dir

      staging_dir="$(/usr/bin/mktemp -d "$applications_dir/.home-manager-app-alias.XXXXXX")"
      if ! /usr/bin/osascript - "$app" "$staging_dir" "$app_name" >/dev/null <<'APPLESCRIPT'
on run argv
  set targetApp to POSIX file (item 1 of argv) as alias
  set aliasFolder to POSIX file (item 2 of argv) as alias
  set aliasName to item 3 of argv
  tell application "Finder"
    set createdAlias to make new alias file at aliasFolder to targetApp
    set name of createdAlias to aliasName
  end tell
end run
APPLESCRIPT
      then
        /bin/rm -R "$staging_dir"
        return 1
      fi

      if ! /usr/bin/xattr -w "$app_alias_target_attribute" "$app_target" "$staging_dir/$app_name"; then
        /bin/rm -R "$staging_dir"
        return 1
      fi

      printf '%s\n' "$staging_dir"
    }

    if [ -d "$apps_dir" ]; then
      for app in "$apps_dir"/*.app; do
        [ -e "$app" ] || continue

        app_name="''${app##*/}"
        application="$applications_dir/$app_name"
        home_manager_link="Home Manager Apps/$app_name"
        app_target="$(cd "$app" && /bin/pwd -P)"
        replace_application=0

        if [ -L "$application" ]; then
          link_target="$(/usr/bin/readlink "$application")"
          if [ "$link_target" = "$home_manager_link" ]; then
            replace_application=1
          else
            printf 'Skipping Home Manager app alias; destination already exists: %s\n' "$application" >&2
            continue
          fi
        elif [ -e "$application" ]; then
          recorded_app_target="$(/usr/bin/xattr -p "$app_alias_target_attribute" "$application" 2>/dev/null || true)"
          if [ "$recorded_app_target" = "$app_target" ]; then
            "$lsregister" -f "$application"
            continue
          elif [ -n "$recorded_app_target" ]; then
            replace_application=1
          else
            printf 'Skipping Home Manager app alias; destination already exists: %s\n' "$application" >&2
            continue
          fi
        fi

        staged_alias_dir="$(create_home_manager_app_alias "$app" "$applications_dir" "$app_name" "$app_target")"
        if [ "$replace_application" -eq 1 ]; then
          if ! /bin/rm "$application"; then
            /bin/rm -R "$staged_alias_dir"
            exit 1
          fi
        fi
        if ! /bin/mv "$staged_alias_dir/$app_name" "$application"; then
          /bin/rm -R "$staged_alias_dir"
          exit 1
        fi
        /bin/rmdir "$staged_alias_dir"
        "$lsregister" -f "$application"
      done
    fi
  '';

  home.packages =
    (import ../packages/common.nix { inherit pkgs; })
    ++ (import ../packages/darwin.nix { inherit pkgs; })
    ++ (import ../packages/aarch64-darwin.nix { inherit pkgs; })
    ++ [
      betterMouse
      figma
      texifier
      protonDrive
      burpSuite
      crealityPrint
      prusaSlicer
      protonMailBridge
      raspberryPiImager
      nordicNrfCommandLineTools
      aflPlusPlus
      mbpoll
      adbEnhanced
      pkgs.segger-jlink
      zoteroPackage
    ];
}