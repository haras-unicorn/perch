{
  self,
  lib,
  nixpkgs,
  ...
}:

{
  flake.lib.configurations.make =
    self.lib.docs.function
      {
        description = ''
          Build NixOS configurations from flake modules,
          across one or more target systems.

          For each module that provides "config",
          this evaluates a "lib.nixosSystem" using the module’s "nixpkgsConfig"
          (or default systems) and returns an attrset
          of configurations keyed like: "<module>-<system>".

          This is useful when you want a module-driven way to generate
          "nixosConfigurations" (including per-system defaults)
          without manually writing one "nixosSystem" per host/system combo.
        '';
        type = self.lib.types.function (self.lib.types.args (
          { lib, ... }:
          {
            options = {
              specialArgs = lib.mkOption {
                type = lib.types.attrs;
                description = ''
                  Extra args passed through to "lib.nixosSystem" and
                  module evaluation (like "specialArgs").
                '';
              };

              flakeModules = lib.mkOption {
                type = lib.types.attrsOf lib.types.deferredModule;
                description = ''
                  Attrset of flake modules to turn into NixOS configurations
                  (keyed by module name).
                '';
              };

              nixpkgs = lib.mkOption {
                type = lib.types.path;
                description = ''
                  Path to a nixpkgs input used indirectly via "lib.nixosSystem"
                  (for system-specific evaluation).
                '';
              };

              nixpkgsConfig = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Name of the config field that defines nixpkgs settings per module
                  (especially the target "system"/systems).
                  If absent, default systems are used.
                '';
              };

              config = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Name of the config field that contains the NixOS module
                  (or module-like value) to feed into "lib.nixosSystem".
                '';
              };

              defaultConfig = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Config flag name that marks a configuration as the default
                  for its system (emits "default-<system>").
                '';
              };
            };
          }
        )) lib.types.attrs;
        tests =
          let
            x86conf = {
              fileSystems."/" = {
                device = "/dev/disk/by-label/NIX86";
                fsType = "ext4";
              };
              boot.loader.grub.device = "nodev";
              system.stateVersion = "25.11";
            };
            linuxConf.config = {
              fileSystems."/" = {
                device = "/dev/disk/by-label/NIXALL";
                fsType = "ext4";
              };
              boot.loader.grub.device = "nodev";
              system.stateVersion = "25.11";
            };
            makeConfigurations = self.lib.configurations.make;
            specialArgs = { inherit self; };
            config = "nixosConfiguration";
            nixpkgsConfig = "nixosConfigurationNixpkgs";
            defaultConfig = "defaultNixosConfiguration";
            flakeModules = {
              x86_64-linux-only = {
                nixosConfigurationNixpkgs = {
                  system = "x86_64-linux";
                };
                nixosConfiguration = x86conf;
              };
              linux-only = {
                nixosConfigurationNixpkgs = {
                  system = [
                    "x86_64-linux"
                    "aarch64-linux"
                  ];
                };
                nixosConfiguration = linuxConf;
              };
            };

            configurations = makeConfigurations {
              inherit
                specialArgs
                flakeModules
                nixpkgs
                nixpkgsConfig
                config
                defaultConfig
                ;
            };
          in
          {
            correct =
              (builtins.mapAttrs (_: value: value.config.fileSystems."/".device) configurations) == {
                "linux-only-aarch64-linux" = linuxConf.config.fileSystems."/".device;
                "x86_64-linux-only-x86_64-linux" = x86conf.fileSystems."/".device;
                "linux-only-x86_64-linux" = linuxConf.config.fileSystems."/".device;
              };
          };
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
        )
      );
}
