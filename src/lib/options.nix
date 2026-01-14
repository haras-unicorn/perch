{ self, lib, ... }:

{
  config.flake.lib.options.flatten =
    self.lib.docs.function
      {
        description = ''
          Flatten an evaluated NixOS-style options tree into a sorted list.
          Also descends into submodule option types (including listOf submodule).
        '';
        type = self.lib.types.function lib.types.raw (lib.types.listOf lib.types.raw);
      }
      (
        let
          subOptionsTreeFromType =
            type: prefix:
            if type ? getSubOptions then
              let
                r = builtins.tryEval (type.getSubOptions prefix);
              in
              if r.success then r.value else null
            else if type ? elemType then
              subOptionsTreeFromType type.elemType prefix
            else if type ? nestedType then
              subOptionsTreeFromType type.nestedType prefix
            else
              null;

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
                    let
                      optionName = lib.concatStringsSep "." (pathPrefix ++ [ attributeName ]);
                      prefix = pathPrefix ++ [ attributeName ];

                      subTree = if attributeValue ? type then subOptionsTreeFromType attributeValue.type prefix else null;

                      subFlattened = if subTree == null then [ ] else flatten prefix subTree;
                    in
                    [
                      {
                        inherit optionName;
                        option = attributeValue;
                      }
                    ]
                    ++ subFlattened
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

  config.flake.lib.options.toMarkdown =
    self.lib.docs.function
      {
        description = ''
          Render an evaluated options tree into a simple markdown document.

          For each option it produces a heading with the option path,
          its description, type and default if provided.
        '';

        type = self.lib.types.function (self.lib.types.args (
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
        )) lib.types.str;
      }
      (
        {
          options,
          transformOptions ? (opt: opt),
        }:
        let
          flattened = builtins.map transformOptions (self.lib.options.flatten options);

          pretty = lib.generators.toPretty { };

          escape =
            string:
            lib.replaceStrings
              [
                "\\"
                "`"
                "*"
                "_"
                "{"
                "}"
                "["
                "]"
                "("
                ")"
                "#"
                "+"
                "-"
                "."
                "!"
                "|"
                ">"
              ]
              [
                "\\\\"
                "\\`"
                "\\*"
                "\\_"
                "\\{"
                "\\}"
                "\\["
                "\\]"
                "\\("
                "\\)"
                "\\#"
                "\\+"
                "\\-"
                "\\."
                "\\!"
                "\\|"
                "\\>"
              ]
              string;

          optionTypeString =
            option:
            if option ? type && option.type ? description then
              lib.trim option.type.description
            else if option ? type && option.type ? name then
              lib.trim option.type.name
            else
              "raw value";

          optionDescriptionStringOrNull =
            option:
            let
              desc = option.description or null;
            in
            if desc == null || desc == "" then null else escape (lib.trim desc);

          defaultString =
            option:
            if option ? defaultText then
              lib.trim option.defaultText
            else if option ? default then
              pretty option.default
            else
              "";

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
                let
                  default = defaultString option;
                in
                if default != "" then [ ("_Default:_ `${default}`") ] else [ ];
            in
            lib.concatStringsSep "\n" (
              [
                "## ${escape optionName}"
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

  options.dummy = {
    submodule = lib.mkOption {
      description = "Dummy option to test direct option flattening.";
      default = { };
      type = lib.types.submodule {
        options.suboption = lib.mkOption {
          description = "Dummy suboption to test direct option flattening.";
          type = lib.types.str;
          default = "";
        };
      };
    };
    attrsOfSubmodule = lib.mkOption {
      description = "Dummy option to test attrs of option flattening.";
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.suboption = lib.mkOption {
            description = "Dummy suboption to test attrs of option flattening.";
            type = lib.types.str;
            default = "";
          };
        }
      );
    };
    listOfSubmodule = lib.mkOption {
      description = "Dummy option to test list of option flattening.";
      default = { };
      type = lib.types.listOf (
        lib.types.submodule {
          options.suboption = lib.mkOption {
            description = "Dummy suboption to test list of option flattening.";
            type = lib.types.str;
            default = "";
          };
        }
      );
    };
  };
}
