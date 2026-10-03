{
  description = "ADB-Enhanced Python command-line package";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pname = "adb-enhanced";
      version = "2.12.0";
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          pythonPackages = pkgs.python312Packages;
          adbEnhanced = pythonPackages.buildPythonApplication {
            inherit pname version;
            format = "pyproject";

            src = pkgs.fetchurl {
              url = "https://files.pythonhosted.org/packages/15/98/64a9e67f5917396f5165861f7860690d0192dc3b392a70db00274d3d961a/adb_enhanced-2.12.0.tar.gz";
              hash = "sha256-1HfegkbCfgMI7u6VKldopYRP9cigJ9YupA++ueV+OrQ=";
            };

            build-system = [ pythonPackages.setuptools ];
            dependencies = [
              pythonPackages.docopt
              pythonPackages.psutil
            ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            makeWrapperArgs = [
              "--prefix"
              "PATH"
              ":"
              (pkgs.lib.makeBinPath [ pkgs.android-tools ])
            ];

            pythonImportsCheck = [ "adbe" ];

            meta = {
              description = "Swiss-army knife for Android testing and development";
              homepage = "https://github.com/ashishb/adb-enhanced";
              license = pkgs.lib.licenses.asl20;
              mainProgram = "adbe";
              platforms = systems;
            };
          };
        in {
          default = adbEnhanced;
          adb-enhanced = adbEnhanced;
        });
    };
}