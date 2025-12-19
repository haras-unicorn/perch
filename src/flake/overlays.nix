{
  self,
  lib,
  config,
  ...
}:

{
  options.overlays = lib.mkOption {
    type = lib.types.attrsOf self.lib.type.overlay;
    default = { };
    description = lib.literalMD ''
      `overlays` flake output.
    '';
  };
  config.eval.privateConfig = [ [ "overlays" ] ];

  options.flake.overlays = lib.mkOption {
    type = lib.types.attrsOf self.lib.type.overlay;
    default = { };
    description = lib.literalMD ''
      `overlays` flake output.
    '';
  };
  config.flake.overlays = config.overlays;
  config.eval.publicConfig = [
    [
      "flake"
      "overlays"
    ]
  ];
}
