{ self, lib, ... }:

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

  traceString = value: builtins.toJSON (removeFunctions value);
in
{
  flake.lib.debug.trace = self.lib.docs.function {
    description = ''
      Trace a JSON-renderable view of a value
      (functions replaced with a placeholder)
      and return the original value.
    '';
    type = self.lib.types.function lib.types.raw lib.types.raw;
    tests =
      let
        f1 = x: x + 1;
        f2 = { a, ... }: a;

        withFunc = {
          a = 1;
          b = f1;
          c = [
            1
            f2
            { d = f1; }
          ];
        };
        nested = {
          x = {
            y = [
              { z = f1; }
              [
                f2
                3
              ]
            ];
          };
        };

      in
      {
        replaces_functions_attr =
          (traceString withFunc) == (builtins.toJSON (
            withFunc
            // {
              b = "<<function>>";
              c = [
                1
                "<<function>>"
                {
                  d = "<<function>>";
                }
              ];
            }
          ));

        replaces_functions_nested =
          (traceString nested) == (builtins.toJSON {
            x = {
              y = [
                { z = "<<function>>"; }
                [
                  "<<function>>"
                  3
                ]
              ];
            };
          });
      };
  } (value: builtins.trace (traceString value) value);
}
