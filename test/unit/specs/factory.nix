{ self, nixpkgs, ... }:

let
  superConfig = { };
  superOptions = { };

  nixosModule =
    { specialArgs, flakeModules, ... }:
    self.lib.factory.submoduleModule {
      inherit
        specialArgs
        flakeModules
        superConfig
        superOptions
        ;
      config = "nixosModule";
    };

  nixosConfigurationModule =
    {
      specialArgs,
      nixpkgs,
      flakeModules,
      ...
    }:
    self.lib.factory.configurationModule {
      inherit
        specialArgs
        nixpkgs
        flakeModules
        superConfig
        superOptions
        ;
      config = "nixosConfiguration";
      nixpkgsConfig = "nixosConfigurationNixpkgs";
    };

  packageModule =
    {
      specialArgs,
      nixpkgs,
      flakeModules,
      ...
    }:
    self.lib.factory.artifactModule {
      inherit
        specialArgs
        nixpkgs
        flakeModules
        superConfig
        superOptions
        ;
      config = "package";
      nixpkgsConfig = "packageNixpkgs";
    };

  appModule =
    {
      specialArgs,
      nixpkgs,
      flakeModules,
      ...
    }:
    self.lib.factory.artifactModule {
      inherit
        specialArgs
        nixpkgs
        flakeModules
        superConfig
        superOptions
        ;
      config = "app";
      nixpkgsConfig = "appNixpkgs";
    };

  flakeResult = self.lib.flake.make {
    inputs = {
      inherit nixpkgs;
      input = {
        modules.default = {
          imports = [
            nixosModule
            packageModule
            appModule
            nixosConfigurationModule
          ];
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
      someNixosModule = {
        nixosModule = {
          value = "some hello :)";
        };
        defaultNixosModule = true;
      };
      otherNixosModule = {
        nixosModule = {
          value = "other hello :)";
        };
      };
      x86_64_Only =
        { pkgs, ... }:
        {
          package = "${pkgs.system} hello x86_64-linux :)";
          packageNixpkgs.system = "x86_64-linux";
          app = "${pkgs.system} hello x86_64-linux :)";
          appNixpkgs.system = "x86_64-linux";
        };
      allDefaultSystems =
        { pkgs, ... }:
        {
          package = "${pkgs.system} hello all default systems :)";
          defaultPackage = true;
          app = "${pkgs.system} hello all default systems :)";
        };
      none = { };
    };
  };
in
rec {
  factory_submodule_artifact_correct =
    (self.lib.debug.trace (
      builtins.removeAttrs flakeResult [
        "modules"
        "nixosConfigurations"
      ]
    )) == {
      apps = {
        aarch64-darwin = {
          allDefaultSystems = "aarch64-darwin hello all default systems :)";
        };
        aarch64-linux = {
          allDefaultSystems = "aarch64-linux hello all default systems :)";
        };
        x86_64-darwin = {
          allDefaultSystems = "x86_64-darwin hello all default systems :)";
        };
        x86_64-linux = {
          allDefaultSystems = "x86_64-linux hello all default systems :)";
          x86_64_Only = "x86_64-linux hello x86_64-linux :)";
        };
      };
      nixosModules = {
        default = {
          key = "someNixosModule";
          value = "some hello :)";
        };
        otherNixosModule = {
          key = "otherNixosModule";
          value = "other hello :)";
        };
        someNixosModule = {
          key = "someNixosModule";
          value = "some hello :)";
        };
      };
      packages = {
        aarch64-darwin = {
          allDefaultSystems = "aarch64-darwin hello all default systems :)";
          default = "aarch64-darwin hello all default systems :)";
        };
        aarch64-linux = {
          allDefaultSystems = "aarch64-linux hello all default systems :)";
          default = "aarch64-linux hello all default systems :)";
        };
        x86_64-darwin = {
          allDefaultSystems = "x86_64-darwin hello all default systems :)";
          default = "x86_64-darwin hello all default systems :)";
        };
        x86_64-linux = {
          allDefaultSystems = "x86_64-linux hello all default systems :)";
          default = "x86_64-linux hello all default systems :)";
          x86_64_Only = "x86_64-linux hello x86_64-linux :)";
        };
      };
    };
  factory_submodule_correct = factory_submodule_artifact_correct;
  factory_artifact_correct = factory_submodule_artifact_correct;
}
