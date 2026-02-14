{
  lib,
  self,
  nixpkgs,
  ...
}:

let
  tests =
    let
      nixosModule =
        {
          specialArgs,
          flakeModules,
          config,
          options,
          ...
        }:
        self.lib.factory.submoduleModule {
          inherit
            specialArgs
            flakeModules
            ;
          superConfig = config;
          superOptions = options;
          config = "nixosModule";
        };

      nixosConfigurationModule =
        {
          specialArgs,
          nixpkgs,
          flakeModules,
          config,
          options,
          ...
        }:
        self.lib.factory.configurationModule {
          inherit
            specialArgs
            nixpkgs
            flakeModules
            ;
          superConfig = config;
          superOptions = options;
          config = "nixosConfiguration";
          nixpkgsConfig = "nixosConfigurationNixpkgs";
        };

      packageModule =
        {
          specialArgs,
          nixpkgs,
          flakeModules,
          config,
          options,
          ...
        }:
        self.lib.factory.artifactModule {
          inherit
            specialArgs
            nixpkgs
            flakeModules
            ;
          superConfig = config;
          superOptions = options;
          config = "package";
          nixpkgsConfig = "packageNixpkgs";
        };

      appModule =
        {
          specialArgs,
          nixpkgs,
          flakeModules,
          config,
          options,
          ...
        }:
        self.lib.factory.artifactModule {
          inherit
            specialArgs
            nixpkgs
            flakeModules
            ;
          superConfig = config;
          superOptions = options;
          config = "app";
          nixpkgsConfig = "appNixpkgs";
        };

      flakeResult = self.lib.flake.make {
        inputs = {
          inherit nixpkgs;
          input = {
            modules.default =
              { lib, ... }:
              {
                imports = [
                  nixosModule
                  packageModule
                  appModule
                  nixosConfigurationModule
                ];

                options.myOption = lib.mkOption {
                  type = lib.types.str;
                  default = "default value";
                };

                config.myOption = "input value";
              };
          };
        };
        selfModules = {
          nixosConfigurationModule = {
            nixosConfigurationNixpkgs.system = "x86_64-linux";
            nixosConfiguration = {
              fileSystems."/" = {
                device = "/dev/disk/by-label/NIXROOT";
                fsType = "ext4";
              };
              boot.loader.grub.device = "nodev";
              system.stateVersion = "25.11";
            };
          };
          someNixosModule =
            { super, ... }:
            {
              nixosModule = {
                value = "some hello :) with super ${super.config.myOption}";
              };
              defaultNixosModule = true;
            };
          otherNixosModule =
            { super, ... }:
            {
              nixosModule = {
                value = "other hello :) with super ${super.config.myOption}";
              };
            };
          x86_64_Only =
            { pkgs, super, ... }:
            {
              package = "${pkgs.stdenv.hostPlatform.system} hello x86_64-linux :) with super ${super.config.myOption}";
              packageNixpkgs.system = "x86_64-linux";
              app = "${pkgs.stdenv.hostPlatform.system} hello x86_64-linux :) with super ${super.config.myOption}";
              appNixpkgs.system = "x86_64-linux";
            };
          allDefaultSystems =
            { pkgs, super, ... }:
            {
              package = "${pkgs.stdenv.hostPlatform.system} hello all default systems :) with super ${super.config.myOption}";
              defaultPackage = true;
              app = "${pkgs.stdenv.hostPlatform.system} hello all default systems :) with super ${super.config.myOption}";
            };
          none = { };
          optionModule = {
            myOption = lib.mkForce "self value";
          };
        };
      };
    in
    {
      factory_submodule_artifact_correct = {
        actual =
          let
            trimmed = builtins.removeAttrs flakeResult [
              "modules"
              "nixosConfigurations"
              "options"
              "config"
            ];
          in
          trimmed
          // {
            nixosModules = builtins.mapAttrs (_: nixosModule: nixosModule { }) trimmed.nixosModules;
          };
        expected = {
          apps = {
            aarch64-darwin = {
              allDefaultSystems = "aarch64-darwin hello all default systems :) with super self value";
            };
            aarch64-linux = {
              allDefaultSystems = "aarch64-linux hello all default systems :) with super self value";
            };
            x86_64-darwin = {
              allDefaultSystems = "x86_64-darwin hello all default systems :) with super self value";
            };
            x86_64-linux = {
              allDefaultSystems = "x86_64-linux hello all default systems :) with super self value";
              x86_64_Only = "x86_64-linux hello x86_64-linux :) with super self value";
            };
          };
          nixosModules = {
            default = {
              key = "someNixosModule";
              value = "some hello :) with super self value";
            };
            otherNixosModule = {
              key = "otherNixosModule";
              value = "other hello :) with super self value";
            };
            someNixosModule = {
              key = "someNixosModule";
              value = "some hello :) with super self value";
            };
          };
          packages = {
            aarch64-darwin = {
              allDefaultSystems = "aarch64-darwin hello all default systems :) with super self value";
              default = "aarch64-darwin hello all default systems :) with super self value";
            };
            aarch64-linux = {
              allDefaultSystems = "aarch64-linux hello all default systems :) with super self value";
              default = "aarch64-linux hello all default systems :) with super self value";
            };
            x86_64-darwin = {
              allDefaultSystems = "x86_64-darwin hello all default systems :) with super self value";
              default = "x86_64-darwin hello all default systems :) with super self value";
            };
            x86_64-linux = {
              allDefaultSystems = "x86_64-linux hello all default systems :) with super self value";
              default = "x86_64-linux hello all default systems :) with super self value";
              x86_64_Only = "x86_64-linux hello x86_64-linux :) with super self value";
            };
          };
        };
      };
    };
