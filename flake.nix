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
                  ghcjs-base = gsuper.ghcjs-base.overrideAttrs (old:
                    let
                      oldsrc = old.src;
                      override = if isGitProtocol then { src = ghsrc; } else {};
                      isGitProtocol = builtins.match "git://.+" oldsrc.url != null;
                      ghsrc = oself.fetchFromGitHub (
                        assert oldsrc.outputHashMode == "recursive";
                        assert oldsrc.outputHashAlgo == "sha256";
                        {
                          name = "ghcjs-base-source";
                          owner = "ghcjs";
                          repo = "ghcjs-base";
                          rev = oldsrc.rev;
                          sha256 = oldsrc.outputHash;
                        }
                      );
                    in override
                  );
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
