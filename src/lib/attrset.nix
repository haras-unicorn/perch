{ self, lib, ... }:

let
  removeAttrByPath =
    path: attrs:
    if path == [ ] then
      attrs
    else
      let
        key = builtins.head path;
        tail = builtins.tail path;
      in
      if tail == [ ] then
        builtins.removeAttrs attrs [ key ]
      else if attrs ? ${key} && builtins.isAttrs attrs.${key} then
        attrs
        // {
          ${key} = removeAttrByPath tail attrs.${key};
        }
      else
        attrs;

  removeAttrsByPath =
    paths: attrs: builtins.foldl' (acc: next: self.lib.attrset.removeAttrByPath next acc) attrs paths;

  keepAttrByPath =
    path: attrs:
    if path == [ ] then
      attrs
    else
      let
        key = builtins.head path;
        tail = builtins.tail path;
      in
      if !(attrs ? ${key}) then
        { }
      else if tail == [ ] then
        { ${key} = attrs.${key}; }
      else if builtins.isAttrs attrs.${key} then
        let
          sub = keepAttrByPath tail attrs.${key};
        in
        if sub == { } then { } else { ${key} = sub; }
      else
        { };

  recursiveMerge =
    lhs: rhs:
    let
      keys = builtins.attrNames lhs ++ builtins.attrNames rhs;
      uniq = builtins.listToAttrs (
        builtins.map
          (key: {
            name = key;
            value = null;
          })
          (
            builtins.attrNames (
              builtins.listToAttrs (
                builtins.map (k: {
                  name = k;
                  value = 1;
                }) keys
              )
            )
          )
      );
      mergeKey =
        key:
        if (lhs ? ${key}) && (rhs ? ${key}) then
          if builtins.isAttrs lhs.${key} && builtins.isAttrs rhs.${key} then
            recursiveMerge lhs.${key} rhs.${key}
          else
            rhs.${key}
        else if lhs ? ${key} then
          lhs.${key}
        else
          rhs.${key};
    in
    builtins.mapAttrs (key: _: mergeKey key) uniq;

  keepAttrsByPath =
    paths: attrs: builtins.foldl' (acc: path: recursiveMerge acc (keepAttrByPath path attrs)) { } paths;

  isDictionary =
    value: builtins.isAttrs value && !(lib.isDerivation value) && !(lib.isOptionType value);

  flatten =
    {
      attrs,
      separator ? "-",
      while ? isDictionary,
    }:
    builtins.listToAttrs (
      (lib.fix (
        recurse: prefix: attrs:
        builtins.concatMap (
          key:
          let
            value = attrs.${key};
            finalKey = if prefix == "" then key else "${prefix}${separator}${key}";
          in
          if while value then
            recurse finalKey value
          else
            [
              {
                name = finalKey;
                value = value;
              }
            ]
        ) (builtins.attrNames attrs)
      ))
        ""
        attrs
    );