in
{
  flake.lib.factory.submoduleModule =
    self.lib.docs.function
      {
        description = ''
          Factory for building a module that collects
          and exposes submodules in "flake.<configs>".

          You tell it which "config" you’re defining,
          and it produces a module that:

          1. lets individual modules declare "config"
          (and optionally mark themselves as the default)

          2. aggregates all of them into "flake.<configs>"" for the whole flake

          3. supports light customization hooks ("mapSubmodules"/"mapOptions"/"mapConfig")
          so you can shape the API without rewriting the plumbing
        '';
        type = self.lib.types.function (self.lib.types.args (
          { config, lib, ... }:
          {
            options = {
              flakeModules = lib.mkOption {
                type = lib.types.attrsOf lib.types.deferredModule;
                description = ''
                  All flake modules to scan/collect submodules from.
                '';
              };

              specialArgs = lib.mkOption {
                type = lib.types.attrs;
                description = ''
                  Extra args for evaluation
                  (extended with "super.config"/"super.options").
                '';
              };

              superConfig = lib.mkOption {
                type = lib.types.raw;
                description = ''
                  Parent config exposed to submodules as "super.config".
                '';
              };

              superOptions = lib.mkOption {
                type = lib.types.raw;
                description = ''
                  Parent options exposed to submodules as "super.options".
                '';
              };

              config = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Singular name of the thing being collected (e.g. "overlay").
                '';
              };

              configs = lib.mkOption {
                type = lib.types.str;
                default = "${config.config}s";
                description = ''
                  Plural name used under "flake.<configs>".
                '';
              };

              submoduleType = lib.mkOption {
                type = lib.types.raw;
                default = lib.types.attrs;
                description = ''
                  Option type for "flake.<configs>".
                '';
              };

              mapSubmodules = lib.mkOption {
                type = self.lib.types.function lib.types.raw lib.types.raw;
                default = x: x;
                description = ''
                  Hook to post-process the collected submodules set.
                '';
              };

              mapConfig = lib.mkOption {
                type = self.lib.types.function lib.types.raw (self.lib.types.function lib.types.raw lib.types.raw);
                default = _: base: base;
                description = ''
                  Hook to post-process final "config"
                  (gets submodules, then base config).
                '';
              };

              mapOptions = lib.mkOption {
                type = self.lib.types.function lib.types.raw lib.types.raw;
                default = x: x;
                description = ''
                  Hook to post-process generated "options".
                '';
              };
            };
          }
        )) lib.types.deferredModule;
        tests = {
          correct = tests.factory_submodule_artifact_correct;
        };
      }
      (
        {
          flakeModules,
          specialArgs,
          superConfig,
          superOptions,
          config,
          configs ? "${config}s",
          submoduleType ? lib.types.attrs,
          mapSubmodules ? _: _,
          mapConfig ? _: _: _,
          mapOptions ? _: _,
        }:
        let
          defaultConfig = "default${self.lib.string.capitalize config}";

          submodules = mapSubmodules (
            self.lib.submodules.make {
              inherit
                flakeModules
                config
                defaultConfig
                ;

              specialArgs = (
                specialArgs
                // {
                  super.config = superConfig;
                  super.options = superOptions;
                }
              );
            }
          );
        in
        {
          options = mapOptions {
            ${defaultConfig} = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Whether to set this as the default ${config}
              '';
            };
            ${config} = lib.mkOption {
              type = lib.types.attrs;
              description = ''
                Result of the ${config}
              '';
            };
            flake.${configs} = lib.mkOption {
              type = submoduleType;
              description = ''
                Attribute set of all ${configs} in the flake
              '';
            };
          };

          config = mapConfig submodules {
            flake.${configs} = submodules;
            eval.allowedArgs = [
              "super"
              "pkgs"
            ];
            eval.privateConfig = [ [ config ] ];
            eval.publicConfig = [
              [
                "flake"
                configs
              ]
            ];
          };
        }
      );

  flake.lib.factory.artifactModule =
    self.lib.docs.function
      {
        description = ''
          Factory for building a module that generates per-system artifacts
          and exposes them in "flake.<configs>".

          You provide "config" plus how to interpret "nixpkgsConfig",
          and it produces a module that:

          1. lets modules define a "config" value
          and nixpkgs settings for it

          2. collects the evaluated results into "flake.<configs>""
          (typically keyed by system, with optional per-system defaults)

          3. offers mapping hooks to tweak the resulting artifacts
          and the exposed options/config shape
        '';
        type = self.lib.types.function (self.lib.types.args (
          { lib, config, ... }:
          {
            options = {
              flakeModules = lib.mkOption {
                type = lib.types.attrsOf lib.types.deferredModule;
                description = ''
                  All flake modules to evaluate artifacts from.
                '';
              };

              specialArgs = lib.mkOption {
                type = lib.types.attrs;
                description = ''
                  Extra args for evaluation (extended with "super.*").
                '';
              };

              superConfig = lib.mkOption {
                type = lib.types.raw;
                description = ''
                  Exposed as "super.config".
                '';
              };
              superOptions = lib.mkOption {
                type = lib.types.raw;
                description = ''
                  Exposed as "super.options".
                '';
              };

              nixpkgs = lib.mkOption {
                type = lib.types.path;
                description = ''
                  nixpkgs input/path used to instantiate "pkgs" per system.
                '';
              };

              nixpkgsConfig = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Name of the config field that carries nixpkgs/system settings.
                '';
              };

              config = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Name of the field to extract as the artifact value.
                '';
              };

              configs = lib.mkOption {
                type = lib.types.str;
                default = "${config.config}s";
                description = ''
                  Plural name used under "flake.<configs>".
                '';
              };

              artifactType = lib.mkOption {
                type = lib.types.raw;
                default = lib.types.attrsOf lib.types.attrs;
                description = ''
                  Option type for "flake.<configs>".
                '';
              };

              mapArtifacts = lib.mkOption {
                type = self.lib.types.function lib.types.raw lib.types.raw;
                default = x: x;
                description = ''
                  Hook to post-process the computed artifacts.
                '';
              };

              mapConfig = lib.mkOption {
                type = self.lib.types.function lib.types.raw (self.lib.types.function lib.types.raw lib.types.raw);
                default = _: base: base;
                description = ''
                  Hook to post-process final "config" (gets artifacts, then base config).
                '';
              };

              mapOptions = lib.mkOption {
                type = self.lib.types.function lib.types.raw lib.types.raw;
                default = x: x;
                description = ''
                  Hook to post-process generated "options".
                '';
              };
            };
          }
        )) lib.types.deferredModule;
        tests = {
          correct = tests.factory_submodule_artifact_correct;
        };
      }
      (
        {
          flakeModules,
          specialArgs,
          superConfig,
          superOptions,
          nixpkgs,
          nixpkgsConfig,
          config,
          configs ? "${config}s",
          artifactType ? lib.types.attrsOf lib.types.attrs,
          mapArtifacts ? (_: _),
          mapConfig ? _: _: _,
          mapOptions ? _: _,
        }:
        let
          defaultConfig = "default${self.lib.string.capitalize config}";

          artifacts = mapArtifacts (
            self.lib.artifacts.make {
              inherit
                flakeModules
                nixpkgs
                nixpkgsConfig
                defaultConfig
                config
                ;

              specialArgs = (
                specialArgs
                // {
                  super.config = superConfig;
                  super.options = superOptions;
                }
              );
            }
          );
        in
        {
          options = mapOptions {
            ${defaultConfig} = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Whether to set this as the default ${config}
              '';
            };
            ${config} = lib.mkOption {
              type = lib.types.raw;
              description = ''
                The ${config}
              '';
            };
            ${nixpkgsConfig} = lib.mkOption {
              type = self.lib.types.nixpkgsConfig;
              description = ''
                Nixpkgs configuration for ${config}
              '';
            };
            flake.${configs} = lib.mkOption {
              type = artifactType;
              description = ''
                Attribute set of all ${configs} in the flake
              '';
            };
          };

          config = mapConfig artifacts {
            flake.${configs} = artifacts;
            eval.allowedArgs = [ "pkgs" ];
            eval.privateConfig = [
              [ nixpkgsConfig ]
              [ config ]
              [ defaultConfig ]
            ];
            eval.publicConfig = [
              [
                "flake"
                configs
              ]
            ];
          };
        }
      );

  flake.lib.factory.configurationModule =
    self.lib.docs.function
      {
        description = ''
          Factory for building a module that produces NixOS configurations
          and exposes them in "flake.<configs>".

          You provide "<config>" plus "<nixpkgsConfig>",
          and it produces a module that:

          1. lets modules define the NixOS module/configuration
          for "config" (and optionally mark a default)

          2. evaluates them into real "nixosSystem" results
          across the intended systems

          3. publishes the final set under "flake.<configs>",
          with hooks for reshaping options/config and post-processing the result
        '';
        type = self.lib.types.function (self.lib.types.args (
          { lib, config, ... }:
          {
            options = {
              flakeModules = lib.mkOption {
                type = lib.types.attrsOf lib.types.deferredModule;
                description = ''
                  All flake modules to evaluate into NixOS configurations.
                '';
              };

              specialArgs = lib.mkOption {
                type = lib.types.attrs;
                description = ''
                  Extra args for evaluation (extended with "super.*").
                '';
              };

              superConfig = lib.mkOption {
                type = lib.types.raw;
                description = ''
                  Exposed as "super.config".
                '';
              };
              superOptions = lib.mkOption {
                type = lib.types.raw;
                description = ''
                  Exposed as "super.options".
                '';
              };

              nixpkgs = lib.mkOption {
                type = lib.types.path;
                description = ''
                  nixpkgs input/path used for system-specific evaluation.
                '';
              };

              nixpkgsConfig = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Name of the config field that carries nixpkgs/system settings.
                '';
              };

              config = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Name of the field that provides the NixOS module/configuration to build.
                '';
              };

              configs = lib.mkOption {
                type = lib.types.str;
                default = "${config.config}s";
                description = ''
                  Plural name used under "flake.<configs>".
                '';
              };

              configurationType = lib.mkOption {
                type = lib.types.raw;
                default = lib.types.attrs;
                description = ''
                  Option type for "flake.<configs>".
                '';
              };

              mapConfigurations = lib.mkOption {
                type = self.lib.types.function lib.types.raw lib.types.raw;
                default = x: x;
                description = ''
                  Hook to post-process the computed configurations.
                '';
              };

              mapConfig = lib.mkOption {
                type = self.lib.types.function lib.types.raw (self.lib.types.function lib.types.raw lib.types.raw);
                default = _: base: base;
                description = ''
                  Hook to post-process final "config".
                '';
              };

              mapOptions = lib.mkOption {
                type = self.lib.types.function lib.types.raw lib.types.raw;
                default = x: x;
                description = ''
                  Hook to post-process generated "options".
                '';
              };
            };
          }
        )) lib.types.deferredModule;
      }
      (
        {
          flakeModules,
          specialArgs,
          superConfig,
          superOptions,
          nixpkgs,
          nixpkgsConfig,
          config,
          configs ? "${config}s",
          configurationType ? lib.types.attrs,
          mapConfigurations ? (_: _),
          mapConfig ? _: _: _,
          mapOptions ? _: _,
        }:
        let
          defaultConfig = "default${self.lib.string.capitalize config}";

          configurations = mapConfigurations (
            self.lib.configurations.make {
              inherit
                flakeModules
                nixpkgs
                nixpkgsConfig
                defaultConfig
                config
                ;

              specialArgs = (
                specialArgs
                // {
                  super.config = superConfig;
                  super.options = superOptions;
                }
              );
            }
          );
        in
        {
          options = mapOptions {
            ${defaultConfig} = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Whether to set this as the default ${config}
              '';
            };
            ${config} = lib.mkOption {
              type = lib.types.raw;
              description = ''
                The module result for ${config}
              '';
            };
            ${nixpkgsConfig} = lib.mkOption {
              type = self.lib.types.nixpkgsConfig;
              description = ''
                Nixpkgs configuration for ${config}
              '';
            };
            flake.${configs} = lib.mkOption {
              type = configurationType;
              description = ''
                Attribute set of all ${configs} in the flake
              '';
            };
          };

          config = mapConfig configurations {
            flake.${configs} = configurations;
            eval.allowedArgs = [
              "super"
              "pkgs"
            ];
            eval.privateConfig = [
              [ nixpkgsConfig ]
              [ config ]
              [ defaultConfig ]
            ];
            eval.publicConfig = [
              [
                "flake"
                configs
              ]
            ];
          };
        }
      );
}
