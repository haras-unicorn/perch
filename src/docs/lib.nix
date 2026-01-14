{
  self,
  pkgs,
  specialArgs,
  ...
}:

{
  package = self.lib.docs.libFunctionsMarkdown {
    inherit pkgs specialArgs;
    lib = self.lib;
  };
}
