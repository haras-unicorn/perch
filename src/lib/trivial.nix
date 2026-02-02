{ self, lib, ... }:

{
  flake.lib.trivial.isFunctor = self.lib.docs.function {
    description = "Return true if a value is a functor attrset (has a functional __functor field).";
    type = self.lib.types.function lib.types.raw lib.types.bool;
    tests =
      let
        dummyFun =
          {
            a,
            b ? 2,
          }:
          {
            out = a + b;
            inherit a b;
          };
      in
      {
        false_for_plain_function =
          let
            f = dummyFun;
          in
          self.lib.trivial.isFunctor f == false;
      };
  } (x: builtins.isAttrs x && x ? __functor && builtins.isFunction x.__functor);

  flake.lib.trivial.toFunctor =
    self.lib.docs.function
      {
        description = "Convert a function to a functor attrset (or pass through an existing functor), throwing on other values.";
        type = self.lib.types.function lib.types.raw lib.types.raw;
        tests =
          let
            dummyFun =
              {
                a,
                b ? 2,
              }:
              {
                out = a + b;
                inherit a b;
              };
          in
          {
            wraps_function_into_functor =
              let
                fun = self.lib.trivial.toFunctor dummyFun;
                r = fun { a = 3; };
              in
              (self.lib.trivial.isFunctor fun)
              && (
                r == {
                  out = 5;
                  a = 3;
                  b = 2;
                }
              );

            preserves_functionArgs_metadata =
              let
                fun = self.lib.trivial.toFunctor dummyFun;
              in
              fun.__functionArgs == builtins.functionArgs dummyFun;

            is_idempotent_on_functors =
              let
                once = self.lib.trivial.toFunctor dummyFun;
                twice = self.lib.trivial.toFunctor once;
              in
              (self.lib.trivial.isFunctor twice)
              && (twice.__functionArgs == once.__functionArgs)
              && (
                twice {
                  a = 1;
                  b = 4;
                } == once {
                  a = 1;
                  b = 4;
                }
              );

            throws_on_non_function_non_functor =
              let
                bad = builtins.tryEval (self.lib.trivial.toFunctor 123);
              in
              bad.success == false;
          };
      }
      (
        x:
        if (builtins.isAttrs x && x ? __functor) then
          x
        else if builtins.isFunction x then
          {
            __functionArgs = builtins.functionArgs x;
            __functor = _self: x;
          }
        else
          throw "perch.lib.trivial.toFunctor: expected a function or a functor attrset"
      );

  flake.lib.trivial.mapFunctionResult =
    self.lib.docs.function
      {
        description = "Wrap a function so its result is transformed by a mapper while preserving declared function arguments.";
        type = self.lib.types.function (self.lib.types.function lib.types.raw (self.lib.types.function lib.types.raw lib.types.raw)) (
          self.lib.types.function lib.types.raw lib.types.raw
        );
        tests =
          let
            dummyFun =
              {
                a,
                b ? 2,
              }:
              {
                out = a + b;
                inherit a b;
              };
          in
          {
            wraps_result =
              let
                f = dummyFun;
                mapped = self.lib.trivial.mapFunctionResult (_: res: res // { tag = "ok"; }) f;
                r = mapped { a = 3; };
              in
              r == {
                out = 5;
                a = 3;
                b = 2;
                tag = "ok";
              };

            preserves_args =
              let
                f = dummyFun;
                mapped = self.lib.trivial.mapFunctionResult (_: res: res) f;
                args = builtins.attrNames (lib.functionArgs mapped);
              in
              builtins.all (k: builtins.elem k args) [
                "a"
                "b"
              ];
          };
      }
      (
        mapResult: function:
        let
          args = lib.functionArgs function;
          mapped = args: mapResult function (function args);
        in
        lib.setFunctionArgs mapped args
      );

  flake.lib.trivial.mapFunctionArgs =
    self.lib.docs.function
      {
        description = "Wrap a function to rewrite its argument declaration and argument value before calling it.";
        type = self.lib.types.function (self.lib.types.function lib.types.raw (self.lib.types.function lib.types.raw lib.types.raw)) (
          self.lib.types.function lib.types.raw (self.lib.types.function lib.types.raw lib.types.raw)
        );
        tests =
          let
            argsOnly =
              {
                x,
                y ? 10,
              }:
              {
                sum = x + y;
              };
          in
          {
            maps_inputs =
              let
                f = argsOnly;
                mapped = self.lib.trivial.mapFunctionArgs (_: decl: decl) (_: args: args // { x = args.x * 2; }) f;
              in
              mapped { x = 5; } == {
                sum = 5 * 2 + 10;
              };

            preserves_args =
              let
                f = argsOnly;
                mapped = self.lib.trivial.mapFunctionArgs (_: decl: decl) (_: x: x) f;
                args = lib.functionArgs mapped;
              in
              (args ? x) && (args ? y);

            can_change_declaration =
              let
                f = argsOnly;
                mapped =
                  self.lib.trivial.mapFunctionArgs
                    (_: decl: {
                      z = false;
                      y = false;
                    })
                    (_: args: {
                      x = args.z;
                      y = args.y;
                    })
                    f;
                argsMeta = lib.functionArgs mapped;
                out = mapped {
                  z = 4;
                  y = 6;
                };
              in
              (argsMeta ? z) && (argsMeta ? y) && (!(argsMeta ? x)) && out == { sum = 4 + 6; };
          };
      }
      (
        mapArgsDeclaration: mapArgsDefinition: function:
        let
          args = mapArgsDeclaration function (lib.functionArgs function);
          mapped = args: function (mapArgsDefinition function args);
        in
        lib.setFunctionArgs mapped args
      );

  flake.lib.trivial.importIfPath =
    self.lib.docs.function
      {
        description = "If given a path/string, import it and attach {_file,key}; otherwise pass through the module and still attach those when possible.";
        type = self.lib.types.function lib.types.raw lib.types.raw;
        tests =
          let
            dummyModule =
              { lib, ... }:
              {
                x = 1;
                y = 2;
                computed = lib.add 39 3;
              };

            mkModuleFile =
              content:
              let
                f = builtins.toFile "mod.nix" content;
              in
              f;
          in
          {
            path_attrset =
              let
                modFile = mkModuleFile ''
                  { lib, ... }: { hello = "world"; }
                '';
                imported = self.lib.trivial.importIfPath modFile;
                result = imported { inherit lib; };
              in
              (result.hello == "world")
              && (result ? _file)
              && (result ? key)
              && (result._file == modFile)
              && (result.key == modFile);

            path_plain_attrset =
              let
                modFile = mkModuleFile ''
                  { hello = "attrset"; n = 7; }
                '';
                imported = self.lib.trivial.importIfPath modFile;
              in
              imported == {
                hello = "attrset";
                n = 7;
                _file = modFile;
                key = modFile;
              };

            string_path =
              let
                modFile = mkModuleFile ''
                  { lib, ... }: { a = 1; }
                '';
                imported = self.lib.trivial.importIfPath (toString modFile);
                result = imported { inherit lib; };
              in
              (result.a == 1) && (result._file == toString modFile) && (result.key == toString modFile);

            function_value =
              let
                imported = self.lib.trivial.importIfPath dummyModule;
                result = imported { inherit lib; };
              in
              (
                result == {
                  x = 1;
                  y = 2;
                  computed = 42;
                }
              );

            plain_attrset_value =
              let
                value = {
                  k = "v";
                };
                imported = self.lib.trivial.importIfPath value;
              in
              imported == value;
          };
      }
      (
        module:
        let
          pathPart =
            if (builtins.isPath module) || (builtins.isString module) then
              let
                path = module;
              in
              {
                _file = path;
                key = path;
              }
            else
              { };

          imported = if (builtins.isPath module) || (builtins.isString module) then import module else module;
        in
        if lib.isFunction imported then
          let
            function = imported;
          in
          self.lib.trivial.mapFunctionResult (_: attrset: attrset // pathPart) function
        else
          let
            attrset = imported;
          in
          attrset // pathPart
      );

  flake.lib.trivial.mapAttrsetImports =
    self.lib.docs.function
      {
        description = "If an attrset has an imports list, map a function over the imported modules (importing paths/strings first).";
        type = self.lib.types.function (self.lib.types.function lib.types.raw lib.types.raw) (
          self.lib.types.function lib.types.raw lib.types.raw
        );
        tests =
          let
            mkModuleFile =
              content:
              let
                f = builtins.toFile "mod.nix" content;
              in
              f;
          in
          {
            maps_each_import =
              let
                modA = mkModuleFile ''{ lib, ... }: { name = "A"; } '';
                modB = mkModuleFile ''{ lib, ... }: { name = "B"; } '';
                attrset = {
                  imports = [
                    modA
                    modB
                  ];
                  root = true;
                };
                mapped = self.lib.trivial.mapAttrsetImports (
                  m: self.lib.trivial.mapFunctionResult (_: r: r // { via = "mapped"; }) m
                ) attrset;

                allGood = builtins.all (
                  f:
                  let
                    m = f { inherit lib; };
                  in
                  (m ? _file) && (m ? key) && (m ? via) && (m.via == "mapped")
                ) mapped.imports;
              in
              (mapped.root == true) && (builtins.length mapped.imports == 2) && allGood;

            noop_when_no_imports =
              let
                attrset = {
                  x = 1;
                };
                mapped = self.lib.trivial.mapAttrsetImports (x: x) attrset;
              in
              mapped == attrset;
          };
      }
      (
        mapImported: attrset:
        if attrset ? imports then
          attrset
          // {
            imports = builtins.map (module: mapImported (self.lib.trivial.importIfPath module)) attrset.imports;
          }
        else
          attrset
      );
}
