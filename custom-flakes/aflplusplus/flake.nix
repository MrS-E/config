{
  description = "AFL++ command-line tools built from the Homebrew formula source";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      version = "5.03c";
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          clang = pkgs.llvmPackages.clang;
          llvm = pkgs.llvmPackages.llvm;
          lld = pkgs.llvmPackages.lld;
          python = pkgs.python3;
          aflClang = pkgs.symlinkJoin {
            name = "aflplusplus-clang";
            paths = [
              (pkgs.writeShellScriptBin "clang" ''
                exec ${clang}/bin/clang ${pkgs.lib.optionalString pkgs.stdenv.isDarwin "-mmacosx-version-min=14.4"} "$@"
              '')
              (pkgs.writeShellScriptBin "clang++" ''
                exec ${clang}/bin/clang++ ${pkgs.lib.optionalString pkgs.stdenv.isDarwin "-mmacosx-version-min=14.4"} "$@"
              '')
            ];
          };
          llvmBin = pkgs.buildEnv {
            name = "aflplusplus-llvm-bin";
            paths = [ aflClang llvm.dev llvm lld ];
            pathsToLink = [ "/bin" ];
            ignoreCollisions = true;
          };
          aflplusplus = pkgs.stdenv.mkDerivation {
            pname = "aflplusplus";
            inherit version;

            src = pkgs.fetchurl {
              url = "https://github.com/AFLplusplus/AFLplusplus/archive/refs/tags/v${version}.tar.gz";
              sha256 = "07f089e8591209862898c770a569d8e2b74b459fe967db323fc6a3924dcc82b5";
            };

            nativeBuildInputs = [
              pkgs.coreutils
              pkgs.gnumake
              clang
              llvm
              llvm.dev
              lld
              python
            ];

            buildInputs = [ llvm python pkgs.zlib ];
            propagatedBuildInputs = [ clang llvm lld python ];
            env = pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
              MACOSX_DEPLOYMENT_TARGET = "14.4";
              NIX_CFLAGS_COMPILE = "-mmacosx-version-min=14.4";
            };

            postPatch = ''
              substituteInPlace src/afl-cc.c \
                --replace-fail "CLANGPP_BIN" '"${aflClang}/bin/clang++"' \
                --replace-fail "CLANG_BIN" '"${aflClang}/bin/clang"' \
                --replace-fail 'getenv("AFL_PATH")' "(getenv(\"AFL_PATH\") ? getenv(\"AFL_PATH\") : \"$out/lib/afl\")" \
                --replace-fail '#ifndef "${aflClang}/bin/clang"' '#ifndef CLANG_BIN'
            '' + pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
              substituteInPlace GNUmakefile GNUmakefile.llvm \
                --replace-fail 'all_done: test_build' 'all_done:' \
                --replace-fail ' test_build all_done' ' all_done'
            '';

            makeFlags = [
              "PREFIX=${placeholder "out"}"
              "CC=${aflClang}/bin/clang"
              "CXX=${aflClang}/bin/clang++"
              "LLVM_BINDIR=${llvmBin}/bin"
              "LLVM_LIBDIR=${llvm.lib}/lib"
              "LLVM_CONFIG=${llvm.dev}/bin/llvm-config"
              "NO_NYX=1"
            ];

            buildPhase = ''
              runHook preBuild
              make source-only $makeFlags -j$NIX_BUILD_CORES
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              make install $makeFlags
              runHook postInstall
            '';

            doCheck = false;

            meta = {
              description = "American Fuzzy Lop++";
              homepage = "https://aflplus.plus/";
              license = pkgs.lib.licenses.asl20;
              mainProgram = "afl-fuzz";
              platforms = systems;
            };
          };
        in {
          default = aflplusplus;
          aflplusplus = aflplusplus;
        });
    };
}