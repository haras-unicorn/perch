{ self, lib, ... }:

{
  flake.lib.glob.toRegex =
    self.lib.docs.function
      {
        description = ''
          Convert a glob pattern to a fully-anchored regular expression string.
        '';
        type = self.lib.types.function lib.types.str lib.types.str;
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
        lib.fix (
          globToRegexRecursive: globPattern:
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
        )
      );
}
