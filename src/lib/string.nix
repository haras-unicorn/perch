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

  flake.lib.string.wordSplit =
    self.lib.docs.function
      {
        description = ''
          Split a string into words on casing boundaries
          (camelCase / PascalCase) and delimiters
          (whitespace / dashes / underscores).
        '';
        type = self.lib.types.function lib.types.str (lib.types.listOf lib.types.str);
      }
      (
        string:
        let
          normalized = builtins.replaceStrings [ "_" "-" ] [ " " " " ] string;

          tokens = lib.filter (part: part != "") (lib.splitString " " normalized);

          casingSplit =
            token:
            let
              len = builtins.stringLength token;

              charAt = i: builtins.substring i 1 token;

              isLower = c: c >= "a" && c <= "z";

              slice = start: endExclusive: builtins.substring start (endExclusive - start) token;

              go =
                i: start: acc:
                if i >= len then
                  let
                    last = slice start len;
                  in
                  acc ++ (if last == "" then [ ] else [ last ])
                else
                  let
                    prev = if i > 0 then charAt (i - 1) else "";
                    curr = charAt i;
                    next = if i + 1 < len then charAt (i + 1) else "";

                    breakHere =
                      (i > 0 && isLower prev && !(isLower curr))
                      || (i > 0 && (i + 1) < len && !(isLower prev) && !(isLower curr) && isLower next);

                  in
                  if breakHere then
                    let
                      part = slice start i;
                    in
                    go (i + 1) i (acc ++ (if part == "" then [ ] else [ part ]))
                  else
                    go (i + 1) start acc;

            in
            if token == "" then [ ] else go 0 0 [ ];

        in
        lib.concatLists (map casingSplit tokens)
      );

  flake.lib.string.toTitle =
    self.lib.docs.function
      {
        description = ''
          Convert a string into a simple title.
        '';
        type = self.lib.types.function lib.types.str lib.types.str;
      }
      (
        string:
        lib.concatStringsSep " " (
          builtins.map self.lib.string.capitalize (self.lib.string.wordSplit string)
        )
      );

  flake.lib.string.indent =
    self.lib.docs.function
      {
        description = ''
          Indent (or dedent via negative) a multi-line string by a number of spaces.
        '';
        type = self.lib.types.function lib.types.int (self.lib.types.function lib.types.str lib.types.str);
      }
      (
        num: string:
        let
          lines = lib.splitString "\n" string;

          pad = count: lib.concatStringsSep "" (lib.replicate count " ");

          indentLine = line: if line == "" then "" else (pad num) + line;

          dedentLine =
            count: line:
            let
              len = builtins.stringLength line;

              leading =
                let
                  go =
                    i:
                    if i >= len then
                      len
                    else if builtins.substring i 1 line == " " then
                      go (i + 1)
                    else
                      i;
                in
                go 0;

              drop = lib.min count leading;
            in
            builtins.substring drop (len - drop) line;

          transformLine =
            if num == 0 then
              (line: line)
            else if num > 0 then
              indentLine
            else
              (line: if line == "" then "" else dedentLine (-num) line);

        in
        lib.concatStringsSep "\n" (builtins.map transformLine lines)
      );
}
