{
  description = "Nixpkgs Zotero with Firefox ESR 153 compatibility updates";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          zotero = pkgs.zotero.overrideAttrs (old: {
            nativeBuildInputs = pkgs.lib.unique ((old.nativeBuildInputs or []) ++ [ pkgs.python3 ]);
            postPatch = (old.postPatch or "") + ''
              python3 ${./patch-fetch-xulrunner.py} app/scripts/fetch_xulrunner
              substituteInPlace app/build.sh \
                --replace-fail 'rm actors/' 'rm -f actors/'
            '';
          });
        in {
          default = zotero;
          zotero = zotero;
        });
    };
}