{ lib, self, ... }:

{
  flake.lib.packages.asApps =
    self.lib.docs.function
      {
        description = ''Convert packages to apps'';
        type = self.lib.types.function (lib.types.attrsOf (lib.types.attrsOf lib.types.package)) (
          lib.types.attrsOf (lib.types.attrsOf lib.types.raw)
        );
        tests =
          let
            f = self.lib.packages.asApps;

            mockPkgNoDesc = {
              type = "derivation";
              outPath = "/nix/store/00000000000000000000000000000000-mock";
              meta = {
                mainProgram = "mock";
              };
            };

            mockPkgWithDesc = {
              type = "derivation";
              outPath = "/nix/store/11111111111111111111111111111111-mock";
              meta = {
                mainProgram = "mock";
                description = "hello";
              };
            };

            system = "x86_64-linux";

            res1 = f { };
            res2 = f {
              ${system} = {
                hello = mockPkgNoDesc;
              };
            };
            res3 = f {
              ${system} = {
                hello = mockPkgWithDesc;
              };
            };
          in
          {
            empty-attrset = res1 == { };

            preserves-system-key = res2 ? ${system};

            preserves-package-key = res2.${system} ? hello;

            sets-type-app = res2.${system}.hello.type or null == "app";

            program-is-string = builtins.isString res2.${system}.hello.program;

            meta-description-defaults-to-name = res2.${system}.hello.meta.description == "hello";

            meta-description-preserved = res3.${system}.hello.meta.description == "hello";
          };
      }
      (
        packages:
        builtins.mapAttrs (
          system: systemPackages:
          builtins.mapAttrs (name: package: {
            type = "app";
            program = lib.getExe package;
            meta =
              let
                initial = package.meta or { };
              in
              initial // { description = initial.description or name; };
          }) systemPackages
        ) packages
      );
}
