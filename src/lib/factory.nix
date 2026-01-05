{ lib, self, ... }:

{
  flake.lib.factory.submoduleModule =
    {
      flakeModules,
      specialArgs,
      superConfig,
      superOptions,
      config,
      configs ? "${config}s",
      submoduleType ? lib.types.attrsOf lib.types.raw,
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
        };
        ${config} = lib.mkOption {
          type = lib.types.attrsOf lib.types.raw;
        };
        flake.${configs} = lib.mkOption {
          type = submoduleType;
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
        };
        ${config} = lib.mkOption {
          type = lib.types.raw;
        };
        ${nixpkgsConfig} = lib.mkOption {
          type = self.lib.type.nixpkgs.config;
        };
        flake.${configs} = lib.mkOption {
          type = artifactType;
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
      configs ? "${config}s",
      configurationType ? lib.types.attrsOf lib.types.raw,
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
        };
        ${config} = lib.mkOption {
          type = lib.types.raw;
        };
        ${nixpkgsConfig} = lib.mkOption {
          type = self.lib.type.nixpkgs.config;
        };
        flake.${configs} = lib.mkOption {
          type = configurationType;
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
    };
}
