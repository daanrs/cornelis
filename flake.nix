{
  description = "Agda mode for vim";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;

    flake-utils = {
      url = github:numtide/flake-utils;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      ghcVersion = "8107";
      compiler = "ghc${ghcVersion}";
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        hsPkgs = pkgs.haskell.packages.${compiler}.override {
          overrides = hfinal: hprev: {
            nvim-hs = hfinal.callPackage ./nix/deps/nvim-hs.nix { };
          };
        };

        cornelis = returnShellEnv: hsPkgs.developPackage {
          inherit returnShellEnv;
          root = builtins.path { path = ./.; name = "cornelis"; };
          name = "cornelis";
          modifier = drv:
            pkgs.haskell.lib.addBuildTools drv
              (
                pkgs.lib.lists.optionals returnShellEnv [
                  hsPkgs.cabal-install
                  hsPkgs.haskell-language-server
                ]
              );
        };
      in
      {
        packages = flake-utils.lib.flattenTree {
          cornelis = cornelis false;
          cornelis-vim = pkgs.vimUtils.buildVimPlugin {
            name = "cornelis";
            src = ./.;
          };
        };
        defaultPackage = self.packages.cornelis;

        app = {
          cornelis = flake-utils.lib.mkApp {
            name = "cornelis";
            drv = self.packages.cornelis;
          };
        };
        defaultApp = self.app.cornelis;

        devShell = cornelis true;
      });
}
