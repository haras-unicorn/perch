{
  self,
  lib,
  pkgs,
  inputs,
  flakeModules,
  ...
}:

{
  packagesAsApps = false;
  package =
    let
      options = pkgs.nixosOptionsDoc {
        transformOptions =
          opt:
          opt
          // {
            visible = opt.visible or true && (builtins.head opt.loc) != "_module";
            declarations = [ ];
          };
        options =
          let
            eval = lib.evalModules {
              specialArgs = inputs;
              modules = (builtins.attrValues flakeModules) ++ [
                self.lib.eval.flakeEvalModule
              ];
            };
          in
          eval.options;
      };
    in
    options.optionsCommonMark;
}
