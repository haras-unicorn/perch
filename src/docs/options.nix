{
  self,
  pkgs,
  inputs,
  flakeModules,
  ...
}:

{
  package = self.lib.docs.moduleOptionsMarkdown {
    inherit pkgs;
    specialArgs = inputs;
    modules = (builtins.attrValues flakeModules) ++ [
      self.lib.eval.flakeEvalModule
    ];
  };
}
