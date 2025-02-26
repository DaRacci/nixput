{
  description = "A simple way to configure your keybinds once for your whole system.";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        specialArgs.lib = inputs.nixpkgs.lib.extend (
          prev: _:
          import ./nixput/lib.nix {
            inherit inputs;
            lib = prev;
          }
        );
      }
      {
        imports = [
          inputs.devenv.flakeModule
          inputs.treefmt.flakeModule
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        perSystem =
          {
            pkgs,
            lib,
            ...
          }:
          {
            treefmt = {
              programs = {
                actionlint.enable = true;
                deadnix.enable = true;
                nixfmt.enable = true;
                statix.enable = true;
                mdformat.enable = true;
              };
            };

            devenv.shells.default = {
              # Fixes https://github.com/cachix/devenv/issues/528
              containers = lib.mkForce { };

              packages = with pkgs; [
                act
                git
                cocogitto
              ];

              git-hooks = {
                hooks = {
                  nil.enable = true;
                  actionlint.enable = true;
                  deadnix.enable = true;
                  statix.enable = true;
                  nixfmt-rfc-style.enable = true;
                };
              };
            };
          };

        flake = {
          homeManagerModules.nixput = import ./nixput/hm;
        };
      };
}
