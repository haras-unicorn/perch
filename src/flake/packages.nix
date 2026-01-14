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
        default = false;
        description = "Convert all packages to apps and put them in flake outputs";
      };
      packagesAsLegacyPackages = lib.mkOption {
        type = lib.types.bool;
        default = false;
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
            meta =
              let
                initial = package.meta or { };
              in
              initial // { description = initial.description or name; };
          }) (lib.filterAttrs (_: value: value ? meta && value.meta ? mainProgram) systemPackages)
        ) packages
      );
    };
  };
}
