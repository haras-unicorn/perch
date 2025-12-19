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
    mapArgsDeclaration: mapArgsDefinition: mapResult: module:
    patchImported mapArgsDeclaration mapArgsDefinition mapResult (self.lib.trivial.importIfPath module);
}
