{ self, lib, ... }:

{
  flake.lib.types.overlay = lib.mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = lib.isFunction;
    merge = lib.mergeOneOption;
  };

  flake.lib.types.nixpkgsConfig =
    # NOTE: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/nixpkgs.nix
    # TODO: somehow import from nixpkgs because this is super brittle
    let
      isConfig = x: builtins.isAttrs x || lib.isFunction x;

      optCall = f: x: if lib.isFunction f then f x else f;

      mergeNixpkgsConfig =
        lhs: rhs:
        lib.recursiveUpdate lhs rhs
        // lib.optionalAttrs (lhs ? packageOverrides) {
          packageOverrides =
            pkgs:
            optCall lhs.packageOverrides pkgs // optCall (lib.attrByPath [ "packageOverrides" ] { } rhs) pkgs;
        }
        // lib.optionalAttrs (lhs ? perlPackageOverrides) {
          perlPackageOverrides =
            pkgs:
            optCall lhs.perlPackageOverrides pkgs
            // optCall (lib.attrByPath [ "perlPackageOverrides" ] { } rhs) pkgs;
        };
    in
    lib.mkOptionType {
      name = "nixpkgs-config";
      description = "nixpkgs config";
      check =
        x:
        let
          traceXIfNot = c: if c x then true else lib.traceSeqN 1 x false;
        in
        traceXIfNot isConfig;
      merge = args: lib.foldr (def: mergeNixpkgsConfig def.value) { };
    };

  flake.lib.types.args =
    modules:
    self.lib.types.argsWith {
      shorthandOnlyDefinesConfig = true;
      modules = lib.toList modules;
    };

  flake.lib.types.argsWith =
    {
      modules,
      specialArgs ? { },
      shorthandOnlyDefinesConfig ? false,
      description ? null,
      class ? null,
    }@attrs:
    let
      base = lib.evalModules {
        inherit class specialArgs;
        modules = [
          { _module.args.name = lib.mkOptionDefault "‹name›"; }
          { _module.freeformType = lib.types.attrsOf lib.types.anything; }
        ]
        ++ modules;
      };

      docsEval = base.extendModules { modules = [ lib.types.noCheckForDocsModule ]; };

      argsDescription = self.lib.format.optionsToArgsString docsEval.options;
    in
    lib.types.submoduleWith (
      attrs
      // {
        description = if description != null then description else argsDescription;
      }
    );

  flake.lib.types.function =
    argumentType: resultType:
    let
      makeTypeDescription =
        type:
        if type ? description then
          type.description
        else if type ? name then
          type.name
        else
          "unknown";

      argumentDescription =
        if argumentType.name == "function" then
          "(${makeTypeDescription argumentType})"
        else
          makeTypeDescription argumentType;
    in
    (lib.types.mkOptionType {
      name = "function";
      description = "${argumentDescription} -> ${makeTypeDescription resultType}";
      check = x: lib.isFunction x;
      merge = lib.options.mergeOneOption;
    })
    // {
      __signature = {
        inherit argumentType resultType;
      };
    };
}
