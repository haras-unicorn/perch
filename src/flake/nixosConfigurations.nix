{
  self,
  nixpkgs,
  flakeModules,
  specialArgs,
  config,
  options,
  ...
}:

self.lib.factory.configurationModule {
  inherit specialArgs flakeModules nixpkgs;
  superConfig = config;
  superOptions = options;
  nixpkgsConfig = "nixosConfigurationNixpkgs";
  config = "nixosConfiguration";
}
