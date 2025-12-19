{
  self,
  flakeModules,
  specialArgs,
  config,
  options,
  ...
}:

self.lib.factory.submoduleModule {
  inherit flakeModules specialArgs;
  superConfig = config;
  superOptions = options;
  config = "nixosModule";
}
