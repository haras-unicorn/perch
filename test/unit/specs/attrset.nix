{ self, ... }:

{
  attrset_remove_single_nested =
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

  attrset_remove_single_top =
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

  attrset_remove_single_noop_missing =
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

  attrset_remove_single_noop_intermediate_not_set =
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

  attrset_remove_single_empty_leaf =
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

  attrset_remove_single_deep =
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

  attrset_remove_single_idempotent =
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

  attrset_remove_single_lists_untouched =
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

  attrset_remove_single_missing_deep_no_change =
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

  attrset_remove_single_remove_subattrset =
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

  attrset_remove_multi_distinct_top =
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

  attrset_remove_multi_nested_siblings =
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

  attrset_remove_multi_mixed_levels =
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

  attrset_remove_multi_missing_ignored =
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

  attrset_remove_multi_deep_overlap_cleanup =
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

  attrset_remove_multi_lists_untouched =
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

  attrset_remove_multi_idempotent_same_paths =
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

  attrset_remove_multi_empty_paths_noop =
    let
      src = {
        a = 1;
        b = 2;
      };
      got = self.lib.attrset.removeAttrsByPath [ ] src;
    in
    got == src;

  attrset_remove_multi_duplicate_paths_ok =
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

  attrset_remove_multi_intermediate_not_attrs_noop_for_that_branch =
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

  attrset_remove_multi_entire_subattrset =
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

  attrset_remove_multi_no_cross_effect_between_branches =
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

  attrset_keep_single_nested =
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

  attrset_keep_single_top =
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

  attrset_keep_single_missing_is_empty =
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

  attrset_keep_single_intermediate_not_attrs =
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

  attrset_keep_single_list_leaf_ok =
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

  attrset_keep_single_deep =
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

  attrset_keep_single_idempotent =
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

  attrset_keep_multi_distinct_top =
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

  attrset_keep_multi_nested_siblings =
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

  attrset_keep_multi_mixed_levels =
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

  attrset_keep_multi_missing_ignored =
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

  attrset_keep_multi_deep_overlap_merge =
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

  attrset_keep_multi_lists_preserved =
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

  attrset_keep_multi_idempotent_same_paths =
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

  attrset_keep_multi_empty_paths_is_empty =
    let
      src = {
        a = 1;
      };
      got = self.lib.attrset.keepAttrsByPath [ ] src;
    in
    got == { };

  attrset_keep_multi_duplicate_paths_ok =
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

  attrset_keep_multi_intermediate_not_attrs_ignored =
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
}
