{
  self,
  lib,
  nixpkgs,
  flakeModules,
  specialArgs,
  config,
  options,
  ...
}:

# TODO: mkMerge when patch supports that kinda stuff

self.lib.factory.artifactModule {
  inherit specialArgs flakeModules nixpkgs;
  superConfig = config;
  superOptions = options;
  nixpkgsConfig = "appNixpkgs";
  config = "app";
  mapOptions =
    prev:
    prev
    // {
      flakeTests.asApps = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Aggregate checks of flakes from a specified path to
          apps in this flake
        '';
      };
    };
  mapConfig =
    prevApps: prev:
    prev
    // {
      flake.apps =
        let
          flakeTestApps = self.lib.packages.asApps (
            self.lib.test.flake {
              path = config.flakeTests.path;
              args = config.flakeTests.args;
              commands = config.flakeTests.commands;
            }
          );
        in
        if config.flakeTests.asApps then
          builtins.listToAttrs (
            builtins.map (
              system:
              let
                prevSystemApps = if prevApps ? ${system} then prevApps.${system} else { };
                systemFlakeTestApps = if flakeTestApps ? ${system} then flakeTestApps.${system} else { };

                pkgs = import nixpkgs {
                  inherit system;
                };

                flakeTest = pkgs.writeShellApplication {
                  name = "test-flake";
                  text = builtins.concatStringsSep "\n" (
                    builtins.map ({ program, ... }: program) (builtins.attrValues systemFlakeTestApps)
                  );
                };
              in
              {
                name = system;
                value =
                  prevSystemApps
                  // (lib.mapAttrs' (name: value: {
                    inherit value;
                    name = "test-flake-${name}";
                  }) systemFlakeTestApps)
                  // {
                    test-flake = {
                      type = "app";
                      program = lib.getExe flakeTest;
                      meta.description = "Run all flake tests";
                    };
                  };
              }
            ) self.lib.defaults.systems
          )
        else
          prevApps;
    };
  mapArtifacts = self.lib.packages.asApps;
}
