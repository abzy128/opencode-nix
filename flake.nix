{
  description = "Nix flake for opencode - AI coding agent in your terminal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      overlay = final: prev: {
        opencode = final.callPackage ./package.nix { };
      };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          default = pkgs.opencode;
          opencode = pkgs.opencode;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.opencode}/bin/opencode";
          };
          opencode = {
            type = "app";
            program = "${pkgs.opencode}/bin/opencode";
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cachix
            gh
            jq
            nixpkgs-fmt
            nix-prefetch-git
            nix-prefetch-scripts
          ];
        };
      }) // {
        overlays.default = overlay;
      };
}
