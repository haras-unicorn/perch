# Modules

Here is a fizzbuzz flake from Perch end-to-end tests:

<!-- markdownlint-disable MD013 -->

```nix
{{ #include ../test/e2e/fizzbuzz/flake.nix }}
```

<!-- markdownlint-enable MD013 -->

In the example we see a call to `perch.lib.flake.make` with one `fizzbuzz`
module. The module defines:

- a default and named package called `fizzbuzz` by the name of the module for
  the abovementioned systems like so:

  ```nix
  {
    packages = {
      "systems..." = {
        default = "<<derivation>>";
        fizzbuzz = "<<derivation>>";
      };
    };
  }
  ```

- a default and named NixOS module using the beforementioned package called
  `fizzbuzz` by the name of the module like so:

  ```nix
  {
    nixosModules = {
      default = "<<module>>";
      fizzbuzz = "<<module>>";
    };
  }
  ```

- a NixOS configuration using the beforementioned NixOS module named
  `fizzbuzz-${system}` where the system is the abovementioned system

  ```nix
  {
    nixosConfigurations = {
      "fizzbuzz-${system}" = "<<nixos configuration>>";
    };
  }
  ```

## Special arguments

- `root` - if using `perch.lib.flake.make` with `root` and `prefix` the `root`
  argument will be supplied to special arguments of each module in any context
- `pkgs` - when creating modules, packages or configurations Perch automatically
  creates `pkgs` for you with the specified systems or all default systems if
  not provided with the consequence of the `pkgs` argument being `null` while
  evaluating the `nixpkgs` configuration for those `pkgs`
- `super` - when creating modules, packages or configurations Perch wraps your
  flake `options` and `config` into `super` attrset with the consequence of
  `super` being `null` in any other context since the prior `config` and
  `options` arguments may be occupied by another NixOS configuration
