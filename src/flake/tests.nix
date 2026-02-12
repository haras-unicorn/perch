{
  lib,
  specialArgs,
  config,
  ...
}:

{
  config = {
    eval.privateConfig = [ [ "flakeTests" ] ];
  };

  options = {
    flakeTests = {
      root = lib.mkOption (
        {
          type = lib.types.path;
          description = ''
            The root of the repository used to get test flakes
            and to set "self'" input
          '';
        }
        // (lib.optionalAttrs (specialArgs ? root) {
          default = specialArgs.root;
          defaultText = lib.literalExpression ''specialArgs.root'';
        })
      );

      prefix = lib.mkOption {
        type = lib.types.str;
        description = "The prefix from the root at which test flakes are located";
        default = "test";
      };

      path = lib.mkOption {
        type = lib.types.path;
        default = lib.path.append config.flakeTests.root config.flakeTests.prefix;
        defaultText = lib.literalExpression ''lib.path.append config.flakeTests.root config.flakeTests.prefix'';
        description = "Path to test flakes";
      };

      args = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = ''Additional arguments for "nix flake check"'';
        defaultText = lib.literalExpression ''
          [
            "--override-input"
            "self'"
            (builtins.toString (
              builtins.path {
                path = config.flakeTests.root;
                name = "self-prime";
              }
            ))
          ]
        '';
        default = [
          "--override-input"
          "self'"
          (builtins.toString (
            builtins.path {
              path = config.flakeTests.root;
              name = "self-prime";
            }
          ))
        ];
      };

      commands = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra commands to run for each flake during flake testing";
      };
    };
  };
}
