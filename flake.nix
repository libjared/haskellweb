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
                  aeson = gself.aeson_1_5_6_0;
                });
              };
            };
          };
        })
        (oself: osuper: {
          haskellPackages = osuper.haskellPackages.override {
            overrides = (gself: gsuper: {
              ghcjs-base = oself.haskell.lib.compose.markUnbroken gself.ghcjs-base-stub;
            });
          };
        })
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
      project = returnShellEnv: (
        let hpkgs = if returnShellEnv then pkgs.haskellPackages else pkgs.haskell.packages.ghcjs;
        in hpkgs.developPackage {
          inherit returnShellEnv;
          name = "haskellweb";
          root = ./.;
          modifier = drv: (
            with pkgs.haskell.lib.compose;
            if returnShellEnv then addBuildTools (with hpkgs; [
              # all optional dependencies that I use for development
              cabal-install
              sensei
            ]) drv else drv
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
