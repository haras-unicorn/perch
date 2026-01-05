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
        default = true;
      };
      packagesAsLegacyPackages = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  mapConfig = packages: prev: {
    eval = prev.eval // {
      privateConfig = [
        [ "packagesAsApps" ]
        [ "packagesAsLegacyPackages" ]
      ]
      ++ prev.eval.privateConfig;
    };

    flake = prev.flake // {
      legacyPackages = lib.mkIf config.packagesAsLegacyPackages packages;
      apps = lib.mkIf config.packagesAsApps (
        builtins.mapAttrs (
          system: systemPackages:
          builtins.mapAttrs (name: package: {
            type = "app";
            program = lib.getExe package;
          }) systemPackages
        ) packages
      );
    };
  };
}
