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
        legacyPackages = lib.mkIf config.packagesAsLegacyPackages packages;
        apps = lib.mkIf config.packagesAsApps (self.lib.packages.asApps packages);
      };
    };
}
