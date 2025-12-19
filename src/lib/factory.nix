{ lib, self, ... }:

{
  flake.lib.factory.submoduleModule =
    {
      flakeModules,
      specialArgs,
      superConfig,
      superOptions,
      config,
      submoduleType ? lib.types.attrsOf lib.types.raw,
      mapSubmodules ? (_: _),
    }:
    let
      configs = "${config}s";
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
      config.eval.allowedArgs = [
        "super"
        "pkgs"
      ];

      options.${defaultConfig} = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      options.${config} = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
      };
      config.eval.privateConfig = [ [ config ] ];

      options.flake.${configs} = lib.mkOption {
        type = submoduleType;
        default = submodules;
      };
      config.eval.publicConfig = [
        [
          "flake"
          configs
        ]
      ];
    };

  flake.lib.factory.artifactModule =
    {
      flakeModules,
      specialArgs,
      superConfig,
      superOptions,
      nixpkgs,
      nixpkgsConfig,
      config,
      configs ? "${config}s",
      artifactType ? lib.types.attrsOf (lib.types.attrsOf lib.types.raw),
      mapArtifacts ? (_: _),
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
      config.eval.allowedArgs = [ "pkgs" ];

      options.${defaultConfig} = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      options.${config} = lib.mkOption {
        type = lib.types.raw;
      };
      options.${nixpkgsConfig} = lib.mkOption {
        type = self.lib.type.nixpkgs.config;
      };
      config.eval.privateConfig = [
        [ nixpkgsConfig ]
        [ config ]
        [ defaultConfig ]
      ];

      options.flake.${configs} = lib.mkOption {
        type = artifactType;
        default = artifacts;
      };
      config.eval.publicConfig = [
        [
          "flake"
          configs
        ]
      ];
    };

  flake.lib.factory.configurationModule =
    {
      flakeModules,
      specialArgs,
      superConfig,
      superOptions,
      nixpkgs,
      nixpkgsConfig,
      config,
      configurationType ? lib.types.attrsOf lib.types.raw,
      mapConfigurations ? (_: _),
    }:
    let
      configs = "${config}s";
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
      config.eval.allowedArgs = [
        "super"
        "pkgs"
      ];

      options.${defaultConfig} = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      options.${config} = lib.mkOption {
        type = lib.types.raw;
      };
      options.${nixpkgsConfig} = lib.mkOption {
        type = self.lib.type.nixpkgs.config;
      };
      config.eval.privateConfig = [
        [ nixpkgsConfig ]
        [ config ]
        [ defaultConfig ]
      ];

      options.flake.${configs} = lib.mkOption {
        type = configurationType;
        default = configurations;
      };
      config.eval.publicConfig = [
        [
          "flake"
          configs
        ]
      ];
    };
}
