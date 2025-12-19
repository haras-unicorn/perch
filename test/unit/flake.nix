{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?rev=727668086d6923171b25b6a74064d418ae1edb27";
  };

  outputs =
    { self, nixpkgs, ... }:
    {
      test =
        {
          root,
          filter ? "",
        }:
        let
          lib = nixpkgs.lib;

          specialArgs = {
            lib = lib;
            self.lib = flake.lib;
            nixpkgs = nixpkgs;
          };

          importLib = ((import "${root}/src/lib/import.nix" specialArgs).flake.lib);

          eval = lib.evalModules {
            specialArgs = specialArgs;
            class = "flake";
            modules = builtins.attrValues (
              lib.filterAttrs (name: _: lib.hasPrefix "lib" name) (
                importLib.import.dirToFlatPathAttrs "-" "${root}/src"
              )
            );
          };

          flake = eval.config.flake;

          specs = importLib.import.dirToFlatValueAttrs "-" "${self}/specs";

          results = lib.flatten (
            builtins.map (
              outer:
              builtins.map
                (inner: {
                  name = "${outer.name}: ${inner.name}";
                  value = if inner.value then "passed" else "failed";
                })
                (
                  builtins.filter (inner: lib.hasPrefix filter outer.name || lib.hasPrefix filter inner.name) (
                    lib.attrsToList (outer.value specialArgs)
                  )
                )
            ) (lib.attrsToList specs)
          );

          ok = builtins.all (result: result.value == "passed") results;

          summary =
            let
              total = builtins.length results;
              failed = builtins.filter (r: r.value == "failed") results;
              passedCount = total - builtins.length failed;

              header = if ok then "✅ All tests passed!" else "❌ Some tests failed.";

              line = result: "- " + result.name + ": " + (if result.value == "passed" then "✅" else "❌");

              details =
                if ok then "" else "\n\nFailed tests:\n" + lib.concatStringsSep "\n" (builtins.map line failed);

              tally = "\n\nSummary: " + toString passedCount + "/" + toString total + " passed";
            in
            header + tally + details;
        in
        {
          inherit ok results summary;
        };
    };
}
