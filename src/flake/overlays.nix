{
  self,
  lib,
  config,
  ...
}:

{
  options.overlays = lib.mkOption {
    type = lib.types.attrsOf self.lib.types.overlay;
    default = { };
    description = "Attribute set of all overlays in the flake";
  };
  config.eval.privateConfig = [ [ "overlays" ] ];

  options.flake.overlays = lib.mkOption {
    type = lib.types.attrsOf self.lib.types.overlay;
    default = { };
    description = "Attribute set of all overlays in the flake";
  };
  config.flake.overlays = config.overlays;
  config.eval.publicConfig = [
    [
      "flake"
      "overlays"
    ]
  ];
}
