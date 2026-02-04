{ self, lib, ... }:

{
  config.flake.lib.options.flatten =
    self.lib.docs.function
      {
        description = ''
          Flatten an evaluated NixOS-style options tree into a sorted list.
          Also descends into submodule option types (including listOf submodule)
          and removes any `_module` options.
        '';
        type = self.lib.types.function lib.types.raw self.lib.types.list;
      }
      (
        let
          flatten =
            options:
            (lib.concatMap
              (
                option:
                if option.type ? getSubOptions then
                  [ option ] ++ (flatten (option.type.getSubOptions option.loc))
                else
                  [ option ]
              )
              (
                lib.collect (value: builtins.isAttrs value && value ? _type && value._type == "option") (
                  builtins.removeAttrs options [ "_module" ]
                )
              )
            );
        in
        flatten
      );

  config.flake.lib.options.toMarkdown =
    self.lib.docs.function
      {
        description = ''
          Render an evaluated options tree into a simple markdown document
          excluding any "_module" options.

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

          isLiteral = v: builtins.isAttrs v && v ? _type && v ? text;

          renderDoc =
            value:
            if value == null then
              null
            else if isLiteral value && value._type == "literalMD" then
              lib.trim value.text
            else if isLiteral value && value._type == "literalExpression" then
              lib.concatStringsSep "\n" [
                "```nix"
                (lib.trim value.text)
                "```"
              ]
            else if builtins.isString value then
              escape (lib.trim value)
            else
              # last resort: pretty-print arbitrary nix values
              lib.trim (pretty value);

          renderValueInlineOrBlock =
            value:
            let
              txt = lib.trim (pretty value);
              lines = lib.splitString "\n" txt;
              isMultiline = (builtins.length lines > 1) && txt != "";
            in
            if !isMultiline then
              "`${txt}`"
            else
              lib.concatStringsSep "\n" ([ "```text" ] ++ lines ++ [ "```" ]);

          optionTypeString =
            option:
            if option ? type && option.type ? description then
              lib.trim option.type.description
            else if option ? type && option.type ? name then
              lib.trim option.type.name
            else
              "raw value";

          optionDescriptionLines =
            option:
            let
              desc = option.description or null;
              rendered = renderDoc desc;
            in
            if rendered == null || rendered == "" then
              [ ]
            else
              [
                rendered
                ""
              ];

          defaultLines =
            option:
            let
              value =
                if option ? defaultText then
                  option.defaultText
                else if option ? default then
                  option.default
                else
                  null;

              rendered =
                if value == null then
                  null
                else if isLiteral value && value._type == "literalExpression" then
                  renderDoc value
                else if isLiteral value && value._type == "literalMD" then
                  renderDoc value
                else
                  renderValueInlineOrBlock value;
            in
            if rendered == null || rendered == "" then
              [ ]
            else
              [
                "_Default:_"
                rendered
                ""
              ];

          exampleLines =
            option:
            let
              example = option.example or null;
              rendered = renderDoc example;
              fallback =
                if example == null then
                  null
                else if isLiteral example then
                  null
                else
                  renderValueInlineOrBlock example;
              final = if rendered != null && rendered != "" then rendered else fallback;
            in
            if final == null || final == "" then
              [ ]
            else
              [
                "_Example:_"
                final
                ""
              ];

          readOnlyLines =
            option:
            if (option.readOnly or false) then
              [
                "- **Read-only**"
              ]
            else
              [ ];

          shouldRender =
            option:
            let
              vis = option.visible or true;
              isHidden = (option.internal or false) || (vis == false) || (vis == "transparent");
            in
            !isHidden;

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
            option:
            let
              typeText = optionTypeString option;
            in
            lib.concatStringsSep "\n" (
              [
                "## ${escape (builtins.concatStringsSep "." option.loc)}"
                ""
              ]
              ++ (readOnlyLines option)
              ++ [ "" ]
              ++ (optionDescriptionLines option)
              ++ [
                (renderTypeBlock typeText)
                ""
              ]
              ++ (defaultLines option)
              ++ (exampleLines option)
            );

          rendered = builtins.filter (x: x != null && x != "") (
            map (fo: if shouldRender fo then renderOneOption fo else "") flattened
          );

        in
        lib.concatStringsSep "\n\n" rendered
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
          defaultText = lib.literalExpression ''(x: builtins.trace x x) "hello world :)"'';
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
            example = lib.literalMD ''~test~ _test_ **test**'';
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
            readOnly = true;
            type = lib.types.str;
            default = "";
          };
        }
      );
    };
  };
}
