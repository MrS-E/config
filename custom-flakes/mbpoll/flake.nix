{
  description = "mbpoll command-line utility built from the Homebrew formula source";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      version = "1.5.4";
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          mbpoll = pkgs.stdenv.mkDerivation {
            pname = "mbpoll";
            inherit version;

            src = pkgs.fetchurl {
              url = "https://github.com/epsilonrt/mbpoll/archive/refs/tags/v${version}.tar.gz";
              sha256 = "a9bcc3afa3b85b3794505d07827873ead280d96a94769d236892eb8a4fb9956f";
            };

            patches = [ (pkgs.fetchurl {
              name = "mbpoll-include-limits.patch";
              url = "https://github.com/epsilonrt/mbpoll/commit/8a8bd34d803ef8f4daa5aad13eabbe838e2f3fad.patch?full_index=1";
              sha256 = "9c663ed9c66e6c62423957a2f19f0916d3ff577433f06f088b721db62c6c080b";
            }) ];

            nativeBuildInputs = [ pkgs.cmake pkgs.pkgconf ];
            buildInputs = [ pkgs.libmodbus ];

            meta = {
              description = "Command-line utility to communicate with ModBus slave (RTU or TCP)";
              homepage = "https://epsilonrt.fr";
              license = pkgs.lib.licenses.gpl3Only;
              mainProgram = "mbpoll";
              platforms = systems;
            };
          };
        in {
          default = mbpoll;
          mbpoll = mbpoll;
        });
    };
}