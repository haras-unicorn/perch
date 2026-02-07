{
  self,
  nixpkgs,
  flakeModules,
  specialArgs,
  config,
  options,
  lib,
  ...
}:

# TODO: mkMerge when patch supports that kinda stuff

self.lib.factory.artifactModule {
  inherit specialArgs flakeModules nixpkgs;
  superConfig = config;
  superOptions = options;
  nixpkgsConfig = "checkNixpkgs";
  config = "check";
  mapOptions =
    prev:
    prev
    // {
      docTestsAsChecks = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''Convert all "perch.lib.docs.function" tests to checks'';
      };

      flakeTests.asChecks = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Aggregate checks of flakes from a specified path to
          checks in this flake

          IMPORTANT: this will require the recursive-nix feature
          which will most likely fail due to a current regression
          in nix (nixpkgs issue 14529)
        '';
      };
    };
  mapConfig =
    prevChecks: prev:
    prev
    // {
      eval = prev.eval // {
        privateConfig = prev.eval.privateConfig ++ [
          [ "docTestsAsChecks" ]
        ];
      };

      flake.checks =
        let
          flakeTests = self.lib.test.flake {
            path = config.flakeTests.path;
            args = config.flakeTests.args;
            recursive = true;
          };

          prevAndFlakeTestChecks =
            if config.flakeTests.asChecks then
              builtins.listToAttrs (
                builtins.map (
                  system:
                  let
                    prevSystemChecks = if prevChecks ? ${system} then prevChecks.${system} else { };
                    systemFlakeTests = if flakeTests ? ${system} then flakeTests.${system} else { };
                  in
                  {
                    name = system;
                    value =
                      prevSystemChecks
                      // (lib.mapAttrs' (name: value: {
                        inherit value;
                        name = "test-flake-${name}";
                      }) systemFlakeTests);

                  }
                ) self.lib.defaults.systems
              )
            else
              prevChecks;
        in
        if config.docTestsAsChecks && lib.hasAttrByPath [ "self" "lib" ] specialArgs then
          let
            result = self.lib.test.unit { lib = specialArgs.self.lib; };
          in
          if result.success then prevAndFlakeTestChecks else throw result.message
        else
          prevAndFlakeTestChecks;
    };
}
