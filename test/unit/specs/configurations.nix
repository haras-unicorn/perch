{ self, nixpkgs, ... }:

let
  x86conf = {
    fileSystems."/" = {
      device = "/dev/disk/by-label/NIX86";
      fsType = "ext4";
    };
    boot.loader.grub.device = "nodev";
    system.stateVersion = "25.11";
  };
  linuxConf = {
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
  configurations_make_correct =
    (self.lib.debug.trace (
      builtins.mapAttrs (_: value: value.config.fileSystems."/".device) configurations
    )) == {
      "linux-only-aarch64-linux" = linuxConf.fileSystems."/".device;
      "x86_64-linux-only-x86_64-linux" = x86conf.fileSystems."/".device;
      "linux-only-x86_64-linux" = linuxConf.fileSystems."/".device;
    };
}
