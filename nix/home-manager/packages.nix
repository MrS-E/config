{ config, lib, pkgs, custom-flakes, sstix-tools, ... }:
{
  home.stateVersion = "26.05";

  programs.nextcloud-vfs.enable = true;

  home.packages =
    (import ../packages/common.nix { inherit pkgs; })
    ++ (import ../packages/darwin.nix { inherit pkgs; })
    ++ (import ../packages/aarch64-darwin.nix {
      inherit pkgs custom-flakes sstix-tools;
    });
}