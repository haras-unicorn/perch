{ self, lib, ... }:

(
  let
    inc = (x: x + 1);
    badResult = (_x: "oops");
    add = (a: b: a + b);

    tIntToInt = self.lib.types.function lib.types.int lib.types.int;
    tIntToIntToInt = self.lib.types.function lib.types.int (
      self.lib.types.function lib.types.int lib.types.int
    );
  in
  {
    docs_function_attaches___doc =
      let
        f = self.lib.docs.function {
          description = "increment";
          type = tIntToInt;
          asserted = false;
        } inc;
      in
      f.__doc.description == "increment" && f.__doc.asserted == false && f.__doc.type.name == "function";

    docs_function_is_callable =
      let
        f = self.lib.docs.function {
          description = "increment";
          type = tIntToInt;
          asserted = false;
        } inc;
      in
      f 1 == 2;

    docs_function_argument_assert_fails =
      let
        f = self.lib.docs.function {
          description = "increment";
          type = tIntToInt;
          asserted = "argument";
        } inc;
        r = builtins.tryEval (f "nope");
      in
      r.success == false;

    docs_function_result_assert_fails =
      let
        f = self.lib.docs.function {
          description = "badResult";
          type = tIntToInt;
          asserted = "result";
        } badResult;
        r = builtins.tryEval (f 1);
      in
      r.success == false;

    docs_function_asserted_true_checks_both =
      let
        f = self.lib.docs.function {
          description = "increment";
          type = tIntToInt;
          asserted = true;
        } inc;

        badArg = builtins.tryEval (f "x");
        good = builtins.tryEval (f 2);
      in
      (badArg.success == false) && (good.success == true) && (good.value == 3);

    docs_function_wraps_curried_functions_recursively =
      let
        f = self.lib.docs.function {
          description = "add";
          type = tIntToIntToInt;
          asserted = true;
        } add;

        good = builtins.tryEval ((f 1) 2);
        bad1 = builtins.tryEval ((f "x") 2);
        bad2 = builtins.tryEval ((f 1) "y");
      in
      (good.success && good.value == 3) && (bad1.success == false) && (bad2.success == false);

    docs_function_returns_functor =
      let
        f = self.lib.docs.function {
          description = "increment";
          type = self.lib.types.function lib.types.int lib.types.int;
          asserted = false;
        } (x: x + 1);
      in
      self.lib.trivial.isFunctor f == true;

    docs_function_asserted_false_does_not_assert =
      let
        f = self.lib.docs.function {
          description = "lies";
          type = self.lib.types.function lib.types.int lib.types.int;
          asserted = false;
        } (_: "not an int");
        r = builtins.tryEval (f 1);
      in
      r.success == true && r.value == "not an int";
  }
)
// (
  let
    wildLib = {
      meta = {
        version = "1.2.3";
        nums = [
          1
          2
          3
        ];
        flags = {
          enabled = true;
          threshold = 10;
        };
      };

      misc = {
        greeting = "hi";
        n = 42;
        xs = [
          "a"
          { k = "v"; }
          9
        ];
      };

      math = {
        inc = self.lib.docs.function {
          description = "Increment an int";
          type = self.lib.types.function lib.types.int lib.types.int;
          asserted = false;
        } (x: x + 1);

        add = self.lib.docs.function {
          description = "Add two ints (curried)";
          type = self.lib.types.function lib.types.int (self.lib.types.function lib.types.int lib.types.int);
          asserted = true;
        } (a: b: a + b);
      };

      junk = {
        a = {
          b = {
            c = "nope";
          };
        };
      };
    };

    outTry = builtins.tryEval (self.lib.docs.libToOptions wildLib);
    out = outTry.value;

    isOption = x: builtins.isAttrs x && x ? type && x ? description;
  in
  {
    docs_libToOptions_does_not_throw = outTry.success == true;

    docs_libToOptions_keeps_only_documented_nodes_as_options =
      (out ? math)
      && (out.math ? inc)
      && (out.math ? add)
      && isOption out.math.inc
      && isOption out.math.add;

    docs_libToOptions_prunes_random_leaves_and_subtrees =
      !(out ? meta) && !(out ? misc) && !(out ? junk);

    docs_libToOptions_prunes_empty_containers = builtins.attrNames out == [ "math" ];

    docs_libToOptions_option_payload_matches_docs_function =
      out.math.inc.description == "Increment an int"
      && out.math.inc.type.name == "function"
      && out.math.add.description == "Add two ints (curried)"
      && out.math.add.type.name == "function"
      && !(out.math.inc ? __doc)
      && !(out.math.add ? __doc);
  }
)
