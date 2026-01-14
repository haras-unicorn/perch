<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and adheres to [Semantic Versioning](https://semver.org/).

## [1.2.0] - 2026-01-14

### Added

- `perch.lib.glob.toRegex` function
- `perch.lib.trivial.isFunctor` and `perch.lib.trivial.toFunctor` functions
- `perch.lib.type.nixpkgs.config` to `perch.lib.types.nixpkgsConfig`
- `perch.lib.types.overlay` to `perch.lib.types.overlay`
- `perch.lib.types.args` as args type that is just an alias of
  `nixpkgs.lib.types.submodule`
- `perch.lib.types.function` as function type with argument and return type
- `perch.lib.docs.document` function for creating library functions with
  optional assertions from argument/return types

### Changed

- import functions regex matching and arguments from attrs instead of curry
- app `meta.description` is now equal to app/package name if otherwise not
  provided
- `packagesAsApps` and `packagesAsLegacyPackages` false by default
- `packagesAsApps` filtered by packages that have a `meta.mainProgram`

## [1.1.1] - 2026-01-07

### Added

- inputs to special args
- option descriptions
- generated options documentation

### Changed

- better handling of `flakeModules` module argument

## [1.1.0] - 2026-01-05

### Added

- `mapConfig` and `mapOptions` arguments for factory library functions
- `packagesAsApps` and `packagesAsLegacyPackages` options that are turned on by
  default

### Changed

- app output fix

## [1.0.4] - 2025-12-21

### Changed

- `perch.lib.configurations.make` default fix

## [1.0.3] - 2025-12-21

### Changed

- `perch.lib.submodules.make` result behavior

## [1.0.2] - 2025-12-21

### Changed

- `libFirst` behavior

## [1.0.1] - 2025-12-21

### Added

- `libFirst` argument to `lib.flake.make`

### Changed

- PR template to only include description

## [1.0.0] - 2025-12-19

### Added

- everything

[1.2.0]: https://github.com/haras-unicorn/perch/compare/1.1.1...1.2.0
[1.1.1]: https://github.com/haras-unicorn/perch/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/haras-unicorn/perch/compare/1.0.4...1.1.0
[1.0.4]: https://github.com/haras-unicorn/perch/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/haras-unicorn/perch/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/haras-unicorn/perch/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/haras-unicorn/perch/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/haras-unicorn/perch/releases/tag/1.0.0