in
{
  flake.lib.attrset.removeAttrByPath = self.lib.docs.function {
    description = ''
      Remove a nested attribute specified by a path from an attrset.
    '';
    type = self.lib.types.function (lib.types.listOf lib.types.str) (
      self.lib.types.function lib.types.attrs lib.types.attrs
    );
    tests = {
      nested =
        let
          src = {
            a = {
              b = 1;
              c = 2;
            };
            d = 3;
          };
          got = self.lib.attrset.removeAttrByPath [ "a" "b" ] src;
        in
        got == {
          a = {
            c = 2;
          };
          d = 3;
        };

      top =
        let
          src = {
            a = 1;
            b = 2;
          };
          got = self.lib.attrset.removeAttrByPath [ "a" ] src;
        in
        got == {
          b = 2;
        };

      noop_missing =
        let
          src = {
            a = {
              c = 2;
            };
            d = 3;
          };
          got = self.lib.attrset.removeAttrByPath [ "a" "b" ] src;
        in
        got == src;

      noop_intermediate_not_set =
        let
          src = {
            a = 1;
            b = {
              c = 2;
            };
          };
          got = self.lib.attrset.removeAttrByPath [ "a" "x" ] src;
        in
        got == src;

      empty_leaf =
        let
          src = {
            a = {
              b = 1;
            };
          };
          got = self.lib.attrset.removeAttrByPath [ "a" "b" ] src;
        in
        got == {
          a = { };
        };

      deep =
        let
          src = {
            a = {
              b = {
                c = {
                  d = 4;
                  e = 5;
                };
              };
            };
            z = 0;
          };
          got = self.lib.attrset.removeAttrByPath [ "a" "b" "c" "d" ] src;
        in
        got == {
          a = {
            b = {
              c = {
                e = 5;
              };
            };
          };
          z = 0;
        };

      idempotent =
        let
          src = {
            a = {
              b = 1;
              c = 2;
            };
          };
          once = self.lib.attrset.removeAttrByPath [ "a" "b" ] src;
          twice = self.lib.attrset.removeAttrByPath [ "a" "b" ] once;
        in
        once == twice;

      lists_untouched =
        let
          src = {
            a = {
              b = 1;
              l = [
                1
                2
                3
              ];
            };
          };
          got = self.lib.attrset.removeAttrByPath [ "a" "b" ] src;
        in
        got == {
          a = {
            l = [
              1
              2
              3
            ];
          };
        };

      missing_deep_no_change =
        let
          src = {
            a = {
              b = {
                c = 1;
              };
            };
          };
          got = self.lib.attrset.removeAttrByPath [ "a" "x" "y" ] src;
        in
        got == src;

      remove_subattrset =
        let
          src = {
            a = {
              b = {
                x = 1;
              };
              c = 2;
            };
          };
          got = self.lib.attrset.removeAttrByPath [ "a" "b" ] src;
        in
        got == {
          a = {
            c = 2;
          };
        };
    };
  } removeAttrByPath;

  flake.lib.attrset.removeAttrsByPath = self.lib.docs.function {
    description = ''
      Remove multiple nested attributes specified by a list of paths from an attrset.
    '';
    type = self.lib.types.function (lib.types.listOf (lib.types.listOf lib.types.str)) (
      self.lib.types.function lib.types.attrs lib.types.attrs
    );
    tests = {
      distinct_top =
        let
          src = {
            a = 1;
            b = 2;
            c = 3;
          };
          got = self.lib.attrset.removeAttrsByPath [
            [ "a" ]
            [ "c" ]
          ] src;
        in
        got == {
          b = 2;
        };

      nested_siblings =
        let
          src = {
            a = {
              b = 1;
              c = 2;
              d = 3;
            };
            x = 0;
          };
          got = self.lib.attrset.removeAttrsByPath [
            [
              "a"
              "b"
            ]
            [
              "a"
              "d"
            ]
          ] src;
        in
        got == {
          a = {
            c = 2;
          };
          x = 0;
        };

      mixed_levels =
        let
          src = {
            a = {
              b = {
                c = 1;
                d = 2;
              };
              e = 3;
            };
            f = 4;
          };
          got = self.lib.attrset.removeAttrsByPath [
            [
              "a"
              "b"
              "c"
            ]
            [
              "a"
              "e"
            ]
          ] src;
        in
        got == {
          a = {
            b = {
              d = 2;
            };
          };
          f = 4;
        };

      missing_ignored =
        let
          src = {
            a = {
              b = 1;
            };
          };
          got = self.lib.attrset.removeAttrsByPath [
            [
              "x"
              "y"
            ]
            [
              "a"
              "z"
            ]
          ] src;
        in
        got == src;

      deep_overlap_cleanup =
        let
          src = {
            a = {
              b = {
                c = {
                  d = 4;
                  e = 5;
                };
                x = 9;
              };
              z = 7;
            };
            q = 1;
          };
          got = self.lib.attrset.removeAttrsByPath [
            [
              "a"
              "b"
              "c"
              "d"
            ]
            [
              "a"
              "b"
              "x"
            ]
          ] src;
        in
        got == {
          a = {
            b = {
              c = {
                e = 5;
              };
            };
            z = 7;
          };
          q = 1;
        };

      lists_untouched =
        let
          src = {
            a = {
              l = [
                1
                2
                3
              ];
              r = [
                "x"
                "y"
              ];
              v = 9;
            };
            b = 2;
          };
          got = self.lib.attrset.removeAttrsByPath [
            [
              "a"
              "v"
            ]
          ] src;
        in
        got == {
          a = {
            l = [
              1
              2
              3
            ];
            r = [
              "x"
              "y"
            ];
          };
          b = 2;
        };

      idempotent_same_paths =
        let
          src = {
            a = {
              b = 1;
              c = 2;
            };
            d = 3;
          };
          once = self.lib.attrset.removeAttrsByPath [
            [
              "a"
              "b"
            ]
            [ "d" ]
          ] src;
          twice = self.lib.attrset.removeAttrsByPath [
            [
              "a"
              "b"
            ]
            [ "d" ]
          ] once;
        in
        once == twice;

      empty_paths_noop =
        let
          src = {
            a = 1;
            b = 2;
          };
          got = self.lib.attrset.removeAttrsByPath [ ] src;
        in
        got == src;

      duplicate_paths_ok =
        let
          src = {
            a = {
              b = 1;
              c = 2;
            };
          };
          got = self.lib.attrset.removeAttrsByPath [
            [
              "a"
              "b"
            ]
            [
              "a"
              "b"
            ]
          ] src;
        in
        got == {
          a = {
            c = 2;
          };
        };

      intermediate_not_attrs_noop_for_that_branch =
        let
          src = {
            a = 1;
            b = {
              c = 2;
            };
          };
          got = self.lib.attrset.removeAttrsByPath [
            [
              "a"
              "x"
            ]
            [
              "b"
              "c"
            ]
          ] src;
        in
        got == {
          a = 1;
          b = { };
        };

      entire_subattrset =
        let
          src = {
            a = {
              b = {
                x = 1;
                y = 2;
              };
              c = 2;
            };
          };
          got = self.lib.attrset.removeAttrsByPath [
            [
              "a"
              "b"
            ]
          ] src;
        in
        got == {
          a = {
            c = 2;
          };
        };

      no_cross_effect_between_branches =
        let
          src = {
            a = {
              b = 1;
            };
            x = {
              y = 2;
              z = 3;
            };
          };
          got = self.lib.attrset.removeAttrsByPath [
            [
              "a"
              "b"
            ]
            [
              "x"
              "z"
            ]
          ] src;
        in
        got == {
          a = { };
          x = {
            y = 2;
          };
        };
    };
  } removeAttrsByPath;

  flake.lib.attrset.keepAttrByPath = self.lib.docs.function {
    description = ''
      Keep only the nested attribute specified by a path,
      returning a minimal attrset (or empty if missing).
    '';
    type = self.lib.types.function (lib.types.listOf lib.types.str) (
      self.lib.types.function lib.types.attrs lib.types.attrs
    );
    tests = {
      nested =
        let
          src = {
            a = {
              b = 1;
              c = 2;
            };
            d = 3;
          };
          got = self.lib.attrset.keepAttrByPath [ "a" "b" ] src;
        in
        got == {
          a = {
            b = 1;
          };
        };

      top =
        let
          src = {
            a = 1;
            b = 2;
          };
          got = self.lib.attrset.keepAttrByPath [ "a" ] src;
        in
        got == {
          a = 1;
        };

      missing_is_empty =
        let
          src = {
            a = {
              c = 2;
            };
            d = 3;
          };
          got = self.lib.attrset.keepAttrByPath [ "a" "b" ] src;
        in
        got == { };

      intermediate_not_attrs =
        let
          src = {
            a = 1;
            b = {
              c = 2;
            };
          };
          got = self.lib.attrset.keepAttrByPath [ "a" "x" ] src;
        in
        got == { };

      list_leaf_ok =
        let
          src = {
            a = {
              l = [
                1
                2
                3
              ];
            };
          };
          got = self.lib.attrset.keepAttrByPath [ "a" "l" ] src;
        in
        got == {
          a = {
            l = [
              1
              2
              3
            ];
          };
        };

      deep =
        let
          src = {
            a = {
              b = {
                c = {
                  d = 4;
                  e = 5;
                };
              };
            };
            z = 0;
          };
          got = self.lib.attrset.keepAttrByPath [ "a" "b" "c" "d" ] src;
        in
        got == {
          a = {
            b = {
              c = {
                d = 4;
              };
            };
          };
        };

      idempotent =
        let
          src = {
            a = {
              b = 1;
              c = 2;
            };
          };
          once = self.lib.attrset.keepAttrByPath [ "a" "b" ] src;
          twice = self.lib.attrset.keepAttrByPath [ "a" "b" ] src;
        in
        once == twice;
    };
  } keepAttrByPath;

  flake.lib.attrset.keepAttrsByPath = self.lib.docs.function {
    description = ''
      Keep only the nested attributes specified by a list of paths,
      merging the kept results into one attrset.
    '';
    type = self.lib.types.function (lib.types.listOf (lib.types.listOf lib.types.str)) (
      self.lib.types.function lib.types.attrs lib.types.attrs
    );
    tests = {
      distinct_top =
        let
          src = {
            a = 1;
            b = 2;
            c = 3;
          };
          got = self.lib.attrset.keepAttrsByPath [
            [ "a" ]
            [ "c" ]
          ] src;
        in
        got == {
          a = 1;
          c = 3;
        };

      nested_siblings =
        let
          src = {
            a = {
              b = 1;
              c = 2;
              d = 3;
            };
            x = 0;
          };
          got = self.lib.attrset.keepAttrsByPath [
            [
              "a"
              "b"
            ]
            [
              "a"
              "d"
            ]
          ] src;
        in
        got == {
          a = {
            b = 1;
            d = 3;
          };
        };

      mixed_levels =
        let
          src = {
            a = {
              b = {
                c = 1;
                d = 2;
              };
              e = 3;
            };
            f = 4;
          };
          got = self.lib.attrset.keepAttrsByPath [
            [
              "a"
              "b"
              "c"
            ]
            [
              "a"
              "e"
            ]
            [ "f" ]
          ] src;
        in
        got == {
          a = {
            b = {
              c = 1;
            };
            e = 3;
          };
          f = 4;
        };

      missing_ignored =
        let
          src = {
            a = {
              b = 1;
            };
          };
          got = self.lib.attrset.keepAttrsByPath [
            [
              "a"
              "b"
            ]
            [
              "x"
              "y"
            ]
          ] src;
        in
        got == {
          a = {
            b = 1;
          };
        };

      deep_overlap_merge =
        let
          src = {
            a = {
              b = {
                c = {
                  d = 4;
                  e = 5;
                };
                x = 9;
              };
              z = 7;
            };
            q = 1;
          };
          got = self.lib.attrset.keepAttrsByPath [
            [
              "a"
              "b"
              "c"
              "d"
            ]
            [
              "a"
              "b"
              "x"
            ]
            [ "q" ]
          ] src;
        in
        got == {
          a = {
            b = {
              c = {
                d = 4;
              };
              x = 9;
            };
          };
          q = 1;
        };

      lists_preserved =
        let
          src = {
            a = {
              l = [
                1
                2
                3
              ];
              r = [
                "x"
                "y"
              ];
            };
            b = 2;
          };
          got = self.lib.attrset.keepAttrsByPath [
            [
              "a"
              "l"
            ]
            [ "b" ]
          ] src;
        in
        got == {
          a = {
            l = [
              1
              2
              3
            ];
          };
          b = 2;
        };

      idempotent_same_paths =
        let
          src = {
            a = {
              b = 1;
              c = 2;
            };
            d = 3;
          };
          once = self.lib.attrset.keepAttrsByPath [
            [
              "a"
              "b"
            ]
            [ "d" ]
          ] src;
          twice = self.lib.attrset.keepAttrsByPath [
            [
              "a"
              "b"
            ]
            [ "d" ]
          ] src;
        in
        once == twice;

      empty_paths_is_empty =
        let
          src = {
            a = 1;
          };
          got = self.lib.attrset.keepAttrsByPath [ ] src;
        in
        got == { };

      duplicate_paths_ok =
        let
          src = {
            a = {
              b = 1;
              c = 2;
            };
          };
          got = self.lib.attrset.keepAttrsByPath [
            [
              "a"
              "b"
            ]
            [
              "a"
              "b"
            ]
          ] src;
        in
        got == {
          a = {
            b = 1;
          };
        };

      intermediate_not_attrs_ignored =
        let
          src = {
            a = 1;
            b = {
              c = 2;
            };
          };
          got = self.lib.attrset.keepAttrsByPath [
            [
              "a"
              "x"
            ]
            [
              "b"
              "c"
            ]
          ] src;
        in
        got == {
          b = {
            c = 2;
          };
        };
    };
  } keepAttrsByPath;

  flake.lib.attrset.flatten = self.lib.docs.function {
    description = ''
      Flatten an attrset recursively using a key separator.
    '';
    type = self.lib.types.function (self.lib.types.args {
      options = {
        attrs = lib.mkOption {
          type = lib.types.attrs;
          description = ''The attrset to flatten'';
        };
        separator = lib.mkOption {
          type = lib.types.str;
          default = ".";
          description = ''Final attrset key separator'';
        };
        while = lib.mkOption {
          description = ''Recurse into attrsets depending on this predicate'';
          type = self.lib.types.function lib.types.raw lib.types.bool;
          default = self.lib.attrset.isDictionary;
          defaultText = lib.literalExpression ''perch.lib.attrset.isDictionary'';
        };
      };
    }) lib.types.attrs;
    tests = {
      basic_dot =
        let
          src = {
            a = {
              b = 1;
              c = 2;
            };
            d = 3;
          };
          got = self.lib.attrset.flatten {
            attrs = src;
            separator = ".";
          };
        in
        got == {
          "a.b" = 1;
          "a.c" = 2;
          "d" = 3;
        };

      deep_custom_separator =
        let
          src = {
            a = {
              b = {
                c = 1;
              };
            };
            z = 0;
          };
          got = self.lib.attrset.flatten {
            attrs = src;
            separator = "-";
          };
        in
        got == {
          "a-b-c" = 1;
          "z" = 0;
        };

      stops_on_lists =
        let
          src = {
            a = {
              l = [
                1
                2
                3
              ];
              x = 9;
            };
          };
          got = self.lib.attrset.flatten {
            attrs = src;
            separator = ".";
          };
        in
        got == {
          "a.l" = [
            1
            2
            3
          ];
          "a.x" = 9;
        };

      empty_is_empty =
        let
          src = { };
          got = self.lib.attrset.flatten { attrs = src; };
        in
        got == { };

      already_flat_no_change =
        let
          src = {
            "a.b" = 1;
            c = 2;
          };
          got = self.lib.attrset.flatten {
            attrs = src;
            separator = ".";
          };
        in
        got == {
          "a.b" = 1;
          "c" = 2;
        };

      custom_while_stops_early =
        let
          src = {
            a = {
              b = {
                c = 1;
              };
              d = 2;
            };
          };
          got = self.lib.attrset.flatten {
            attrs = src;
            separator = ".";
            while = value: builtins.isAttrs value && !(value ? c);
          };
        in
        got == {
          "a.b" = {
            c = 1;
          };
          "a.d" = 2;
        };

      idempotent =
        let
          src = {
            a = {
              b = 1;
              c = {
                d = 2;
              };
            };
          };
          once = self.lib.attrset.flatten {
            attrs = src;
            separator = ".";
          };
          twice = self.lib.attrset.flatten {
            attrs = once;
            separator = ".";
          };
        in
        once == twice;
    };
  } flatten;

  flake.lib.attrset.isDictionary = self.lib.docs.function {
    description = ''
      Returns true for an attrset that is "safe" to peek into
      (not a derivation and not an option type).
    '';
    type = self.lib.types.function lib.types.attrs lib.types.bool;
  } isDictionary;
}
