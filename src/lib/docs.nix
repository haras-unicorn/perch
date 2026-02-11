{ self, lib, ... }:

{
  flake.lib.docs.moduleOptionsMarkdown =
    self.lib.docs.function
      {
        description = ''
          Render module options docs as markdown.

          It also hides "_module.*" options and strips "declarations".
        '';
        type = self.lib.types.function (self.lib.types.args (
          { lib, ... }:
          {
            options = {
              pkgs = lib.mkOption {
                type = lib.types.raw;
                description = ''A "pkgs" set providing "nixosOptionsDoc".'';
              };

              specialArgs = lib.mkOption {
                type = lib.types.attrs;
                description = ''Special args passed to "lib.evalModules".'';
              };

              modules = lib.mkOption {
                type = lib.types.listOf lib.types.deferredModule;
                description = ''Modules to evaluate and document.'';
              };
            };
          }
        )) lib.types.str;
      }
      (
        {
          pkgs,
          specialArgs,
          modules,
        }:
        pkgs.writeText "perch-lib.md" (
          self.lib.options.toMarkdown {
            transformOptions =
              opt:
              opt
              // {
                visible = opt.visible or true && (builtins.head opt.loc) != "_module";
                declarations = [ ];
              };
            options =
              let
                eval = lib.evalModules {
                  inherit specialArgs;
                  modules = modules ++ [ lib.types.noCheckForDocsModule ];
                };
              in
              eval.options;
          }
        )
      );

  flake.lib.docs.libFunctionsMarkdown =
    self.lib.docs.function
      {
        description = ''
          Render docs for a library attrset as markdown.

          Hides ""_module.*"" options and strips "declarations".
        '';
        type = self.lib.types.function (self.lib.types.args (
          { lib, ... }:
          {
            options = {
              pkgs = lib.mkOption {
                type = lib.types.raw;
                description = ''A "pkgs" set providing "nixosOptionsDoc".'';
              };

              specialArgs = lib.mkOption {
                type = lib.types.attrs;
                description = ''Special args passed to "evalModules".'';
              };

              lib = lib.mkOption {
                type = lib.types.raw;
                description = ''The library attrset to document.'';
              };
            };
          }
        )) lib.types.str;
      }
      (
        let
          nixpkgsLib = lib;
        in
        {
          specialArgs,
          pkgs,
          lib,
        }:
        pkgs.writeText "perch-lib.md" (
          self.lib.options.toMarkdown {
            transformOptions =
              opt:
              opt
              // {
                visible = opt.visible or true && (builtins.head opt.loc) != "_module";
                declarations = [ ];
              };
            options =
              let
                eval = nixpkgsLib.evalModules {
                  inherit specialArgs;
                  modules = [
                    { options = self.lib.docs.libToOptions lib; }
                    nixpkgsLib.types.noCheckForDocsModule
                  ];
                };
              in
              eval.options;
          }
        )
      );

  flake.lib.docs.libToOptions =
    self.lib.docs.function
      {
        description = ''
          Render a flake library to options ready to be rendered to markdown.
        '';
        type = self.lib.types.function lib.types.attrs lib.types.attrs;
        tests =
          let
            wildLib = {
              meta = {
                version = "1.2.3";
                nums = [
                  1
                  2
                  3
                ];
                flags = {
                  enabled = true;
                  threshold = 10;
                };
              };

              misc = {
                greeting = "hi";
                n = 42;
                xs = [
                  "a"
                  { k = "v"; }
                  9
                ];
              };

              math = {
                inc = self.lib.docs.function {
                  description = "Increment an int";
                  type = self.lib.types.function lib.types.int lib.types.int;
                  asserted = false;
                } (x: x + 1);

                add = self.lib.docs.function {
                  description = "Add two ints (curried)";
                  type = self.lib.types.function lib.types.int (self.lib.types.function lib.types.int lib.types.int);
                  asserted = true;
                } (a: b: a + b);
              };

              junk = {
                a = {
                  b = {
                    c = "nope";
                  };
                };
              };
            };

            outTry = builtins.tryEval (self.lib.docs.libToOptions wildLib);
            out = outTry.value;

            isOption = x: builtins.isAttrs x && x ? type && x ? description;
          in
          {
            does_not_throw = outTry.success == true;

            keeps_only_documented_nodes_as_options =
              (out ? math)
              && (out.math ? inc)
              && (out.math ? add)
              && isOption out.math.inc
              && isOption out.math.add;

            prunes_random_leaves_and_subtrees = !(out ? meta) && !(out ? misc) && !(out ? junk);

            prunes_empty_containers = builtins.attrNames out == [ "math" ];

            option_payload_matches_docs_function =
              out.math.inc.description == "Increment an int"
              && out.math.inc.type.name == "function"
              && out.math.add.description == "Add two ints (curried)"
              && out.math.add.type.name == "function"
              && !(out.math.inc ? ${self.lib.docs.functionDocAttr})
              && !(out.math.add ? ${self.lib.docs.functionDocAttr});
          };
      }
      (
        let
          impl = lib.fix (
            libToOptions: options:
            if self.lib.attrset.isDictionary options then
              let
                pruned = lib.filterAttrs (_: value: value != null) (
                  lib.mapAttrs (_: value: libToOptions value) options
                );
              in
              if pruned == { } then null else pruned
            else if options ? ${self.lib.docs.functionDocAttr} then
              lib.mkOption { inherit (options.${self.lib.docs.functionDocAttr}) type description; }
            else
              null
          );
        in
        options:
        let
          result = impl options;
        in
        if result == null then { } else result
      );

  flake.lib.docs.functionDocAttr = "__functionDoc";

  flake.lib.docs.function =
    let
      makeAsserted =
        asserted: type:
        let
          makeAssertedIfResultIsFunction =
            if
              type.${self.lib.types.functionSignatureAttr}.resultType ? ${self.lib.types.functionSignatureAttr}
            then
              makeAsserted asserted type.${self.lib.types.functionSignatureAttr}.resultType
            else
              function: function;
        in
        if asserted == false then
          function: function
        else if asserted == "argument" then
          function: argument:
          assert type.${self.lib.types.functionSignatureAttr}.argumentType.check argument;
          makeAssertedIfResultIsFunction (function argument)
        else if asserted == "result" then
          function: argument:
          let
            result = function argument;
            resultType = type.${self.lib.types.functionSignatureAttr}.resultType;
          in
          assert resultType.check result;
          makeAssertedIfResultIsFunction result
        else
          function: argument:
          assert type.${self.lib.types.functionSignatureAttr}.argumentType.check argument;
          let
            result = function argument;
            resultType = type.${self.lib.types.functionSignatureAttr}.resultType;
          in
          assert resultType.check result;
          makeAssertedIfResultIsFunction result;

      # NOTE: reimplemented here to not cause infinite recursion
      # on the actual function
      toFunctor =
        x:
        if (builtins.isAttrs x && x ? __functor) then
          x
        else if builtins.isFunction x then
          {
            __functionArgs = builtins.functionArgs x;
            __functor = _self: x;
          }
        else
          throw "expected a function or a functor attrset";

      undocumented =
        {
          type,
          description ? "",
          asserted ? false,
          tests ? { },
        }:
        function:
        (toFunctor (makeAsserted asserted type function))
        // {
          ${self.lib.types.functionSignatureAttr} = type.${self.lib.types.functionSignatureAttr};
          ${self.lib.docs.functionDocAttr} = {
            inherit
              description
              type
              asserted
              tests
              ;
          };
        };
    in
    undocumented {
      description = ''
        Attach documentation (and optional runtime assertions) to a function.
      '';
      asserted = "argument";
      type = self.lib.types.function (self.lib.types.args {
        options = {
          type = lib.mkOption {
            description = ''Function type'';
            # TODO: find alternative to addCheck?
            # https://github.com/NixOS/nixpkgs/issues/396021
            type = lib.types.addCheck lib.types.optionType (
              type:
              builtins.isAttrs type
              && type ? ${self.lib.types.functionSignatureAttr}
              && type.${self.lib.types.functionSignatureAttr} ? argumentType
              && (lib.types.optionType.check type.${self.lib.types.functionSignatureAttr}.argumentType)
              && type.${self.lib.types.functionSignatureAttr} ? resultType
              && (lib.types.optionType.check type.${self.lib.types.functionSignatureAttr}.resultType)
            );
          };
          description = lib.mkOption {
            description = ''Function description'';
            default = "";
            type = lib.types.str;
          };
          asserted = lib.mkOption {
            description = ''Whether the function argument/result will be asserted'';
            default = false;
            type = lib.types.either lib.types.bool (
              lib.types.enum [
                "argument"
                "result"
              ]
            );
          };
          tests = lib.mkOption {
            description = ''Unit test attrset or function for this function'';
            default = { };
            type =
              let
                messageOption = lib.mkOption {
                  type = lib.types.str;
                  description = "Test failure message";
                  default = "test failed";
                };

                targetOption = lib.mkOption {
                  type = self.lib.types.opaqueFunction;
                  description = "Function to test";
                };

                testType = lib.types.oneOf [
                  lib.types.bool
                  (self.lib.types.args {
                    options = {
                      success = lib.mkOption {
                        type = lib.types.bool;
                        description = "Whether te test passes or not";
                      };
                      message = messageOption;
                    };
                  })
                  (self.lib.types.args {
                    options = {
                      actual = lib.mkOption {
                        type = lib.types.raw;
                        description = "Actual value to be equated with expected";
                      };
                      expected = lib.mkOption {
                        type = lib.types.raw;
                        description = "Expected value to be equated against actual";
                      };
                      message = messageOption;
                    };
                  })
                ];

                attrsOfTestType = lib.types.attrsOf testType;
              in
              lib.types.oneOf [
                attrsOfTestType
                (self.lib.types.function self.lib.types.opaqueFunction attrsOfTestType)
                (self.lib.types.function (self.lib.types.args {
                  options.target = targetOption;
                }) attrsOfTestType)
                (self.lib.types.function (self.lib.types.args {
                  options = {
                    target = targetOption;
                    pkgs = lib.mkOption {
                      type = lib.types.raw;
                      description = ''
                        Pkgs constructed from nixpkgs if available.
                        If pkgs are required and not available for this test run
                        this testing function wont be ran.
                      '';
                    };
                  };
                }) attrsOfTestType)
              ];
          };
        };
      }) (self.lib.types.function self.lib.types.opaqueFunction self.lib.types.opaqueFunction);
      tests =
        let
          inc = (x: x + 1);
          badResult = (_x: "oops");
          add = (a: b: a + b);

          tIntToInt = self.lib.types.function lib.types.int lib.types.int;
          tIntToIntToInt = self.lib.types.function lib.types.int (
            self.lib.types.function lib.types.int lib.types.int
          );
        in
        {
          attaches_doc_and_signature_attrs =
            let
              f = self.lib.docs.function {
                description = "increment";
                type = tIntToInt;
                asserted = false;
              } inc;
            in
            f.${self.lib.docs.functionDocAttr}.description == "increment"
            && f.${self.lib.docs.functionDocAttr}.asserted == false
            && f.${self.lib.docs.functionDocAttr}.type.name == "function"
            && f.${self.lib.types.functionSignatureAttr}.argumentType.name == "int"
            && f.${self.lib.types.functionSignatureAttr}.resultType.name == "int";

          is_callable =
            let
              f = self.lib.docs.function {
                description = "increment";
                type = tIntToInt;
                asserted = false;
              } inc;
            in
            f 1 == 2;

          argument_assert_fails =
            let
              f = self.lib.docs.function {
                description = "increment";
                type = tIntToInt;
                asserted = "argument";
              } inc;
              r = builtins.tryEval (f "nope");
            in
            r.success == false;

          result_assert_fails =
            let
              f = self.lib.docs.function {
                description = "badResult";
                type = tIntToInt;
                asserted = "result";
              } badResult;
              r = builtins.tryEval (f 1);
            in
            r.success == false;

          asserted_true_checks_both =
            let
              f = self.lib.docs.function {
                description = "increment";
                type = tIntToInt;
                asserted = true;
              } inc;

              badArg = builtins.tryEval (f "x");
              good = builtins.tryEval (f 2);
            in
            (badArg.success == false) && (good.success == true) && (good.value == 3);

          wraps_curried_functions_recursively =
            let
              f = self.lib.docs.function {
                description = "add";
                type = tIntToIntToInt;
                asserted = true;
              } add;

              good = builtins.tryEval ((f 1) 2);
              bad1 = builtins.tryEval ((f "x") 2);
              bad2 = builtins.tryEval ((f 1) "y");
            in
            (good.success && good.value == 3) && (bad1.success == false) && (bad2.success == false);

          returns_functor =
            let
              f = self.lib.docs.function {
                description = "increment";
                type = self.lib.types.function lib.types.int lib.types.int;
                asserted = false;
              } (x: x + 1);
            in
            self.lib.trivial.isFunctor f == true;

          asserted_false_does_not_assert =
            let
              f = self.lib.docs.function {
                description = "lies";
                type = self.lib.types.function lib.types.int lib.types.int;
                asserted = false;
              } (_: "not an int");
              r = builtins.tryEval (f 1);
            in
            r.success == true && r.value == "not an int";
        };
    } undocumented;
}
