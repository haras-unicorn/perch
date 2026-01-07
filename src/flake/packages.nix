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
        description = "Convert all packages to apps and put them in flake outputs";
      };
      packagesAsLegacyPackages = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Convert all packages to legacy packages and put them in flake outputs";
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
            meta = package.meta or { };
          }) systemPackages
        ) packages
      );
    };
  };
}
