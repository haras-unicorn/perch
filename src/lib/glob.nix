{ self, lib, ... }:

{
  flake.lib.glob.toRegex =
    self.lib.docs.function
      {
        description = ''
          Convert a glob pattern to a fully-anchored regular expression string.
        '';
        type = self.lib.types.function lib.types.str lib.types.str;
        tests =
          let
            toRegex = self.lib.glob.toRegex;

            expects =
              {
                glob,
                regex,
                ok ? [ ],
                bad ? [ ],
              }:
              let
                produced = toRegex glob;
                okResults = builtins.all (s: (builtins.match produced s) != null) ok;
                badResults = builtins.all (s: (builtins.match produced s) == null) bad;
              in
              produced == regex && okResults && badResults;
          in
          {
            empty = expects {
              glob = "";
              regex = "^$";
              ok = [ "" ];
              bad = [
                "a"
                "/"
              ];
            };

            literal = expects {
              glob = "Cargo.toml";
              regex = "^Cargo\\.toml$";
              ok = [ "Cargo.toml" ];
              bad = [
                "Cargo-toml"
                "Cargo.toml.bak"
              ];
            };

            star = expects {
              glob = "*.nix";
              regex = "^[^/]*\\.nix$";
              ok = [
                "foo.nix"
                ".nix"
                "bar123.nix"
              ];
              bad = [
                "dir/foo.nix"
                "foo.nix.bak"
              ];
            };

            starstar = expects {
              glob = "**/*.nix";
              regex = "^(.*/)?[^/]*\\.nix$";
              ok = [
                "foo.nix"
                "dir/foo.nix"
                "a/b/c/foo.nix"
              ];
              bad = [
                "foo.nix.bak"
                "a/b/c/foo.txt"
              ];
            };

            starstar_prefix = expects {
              glob = "**/Cargo.toml";
              regex = "^(.*/)?Cargo\\.toml$";
              ok = [
                "Cargo.toml"
                "a/b/Cargo.toml"
              ];
              bad = [
                "a/b/Cargo-toml"
                "a/b/Cargo.toml.bak"
              ];
            };

            qmark = expects {
              glob = "a?c";
              regex = "^a[^/]c$";
              ok = [
                "abc"
                "a_c"
              ];
              bad = [
                "ac"
                "a/c"
                "ab/c"
              ];
            };

            braces_simple = expects {
              glob = "{foo,bar}.nix";
              regex = "^(foo|bar)\\.nix$";
              ok = [
                "foo.nix"
                "bar.nix"
              ];
              bad = [
                "baz.nix"
                "foobar.nix"
                "dir/foo.nix"
              ];
            };

            braces_in_path = expects {
              glob = "src/{foo,bar}/*.nix";
              regex = "^src/(foo|bar)/[^/]*\\.nix$";
              ok = [
                "src/foo/a.nix"
                "src/bar/main.nix"
              ];
              bad = [
                "src/baz/a.nix"
                "src/foo/a.txt"
                "src/foo/x/y.nix"
              ];
            };

            braces_with_starstar = expects {
              glob = "**/*.{nix,md}";
              regex = "^(.*/)?[^/]*\\.(nix|md)$";
              ok = [
                "a.nix"
                "b.md"
                "x/y/z/readme.md"
              ];
              bad = [
                "a.txt"
                "x/y/z/readme.markdown"
              ];
            };
          };
      }
      (
        let
          escapeRegexCharacter =
            character:
            if
              lib.elem character [
                "."
                "+"
                "("
                ")"
                "|"
                "^"
                "$"
                "{"
                "}"
                "\\"
              ]
            then
              "\\" + character
            else
              character;

          parseBraceAlternatives =
            characters: openingBraceIndex:
            let
              totalLength = builtins.length characters;

              parseLoop =
                currentIndex: currentAlternative: alternatives:
                if currentIndex >= totalLength then
                  null
                else
                  let
                    currentCharacter = builtins.elemAt characters currentIndex;
                  in
                  if currentCharacter == "}" then
                    {
                      alternatives = alternatives ++ [ currentAlternative ];
                      nextIndex = currentIndex + 1;
                    }
                  else if currentCharacter == "," then
                    parseLoop (currentIndex + 1) "" (alternatives ++ [ currentAlternative ])
                  else
                    parseLoop (currentIndex + 1) (currentAlternative + currentCharacter) alternatives;
            in
            parseLoop (openingBraceIndex + 1) "" [ ];
        in
        globPattern:
        let
          translateGlobString =
            inputString:
            let
              characters = lib.stringToCharacters inputString;
              totalLength = builtins.length characters;

              translateAtIndex =
                index:
                if index >= totalLength then
                  ""
                else
                  let
                    currentCharacter = builtins.elemAt characters index;
                    nextCharacter = if index + 1 < totalLength then builtins.elemAt characters (index + 1) else null;
                    nextNextCharacter =
                      if index + 2 < totalLength then builtins.elemAt characters (index + 2) else null;
                  in
                  if currentCharacter == "*" && nextCharacter == "*" && nextNextCharacter == "/" then
                    "(.*/)?" + translateAtIndex (index + 3)
                  else if currentCharacter == "*" && nextCharacter == "*" then
                    ".*" + translateAtIndex (index + 2)
                  else if currentCharacter == "*" then
                    "[^/]*" + translateAtIndex (index + 1)
                  else if currentCharacter == "?" then
                    "[^/]" + translateAtIndex (index + 1)
                  else if currentCharacter == "{" then
                    let
                      braceParseResult = parseBraceAlternatives characters index;
                    in
                    if braceParseResult == null then
                      "\\{" + translateAtIndex (index + 1)
                    else
                      let
                        translatedAlternatives = builtins.map translateGlobString braceParseResult.alternatives;
                        alternativesRegex = lib.concatStringsSep "|" translatedAlternatives;
                      in
                      "(" + alternativesRegex + ")" + translateAtIndex braceParseResult.nextIndex
                  else if currentCharacter == "[" then
                    let
                      restOfString = lib.concatStrings (lib.drop (index + 1) characters);
                      matchResult = builtins.match "([!^]?[^\n\\]]*)\\](.*)" restOfString;
                    in
                    if matchResult == null then
                      "\\[" + translateAtIndex (index + 1)
                    else
                      let
                        characterClassBody = builtins.elemAt matchResult 0;
                        remainingTail = builtins.elemAt matchResult 1;
                        normalizedBody =
                          if lib.hasPrefix "!" characterClassBody then
                            "^" + lib.removePrefix "!" characterClassBody
                          else
                            characterClassBody;
                      in
                      "[" + normalizedBody + "]" + translateGlobString remainingTail
                  else
                    escapeRegexCharacter currentCharacter + translateAtIndex (index + 1);
            in
            translateAtIndex 0;
        in
        "^" + translateGlobString globPattern + "$"
      );
}
