{
  description = "demo of haskell for the web";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }:
  (
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: let
      overlays = [
        (oself: osuper: {
          haskell = osuper.haskell // {
            packages = osuper.haskell.packages // {
              ghcjs = osuper.haskell.packages.ghcjs.override {
                overrides = (gself: gsuper: {
                  aeson = oself.haskell.lib.compose.overrideCabal (drv: {
                    patches = drv.patches or [] ++ [
                      ./patches/short-text-aeson.patch
                    ];
                    libraryHaskellDepends =
                      oself.lib.remove gself.text-short drv.libraryHaskellDepends;
                    testHaskellDepends =
                      oself.lib.remove gself.text-short drv.testHaskellDepends;
                  }) gsuper.aeson;
                  quickcheck-instances = oself.haskell.lib.compose.overrideCabal (drv: {
                    patches = drv.patches or [] ++ [
                      ./patches/short-text-qc-instances.patch
                    ];
                    libraryHaskellDepends =
                      oself.lib.remove gself.text-short drv.libraryHaskellDepends;
                  }) gsuper.quickcheck-instances;
                  ghcjs-base = oself.haskell.lib.compose.appendPatch (./patches/loosen-aeson-ghcjs-base.patch) gsuper.ghcjs-base;
                });
              };
            };
          };
        })
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
      hpkgs = pkgs.haskell.packages.ghcjs;
      project = returnShellEnv: (
        hpkgs.developPackage {
          inherit returnShellEnv;
          name = "haskellweb";
          root = ./.;
          modifier = drv: (
            pkgs.haskell.lib.addBuildTools drv (with hpkgs; if returnShellEnv then [
              # all optional dependencies that I use for development
              # cabal-fmt
              cabal-install
              # ghcid
              # haskell-language-server
              # ormolu
              # pkgs.nixpkgs-fmt
              # sensei
            ] else [])
          );
        }
      );
      built = pkgs.symlinkJoin {
        name = "haskellweb-wrapped";
        paths = [ (project false) ];
        postBuild = ''
          ln -sf "${./index.html}" "$out"/bin/*.jsexe/index.html
        '';
      };
      in {
        packages.ghcjs-base = pkgs.haskell.packages.ghcjs.ghcjs-base;
        defaultPackage = built;
        devShell = project true;
      }
    )
  );
}
