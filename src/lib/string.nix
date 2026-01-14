{ self, lib, ... }:

{
  flake.lib.string.capitalize =
    self.lib.docs.function
      {
        description = ''
          Capitalize the first character of a string (leaving the rest unchanged).
        '';
        type = self.lib.types.function lib.types.str lib.types.str;
      }
      (
        string:
        if string == "" then
          ""
        else
          let
            first = lib.toUpper (builtins.substring 0 1 string);
            rest = builtins.substring 1 (builtins.stringLength string) string;
          in
          first + rest
      );
}
