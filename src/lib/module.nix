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
      }
      (
        mapArgsDeclaration: mapArgsDefinition: mapResult: module:
        patchImported mapArgsDeclaration mapArgsDefinition mapResult (self.lib.trivial.importIfPath module)
      );
}
