{
  lib,
  self,
  nixpkgs,
  ...
}:

{
  flake.lib.test.unit =
    self.lib.docs.function
      {
        description = ''
          Evaluate unit tests for a flake library attrset.
        '';
        type =
          self.lib.types.function
            (self.lib.types.args {
              options = {
                lib = lib.mkOption {
                  type = self.lib.types.recursiveAttrsOf lib.types.raw;
                  description = "Library with tests to evaluate";
                };
              };
            })
            (
              self.lib.types.args {
                options = {
                  success = lib.mkOption {
                    type = lib.types.bool;
                    description = "Whether all tests passed";
                  };
                  message = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    description = "Message to display in case of test failure";
                  };
                };
              }
            );
        tests =
          let
            doc = self.lib.docs.functionDocAttr;

            mkFn =
              {
                name ? "fn",
                body ? (x: x),
                tests,
              }:
              let
                f = self.lib.trivial.toFunctor body;
              in
              f
              // {
                ${doc} = {
                  inherit tests;
                  description = name;
                };
              };

            run = fakeLib: self.lib.test.unit { lib = fakeLib; };
          in
          {
            empty_lib_is_success =
              let
                res = run { };
              in
              res.success && res.message == null;

            ignores_functions_without_tests =
              let
                res = run {
                  foo = (x: x + 1); # no doc attr => ignored
                };
              in
              res.success && res.message == null;

            all_tests_pass_success =
              let
                res = run {
                  ok = mkFn {
                    name = "ok";
                    body = x: x;
                    tests = fn: {
                      returns_1 = (fn 1) == 1;
                      returns_2 = (fn 2) == 2;
                    };
                  };
                };
              in
              res.success && res.message == null;

            failing_test_sets_message =
              let
                res = run {
                  bad = mkFn {
                    name = "bad";
                    body = x: x;
                    tests = {
                      one_is_one = 1 == 1;
                      one_is_two = 1 == 2;
                    };
                  };
                };
              in
              !res.success
              && res.message != null
              && lib.strings.hasInfix "Tests failed!" res.message
              && lib.strings.hasInfix "bad" res.message
              && lib.strings.hasInfix "one_is_two" res.message;

            throwing_tests_is_failed_evaluation =
              let
                res = run {
                  explode = mkFn {
                    name = "explode";
                    body = x: x;
                    tests = _: builtins.throw "boom";
                  };
                };
              in
              (!res.success)
              && res.message != null
              && lib.strings.hasInfix "failed evaluation" res.message
              && lib.strings.hasInfix "explode" res.message;
          };
      }
      (
        let
          nixpkgsLib = lib;
        in
        { lib }:
        let
          flattenedLib = self.lib.attrset.flatten {
            separator = ".";
            attrs = lib;
          };
          testedLibFunctions = nixpkgsLib.filterAttrs (
            _: value:
            nixpkgsLib.isFunction value
            && value ? ${self.lib.docs.functionDocAttr}
            && value.${self.lib.docs.functionDocAttr} ? tests
          ) flattenedLib;
          functionTestResults = nixpkgsLib.flatten (
            builtins.map (
              { name, value, ... }:
              let
                testEval = builtins.tryEval (
                  if nixpkgsLib.isFunction value.${self.lib.docs.functionDocAttr}.tests then
                    value.${self.lib.docs.functionDocAttr}.tests value
                  else
                    value.${self.lib.docs.functionDocAttr}.tests
                );
              in
              if testEval.success then
                let
                  success = builtins.all nixpkgsLib.id (builtins.attrValues testEval.value);
                  message = if success then "" else "failed tests";
                in
                {
                  inherit success message;
                  function = name;
                  tests = builtins.map (
                    test:
                    let
                      success = test.value;
                      message = if success then "failed test" else "";
                    in
                    {
                      inherit success message;
                      function = name;
                      test = test.name;
                    }
                  ) (nixpkgsLib.attrsToList testEval.value);
                }
              else
                {
                  function = name;
                  success = false;
                  message = "failed evaluation";
                  tests = [ ];
                }
            ) (nixpkgsLib.attrsToList testedLibFunctions)
          );
          functionTestFailures = builtins.map (
            result: result // { tests = builtins.filter (result: !result.success) result.tests; }
          ) (builtins.filter (result: !result.success) functionTestResults);

          totalFunctionCount = builtins.length functionTestResults;
          successFunctionCount = builtins.length (
            builtins.filter (result: result.success) functionTestResults
          );
          totalTestCount = builtins.foldl' (acc: next: acc + next) 0 (
            builtins.map (result: builtins.length result.tests) functionTestResults
          );
          successTestCount = builtins.foldl' (acc: next: acc + next) 0 (
            builtins.map (
              result: builtins.length (builtins.filter (result: result.success) result.tests)
            ) functionTestResults
          );

          success = builtins.all ({ success, ... }: success) functionTestResults;
          failureMessage = self.lib.string.indent 2 (
            builtins.concatStringsSep "\n" (
              builtins.map (
                {
                  function,
                  message,
                  tests,
                  ...
                }:
                let
                  testFailureMessage =
                    if builtins.length tests > 0 then
                      "\n"
                      + self.lib.string.indent 2 (
                        builtins.concatStringsSep "\n" (
                          builtins.map ({ test, message, ... }: ''- ${test}: ${message}'') tests
                        )
                      )
                    else
                      "";
                in
                ''- ${function}: ${message}'' + testFailureMessage
              ) functionTestFailures
            )
          );
          message = ''
            Tests failed!

            Functions passed: ${builtins.toString successFunctionCount}/${builtins.toString totalFunctionCount}
            Tests passed: ${builtins.toString successTestCount}/${builtins.toString totalTestCount}

            Function failures:
          ''
          + failureMessage;
        in
        {
          inherit success;
          message = if success then null else message;
        }
      );

  flake.lib.test.flake =
    self.lib.docs.function
      {
        description = ''
          Evaluate flake tests in a directory and
          returns an attrset in the form expected for flake outputs.
        '';
        type = self.lib.types.function (self.lib.types.args {
          options = {
            path = lib.mkOption {
              type = lib.types.path;
              description = ''Path to the directory containing test flakes'';
            };
            args = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = ''Additional arguments for "nix flake check"'';
            };
            recursive = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Creates packages suitable for flake checks.

                IMPORTANT: this will require the recursive-nix feature
                which will most likely fail due to a current regression
                in nix (https://github.com/NixOS/nix/issues/14529)
              '';
            };
          };
        }) (lib.types.attrsOf (lib.types.attrsOf lib.types.package));
      }
      (
        {
          path,
          args ? [ ],
          recursive ? false,
        }:
        builtins.listToAttrs (
          builtins.map (
            system:
            let
              pkgs = import nixpkgs {
                inherit system;
              };

              flakes = builtins.map ({ name, ... }: lib.path.append path name) (
                builtins.filter (
                  { name, value }:
                  (value == "directory")
                  && (
                    let
                      contents = builtins.readDir (lib.path.append path name);
                    in
                    contents ? "flake.nix" && contents."flake.nix" == "regular"
                  )
                ) (lib.attrsToList (builtins.readDir path))
              );
            in
            {
              name = system;
              value = builtins.listToAttrs (
                builtins.map (
                  flake:
                  let
                    name = builtins.baseNameOf flake;

                    nativeBuildInputs =
                      if recursive then
                        [
                          pkgs.git
                          pkgs.nix
                        ]
                      else
                        [ pkgs.git ];

                    requiredSystemFeatures = if recursive then [ "recursive-nix" ] else [ ];

                    setup =
                      if recursive then
                        ''
                          tmp="''${TMPDIR:?}"
                          out="''${out:?}"
                          HOME="$tmp/home"
                          export HOME
                          mkdir -p "$HOME"
                        ''
                      else
                        ''
                          tmp="$(mktemp -d)"
                          out="$tmp/out"
                        '';
                    cleanup = if recursive then "" else ''rm -rf "$tmp"'';
                    text = ''
                      depth="''${1:-1}"
                      if ! [[ "$depth" =~ ^[0-9]+$ ]]; then
                        echo "Error: depth must be a positive integer" >&2
                        exit 1
                      fi
                      prompt="$(printf '>%.0s' $(seq 1 "$depth"))"

                      cleanup() {
                        ${cleanup}
                      }
                      trap cleanup EXIT
                      ${setup}
                      log="$tmp/flake-check.log"
                      touch "$log"

                      echo "$prompt testing ${name}..."
                      echo ""

                      cp -r "${flake}" "$tmp/src"
                      chmod -R u+rwX "$tmp/src"
                      cd "$tmp/src"

                      git init -q
                      git config user.name "flake-tester"
                      git config user.email "flake-tester@localhost"
                      git add .
                      git commit -qm "flake-test-${name}"

                      set +e
                      printf "%s\n\n" "''${prompt}> nix flake show" >>"$log"
                      nix flake show \
                        --extra-experimental-features flakes \
                        --extra-experimental-features nix-command \
                        ${lib.escapeShellArgs args} \
                        "git+file://$tmp/src" >>"$log" 2>&1
                      rc=$?
                      if [ "$rc" -ne 0 ]; then
                        cat "$log" >&2
                        echo "$prompt ${name} not ok!" >&2
                        exit "$rc"
                      fi
                      printf "\n\n%s\n\n" "''${prompt}> nix flake check" >>"$log"
                      nix flake check \
                        --extra-experimental-features flakes \
                        --extra-experimental-features nix-command \
                        ${lib.escapeShellArgs args} \
                        "git+file://$tmp/src" >>"$log" 2>&1
                      rc=$?
                      if [ "$rc" -ne 0 ]; then
                        cat "$log" >&2
                        echo ""
                        echo "$prompt ${name} not ok!" >&2
                        exit "$rc"
                      fi
                      set -e

                      cp "$log" "''${out:?}"
                      cat "''${out:?}"
                      echo ""
                      echo "$prompt ${name} ok!"
                    '';

                    testName = "flake-test-${name}";

                    application = pkgs.writeShellApplication {
                      name = testName;
                      derivationArgs = {
                        inherit
                          nativeBuildInputs
                          requiredSystemFeatures
                          ;
                      };
                      inherit
                        text
                        ;
                    };

                    value =
                      if recursive then
                        pkgs.runCommand testName {
                          nativeBuildInputs = [ application ];
                        } ''${testName} > "$out"''
                      else
                        application;
                  in
                  {
                    inherit name value;
                  }
                ) flakes
              );
            }
          ) self.lib.defaults.systems
        )
      );
}
