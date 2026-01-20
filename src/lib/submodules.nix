{
  self,
  lib,
  ...
}:

{
  flake.lib.submodules.make =
    self.lib.docs.function
      {
        description = ''
          Create a ready-to-use attrset of submodules from a set of flake modules.

          You pick which config field you want to expose (via "config"),
          and this function returns only the modules that provide it,
          plus a sensible "default" module.

          This is useful for turning a large flake module collection
          into a small, clean “module API” other code can consume.
        '';
        type = self.lib.types.function (self.lib.types.args (
          { lib, ... }:
          {
            options = {
              flakeModules = lib.mkOption {
                type = lib.types.attrsOf lib.types.deferredModule;
                description = ''
                  Candidate flake modules to turn into submodules (keyed by name).
                '';
              };

              specialArgs = lib.mkOption {
                type = lib.types.attrs;
                description = ''
                  Extra args used during evaluation (like "specialArgs" in "lib.evalModules").
                '';
              };

              config = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Which config field to extract from each module
                  (e.g. "nixosModule", "homeManagerModule", etc.).
                '';
              };

              defaultConfig = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Config flag name used to choose the default module;
                  if none is marked, a default is generated.
                '';
              };
            };
          }
        )) (lib.types.attrsOf lib.types.deferredModule);
      }
      (
        {
          flakeModules,
          specialArgs,
          config,
          defaultConfig,
        }:
        let
          filterModule =
            _: configs:
            builtins.any (conf: conf ? ${config} || conf ? config && conf.config ? ${config}) configs;

          filteredModules = self.lib.eval.filter specialArgs filterModule flakeModules;

          filterDefaultModule =
            _: configs:
            builtins.any (
              conf:
              (conf ? ${defaultConfig} && conf.${defaultConfig})
              || (conf ? config && conf.config ? ${defaultConfig} && conf.config.${defaultConfig})
            ) configs;

          defaultModule =
            let
              defaultModules = builtins.attrValues (
                self.lib.eval.filter specialArgs filterDefaultModule filteredModules
              );
            in
            if (builtins.length defaultModules) == 0 then
              {
                default = {
                  imports = builtins.attrValues filteredModules;
                };
              }
            else
              {
                default = builtins.head defaultModules;
              };

          configModules = builtins.mapAttrs (
            _:
            self.lib.module.patch (_: args: builtins.removeAttrs args (builtins.attrNames specialArgs))
              (_: args: args // specialArgs)
              (
                _: result:
                (
                  if result ? ${config} then
                    result.${config}
                  else if result ? config && result.config ? ${config} then
                    result.config.${config}
                  else
                    { }
                )
                // (if result ? key then { key = result.key; } else { })
                // (if result ? _file then { _file = result._file; } else { })
              )
          ) (filteredModules // defaultModule);
        in
        configModules
      );
}
