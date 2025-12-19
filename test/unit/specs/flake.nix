{ self, ... }:

let
  makeFlake = self.lib.flake.make;

  inputs = {
    perch = self // {
      modules.default = {
        imports = [
          (
            {
              perch,
              lib,
              flakeModules,
              ...
            }:
            let
              nixosModules = builtins.mapAttrs (
                _:
                perch.lib.module.patch (_: args: args) (_: args: args) (
                  _: result:
                  if result ? nixosModule then
                    result.nixosModule
                  else if result ? config && result.config ? nixosModule then
                    result.config.nixosModule
                  else
                    { }
                )
              ) flakeModules;
            in
            {
              _file = ./flake.nix;
              key = "input";
              options.nixosModule = lib.mkOption {
                type = lib.types.attrsOf lib.types.raw;
              };
              options.flake.nixosModules = lib.mkOption {
                type = lib.types.attrsOf lib.types.raw;
              };
              config.eval.privateConfig = [ [ "nixosModule" ] ];
              config.eval.publicConfig = [
                [
                  "flake"
                  "nixosModules"
                ]
              ];
              config.flake.nixosModules = nixosModules // {
                default = {
                  imports = builtins.attrValues nixosModules;
                };
              };
            }
          )
        ];
      };
    };
  };

  selfModules = {
    module = {
      _file = ./flake.nix;
      key = "self";
      nixosModule = {
        environment.systemPackages = [ "my package" ];
      };
    };
  };

  result = makeFlake { inherit inputs selfModules; };
  resultList = makeFlake {
    inherit inputs;
    selfModules = builtins.attrValues selfModules;
  };
in
{
  flake_make_nixos_modules_result_correct =
    result.nixosModules == {
      module = {
        environment.systemPackages = [ "my package" ];
      };
      default = {
        imports = [
          {
            environment.systemPackages = [ "my package" ];
          }
        ];
      };
    };

  flake_make_list_nixos_modules_result_correct =
    resultList.nixosModules == {
      # NOTE: -1 from being a list index
      module-1 = {
        environment.systemPackages = [ "my package" ];
      };
      default = {
        imports = [
          {
            environment.systemPackages = [ "my package" ];
          }
        ];
      };
    };
}
