{ lib, ... }:

let
  # NOTE: reimplemented here to avoid infinite recursion
  recursiveAttrsOf =
    elemType:
    lib.types.mkOptionType {
      name = "recursiveAttrsOf";
      description = "nested attribute set of ${elemType.description or "values"}";
      descriptionClass = "noun";
      check = value: lib.isAttrs value;
      merge = loc: defs: lib.foldl' lib.recursiveUpdate { } (map (def: def.value) defs);
    };
in
{
  options.flake.lib = lib.mkOption {
    type = recursiveAttrsOf lib.types.raw;
    default = { };
    description = "Attribute set of all library functions in the flake";
  };

  config.flake.lib.types = {
    inherit recursiveAttrsOf;
  };
}
