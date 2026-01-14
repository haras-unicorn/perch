{ self, lib, ... }:

{
  flake.lib.options.flatten =
    self.lib.docs.function
      {
        description = ''
          Flatten an evaluated NixOS-style options tree into a sorted list.
        '';
        type = self.lib.types.function lib.types.raw (lib.types.listOf lib.types.raw);
      }
      (
        let
          flatten =
            pathPrefix: optionsTree:
            lib.sortOn (flattened: flattened.optionName) (
              lib.concatLists (
                lib.mapAttrsToList (
                  attributeName: attributeValue:
                  if lib.hasPrefix "_" attributeName then
                    [ ]
                  else if
                    lib.isAttrs attributeValue && attributeValue ? _type && attributeValue._type == "option"
                  then
                    [
                      {
                        optionName = lib.concatStringsSep "." (pathPrefix ++ [ attributeName ]);
                        option = attributeValue;
                      }
                    ]
                  else if lib.isAttrs attributeValue then
                    flatten (pathPrefix ++ [ attributeName ]) attributeValue
                  else
                    [ ]
                ) optionsTree
              )
            );
        in
        optionsTree: flatten [ ] optionsTree
      );

  flake.lib.options.toMarkdown =
    self.lib.docs.function
      {
        description = ''
          Render an evaluated options tree into a simple markdown document.

          For each option, produces:

          ## <option name>

          <option description>

          _Type:_
          - If single-line: `<type>`
          - If multi-line: fenced ```text block

          (_Default:_ <default>) # only when a default exists
        '';

        type = self.lib.types.args (
          { lib, ... }:
          {
            options = {
              options = lib.mkOption {
                description = "Evaluated options tree to render.";
                type = lib.types.raw;
              };

              transformOptions = lib.mkOption {
                description = "Transform options with a mapper function.";
                type = self.lib.types.function lib.types.raw lib.types.raw;
                default = xs: xs;
              };
            };
          }
        );
      }
      (
        {
          options,
          transformOptions ? (opt: opt),
        }:
        let
          flattened = builtins.map transformOptions (self.lib.options.flatten options);

          optionTypeString =
            option:
            if option ? type && option.type ? description then
              option.type.description
            else if option ? type && option.type ? name then
              option.type.name
            else
              "raw value";

          optionDescriptionStringOrNull =
            option:
            let
              desc = option.description or null;
            in
            if desc == null || desc == "" then null else desc;

          hasDefault = option: option ? default;

          defaultString = option: if builtins.isString option.default then option.default else "";

          renderTypeBlock =
            typeText:
            let
              typeLines = lib.splitString "\n" typeText;
              trimmed = lib.strings.trim typeText;
              isActuallyMultiline = (builtins.length typeLines > 1) && trimmed != "";
            in
            if !isActuallyMultiline then
              "_Type:_ `" + trimmed + "`"
            else
              lib.concatStringsSep "\n" (
                [
                  "_Type:_"
                  "```text"
                ]
                ++ typeLines
                ++ [ "```" ]
              );

          renderOneOption =
            flattenedOption:
            let
              optionName = flattenedOption.optionName;
              option = flattenedOption.option;

              descriptionOrNull = optionDescriptionStringOrNull option;
              typeText = optionTypeString option;

              defaultLines =
                if hasDefault option && defaultString option != "" then
                  [ ("_Default:_ " + defaultString option) ]
                else
                  [ ];
            in
            lib.concatStringsSep "\n" (
              [
                "## ${optionName}"
                ""
              ]
              ++ (
                if descriptionOrNull == null then
                  [ ]
                else
                  [
                    descriptionOrNull
                    ""
                  ]
              )
              ++ [
                (renderTypeBlock typeText)
                ""
              ]
              ++ defaultLines
            );

        in
        lib.concatStringsSep "\n\n" (map renderOneOption flattened)
      );
}
