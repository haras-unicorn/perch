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
      libPrefix ? null,
    }:
    let
      selfModuleAttrs =
        builtins.mapAttrs
          (
            name: module:
            self.lib.module.patch (_: args: args) (_: args: args) (
              _: result:
              result
              // {
                key = name;
              }
            ) module
          )
          (
            if builtins.isList selfModules then
              builtins.listToAttrs (
                lib.imap (i: module: {
                  name = "module-${builtins.toString i}";
                  value = module;
                }) selfModules
              )
            else
              selfModules
          );

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

      eval =
        if libPrefix == null then
          self.lib.eval.flake (inputs // { inherit root; }) (inputModulesFromInputs ++ inputModules) (
            prefixedRootModules // selfModuleAttrs
          )
        else
          let
            libModules = lib.filterAttrs (name: _: lib.hasPrefix libPrefix name) (
              prefixedRootModules // selfModuleAttrs
            );

            libSpecialArgs = (
              inputs
              // {
                inherit root;
                self.lib = selfLib;
              }
            );

            libEval = self.lib.eval.flake libSpecialArgs (inputModulesFromInputs ++ inputModules) libModules;

            selfLib =
              if libEval.config ? flake && libEval.config.flake ? lib then libEval.config.flake.lib else { };
          in
          self.lib.eval.flake libSpecialArgs (inputModulesFromInputs ++ inputModules) (
            prefixedRootModules // selfModuleAttrs
          );
    in
    if eval.config ? flake then eval.config.flake else { };
}
