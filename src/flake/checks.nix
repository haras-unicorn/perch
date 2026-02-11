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
# TODO: nixpkgs configuration for pkgs tests
# TODO: systems configuration for pkgs tests

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

      traceDocTestsInChecks = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''Whether to trace successful passes of library tests in checks'';
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

          enrichedWithDocTests =
            if config.docTestsAsChecks && lib.hasAttrByPath [ "self" "lib" ] specialArgs then
              builtins.mapAttrs
                (
                  system: prevSystemChecks:
                  let
                    pkgs = import (if specialArgs ? nixpkgs then specialArgs.nixpkgs else nixpkgs) {
                      inherit system;
                    };

                    result = self.lib.test.unit {
                      inherit pkgs;
                      lib = specialArgs.self.lib;
                    };

                    # NOTE: dummy derivation so it doesn't evaluate for systems apart from host
                    resultAttrs = {
                      doc-tests = builtins.derivation {
                        inherit system;
                        name =
                          if result.success then
                            if config.traceDocTestsInChecks then
                              builtins.trace "doc test results for system '${system}'\n\n${result.message}" "doc-tests"
                            else
                              "doc-tests"
                          else
                            builtins.throw result.message;
                        builder = "${pkgs.bash}/bin/sh";
                        args = [
                          "-c"
                          ''echo "passed" > "$out"''
                        ];
                      };
                    };
                  in
                  prevSystemChecks // resultAttrs
                )
                (
                  builtins.listToAttrs (
                    builtins.map (system: {
                      name = system;
                      value = if prevChecks ? ${system} then prevChecks.${system} else { };
                    }) self.lib.defaults.systems
                  )
                )
            else
              prevChecks;

          enrichedWithFlakeTests =
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
              enrichedWithDocTests;
        in
        if config.docTestsAsChecks && lib.hasAttrByPath [ "self" "lib" ] specialArgs then
          let
            result = self.lib.test.unit { lib = specialArgs.self.lib; };
          in
          if result.success then
            if config.traceDocTestsInChecks then
              builtins.trace "doc test results\n\n${result.message}" enrichedWithFlakeTests
            else
              enrichedWithFlakeTests
          else
            builtins.throw result.message
        else
          enrichedWithFlakeTests;
    };
}
