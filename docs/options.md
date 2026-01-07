# Options

## package

The package

_Type:_ raw value

## packageNixpkgs

Nixpkgs configuration for package

_Type:_ nixpkgs config

## packagesAsApps

Convert all packages to apps and put them in flake outputs

_Type:_ boolean

_Default:_ `true`

## packagesAsLegacyPackages

Convert all packages to legacy packages and put them in flake outputs

_Type:_ boolean

_Default:_ `true`

## app

The app

_Type:_ raw value

## appNixpkgs

Nixpkgs configuration for app

_Type:_ nixpkgs config

## check

The check

_Type:_ raw value

## checkNixpkgs

Nixpkgs configuration for check

_Type:_ nixpkgs config

## defaultApp

Whether to set this as the default app

_Type:_ boolean

_Default:_ `false`

## defaultCheck

Whether to set this as the default check

_Type:_ boolean

_Default:_ `false`

## defaultDevShell

Whether to set this as the default devShell

_Type:_ boolean

_Default:_ `false`

## defaultFormatter

Whether to set this as the default formatter

_Type:_ boolean

_Default:_ `false`

## defaultLegacyPackage

Whether to set this as the default legacyPackage

_Type:_ boolean

_Default:_ `false`

## defaultNixosConfiguration

Whether to set this as the default nixosConfiguration

_Type:_ boolean

_Default:_ `false`

## defaultNixosModule

Whether to set this as the default nixosModule

_Type:_ boolean

_Default:_ `false`

## defaultPackage

Whether to set this as the default package

_Type:_ boolean

_Default:_ `false`

## devShell

The devShell

_Type:_ raw value

## devShellNixpkgs

Nixpkgs configuration for devShell

_Type:_ nixpkgs config

## eval\.allowedArgs

List of allowed argument names for module evaluation

_Type:_ list of string

_Default:_ `[ ]`

## eval\.privateConfig

Private configuration paths not exposed in output flake modules

_Type:_ list of list of string

_Default:_ `[ ]`

## eval\.publicConfig

Public configuration paths are exposed in output flake modules

_Type:_ list of list of string

_Default:_ `[ ]`

## flake\.packages

Attribute set of all packages in the flake

_Type:_ attribute set of attribute set of raw value

## flake\.apps

Attribute set of all apps in the flake

_Type:_ attribute set of attribute set of raw value

## flake\.checks

Attribute set of all checks in the flake

_Type:_ attribute set of attribute set of raw value

## flake\.devShells

Attribute set of all devShells in the flake

_Type:_ attribute set of attribute set of raw value

## flake\.formatter

Attribute set of all formatter in the flake

_Type:_ attribute set of raw value

## flake\.legacyPackages

Attribute set of all legacyPackages in the flake

_Type:_ attribute set of attribute set of raw value

## flake\.lib

Attribute set of all library functions in the flake

_Type:_ nested attribute set of raw value

_Default:_ `{ }`

## flake\.modules

Modules prepared for use in other flakes

_Type:_ attribute set of module

_Default:_ `{ }`

## flake\.nixosConfigurations

Attribute set of all nixosConfigurations in the flake

_Type:_ attribute set of raw value

## flake\.nixosModules

Attribute set of all nixosModules in the flake

_Type:_ attribute set of raw value

## flake\.overlays

Attribute set of all overlays in the flake

_Type:_ attribute set of (nixpkgs overlay)

_Default:_ `{ }`

## formatter

The formatter

_Type:_ raw value

## formatterNixpkgs

Nixpkgs configuration for formatter

_Type:_ nixpkgs config

## legacyPackage

The legacyPackage

_Type:_ raw value

## legacyPackageNixpkgs

Nixpkgs configuration for legacyPackage

_Type:_ nixpkgs config

## nixosConfiguration

The module result for nixosConfiguration

_Type:_ raw value

## nixosConfigurationNixpkgs

Nixpkgs configuration for nixosConfiguration

_Type:_ nixpkgs config

## nixosModule

Result of the nixosModule

_Type:_ attribute set of raw value

## overlays

Attribute set of all overlays in the flake

_Type:_ attribute set of (nixpkgs overlay)

_Default:_ `{ }`
