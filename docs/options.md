# Options

## app

The app

_Type:_ `raw value`

## appNixpkgs

Nixpkgs configuration for app

_Type:_ `nixpkgs config`

## check

The check

_Type:_ `raw value`

## checkNixpkgs

Nixpkgs configuration for check

_Type:_ `nixpkgs config`

## defaultApp

Whether to set this as the default app

_Type:_ `boolean`

_Default:_ `false`

## defaultCheck

Whether to set this as the default check

_Type:_ `boolean`

_Default:_ `false`

## defaultDevShell

Whether to set this as the default devShell

_Type:_ `boolean`

_Default:_ `false`

## defaultFormatter

Whether to set this as the default formatter

_Type:_ `boolean`

_Default:_ `false`

## defaultLegacyPackage

Whether to set this as the default legacyPackage

_Type:_ `boolean`

_Default:_ `false`

## defaultNixosConfiguration

Whether to set this as the default nixosConfiguration

_Type:_ `boolean`

_Default:_ `false`

## defaultNixosModule

Whether to set this as the default nixosModule

_Type:_ `boolean`

_Default:_ `false`

## defaultPackage

Whether to set this as the default package

_Type:_ `boolean`

_Default:_ `false`

## devShell

The devShell

_Type:_ `raw value`

## devShellNixpkgs

Nixpkgs configuration for devShell

_Type:_ `nixpkgs config`

## docTestsAsChecks

Convert all "perch\.lib\.docs\.function" tests to checks

_Type:_ `boolean`

_Default:_ `false`

## dummy\.attrsOfSubmodule

Dummy option to test attrs of option flattening\.

_Type:_ `attribute set of (submodule)`

_Default:_ `{ }`

## dummy\.attrsOfSubmodule\.<name\>\.suboption

Dummy suboption to test attrs of option flattening\.

_Type:_ `string`

_Default:_ `""`

_Example:_ ~test~ _test_ **test**

## dummy\.listOfSubmodule

Dummy option to test list of option flattening\.

_Type:_ `list of (submodule)`

_Default:_ `{ }`

## dummy\.listOfSubmodule\.\*\.suboption

- **Read-only**

Dummy suboption to test list of option flattening\.

_Type:_ `string`

_Default:_ `""`

## dummy\.submodule

Dummy option to test direct option flattening\.

_Type:_ `submodule`

_Default:_ `{ }`

## dummy\.submodule\.suboption

Dummy suboption to test direct option flattening\.

_Type:_ `string`

_Default:_

```nix
(x: builtins.trace x x) "hello world :)"
```

## eval\.allowedArgs

List of allowed argument names for module evaluation

_Type:_ `list of string`

_Default:_ `[ ]`

## eval\.privateConfig

Private configuration paths not exposed in output flake modules

_Type:_ `list of list of string`

_Default:_ `[ ]`

## eval\.publicConfig

Public configuration paths are exposed in output flake modules

_Type:_ `list of list of string`

_Default:_ `[ ]`

## flake\.apps

Attribute set of all apps in the flake

_Type:_ `attribute set of (attribute set)`

## flake\.checks

Attribute set of all checks in the flake

_Type:_ `attribute set of (attribute set)`

## flake\.devShells

Attribute set of all devShells in the flake

_Type:_ `attribute set of (attribute set)`

## flake\.formatter

Attribute set of all formatter in the flake

_Type:_ `attribute set`

## flake\.legacyPackages

Attribute set of all legacyPackages in the flake

_Type:_ `attribute set of (attribute set)`

## flake\.lib

Attribute set of all library functions in the flake

_Type:_ `nested attribute set of raw value`

_Default:_ `{ }`

## flake\.modules

Modules prepared for use in other flakes

_Type:_ `attribute set of module`

_Default:_ `{ }`

## flake\.nixosConfigurations

Attribute set of all nixosConfigurations in the flake

_Type:_ `attribute set`

## flake\.nixosModules

Attribute set of all nixosModules in the flake

_Type:_ `attribute set`

## flake\.overlays

Attribute set of all overlays in the flake

_Type:_ `attribute set of (nixpkgs overlay)`

_Default:_ `{ }`

## flake\.packages

Attribute set of all packages in the flake

_Type:_ `attribute set of (attribute set)`

## flakeTests\.args

Additional arguments for "nix flake check"

_Type:_ `list of string`

_Default:_

```nix
[
  "--override-input"
  "self'"
  (builtins.toString (
    builtins.path {
      path = config.flakeTests.root;
      name = "self-prime";
    }
  ))
]
```

## flakeTests\.asApps

Aggregate checks of flakes from a specified path to apps in this flake

_Type:_ `boolean`

_Default:_ `false`

## flakeTests\.asChecks

Aggregate checks of flakes from a specified path to checks in this flake

IMPORTANT: this will require the recursive\-nix feature which will most likely
fail due to a current regression in nix \(nixpkgs issue 14529\)

_Type:_ `boolean`

_Default:_ `false`

## flakeTests\.asPackages

Aggregate checks of flakes from a specified path to packages in this flake

_Type:_ `boolean`

_Default:_ `false`

## flakeTests\.path

Path to test flakes

_Type:_ `absolute path`

_Default:_

```nix
lib.path.append config.flakeTests.root config.flakeTests.prefix
```

## flakeTests\.prefix

The prefix from the root at which test flakes are located

_Type:_ `string`

_Default:_ `"test"`

## flakeTests\.root

The root of the repository used to get test flakes and to set "self'" input

_Type:_ `absolute path`

_Default:_

```nix
specialArgs.root
```

## formatter

The formatter

_Type:_ `raw value`

## formatterNixpkgs

Nixpkgs configuration for formatter

_Type:_ `nixpkgs config`

## legacyPackage

The legacyPackage

_Type:_ `raw value`

## legacyPackageNixpkgs

Nixpkgs configuration for legacyPackage

_Type:_ `nixpkgs config`

## nixosConfiguration

The module result for nixosConfiguration

_Type:_ `raw value`

## nixosConfigurationNixpkgs

Nixpkgs configuration for nixosConfiguration

_Type:_ `nixpkgs config`

## nixosModule

Result of the nixosModule

_Type:_ `attribute set`

## overlays

Attribute set of all overlays in the flake

_Type:_ `attribute set of (nixpkgs overlay)`

_Default:_ `{ }`

## package

The package

_Type:_ `raw value`

## packageNixpkgs

Nixpkgs configuration for package

_Type:_ `nixpkgs config`

## packagesAsApps

Convert all packages to apps and put them in flake outputs

_Type:_ `boolean`

_Default:_ `false`

## packagesAsLegacyPackages

Convert all packages to legacy packages and put them in flake outputs

_Type:_ `boolean`

_Default:_ `false`
