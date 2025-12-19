{ self, ... }:

let
  trace = self.lib.debug.trace;

  f1 = x: x + 1;
  f2 = { a, ... }: a;

  simple = 42;
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
  trace_simple_value =
    let
      v = trace simple;
    in
    v == 42;

  trace_replaces_functions_attr =
    let
      v = trace withFunc;
    in
    v == withFunc
    && (
      builtins.toJSON (
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
      ) != ""
    );

  trace_replaces_functions_nested =
    let
      v = trace nested;
    in
    v == nested
    && (
      builtins.toJSON {
        x = {
          y = [
            { z = "<<function>>"; }
            [
              "<<function>>"
              3
            ]
          ];
        };
      } != ""
    );

  trace_list =
    let
      v = trace [
        1
        f1
        { k = f2; }
      ];
    in
    v == [
      1
      f1
      { k = f2; }
    ];

  trace_mixed_types =
    let
      v = trace {
        s = "hi";
        n = 0;
        b = true;
        l = [
          null
          f1
        ];
      };
    in
    v == {
      s = "hi";
      n = 0;
      b = true;
      l = [
        null
        f1
      ];
    };
}
