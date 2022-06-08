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
                  ghcjs-base = gsuper.ghcjs-base.overrideScope (jself: jsuper: {
                    aeson = jsuper.aeson_1_5_6_0;
                  });
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
        defaultPackage = built;
        devShell = project true;
      }
    )
  );
}
