{ self, lib, ... }:

{
  flake.lib.flake.make =
    {
      inputs,
      root ? null,
      prefix ? null,
      selfModules ? { },
      inputModules ? [ ],
      includeInputModulesFromInputs ? true,
      separator ? "-",
    }:
    let
      selfModule =
        if builtins.isList selfModules then
          builtins.listToAttrs (
            lib.imap (i: module: {
              name = "module-${builtins.toString i}";
              value = module;
            }) selfModules
          )
        else
          selfModules;

      prefixedRoot = if root == null || prefix == null then null else lib.path.append root prefix;

      prefixedRootModules =
        if prefixedRoot == null then { } else self.lib.import.dirToFlatPathAttrs separator prefixedRoot;

      inputModulesFromInputs =
        if !includeInputModulesFromInputs then
          [ ]
        else
          let
            selflessInputList = builtins.attrValues (builtins.removeAttrs inputs [ "self" ]);
          in
          builtins.filter (module: module != null) (
            builtins.map (
              input: if input ? modules && input.modules ? default then input.modules.default else null
            ) selflessInputList
          );

      eval = self.lib.eval.flake (inputs // { inherit root; }) (inputModulesFromInputs ++ inputModules) (
        prefixedRootModules // selfModule
      );
    in
    if eval.config ? flake then eval.config.flake else { };
}
