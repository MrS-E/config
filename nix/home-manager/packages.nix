{ config, lib, pkgs, betterMouse, figma, texifier, protonDrive, burpSuite, crealityPrint, prusaSlicer, protonMailBridge, raspberryPiImager, nordicNrfCommandLineTools, aflPlusPlus, mbpoll, zoteroPackage, ... }:
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

    if [ -d "$apps_dir" ]; then
      for app in "$apps_dir"/*.app; do
        [ -e "$app" ] || continue

        app_name="''${app##*/}"
        application="$applications_dir/$app_name"
        home_manager_link="Home Manager Apps/$app_name"

        if [ -L "$application" ]; then
          link_target="$(/usr/bin/readlink "$application")"
          if [ "$link_target" = "$home_manager_link" ]; then
            "$lsregister" -f "$application"
            continue
          fi
        fi

        if [ -e "$application" ] || [ -L "$application" ]; then
          printf 'Skipping Home Manager app link; destination already exists: %s\n' "$application" >&2
          continue
        fi

        ln -s "$home_manager_link" "$application"
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
      pkgs.segger-jlink
      zoteroPackage
    ];
}