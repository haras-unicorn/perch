{ lib, self, ... }:

let
  patchAttrsetImports =
    mapArgsDeclaration: mapArgsDefinition: mapResult: attrset:
    self.lib.trivial.mapAttrsetImports (patchImported mapArgsDeclaration mapArgsDefinition
      mapResult
    ) attrset;

  patchImported =
    mapArgsDeclaration: mapArgsDefinition: mapResult: imported:
    if lib.isFunction imported then
      let
        function = imported;
      in
      self.lib.trivial.mapFunctionArgs mapArgsDeclaration mapArgsDefinition (
        self.lib.trivial.mapFunctionResult (
          function: attrset:
          mapResult function (patchAttrsetImports mapArgsDeclaration mapArgsDefinition mapResult attrset)
        ) function
      )
    else
      mapResult imported (patchAttrsetImports mapArgsDeclaration mapArgsDefinition mapResult imported);
in
{
  flake.lib.module.patch =
    self.lib.docs.function
      {
        description = "
          Patch a module (or module path)
          by rewriting its function args declaration/values
          and mapping its resulting attrset,
          recursively applying the same patch to any imported modules.
        ";
        type = self.lib.types.function lib.types.raw (
          self.lib.types.function lib.types.raw (
            self.lib.types.function lib.types.raw (self.lib.types.function lib.types.raw lib.types.raw)
          )
        );
        tests =
          let
            patch = self.lib.module.patch;

            mkModuleFile = content: builtins.toFile "mod.nix" content;

            baseResultPatch = (_: attrset: attrset // { tag = "patched"; });

            declNoop = (_: decl: decl);

            declRequireX = (
              _: decl:
              let
                xReq = if decl ? x then { x = false; } else { };
              in
              decl // xReq
            );

            argsNoop = (_: args: args);
            argsBumpX = (_: args: args // (if args ? x then { x = args.x + 1; } else { }));

            plainAttr = {
              alpha = 1;
            };
            fnModule =
              { lib, ... }:
              {
                beta = lib.add 39 3;
              };
            fnWithArgs =
              {
                x,
                y ? 10,
                ...
              }:
              {
                got = x + y;
              };

            withImportsFile = mkModuleFile ''
              { lib, ... }: {
                imports = [
                  ({ ... }: { inner = 7; })
                  (${builtins.toString (mkModuleFile ''{ ... }: { deep = 9; } '')})
                ];
                root = true;
              }
            '';
          in
          {
            plain_attrset =
              let
                out = patch declNoop argsNoop baseResultPatch plainAttr;
              in
              out == {
                alpha = 1;
                tag = "patched";
              };

            function_module =
              let
                outF = patch declNoop argsNoop baseResultPatch fnModule;
                out = outF { inherit lib; };
              in
              out == {
                beta = 42;
                tag = "patched";
              };

            preserves_args_and_maps =
              let
                outF = patch declNoop argsBumpX baseResultPatch fnWithArgs;
                argsMeta = lib.functionArgs outF;
                out = outF { x = 5; };
              in
              (argsMeta ? x)
              && (argsMeta ? y)
              && (
                out == {
                  got = (5 + 1) + 10;
                  tag = "patched";
                }
              );

            declaration_flags_apply =
              let
                outF = patch declRequireX argsNoop baseResultPatch fnWithArgs;
                argsMeta = lib.functionArgs outF;
                out = outF { x = 3; };
              in
              (argsMeta ? x)
              && (argsMeta.x == false)
              && (argsMeta ? y)
              &&
                out == {
                  got = 3 + 10;
                  tag = "patched";
                };

            recurses_imports_path =
              let
                outF = patch declNoop argsNoop baseResultPatch withImportsFile;
                out = outF { inherit lib; };
                subOK = builtins.all (
                  f:
                  let
                    v = f { inherit lib; };
                  in
                  v ? tag && v.tag == "patched"
                ) out.imports;
              in
              out.root == true && subOK && out.tag == "patched";

            string_path_works =
              let
                strPath = toString withImportsFile;
                outF = patch declNoop argsNoop baseResultPatch strPath;
                out = outF { inherit lib; };
              in
              out.tag == "patched";

            plain_value_nested =
              let
                nested = {
                  imports = [
                    (
                      { ... }:
                      {
                        z = 3;
                      }
                    )
                  ];
                  top = 1;
                };
                out = patch declNoop argsNoop baseResultPatch nested;
                subs = builtins.map (f: f { }) out.imports;
                allPatched = builtins.all (m: m ? tag && m.tag == "patched") subs;
              in
              out.top == 1 && out.tag == "patched" && allPatched;

            args_transform_applies_nested =
              let
                modF =
                  { x, ... }:
                  {
                    imports = [
                      (
                        { x, ... }:
                        {
                          child = x;
                        }
                      )
                    ];
                    here = x;
                  };
                outF = patch declNoop argsBumpX baseResultPatch modF;
                out = outF { x = 10; };
                sub = (builtins.head out.imports) { x = 10; };
              in
              out.here == 11 && sub.child == 11 && out.tag == "patched" && sub.tag == "patched";
          };
      }
      (
        mapArgsDeclaration: mapArgsDefinition: mapResult: module:
        patchImported mapArgsDeclaration mapArgsDefinition mapResult (self.lib.trivial.importIfPath module)
      );
}
