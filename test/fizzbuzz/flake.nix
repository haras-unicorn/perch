{
  outputs =
    { perch, ... }@inputs:
    perch.lib.flake.make {
      inherit inputs;
      selfModules.fizzbuzz =
        {
          self,
          pkgs,
          lib,
          config,
          ...
        }:
        {
          defaultPackage = true;
          packageNixpkgs.system = [
            "x86_64-linux"
            "x86_64-darwin"
          ];
          package = pkgs.writeShellApplication {
            name = "fizzbuzz";
            text = builtins.readFile ./fizzbuzz.sh;
            meta.description = "fizzbuzz";
          };

          defaultNixosModule = true;
          nixosModule = {
            options.programs.fizzbuzz = {
              enable = lib.mkEnableOption "fizzbuzz";
            };
            config = lib.mkIf config.programs.fizzbuzz.enable {
              environment.systemPackages = [
                self.packages.${pkgs.stdenv.hostPlatform.system}.default
              ];
            };
          };

          nixosConfigurationNixpkgs.system = "x86_64-linux";
          nixosConfiguration = {
            imports = [
              self.nixosModules.default
            ];
            fileSystems."/" = {
              device = "/dev/disk/by-label/NIXROOT";
              fsType = "ext4";
            };
            boot.loader.grub.device = "nodev";
            programs.fizzbuzz.enable = true;
            system.stateVersion = "25.11";
          };
        };
    };
}
