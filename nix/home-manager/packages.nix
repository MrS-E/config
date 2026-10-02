{ pkgs, betterMouse, protonDrive, burpSuite, ... }:
{
  home.stateVersion = "26.05";
  targets.darwin.linkApps.enable = true;

  home.packages =
    (import ../packages/common.nix { inherit pkgs; })
    ++ (import ../packages/darwin.nix { inherit pkgs; })
    ++ (import ../packages/aarch64-darwin.nix { inherit pkgs; })
    ++ [ betterMouse protonDrive burpSuite ];
}