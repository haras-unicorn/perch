{ self, ... }:

let
  submodules = self.lib.submodules.make {
    flakeModules = {
      withConfig = {
        submodule = {
          value = 1;
        };
        defaultSubmodule = true;
      };
      withoutConfig = {
        other = 2;
      };
    };
    specialArgs = { inherit self; };
    config = "submodule";
    defaultConfig = "defaultSubmodule";
  };
in
{
  submodules_make_correct =
    submodules == {
      default = {
        value = 1;
      };
      withConfig = {
        value = 1;
      };
    };
}
