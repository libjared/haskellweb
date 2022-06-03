let
  nixpkgs = builtins.fetchTarball {
    url    = "https://github.com/NixOS/nixpkgs/archive/f1c9c23aad972787f00f175651e4cb0d7c7fd5ea.tar.gz";
    sha256 = "01msl5fffdrg7q43amvaqv9m00c2j1y3ihz3xhhnwl56l46df05j";
  };

  overlay = pkgsNew: pkgsOld: {
    haskell = pkgsOld.haskell // {
      packages = pkgsOld.haskell.packages // {
        ghcjs = pkgsOld.haskell.packages.ghcjs.override (old: {
          overrides =
            let
              oldOverrides = old.overrides or (_: _: {});

              sourceOverrides = pkgsNew.haskell.lib.packageSourceOverrides {
                ghcjs-demo = ./.;
              };

            in
              pkgsNew.lib.composeExtensions oldOverrides sourceOverrides;
        });
      };
    };
  };

  config = { };

  pkgs = import nixpkgs { inherit config; overlays = [ overlay ]; };

in
  pkgs.haskell.packages.ghcjs.ghcjs-demo.env
