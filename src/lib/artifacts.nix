{
  self,
  lib,
  ...
}:

{
  flake.lib.artifacts.make =
    self.lib.docs.function
      {
        description = ''
          Build a system-indexed set of “artifacts” from flake modules.

          This evaluates each module for one or more target systems
          (based on its nixpkgsConfig settings, or a default set),
          then extracts the requested "config" value
          into an output shaped like "result.<system>.<module> = <value>".

          This is useful for producing flake outputs like
          per-system packages/apps/checks from a shared module collection,
          while still supporting a clean per-system "default".
        '';
        type = self.lib.types.function (self.lib.types.args (
          { lib, ... }:
          {
            options = {
              specialArgs = lib.mkOption {
                type = lib.types.attrs;
                description = ''
                  Extra args used during module evaluation
                  (passed through like "specialArgs").
                '';
              };

              flakeModules = lib.mkOption {
                type = lib.types.attrsOf lib.types.deferredModule;
                description = ''
                  Attrset of flake modules to evaluate
                  and extract artifacts from (keyed by module name).
                '';
              };

              nixpkgs = lib.mkOption {
                type = lib.types.path;
                description = ''
                  Path to a nixpkgs input,
                  used to instantiate "pkgs" for each target system.
                '';
              };

              nixpkgsConfig = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Name of the config field that describes nixpkgs settings for a module
                  (especially the target "system"/systems).
                  If a module doesn’t specify it, default systems are used.
                '';
              };

              config = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Name of the config field to extract as the artifact value
                  (supports top-level or "config.<name>").
                '';
              };

              defaultConfig = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Config flag name that marks an artifact as the per-system default.
                '';
              };
            };
          }
        )) lib.types.attrs;
      }
      (
        {
          specialArgs,
          flakeModules,
          nixpkgs,
          nixpkgsConfig,
          config,
          defaultConfig,
        }:
        let
          nixpkgsAttrModules = builtins.mapAttrs (
            module:
            self.lib.module.patch (_: args: args) (_: args: args) (
              _: result:
              let
                exists = result ? ${config} || (result ? config && result.config ? ${config});

                nixpkgs =
                  if result ? ${nixpkgsConfig} then
                    result.${nixpkgsConfig}
                  else if result ? config && result.config ? ${nixpkgsConfig} then
                    result.config.${nixpkgsConfig}
                  else
                    { };

                systems =
                  if !(exists) then
                    [ ]
                  else if nixpkgs ? system then
                    if builtins.isList nixpkgs.system then nixpkgs.system else [ nixpkgs.system ]
                  else
                    self.lib.defaults.systems;

                configs = builtins.map (system: nixpkgs // { inherit system; }) systems;
              in
              {
                nixpkgs.${module} = configs;
              }
            )
          ) flakeModules;

          nixpkgsAttrEval = lib.evalModules {
            inherit specialArgs;
            modules = (builtins.attrValues nixpkgsAttrModules) ++ [
              (
                { lib, ... }:
                {
                  options.nixpkgs = lib.mkOption {
                    type = lib.types.attrsOf (lib.types.listOf self.lib.types.nixpkgsConfig);
                    default = { };
                  };
                  config._module.args = {
                    inherit flakeModules;
                    pkgs = null;
                  };
                }
              )
            ];
          };

          valueModules = builtins.mapAttrs (
            module:
            self.lib.module.patch (_: args: args) (_: args: args) (
              _: result:
              let
                value =
                  if result ? ${config} then
                    result.${config}
                  else if result ? config && result.config ? ${config} then
                    result.config.${config}
                  else
                    null;
                default =
                  if result ? ${defaultConfig} then
                    result.${defaultConfig}
                  else if result ? config && result.config ? ${defaultConfig} then
                    result.config.${defaultConfig}
                  else
                    false;
              in
              {
                inherit value default;
              }
            )
          ) flakeModules;

          valuesEval = lib.flatten (
            builtins.attrValues (
              builtins.mapAttrs (
                module: configs:
                builtins.map (
                  conf:
                  let
                    eval = lib.evalModules {
                      inherit specialArgs;
                      modules = [
                        valueModules.${module}
                        (
                          { lib, ... }:
                          {
                            options.value = lib.mkOption {
                              type = lib.types.raw;
                              default = { };
                            };
                            options.default = lib.mkOption {
                              type = lib.types.bool;
                              default = false;
                            };
                            config._module.args = {
                              inherit flakeModules;
                              pkgs = import nixpkgs conf;
                            };
                          }
                        )
                      ];
                    };
                  in
                  {
                    inherit module;
                    system = conf.system;
                    value = eval.config.value;
                    default = eval.config.default;
                  }
                ) configs
              ) nixpkgsAttrEval.config.nixpkgs
            )
          );

          systems = lib.unique (builtins.map (attr: attr.system) valuesEval);

          values = builtins.listToAttrs (
            builtins.map (system: {
              name = system;
              value = builtins.listToAttrs (
                lib.flatten (
                  builtins.map (
                    value:
                    if value.default then
                      [
                        {
                          name = "default";
                          value = value.value;
                        }
                        {
                          name = value.module;
                          value = value.value;
                        }
                      ]
                    else
                      [
                        {
                          name = value.module;
                          value = value.value;
                        }
                      ]
                  ) (builtins.filter (value: value.system == system) valuesEval)
                )
              );
            }) systems
          );
        in
        values
      );
}
