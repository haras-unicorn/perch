{ ... }:

{
  flake.lib.debug.trace =
    value:
    let
      removeFunctions =
        value:
        if builtins.isFunction value then
          "<<function>>"
        else if builtins.isAttrs value then
          builtins.mapAttrs (_: removeFunctions) value
        else if builtins.isList value then
          builtins.map removeFunctions value
        else
          value;
    in
    builtins.trace (builtins.toJSON (removeFunctions value)) value;
}
