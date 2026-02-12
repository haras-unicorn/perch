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
  nixpkgsConfig = "packageNixpkgs";
  config = "package";
  mapOptions =
    prev:
    prev
    // {
      flakeTests.asPackages = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Aggregate checks of flakes from a specified path to
          packages in this flake
        '';
      };
      packagesAsApps = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Convert all packages to apps and put them in flake outputs";
      };
      packagesAsLegacyPackages = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Convert all packages to legacy packages and put them in flake outputs";
      };
    };
  mapConfig =
    packages: prev:
    prev
    // {
      eval = prev.eval // {
        privateConfig = prev.eval.privateConfig ++ [
          [ "packagesAsApps" ]
          [ "packagesAsLegacyPackages" ]
        ];
      };

      flake = prev.flake // {
        packages =
          let
            prevPackages = packages;

            flakeTestPackages = self.lib.test.flake {
              path = config.flakeTests.path;
              args = config.flakeTests.args;
              commands = config.flakeTests.commands;
            };
          in
          if config.flakeTests.asPackages then
            builtins.listToAttrs (
              builtins.map (
                system:
                let
                  prevSystemPackages = if prevPackages ? ${system} then prevPackages.${system} else { };
                  systemFlakeTestPackages =
                    if flakeTestPackages ? ${system} then flakeTestPackages.${system} else { };

                  pkgs = import nixpkgs {
                    inherit system;
                  };

                  testFlake = pkgs.writeShellApplication {
                    name = "test-flake";
                    runtimeInputs = builtins.attrValues systemFlakeTestPackages;
                    text = builtins.concatStringsSep "\necho ''\n" (
                      builtins.map (
                        package:
                        if package ? meta && package.meta ? mainProgram then
                          package.meta.mainProgram
                        else
                          lib.getExe package
                      ) (builtins.attrValues systemFlakeTestPackages)
                    );
                  };
                in
                {
                  name = system;
                  value =
                    prevSystemPackages
                    // (lib.mapAttrs' (name: value: {
                      inherit value;
                      name = "test-flake-${name}";
                    }) systemFlakeTestPackages)
                    // {
                      test-flake = testFlake;
                    };
                }
              ) self.lib.defaults.systems
            )

          else
            prevPackages;
        legacyPackages = lib.mkIf config.packagesAsLegacyPackages packages;
        apps = lib.mkIf config.packagesAsApps (self.lib.packages.asApps packages);
      };
    };
}
