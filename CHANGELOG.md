<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and adheres to [Semantic Versioning](https://semver.org/).

## [1.3.3] - 2026-02-12

### Added

- extra commands argument and option for flake tests

## [1.3.3] - 2026-02-11

### Added

- tracing of library tests when passing all tests

### Changed

- flexibility for `perch.lib.docs.function` to accept test functions that
  require `pkgs` and the `perch.lib.test.unit` runner to run tests requiring
  `pkgs` if available

## [1.3.2] - 2026-02-09

### Added

- `perch.lib.debug.traceString` that converts any value to a JSON-renderable
  string that is used for testing and tracing

### Changed

- Fix default submodule existing even if no submodules exist in
  `perch.lib.submodules.make`
- Fix bug in `perch.lib.attrset.isDictionary` that would return true for
  functors
- Fix bug in `perch.lib.docs.libToOptions` that would use `isDictionary`
  improperly
- Allow for unit tests evaluated via `perch.lib.test.unit` to be attrsets for
  richer test output
- Switch to adding context to evaluation failures in `perch.lib.test.unit`

## [1.3.1] - 2026-02-07

### Added

- `flakeTests.asPackages` option
- depth parameter to flake test scripts for logging

### Changed

- names of flake test apps and checks
- nicer log for flake tests

## [1.3.0] - 2026-02-04

### Changed

- change uses of `lib.types.attrsOf lib.types.raw` to `lib.types.attrs`
- change uses of `lib.types.listOf lib.types.raw` to `self.lib.types.list`
- unit tests moved to running with `perch.lib.docs.function`
- flake tests moved to running with `perch.lib.test.flake` generated app

### Added

- `perch.lib.test.unit` function for unit test evaluation
- `perch.lib.test.flake` function for flake test evaluation
- `perch.lib.attrset.flatten` function for attrset flattening
- `perch.lib.attrset.isDictionary` function for checking whether an attrset
  should be peeked into

### Removed

- tests from `test/unit` folder

## [1.2.3] - 2026-01-27

### Changed

- fix link to flakes in `introduction.md`

### Added

- `perch.lib.string.wordSplit` function to split strings based on common schemes
- `perch.lib.string.toTitle` function that users `wordSplit` and `capitalize` to
  make titles
- `perch.lib.string.indent` function that indents/dedents strings

## [1.2.2] - 2026-01-23

### Changed

- options markdown rendering support for literals, example, and read-only
- correct option location for suboptions
- fix `libraryFunctionsToMarkdown` with empty options

## [1.2.1] - 2026-01-22

### Added

- `ignoreDefault` argument to import functions that doesn't stop recursion when
  encountering `default.nix`
- default `separator` argument to import functions equal to "-"

### Changed

- change import function documentation to fit other library functions better

## [1.2.0] - 2026-01-14

### Added

- `perch.lib.glob.toRegex` function
- `perch.lib.trivial.isFunctor` and `perch.lib.trivial.toFunctor` functions
- `perch.lib.type.nixpkgs.config` to `perch.lib.types.nixpkgsConfig`
- `perch.lib.types.overlay` to `perch.lib.types.overlay`
- `perch.lib.types.args` as args type that is just an alias of
  `nixpkgs.lib.types.submodule`
- `perch.lib.types.function` as function type with argument and return type
- `perch.lib.options.flatten` function for flattening evaluated option into a
  list of options
- `perch.lib.options.toMarkdown` function similar to `pkgs.nixosOptionsDoc` that
  is a bit simpler and directly spits out a markdown string
- `perch.lib.docs.function` function for creating library functions with
  optional assertions from argument/return types
- `perch.lib.docs.moduleOptionsMarkdown` function for creating markdown
  documentation from a set of modules
- `perch.lib.docs.libFunctionsMarkdown` function to be used with
  `perch.lib.docs.function` to create markdown documentation from an attrset of
  library functions

### Changed

- import functions regex matching and arguments from attrs instead of curry
- app `meta.description` is now equal to app/package name if otherwise not
  provided
- `packagesAsApps` and `packagesAsLegacyPackages` false by default
- `packagesAsApps` filtered by packages that have a `meta.mainProgram`
- library function documentation generation via newly added functions

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

[1.3.2]: https://github.com/haras-unicorn/perch/compare/1.3.1...1.3.2
[1.3.1]: https://github.com/haras-unicorn/perch/compare/1.3.0...1.3.1
[1.3.0]: https://github.com/haras-unicorn/perch/compare/1.2.3...1.3.0
[1.2.3]: https://github.com/haras-unicorn/perch/compare/1.2.2...1.2.3
[1.2.2]: https://github.com/haras-unicorn/perch/compare/1.2.1...1.2.2
[1.2.1]: https://github.com/haras-unicorn/perch/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/haras-unicorn/perch/compare/1.1.1...1.2.0
[1.1.1]: https://github.com/haras-unicorn/perch/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/haras-unicorn/perch/compare/1.0.4...1.1.0
[1.0.4]: https://github.com/haras-unicorn/perch/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/haras-unicorn/perch/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/haras-unicorn/perch/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/haras-unicorn/perch/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/haras-unicorn/perch/releases/tag/1.0.0
