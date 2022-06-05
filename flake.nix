{
  description = "demo of haskell for the web";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/21a3136d25e1652cb32197445e9799e6a5154588";
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
                  ghcjs-base = gsuper.ghcjs-base.overrideAttrs (old: {
                    src = oself.fetchFromGitHub {
                      owner = "ghcjs";
                      repo = "ghcjs-base";
                      rev = "85e31beab9beffc3ea91b954b61a5d04e708b8f2";
                      sha256 = "15fdkjv0l7hpbbsn5238xxgzfdg61g666nzbv2sgxkwryn5rycv0";
                      # rev = "85e31beab9beffc3ea91b954b61a5d04e708b8f2";
                      # sha256 = "sha256-YDOfi/WZz/602OtbY8wL5jX3X+9oiGL1WhceCraczZU=";
                    };
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
      project = returnShellEnv: let
        # hpkgs = pkgs.haskellPackages;
        hpkgs = pkgs.haskell.packages.ghcjs;
      in (
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
      in {
        defaultPackage = project false;
        devShell = project true;
      }
    )
  );
}
