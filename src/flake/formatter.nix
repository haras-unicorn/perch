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
  nixpkgsConfig = "formatterNixpkgs";
  config = "formatter";
  configs = "formatter";
  artifactType = lib.types.attrs;
  mapArtifacts =
    formatters:
    builtins.mapAttrs (
      _: systemFormatters:
      # NOTE: there should always be at least one
      builtins.head (builtins.attrValues systemFormatters)
    ) formatters;
}
