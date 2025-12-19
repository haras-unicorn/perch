{ self, lib, ... }:

{
  flake.lib.trivial.mapFunctionResult =
    mapResult: function:
    let
      args = lib.functionArgs function;
      mapped = args: mapResult function (function args);
    in
    lib.setFunctionArgs mapped args;

  flake.lib.trivial.mapFunctionArgs =
    mapArgsDeclaration: mapArgsDefinition: function:
    let
      args = mapArgsDeclaration function (lib.functionArgs function);
      mapped = args: function (mapArgsDefinition function args);
    in
    lib.setFunctionArgs mapped args;

  flake.lib.trivial.importIfPath =
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
      attrset // pathPart;

  flake.lib.trivial.mapAttrsetImports =
    mapImported: attrset:
    if attrset ? imports then
      attrset
      // {
        imports = builtins.map (module: mapImported (self.lib.trivial.importIfPath module)) attrset.imports;
      }
    else
      attrset;
}
