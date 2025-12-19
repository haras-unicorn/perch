{ lib, ... }:

# TODO: with mkOptionType
# NOTE: anything results in infinite recursion?

let
  nest = lib.fix (
    nest: times:
    if times == 0 then
      lib.types.oneOf [
        lib.types.bool
        lib.types.number
        lib.types.str
        lib.types.optionType
        (lib.types.functionTo lib.types.raw)
      ]
    else
      lib.types.oneOf [
        lib.types.bool
        lib.types.number
        lib.types.str
        lib.types.optionType
        (lib.types.functionTo lib.types.raw)
        (lib.types.listOf (nest (times - 1)))
        (lib.types.attrsOf (nest (times - 1)))
      ]
  );
in
{
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf (nest 8);
    default = { };
    description = lib.literalMD ''
      `lib` flake output.
    '';
  };
}
