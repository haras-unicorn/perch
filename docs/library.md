# Library

The `perch.lib` library is split by its modules.

## Artifacts

- `perch.lib.artifacts.make`:

  ```text
    {
      specialArgs,
      flakeModules,
      nixpkgs,
      nixpkgsConfig,
      config,
      defaultConfig,
    } -> {
      "systems...": {
        "default or names...": "<<artifact>>"
      }
    }
  ```

  Makes artifacts from provided flake modules and config attributes.

## Attrset

- `perch.lib.attrset.removeAttrByPath`:

  ```text
  [string]: ?: ?
  ```

  Removes provided path from attrset.

- `perch.lib.attrset.removeAttrsByPath`

  ```text
  [[string]]: ?: ?
  ```

  Removes provided paths from attrset.

- `perch.lib.attrset.keepAttrByPath`

  ```text
  [string]: ?: ?
  ```

  Keeps only provided path in attrset.

- `perch.lib.attrset.keepAttrsByPath`

  ```text
  [[string]]: ?: ?
  ```

  Keeps only provided paths in attrset.

## Configurations

- `perch.lib.configurations.make`:

  ```text
  {
    specialArgs,
    flakeModules,
    nixpkgs,
    nixpkgsConfig,
    config,
    defaultConfig,
  } -> {
    "${name}-${system}" = "<<nixos configuration>>"
  }
  ```

  Makes NixOS configurations from provided flake modules and config attributes.

## Debug

- `perch.lib.debug.trace`:

  ```text
  ?: ?
  ```

  Prints the value in JSON and returns it.

## Defaults

- `perch.lib.defaults.systems`:

  ```text
  [string]
  ```

  The default systems.

## Eval

- `perch.lib.eval.filter`:

  ```text
  specialArgs: filterModule: modules:
  ```

  Filters `modules: attrset of module` based on the
  `filterModule: ([options] [config]) -> bool` predicate during eval.

- `perch.lib.eval.flake`:

  ```text
  specialArgs: inputModules: selfModules: flake
  ```

  Evaluates a flake based on `inputModules: [module]` and
  `selfModules: attrset of module`.

## Factory

- `perch.lib.factory.submoduleModule`:

  ```text
  {
    flakeModules,
    specialArgs,
    superConfig,
    superOptions,
    config,
    configs ? "${config}s",
    submoduleType ? lib.types.attrsOf lib.types.raw,
    mapSubmodules ? _: _,
    mapConfig ? _: _: _,
    mapOptions ? _: _,
  } -> module result
  ```

  Creates a submodules options and config from the provided flake modules and
  config attrs.

- `perch.lib.factory.artifactModule`

  ```text
  {
    flakeModules,
    specialArgs,
    superConfig,
    superOptions,
    nixpkgs,
    nixpkgsConfig,
    config,
    configs ? "${config}s",
    artifactType ? lib.types.attrsOf (lib.types.attrsOf lib.types.raw),
    mapArtifacts ? (_: _),
    mapConfig ? _: _: _,
    mapOptions ? _: _,
  } -> module result
  ```

  Creates an artifacts options and config from the provided flake modules and
  config attrs.

- `perch.lib.factory.configurationModule`

  ```text
  {
    flakeModules,
    specialArgs,
    superConfig,
    superOptions,
    nixpkgs,
    nixpkgsConfig,
    config,
    configs ? "${config}s",
    configurationType ? lib.types.attrsOf lib.types.raw,
    mapConfigurations ? (_: _),
    mapConfig ? _: _: _,
    mapOptions ? _: _,
  } -> module result
  ```

  Creates a NixOS configurations options and config from the provided flake
  modules and config attrs.

## Flake

- `perch.lib.flake.make`

  ```text
  {
    inputs,
    root ? null,
    prefix ? null,
    selfModules ? { },
    inputModules ? [ ],
    includeInputModulesFromInputs ? true,
    separator ? "-",
    libPrefix ? null,
  } -> flake
  ```

  Creates a flake based on the provided inputs and root/prefix or selfModules.
  Evaluates modules with the `libPrefix` first if provided.

## Import

- `perch.lib.import.dirTo(Attrs|List|FlatAttrs)(WithMap|WithMetadata|Value|Path)`

  ```text
  path: (mapFn?): result
  ```

  Imports a directory from `path` into attrs, list or flat attrs of values,
  paths, raw metadata values or into anything with the provided function when
  using the `WithMap` variant.

## Lib

Contains the `flake.lib` option definition.

## Module

- `perch.lib.module.patch`

  ```text
  mapArgsDeclaration: mapArgsDefinition: mapResult: module: module
  ```

  Patches a modules result, arguments declarations (if function) and argument
  definitions (if function). It does this on the module and all of its imports
  recursively.

## String

- `perch.lib.string.capitalize`

  ```text
  string: string
  ```

  Capitalizes the string turning the first letter uppercase.

## Submodules

- `perch.lib.submodules.make`

  ```text
  {
    flakeModules,
    specialArgs,
    config,
    defaultConfig,
  } -> {
    "module names..." = "<<module>>"
  }
  ```

  Makes modules from provided flake modules and config attributes.

## Trivial

- `perch.lib.trivial.mapFunctionResult`

  ```text
  mapResult: function: function
  ```

  Maps the function result using the provided function.

- `perch.lib.trivial.mapFunctionArgs`

  ```text
  mapArgsDeclaration: mapArgsDefinition: function: function
  ```

  Maps the function argument declaration and argument definition using the
  provided function.

- `perch.lib.trivial.importIfPath`

  ```text
  module: module
  ```

  If the module is a path, imports it and returns it, otherwise it just returns
  it.

- `perch.lib.trivial.mapAttrsetImports`

  ```text
  mapImported: attrset: attrset
  ```

  Maps all `imports` attrs in an attrset recursively using the provided
  function.

## Type

- `perch.lib.type.overlay`: `type` - Overlay type

- `perch.lib.type.nixpkgs.config`: `type` - Nixpkgs config type
