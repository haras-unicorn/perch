{ self, lib, ... }:

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

  argsOnly =
    {
      x,
      y ? 10,
    }:
    {
      sum = x + y;
    };

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
  trivial_mapFunctionResult_wraps_result =
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

  trivial_mapFunctionResult_preserves_args =
    let
      f = dummyFun;
      mapped = self.lib.trivial.mapFunctionResult (_: res: res) f;
      args = builtins.attrNames (lib.functionArgs mapped);
    in
    builtins.all (k: builtins.elem k args) [
      "a"
      "b"
    ];

  trivial_mapFunctionArgs_maps_inputs =
    let
      f = argsOnly;
      mapped = self.lib.trivial.mapFunctionArgs (_: decl: decl) (_: args: args // { x = args.x * 2; }) f;
    in
    mapped { x = 5; } == {
      sum = 5 * 2 + 10;
    };

  trivial_mapFunctionArgs_preserves_args =
    let
      f = argsOnly;
      mapped = self.lib.trivial.mapFunctionArgs (_: decl: decl) (_: x: x) f;
      args = lib.functionArgs mapped;
    in
    (args ? x) && (args ? y);

  trivial_mapFunctionArgs_can_change_declaration =
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

  trivial_importIfPath_path_attrset =
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

  trivial_importIfPath_path_plain_attrset =
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

  trivial_importIfPath_string_path =
    let
      modFile = mkModuleFile ''
        { lib, ... }: { a = 1; }
      '';
      imported = self.lib.trivial.importIfPath (toString modFile);
      result = imported { inherit lib; };
    in
    (result.a == 1) && (result._file == toString modFile) && (result.key == toString modFile);

  trivial_importIfPath_function_value =
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

  trivial_importIfPath_plain_attrset_value =
    let
      value = {
        k = "v";
      };
      imported = self.lib.trivial.importIfPath value;
    in
    imported == value;

  trivial_mapAttrsetImports_maps_each_import =
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

  trivial_mapAttrsetImports_noop_when_no_imports =
    let
      attrset = {
        x = 1;
      };
      mapped = self.lib.trivial.mapAttrsetImports (x: x) attrset;
    in
    mapped == attrset;
}
