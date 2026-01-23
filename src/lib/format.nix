{ self, lib, ... }:

{
  flake.lib.format.optionsToArgsString =
    self.lib.docs.function
      {
        type = self.lib.types.function lib.types.raw lib.types.raw;
        description = ''
          Converts evaluated options to a human-friendly string
          useful for function arguments
        '';
      }
      (
        evaluatedOptions:
        let
          optionTypeToString =
            option:
            if option ? type && option.type ? description then
              option.type.description
            else if option ? type && option.type ? name then
              option.type.name
            else
              "unknown";

          optionDescriptionToStringOrNull =
            option:
            let
              optionDescription = option.description or null;
            in
            if optionDescription == null || optionDescription == "" then null else lib.trim optionDescription;

          indentation = "  ";

          renderSingleArgument =
            option:
            let
              typeString = optionTypeToString option;
              descriptionStringOrNull = optionDescriptionToStringOrNull option;

              renderedTypeString = if lib.hasInfix "," typeString then "(${typeString})" else typeString;

              renderedDescriptionLines =
                if descriptionStringOrNull == null then
                  [ ]
                else
                  map (descriptionLine: "${indentation}# ${descriptionLine}") (
                    lib.splitString "\n" descriptionStringOrNull
                  );
            in
            lib.concatStringsSep "\n" (
              renderedDescriptionLines
              ++ [ "${indentation}${builtins.concatStringsSep "." option.loc}: ${renderedTypeString},\n" ]
            );

          renderedArgumentsBody = lib.concatStringsSep "\n" (
            map renderSingleArgument (self.lib.options.flatten evaluatedOptions)
          );
        in
        "{\n"
        + (if renderedArgumentsBody == "" then "" else renderedArgumentsBody + "\n")
        + "${indentation}...\n"
        + "}"
      );
}
