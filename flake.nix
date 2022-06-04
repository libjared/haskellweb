{
  description = "demo of haskell for the web";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/haskell-updates";
  };

  outputs = { self, flake-utils, nixpkgs }:
  (
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
      project = returnShellEnv: (
        pkgs.haskellPackages.developPackage {
          inherit returnShellEnv;
          name = "haskellweb";
          root = ./.;
          modifier = drv: (
            pkgs.haskell.lib.addBuildTools drv (with pkgs.haskellPackages; if returnShellEnv then [
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
