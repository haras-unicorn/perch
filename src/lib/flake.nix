{ self, lib, ... }:

{
  flake.lib.flake.make =
    self.lib.docs.function
      {
        description = ''
          Build a “flake output” attrset by collecting modules, evaluating them with Perch’s flake evaluator,
          and returning `config.flake` from the result.

          It can:
          - load modules from a directory on disk (via `root` + `prefix`)
          - take explicit modules you pass in (`selfModules`, `inputModules`)
          - optionally include `modules.default` from your flake inputs
          - (optionally) do a small bootstrapping step (`libPrefix`) so `self.lib` can be provided by modules themselves
        '';
        type = self.lib.types.function (self.lib.types.args (
          { lib, ... }:
          {
            options = {
              inputs = lib.mkOption {
                type = lib.types.attrs;
                description = ''
                  Flake inputs attrset (typically the `inputs` from your `outputs = { ... }:` function).
                  Used as `specialArgs` during evaluation, and also scanned for `modules.default` when enabled.
                '';
              };

              root = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
                description = ''
                  Root path for discovering modules on disk. When combined with `prefix`, Perch will import modules
                  from `root/prefix` using `flake.lib.import`.
                  Set to `null` to disable directory-based module discovery.
                '';
              };

              prefix = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                  Subdirectory (relative to `root`) to scan for modules.
                  Only used when both `root` and `prefix` are non-null.
                '';
              };

              selfModules = lib.mkOption {
                type = lib.types.attrsOf lib.types.raw;
                default = { };
                description = ''
                  Modules belonging to this flake.

                  You can pass either:
                  - an attrset `{ name = module; ... }` (recommended), or
                  - a list of modules (they will be named `module-0`, `module-1`, ...).

                  Each module is patched to have a stable `key` corresponding to its name.
                '';
              };

              inputModules = lib.mkOption {
                type = lib.types.listOf lib.types.raw;
                default = [ ];
                description = ''
                  Extra modules to include during evaluation (in addition to `selfModules` and any modules discovered from `root/prefix`).
                  This is a list, since ordering can matter for module composition.
                '';
              };

              includeInputModulesFromInputs = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                  Whether to automatically include `modules.default` from each flake input (excluding `self`),
                  when that input provides it.
                  Disable this if you want full manual control over which input modules participate.
                '';
              };

              separator = lib.mkOption {
                type = lib.types.str;
                default = "-";
                description = ''
                  Separator used when generating names for modules discovered on disk (via `root/prefix`).
                  These names become keys in the “flat” module attrset (for example: `foo-bar-baz`).
                '';
              };

              libPrefix = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                  Optional bootstrapping mode for flakes that define their own `self.lib` via modules.

                  When set, Perch first evaluates only modules whose names start with `libPrefix` to obtain `config.flake.lib`,
                  then re-evaluates the full module set with that `self.lib` injected into `specialArgs`.
                  Leave as `null` for normal operation.
                '';
              };
            };
          }
        )) lib.types.attrs;
      }
      (
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
            if prefixedRoot == null then
              { }
            else
              builtins.mapAttrs (_: value: value.__import.path) (
                lib.filterAttrs (_: value: value.__import.type != "unknown") (
                  self.lib.import.dirToFlatAttrsWithMetadata {
                    inherit separator;
                    dir = prefixedRoot;
                  }
                )
              );

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
              self.lib.eval.flake (
                inputs
                // {
                  inherit root;
                  inputs = inputs // {
                    inherit root;
                  };
                }
              ) (inputModulesFromInputs ++ inputModules) (prefixedRootModules // selfModuleAttrs)
            else
              let
                libModules = lib.filterAttrs (name: _: lib.hasPrefix libPrefix name) (
                  prefixedRootModules // selfModuleAttrs
                );

                libSpecialArgs = (
                  inputs
                  // {
                    inherit root;
                    inputs = inputs // {
                      inherit root;
                      self.lib = selfLib;
                    };
                  }
                  // {
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
        if eval.config ? flake then eval.config.flake else { }
      );
}
