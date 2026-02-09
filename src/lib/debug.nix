{ self, lib, ... }:

{
  flake.lib.debug.traceString =
    self.lib.docs.function
      {
        description = ''
          Create a JSON-renderable view of a value;
        '';
        type = self.lib.types.function lib.types.raw lib.types.str;
        tests =
          traceString:
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

            withOption = {
              x = lib.mkOption {
                type = lib.types.str;
              };
            };

            withOptionType = {
              x = lib.types.raw;
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

            replaces_option_attr = (traceString withOption) == (builtins.toJSON { x = "<<option: str>>"; });

            replaces_option_type_attr =
              (traceString withOptionType) == (builtins.toJSON { x = "<<option type: raw>>"; });
          };
      }
      (
        let
          removeFunctions =
            value:
            if builtins.isFunction value then
              "<<function>>"
            else if lib.isDerivation value then
              "<<derivation: ${value.name}>>"
            else if lib.isOptionType value then
              "<<option type: ${value.name}>>"
            else if lib.isOption value then
              "<<option: ${value.type.name}>>"
            else if builtins.isAttrs value then
              builtins.mapAttrs (_: removeFunctions) value
            else if builtins.isList value then
              builtins.map removeFunctions value
            else
              value;
        in

        value: builtins.toJSON (removeFunctions value)
      );

  flake.lib.debug.trace = self.lib.docs.function {
    description = ''
      Trace a JSON-renderable view of a value
      (functions replaced with a placeholder)
      and return the original value.
    '';
    type = self.lib.types.function lib.types.raw lib.types.raw;
  } (value: builtins.trace (self.lib.debug.traceString value) value);
}
