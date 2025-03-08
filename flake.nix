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
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      home-manager,
      nixpkgs,
      devenv,
      treefmt,
      ...
    }:
    let
      lib = inputs.nixpkgs.lib.extend (
        prev: _:
        import ./nixput/lib.nix {
          inherit inputs;
          lib = prev;
        }
      );
    in
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        specialArgs.lib = lib;
      }
      rec {
        imports = [
          devenv.flakeModule
          treefmt.flakeModule
          home-manager.flakeModules.home-manager
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

            checks = {
              buildHomeManagerConfiguration = flake.homeConfigurations.test.activationPackage;
            };
          };

        flake = rec {
          homeManagerModules.nixput = import ./nixput/hm;

          homeConfigurations.test = home-manager.lib.homeManagerConfiguration rec {
            inherit lib;
            pkgs = import nixpkgs { system = builtins.currentSystem; };

            extraSpecialArgs = {
              flake = self;
              inherit (self) inputs outputs;
            };

            modules = [
              {
                imports = [
                  homeManagerModules.nixput
                ];

                home = {
                  username = "test";
                  homeDirectory = "/home/test";
                  stateVersion = "25.05";
                };

                programs = {
                  zed-editor.enable = true;
                  micro.enable = true;
                  vscode = {
                    enable = true;
                    package = pkgs.vscodium;
                  };
                };

                nixput = {
                  enable = true;
                  targets = {
                    zed-editor.enable = true;
                    vscode.enable = true;
                    micro.enable = true;
                  };
                  keybinds = {
                    NewLine = "Enter";
                    NewLineAbove = "Ctrl+Shift+Enter";
                    NewLineBelow = "Ctrl+Enter";
                    SelectLine = "Ctrl+L";
                    GotoLine = "Alt+G";
                    MoveLineUp = "Ctrl+Alt+Up";
                    MoveLineDown = "Ctrl+Alt+Down";
                  };
                };
              }
            ];
          };
        };
      };
}
