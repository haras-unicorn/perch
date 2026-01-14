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
  nixpkgsConfig = "appNixpkgs";
  config = "app";
  mapArtifacts =
    apps:
    builtins.mapAttrs (
      system: systemApps:
      builtins.mapAttrs (name: app: {
        type = "app";
        program = lib.getExe app;
        meta =
          let
            initial = app.meta or { };
          in
          initial // { description = initial.description or name; };
      }) systemApps
    ) apps;
}
