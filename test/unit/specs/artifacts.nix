{ self, nixpkgs, ... }:

let
  makeArtifacts = self.lib.artifacts.make;
  specialArgs = { inherit self; };
  config = "package";
  nixpkgsConfig = "packageNixpkgs";
  defaultConfig = "defaultPackage";
  flakeModules = {
    x68_64_Only = {
      packageNixpkgs = {
        system = "x86_64-linux";
      };
      package = "hello x86_64 :)";
    };
    allDefaultSystems = {
      package = "hello all default systems :)";
    };
  };

  artifacts = makeArtifacts {
    inherit
      specialArgs
      flakeModules
      nixpkgs
      nixpkgsConfig
      config
      defaultConfig
      ;
  };
in
{
  artifacts_make_correct =
    artifacts == {
      "aarch64-darwin" = {
        allDefaultSystems = "hello all default systems :)";
      };
      "aarch64-linux" = {
        allDefaultSystems = "hello all default systems :)";
      };
      "x86_64-darwin" = {
        allDefaultSystems = "hello all default systems :)";
      };
      "x86_64-linux" = {
        x68_64_Only = "hello x86_64 :)";
        allDefaultSystems = "hello all default systems :)";
      };
    };
}
