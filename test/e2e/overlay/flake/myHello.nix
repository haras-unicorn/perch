{
  self,
  super,
  pkgs,
  ...
}:

{
  overlays.default = final: prev: {
    myHello = final.writeShellApplication {
      name = "hello";
      runtimeInputs = [ prev.hello ];
      text = ''
        hello
      '';
    };
  };

  defaultApp = true;
  appNixpkgs = {
    system = [
      "x86_64-linux"
      "x86_64-darwin"
    ];
    overlays = [ self.overlays.default ];
  };
  app = pkgs.myHello;

  defaultNixosModule = true;
  nixosModule = {
    environment.systemPackages = [
      pkgs.myHello
    ];
  };

  nixosConfigurationNixpkgs = {
    system = "x86_64-linux";
    overlays = [ self.overlays.default ];
  };
  nixosConfiguration = {
    imports = [
      super.config.flake.nixosModules.default
    ];

    fileSystems."/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };

    boot.loader.grub.device = "nodev";

    system.stateVersion = "25.11";
  };
}
