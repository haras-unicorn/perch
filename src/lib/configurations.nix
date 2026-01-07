{
  self,
  lib,
  ...
}:

{
  flake.lib.configurations.make =
    {
      specialArgs,
      flakeModules,
      nixpkgs,
      nixpkgsConfig,
      config,
      defaultConfig,
    }:
    let
      nixpkgsModules = builtins.mapAttrs (
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

      nixpkgsEval = lib.evalModules {
        inherit specialArgs;
        modules = (builtins.attrValues nixpkgsModules) ++ [
          (
            { lib, ... }:
            {
              options.nixpkgs = lib.mkOption {
                type = lib.types.attrsOf (lib.types.listOf self.lib.type.nixpkgs.config);
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

      modules = builtins.mapAttrs (
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
          if value == null then
            null
          else if value ? config || value ? options then
            value
            // {
              config = value.config // {
                __perch_default = default;
              };
            }
          else
            value
            // {
              __perch_default = default;
            }
        )
      ) flakeModules;

      configurations = lib.flatten (
        builtins.attrValues (
          builtins.mapAttrs (
            module: configs:
            builtins.map (
              conf:
              let
                eval = lib.nixosSystem {
                  inherit specialArgs;
                  system = conf.system;
                  modules = [
                    (
                      { lib, ... }:
                      {
                        options.__perch_default = lib.mkOption {
                          type = lib.types.bool;
                          default = false;
                        };

                        config.nixpkgs = conf;

                        config._module.args = {
                          inherit flakeModules;
                        };
                      }
                    )
                    modules.${module}
                  ];
                };
              in
              {
                inherit module;
                system = conf.system;
                value = eval;
                default = eval.config.__perch_default;
              }
            ) configs
          ) nixpkgsEval.config.nixpkgs
        )
      );
    in
    builtins.listToAttrs (
      lib.flatten (
        builtins.map (
          {
            module,
            system,
            value,
            default,
            ...
          }:
          if default then
            [
              {
                inherit value;
                name = "${module}-${system}";
              }
              {
                inherit value;
                name = "default-${system}";
              }
            ]
          else
            [
              {
                inherit value;
                name = "${module}-${system}";
              }
            ]
        ) configurations
      )
    );
}
