{ self, lib, ... }:

{
  flake.lib.string.capitalize =
    self.lib.docs.function
      {
        description = ''
          Capitalize the first character of a string (leaving the rest unchanged).
        '';
        type = self.lib.types.function lib.types.str lib.types.str;
        tests = {
          noop_empty = (self.lib.string.capitalize "") == "";
          first_len_1 = (self.lib.string.capitalize "a") == "A";
          noop_upper_len_1 = (self.lib.string.capitalize "A") == "A";
          first = (self.lib.string.capitalize "aaa") == "Aaa";
          first_noop_upper = (self.lib.string.capitalize "Aaa") == "Aaa";
          first_noop_upper_all = (self.lib.string.capitalize "AAA") == "AAA";
        };
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
        tests = {
          empty = (self.lib.string.wordSplit "") == [ ];
          single = (self.lib.string.wordSplit "hello") == [ "hello" ];

          dashes =
            (self.lib.string.wordSplit "some-file-name") == [
              "some"
              "file"
              "name"
            ];
          underscores =
            (self.lib.string.wordSplit "some_file_name") == [
              "some"
              "file"
              "name"
            ];
          mixed_separators =
            (self.lib.string.wordSplit "some-file_name") == [
              "some"
              "file"
              "name"
            ];
          dedup_separators =
            (self.lib.string.wordSplit "some--file___name") == [
              "some"
              "file"
              "name"
            ];

          camelCase =
            (self.lib.string.wordSplit "someFileName") == [
              "some"
              "File"
              "Name"
            ];
          pascalCase =
            (self.lib.string.wordSplit "SomeFileName") == [
              "Some"
              "File"
              "Name"
            ];
          acronym_boundary =
            (self.lib.string.wordSplit "HTTPServer") == [
              "HTTP"
              "Server"
            ];
          acronym_chain =
            (self.lib.string.wordSplit "MyHTTPServer") == [
              "My"
              "HTTP"
              "Server"
            ];

          digits_boundary =
            (self.lib.string.wordSplit "sha256Sum") == [
              "sha"
              "256"
              "Sum"
            ];
          digits_inside_acronym =
            (self.lib.string.wordSplit "SHA256Sum") == [
              "SHA256"
              "Sum"
            ];

          spaces =
            (self.lib.string.wordSplit "some   file  name") == [
              "some"
              "file"
              "name"
            ];
        };
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
        tests = {
          string_toTitle_noop_empty = (self.lib.string.toTitle "") == "";
          string_toTitle_single = (self.lib.string.toTitle "hello") == "Hello";
          string_toTitle_dashes = (self.lib.string.toTitle "some-file-name") == "Some File Name";
          string_toTitle_underscores = (self.lib.string.toTitle "some_file_name") == "Some File Name";
          string_toTitle_mixed = (self.lib.string.toTitle "some-file_name") == "Some File Name";
          string_toTitle_dedup_separators = (self.lib.string.toTitle "some--file___name") == "Some File Name";

          string_toTitle_camelCase = (self.lib.string.toTitle "someFileName") == "Some File Name";
          string_toTitle_pascalCase = (self.lib.string.toTitle "SomeFileName") == "Some File Name";
          string_toTitle_acronym_boundary = (self.lib.string.toTitle "HTTPServer") == "HTTP Server";
          string_toTitle_acronym_chain = (self.lib.string.toTitle "myHTTPServer") == "My HTTP Server";
          string_toTitle_digits_boundary = (self.lib.string.toTitle "sha256Sum") == "Sha 256 Sum";
        };
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
        tests = {
          noop_0 = (self.lib.string.indent 0 "a\nb") == "a\nb";
          add_2_single = (self.lib.string.indent 2 "a") == "  a";
          add_2_multi = (self.lib.string.indent 2 "a\nb") == "  a\n  b";
          preserve_empty_lines = (self.lib.string.indent 2 "a\n\nb") == "  a\n\n  b";

          dedent_2_single_exact = (self.lib.string.indent (-2) "  a") == "a";
          dedent_2_single_less = (self.lib.string.indent (-2) " a") == "a";
          dedent_2_single_none = (self.lib.string.indent (-2) "a") == "a";
          dedent_2_multi_mixed = (self.lib.string.indent (-2) "  a\n b\na") == "a\nb\na";
          dedent_preserve_empty_lines = (self.lib.string.indent (-2) "  a\n\n  b") == "a\n\nb";
        };
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
