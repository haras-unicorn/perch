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

                pkgs = lib.mkOption {
                  type = lib.types.raw;
                  description = ''
                    Pkgs constructed via nixpkgs.
                    If provided, runs only tests that require pkgs.
                    If not provided, runs only tests that do not require pkgs.
                  '';
                  default = null;
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
                    type = lib.types.str;
                    description = "Message to display";
                  };
                };
              }
            );
        tests =
          {
            pkgs ? null,
          }:
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

            run =
              fakeLib:
              self.lib.test.unit {
                inherit pkgs;
                lib = fakeLib;
              };
          in
          {
            empty_lib_is_success =
              let
                res = run { };
              in
              res.success;

            ignores_functions_without_tests =
              let
                res = run {
                  foo = (x: x + 1);
                };
              in
              res.success;

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
              res.success;

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
              if pkgs == null then
                !res.success
                && res.message != null
                && lib.strings.hasInfix "Tests failed!" res.message
                && lib.strings.hasInfix "bad" res.message
                && lib.strings.hasInfix "one_is_two" res.message
              else
                res.success;

            runs_tests_with_attrset_args =
              let
                res = run {
                  test_attrset_args = mkFn {
                    name = "test_attrset_args";
                    body = x: x;
                    tests =
                      { test_attrset_args, target }:
                      {
                        id_is_id = (test_attrset_args 1) == 1;
                        id_fails = (target 2) == 1;
                      };
                  };
                };
              in
              if pkgs == null then
                !res.success
                && res.message != null
                && lib.strings.hasInfix "Tests failed!" res.message
                && !(lib.strings.hasInfix "id_is_id" res.message)
                && lib.strings.hasInfix "id_fails" res.message
              else
                res.success;

            runs_tests_with_pkgs_args =
              let
                res = run {
                  test_pkgs_args = mkFn {
                    name = "test_pkgs_args";
                    body = x: x;
                    tests =
                      { target, pkgs }:
                      {
                        pkgs_is_pkgs =
                          lib.hasAttrByPath [ "stdenv" "hostPlatform" "system" ] pkgs
                          && builtins.isString pkgs.stdenv.hostPlatform.system;
                      };
                  };
                  id_test = mkFn {
                    name = "test_pkgs_args";
                    body = x: x;
                    tests =
                      { target }:
                      {
                        id_is_id = (target 1) == 1;
                        false_result = false;
                      };
                  };
                };
              in

              if pkgs == null then
                !res.success
                && res.message != null
                && lib.strings.hasInfix "Tests failed!" res.message
                && !(lib.strings.hasInfix "pkgs_is_pkgs" res.message)
                && lib.strings.hasInfix "false_result" res.message
              else
                res.success;
          };
      }
      (
        let
          nixpkgsLib = lib;
        in
        {
          lib,
          pkgs ? null,
        }:
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

          functionTestResults = builtins.filter ({ tests, ... }: builtins.length tests > 0) (
            builtins.map (
              { name, value, ... }:
              let
                functionTests = builtins.addErrorContext "while evaluating tests results for function '${name}'" (
                  if nixpkgsLib.isFunction value.${self.lib.docs.functionDocAttr}.tests then
                    let
                      functionArgs = nixpkgsLib.functionArgs value.${self.lib.docs.functionDocAttr}.tests;

                      resultWithArgs = value.${self.lib.docs.functionDocAttr}.tests (
                        nixpkgsLib.filterAttrs (name: _: functionArgs ? ${name}) {
                          inherit pkgs;
                          target = value;
                          ${name} = value;
                        }
                      );
                    in
                    if pkgs == null then
                      if functionArgs == { } then
                        value.${self.lib.docs.functionDocAttr}.tests value
                      else if functionArgs ? pkgs && functionArgs.pkgs == false then
                        { }
                      else
                        resultWithArgs
                    else if functionArgs ? pkgs then
                      resultWithArgs
                    else
                      { }
                  else if pkgs == null then
                    value.${self.lib.docs.functionDocAttr}.tests
                  else
                    { }
                );

                tests = builtins.map (
                  test:
                  let
                    initial =
                      builtins.addErrorContext "while evaluating test '${test}' of function '${name}'"
                        functionTests.${test};
                  in
                  {
                    inherit test;

                    function = name;

                    success =
                      if builtins.isAttrs initial then
                        if initial ? success then
                          let
                            success = builtins.addErrorContext "while evaluating test '${test}' of function '${name}'" initial.value.success;
                          in
                          success
                        else if initial ? actual && initial ? expected then
                          let
                            actual = builtins.addErrorContext "while evaluating test actual '${test}' of function '${name}'" initial.actual;
                            expected = builtins.addErrorContext "while evaluating test expected '${test}' of function '${name}'" initial.expected;
                          in
                          actual == expected
                        else
                          false
                      else
                        initial;

                    message =
                      if success then
                        "passed"
                      else if builtins.isAttrs initial then
                        if initial ? message && builtins.isString initial.message then
                          initial.message
                        else if initial ? actual && initial ? expected then
                          let
                            actual = builtins.addErrorContext "while evaluating test actual '${test}' of function '${name}'" initial.actual;
                            expected = builtins.addErrorContext "while evaluating test expected '${test}' of function '${name}'" initial.expected;
                          in
                          "actual is not equal to expected"
                          + "\n  - actual: '${self.lib.debug.traceString actual}'"
                          + "\n  - expected: '${self.lib.debug.traceString expected}'"
                        else
                          "failed"
                      else
                        "failed";
                  }
                ) (builtins.attrNames functionTests);

                success = builtins.all ({ success, ... }: success) tests;
              in
              {
                inherit success tests;

                message = if success then "passed" else "failed";

                function = name;
              }
            ) (nixpkgsLib.attrsToList testedLibFunctions)
          );
          functionTestFailures = builtins.map (
            result: result // { tests = builtins.filter (result: !result.success) result.tests; }
          ) (builtins.filter (result: !result.success) functionTestResults);
          functionTestPasses = builtins.map (
            result: result // { tests = builtins.filter (result: result.success) result.tests; }
          ) (builtins.filter (result: result.success) functionTestResults);

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
          failedOrPassed = if successFunctionCount == totalFunctionCount then "passed" else "failed";

          mkAggregatedMessage =
            failuresOrPasses:
            self.lib.string.indent 2 (
              builtins.concatStringsSep "\n" (
                builtins.map (
                  {
                    function,
                    message,
                    tests,
                    ...
                  }:
                  let
                    aggregatedMessage =
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
                  ''- ${function}: ${message}'' + aggregatedMessage
                ) failuresOrPasses
              )
            );
        in
        {
          success = builtins.all ({ success, ... }: success) functionTestResults;

          message = ''
            Tests ${failedOrPassed}!

            Functions passed: ${builtins.toString successFunctionCount}/${builtins.toString totalFunctionCount}
            Tests passed: ${builtins.toString successTestCount}/${builtins.toString totalTestCount}

            Function failures:
            ${mkAggregatedMessage functionTestFailures}

            Function passes:
            ${mkAggregatedMessage functionTestPasses}
          '';
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
              default = [ ];
            };
            commands = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Extra commands to run for each flake during flake testing";
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
          commands ? [ ],
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

                    extra =
                      if commands == [ ] then
                        ""
                      else
                        builtins.concatStringsSep "\n" (
                          builtins.map (
                            command:
                            let
                              trimmed = lib.trim command;
                            in
                            ''
                              script=$(cat <<'PERCH_DEV_FLAKE_TEST_ESCAPE'
                              ${trimmed}
                              PERCH_DEV_FLAKE_TEST_ESCAPE
                              )
                              {
                                while IFS= read -r line; do
                                  printf "%s> %s\n" "$prompt" "$line"
                                done <<< "$script"
                                printf "\n"
                              } >> "$log"
                              ( ${trimmed} ) >>"$log" 2>&1
                              rc=$?
                              printf "\n\n" >>"$log"
                              if [ "$rc" -ne 0 ]; then
                                cat "$log" >&2
                                echo "$prompt ${name} not ok!" >&2
                                exit "$rc"
                              fi
                            ''
                          ) commands
                        );

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

                      printf "%s testing ${name}...\n\n" "$prompt"

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
                      printf "\n\n" >>"$log"
                      if [ "$rc" -ne 0 ]; then
                        cat "$log" >&2
                        echo "$prompt ${name} not ok!" >&2
                        exit "$rc"
                      fi
                      ${extra}
                      printf "%s\n\n" "''${prompt}> nix flake check" >>"$log"
                      nix flake check \
                        --extra-experimental-features flakes \
                        --extra-experimental-features nix-command \
                        ${lib.escapeShellArgs args} \
                        "git+file://$tmp/src" >>"$log" 2>&1
                      rc=$?
                      printf "\n\n" >>"$log"
                      if [ "$rc" -ne 0 ]; then
                        cat "$log" >&2
                        echo "$prompt ${name} not ok!" >&2
                        exit "$rc"
                      fi
                      set -e

                      cp "$log" "''${out:?}"
                      cat "''${out:?}"
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
