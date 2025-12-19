{
  self,
  perch,
  perchModules,
  lib,
  pkgs,
  ...
}:

{
  options = {
    flake.scratch = lib.mkOption {
      type = lib.types.raw;
    };
  };

  config = {
    flake.scratch = {
      inherit
        self
        perch
        perchModules
        ;
    };

    nixosModule = {
      environment.systemPackages = [
        pkgs.hello
      ];
    };

    nixosConfigurationNixpkgs.system = [ "x86_64-linux" ];
    nixosConfiguration = {
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };

      boot.loader.grub.device = "nodev";

      system.stateVersion = "25.11";

      environment.systemPackages = [
        pkgs.hello
      ];
    };

    packageNixpkgs.system = [
      "x86_64-linux"
      "x86_64-darwin"
    ];
    package = pkgs.writeShellApplication {
      name = "hello";
      runtimeInputs = [ pkgs.hello ];
      text = "hello";
    };

    checkNixpkgs.system = [
      "x86_64-linux"
      "x86_64-darwin"
    ];
    check = pkgs.runCommand "check" { } "touch $out";

    formatterNixpkgs.system = [
      "x86_64-linux"
      "x86_64-darwin"
    ];
    formatter = pkgs.writeShellApplication {
      name = "formatter";
      runtimeInputs = [ ];
      text = "exit 0";
    };

    devShellNixpkgs.system = [
      "x86_64-linux"
      "x86_64-darwin"
    ];
    devShell = pkgs.mkShell {
      packages = [
        pkgs.hello
      ];
    };
  };

}
