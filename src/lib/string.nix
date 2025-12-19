{ lib, ... }:

{
  flake.lib.string.capitalize =
    s:
    if s == "" then
      ""
    else
      let
        first = lib.toUpper (builtins.substring 0 1 s);
        rest = builtins.substring 1 (builtins.stringLength s) s;
      in
      first + rest;
}
