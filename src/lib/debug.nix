{ self, lib, ... }:

{
  flake.lib.debug.trace =
    self.lib.docs.function
      {
        description = ''
          Trace a JSON-renderable view of a value
          (functions replaced with a placeholder)
          and return the original value.
        '';
        type = self.lib.types.function lib.types.raw lib.types.raw;
      }
      (
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
        builtins.trace (builtins.toJSON (removeFunctions value)) value
      );
}
