{ lib, ... }:

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

  nixpkgsConfigType = lib.mkOptionType {
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

  overlayType = lib.mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = lib.isFunction;
    merge = lib.mergeOneOption;
  };
in
{
  flake.lib.type.overlay = overlayType;

  flake.lib.type.nixpkgs.config = nixpkgsConfigType;
}
