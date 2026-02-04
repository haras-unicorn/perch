# Library

## artifacts\.make

Build a system\-indexed set of “artifacts” from flake modules\.

This evaluates each module for one or more target systems \(based on its
nixpkgsConfig settings, or a default set\), then extracts the requested "config"
value into an output shaped like "result\.<system\>\.<module\> = <value\>"\.

This is useful for producing flake outputs like per\-system packages/apps/checks
from a shared module collection, while still supporting a clean per\-system
"default"\.

_Type:_

```text
{
  # Name of the config field to extract as the artifact value
  # (supports top-level or "config.<name>").
  config: string,

  # Config flag name that marks an artifact as the per-system default.
  defaultConfig: string,

  # Attrset of flake modules to evaluate
  # and extract artifacts from (keyed by module name).
  flakeModules: attribute set of module,

  # Path to a nixpkgs input,
  # used to instantiate "pkgs" for each target system.
  nixpkgs: absolute path,

  # Name of the config field that describes nixpkgs settings for a module
  # (especially the target "system"/systems).
  # If a module doesn’t specify it, default systems are used.
  nixpkgsConfig: string,

  # Extra args used during module evaluation
  # (passed through like "specialArgs").
  specialArgs: attribute set,

  ...
} -> attribute set
```

## attrset\.flatten

Flatten an attrset recursively using a key separator\.

_Type:_

```text
{
  # The attrset to flatten
  attrs: attribute set,

  # Maximum recursion depth
  maxDepth: (positive integer, meaning >0),

  # Final attrset key separator
  separator: string,

  # Recurse into attrsets depending on this predicate
  while: raw value -> boolean,

  ...
} -> attribute set
```

## attrset\.keepAttrByPath

Keep only the nested attribute specified by a path, returning a minimal attrset
\(or empty if missing\)\.

_Type:_ `list of string -> attribute set -> attribute set`

## attrset\.keepAttrsByPath

Keep only the nested attributes specified by a list of paths, merging the kept
results into one attrset\.

_Type:_ `list of list of string -> attribute set -> attribute set`

## attrset\.removeAttrByPath

Remove a nested attribute specified by a path from an attrset\.

_Type:_ `list of string -> attribute set -> attribute set`

## attrset\.removeAttrsByPath

Remove multiple nested attributes specified by a list of paths from an attrset\.

_Type:_ `list of list of string -> attribute set -> attribute set`

## configurations\.make

Build NixOS configurations from flake modules, across one or more target
systems\.

For each module that provides "config", this evaluates a "lib\.nixosSystem"
using the module’s "nixpkgsConfig" \(or default systems\) and returns an attrset
of configurations keyed like: "<module\>\-<system\>"\.

This is useful when you want a module\-driven way to generate
"nixosConfigurations" \(including per\-system defaults\) without manually
writing one "nixosSystem" per host/system combo\.

_Type:_

```text
{
  # Name of the config field that contains the NixOS module
  # (or module-like value) to feed into "lib.nixosSystem".
  config: string,

  # Config flag name that marks a configuration as the default
  # for its system (emits "default-<system>").
  defaultConfig: string,

  # Attrset of flake modules to turn into NixOS configurations
  # (keyed by module name).
  flakeModules: attribute set of module,

  # Path to a nixpkgs input used indirectly via "lib.nixosSystem"
  # (for system-specific evaluation).
  nixpkgs: absolute path,

  # Name of the config field that defines nixpkgs settings per module
  # (especially the target "system"/systems).
  # If absent, default systems are used.
  nixpkgsConfig: string,

  # Extra args passed through to "lib.nixosSystem" and
  # module evaluation (like "specialArgs").
  specialArgs: attribute set,

  ...
} -> attribute set
```

## debug\.trace

Trace a JSON\-renderable view of a value \(functions replaced with a
placeholder\) and return the original value\.

_Type:_ `raw value -> raw value`

## docs\.function

Attach documentation \(and optional runtime assertions\) to a function\.

_Type:_

```text
{
  # Whether the function argument/result will be asserted
  asserted: (boolean or one of "argument", "result"),

  # Function description
  description: string,

  # Unit test attrset or function for this function
  tests: (attribute set of boolean) or (opaque function -> attribute set of boolean),

  # Function type
  type: optionType,

  ...
} -> opaque function -> opaque function
```

## docs\.libFunctionsMarkdown

Render docs for a library attrset as markdown\.

Hides ""\_module\.\*"" options and strips "declarations"\.

_Type:_

```text
{
  # The library attrset to document.
  lib: raw value,

  # A "pkgs" set providing "nixosOptionsDoc".
  pkgs: raw value,

  # Special args passed to "evalModules".
  specialArgs: attribute set,

  ...
} -> string
```

## docs\.libToOptions

Render a flake library to options ready to be rendered to markdown\.

_Type:_ `attribute set -> attribute set`

## docs\.moduleOptionsMarkdown

Render module options docs as markdown\.

It also hides "\_module\.\*" options and strips "declarations"\.

_Type:_

```text
{
  # Modules to evaluate and document.
  modules: list of module,

  # A "pkgs" set providing "nixosOptionsDoc".
  pkgs: raw value,

  # Special args passed to "lib.evalModules".
  specialArgs: attribute set,

  ...
} -> string
```

## eval\.filter

Filters an attrset of modules based on a predicate that runs during module
evaluation\.

_Type:_
`attribute set -> (raw value -> raw value -> boolean) -> attribute set -> attribute set`

## eval\.flake

Evaluate a list of input modules and an attrset of flake modules\.

This occurs in two stages:

Stage 1: evaluate to discover policy \(allowed args \+ which config paths are
public/private\)\.

Stage 2: re\-evaluate with arg filtering and config path filtering applied, and
produce "flake\.modules" suitable for consumption by other flakes \(including a
generated "default" module\)\.

_Type:_
`attribute set -> list of module -> attribute set of module -> raw value`

## eval\.flakeEvalModule

Internal module that defines the options used by "flake\.lib\.eval\.flake" to
control what is considered public/private config, and which ""\_module\.args"
are allowed through during evaluation\. Exposed as a function only to satisfy
module/type expectations during evaluation\.

_Type:_ `attribute set -> attribute set`

## eval\.preEval

Safely evaluate a list of modules patching up any args they might need with null
if not available in "specialArgs"\.

_Type:_ `attribute set -> module -> list of module -> raw value`

## factory\.artifactModule

Factory for building a module that generates per\-system artifacts and exposes
them in "flake\.<configs\>"\.

You provide "config" plus how to interpret "nixpkgsConfig", and it produces a
module that:

1\. lets modules define a "config" value and nixpkgs settings for it

2\. collects the evaluated results into "flake\.<configs\>"" \(typically keyed
by system, with optional per\-system defaults\)

3\. offers mapping hooks to tweak the resulting artifacts and the exposed
options/config shape

_Type:_

```text
{
  # Option type for "flake.<configs>".
  artifactType: raw value,

  # Name of the field to extract as the artifact value.
  config: string,

  # Plural name used under "flake.<configs>".
  configs: string,

  # All flake modules to evaluate artifacts from.
  flakeModules: attribute set of module,

  # Hook to post-process the computed artifacts.
  mapArtifacts: raw value -> raw value,

  # Hook to post-process final "config" (gets artifacts, then base config).
  mapConfig: raw value -> raw value -> raw value,

  # Hook to post-process generated "options".
  mapOptions: raw value -> raw value,

  # nixpkgs input/path used to instantiate "pkgs" per system.
  nixpkgs: absolute path,

  # Name of the config field that carries nixpkgs/system settings.
  nixpkgsConfig: string,

  # Extra args for evaluation (extended with "super.*").
  specialArgs: attribute set,

  # Exposed as "super.config".
  superConfig: raw value,

  # Exposed as "super.options".
  superOptions: raw value,

  ...
} -> module
```

## factory\.configurationModule

Factory for building a module that produces NixOS configurations and exposes
them in "flake\.<configs\>"\.

You provide "<config\>" plus "<nixpkgsConfig\>", and it produces a module that:

1\. lets modules define the NixOS module/configuration for "config" \(and
optionally mark a default\)

2\. evaluates them into real "nixosSystem" results across the intended systems

3\. publishes the final set under "flake\.<configs\>", with hooks for reshaping
options/config and post\-processing the result

_Type:_

```text
{
  # Name of the field that provides the NixOS module/configuration to build.
  config: string,

  # Plural name used under "flake.<configs>".
  configs: string,

  # Option type for "flake.<configs>".
  configurationType: raw value,

  # All flake modules to evaluate into NixOS configurations.
  flakeModules: attribute set of module,

  # Hook to post-process final "config".
  mapConfig: raw value -> raw value -> raw value,

  # Hook to post-process the computed configurations.
  mapConfigurations: raw value -> raw value,

  # Hook to post-process generated "options".
  mapOptions: raw value -> raw value,

  # nixpkgs input/path used for system-specific evaluation.
  nixpkgs: absolute path,

  # Name of the config field that carries nixpkgs/system settings.
  nixpkgsConfig: string,

  # Extra args for evaluation (extended with "super.*").
  specialArgs: attribute set,

  # Exposed as "super.config".
  superConfig: raw value,

  # Exposed as "super.options".
  superOptions: raw value,

  ...
} -> module
```

## factory\.submoduleModule

Factory for building a module that collects and exposes submodules in
"flake\.<configs\>"\.

You tell it which "config" you’re defining, and it produces a module that:

1\. lets individual modules declare "config" \(and optionally mark themselves as
the default\)

2\. aggregates all of them into "flake\.<configs\>"" for the whole flake

3\. supports light customization hooks
\("mapSubmodules"/"mapOptions"/"mapConfig"\) so you can shape the API without
rewriting the plumbing

_Type:_

```text
{
  # Singular name of the thing being collected (e.g. "overlay").
  config: string,

  # Plural name used under "flake.<configs>".
  configs: string,

  # All flake modules to scan/collect submodules from.
  flakeModules: attribute set of module,

  # Hook to post-process final "config"
  # (gets submodules, then base config).
  mapConfig: raw value -> raw value -> raw value,

  # Hook to post-process generated "options".
  mapOptions: raw value -> raw value,

  # Hook to post-process the collected submodules set.
  mapSubmodules: raw value -> raw value,

  # Extra args for evaluation
  # (extended with "super.config"/"super.options").
  specialArgs: attribute set,

  # Option type for "flake.<configs>".
  submoduleType: raw value,

  # Parent config exposed to submodules as "super.config".
  superConfig: raw value,

  # Parent options exposed to submodules as "super.options".
  superOptions: raw value,

  ...
} -> module
```

## flake\.make

Build a flake output attrset from flake modules\.

It can:

1\. load modules from a directory on disk \(via "root" \+ "prefix"\)

2\. take explicit modules you pass in \("selfModules", "inputModules"\)

3\. optionally include "modules\.default" from your flake inputs

4\. \(optionally\) do a small bootstrapping step \("libPrefix"\) so "self\.lib"
can be provided by modules themselves

_Type:_

```text
{
  # Whether to automatically include "modules.default" from each flake input
  # (excluding "self"), when that input provides it.
  #
  # Disable this if you want full manual control over
  # which input modules participate.
  includeInputModulesFromInputs: boolean,

  # Extra input modules to include during evaluation.
  inputModules: list,

  # Flake inputs attrset
  # (typically the "inputs" from your "outputs = { ... }:" function).
  #
  # Used as "specialArgs" during evaluation,
  # and also scanned for "modules.default" when enabled.
  inputs: attribute set,

  # Optional bootstrapping mode for flakes
  # that define their own "self.lib" via modules.
  #
  # When set, Perch first evaluates only modules whose names start with "libPrefix"
  # to obtain "config.flake.lib", then re-evaluates the full module se
  # with that "self.lib" injected into "specialArgs".
  #
  # This is useful when options/config evaluation
  # depends on something from "self.lib" to avoid infinite recursion.
  libPrefix: null or string,

  # Subdirectory (relative to "root") to scan for modules.
  # Only used when both "root" and "prefix" are non-null.
  prefix: null or string,

  # Root path for discovering modules on disk.
  #
  # When combined with "prefix", imports modules
  # from "root/prefix".
  root: null or absolute path,

  # Modules belonging to this flake.
  #
  # When a list is passed the modules are named
  # "module-0", "module-1", etc.
  #
  # Each module is patched to have a key corresponding to its name.
  selfModules: (list) or (attribute set),

  # Separator used when generating names for modules
  # discovered on disk (via "root/prefix").
  #
  # These names become keys in the flat module attrset
  # (for example: "foo-bar-baz").
  separator: string,

  ...
} -> attribute set
```

## format\.optionsToArgsString

Converts evaluated options to a human\-friendly string useful for function
arguments

_Type:_ `raw value -> raw value`

## glob\.toRegex

Convert a glob pattern to a fully\-anchored regular expression string\.

_Type:_ `string -> string`

## module\.patch

Patch a module \(or module path\) by rewriting its function args
declaration/values and mapping its resulting attrset, recursively applying the
same patch to any imported modules\.

_Type:_ `raw value -> raw value -> raw value -> raw value -> raw value`

## options\.flatten

Flatten an evaluated NixOS\-style options tree into a sorted list\. Also
descends into submodule option types \(including listOf submodule\) and removes
any \`\_module\` options\.

_Type:_ `raw value -> list`

## options\.toMarkdown

Render an evaluated options tree into a simple markdown document excluding any
"\_module" options\.

For each option it produces a heading with the option path, its description,
type and default if provided\.

_Type:_

```text
{
  # Evaluated options tree to render.
  options: raw value,

  # Transform options with a mapper function.
  transformOptions: raw value -> raw value,

  ...
} -> string
```

## string\.capitalize

Capitalize the first character of a string \(leaving the rest unchanged\)\.

_Type:_ `string -> string`

## string\.indent

Indent \(or dedent via negative\) a multi\-line string by a number of spaces\.

_Type:_ `signed integer -> string -> string`

## string\.toTitle

Convert a string into a simple title\.

_Type:_ `string -> string`

## string\.wordSplit

Split a string into words on casing boundaries \(camelCase / PascalCase\) and
delimiters \(whitespace / dashes / underscores\)\.

_Type:_ `string -> list of string`

## submodules\.make

Create a ready\-to\-use attrset of submodules from a set of flake modules\.

You pick which config field you want to expose \(via "config"\), and this
function returns only the modules that provide it, plus a sensible "default"
module\.

This is useful for turning a large flake module collection into a small, clean
“module API” other code can consume\.

_Type:_

```text
{
  # Which config field to extract from each module
  # (e.g. "nixosModule", "homeManagerModule", etc.).
  config: string,

  # Config flag name used to choose the default module;
  # if none is marked, a default is generated.
  defaultConfig: string,

  # Candidate flake modules to turn into submodules (keyed by name).
  flakeModules: attribute set of module,

  # Extra args used during evaluation (like "specialArgs" in "lib.evalModules").
  specialArgs: attribute set,

  ...
} -> attribute set of module
```

## test\.eval

Evaluate tests for a flake library attrset\.

_Type:_

```text
{
  # Library with tests to evaluate
  lib: nested attribute set of raw value,

  ...
} -> {
  # Message to display in case of test failure
  message: null or string,

  # Whether all tests passed
  success: boolean,

  ...
}
```

## trivial\.importIfPath

If given a path/string, import it and attach \{\_file,key\}; otherwise pass
through the module and still attach those when possible\.

_Type:_ `raw value -> raw value`

## trivial\.isFunctor

Return true if a value is a functor attrset \(has a functional \_\_functor
field\)\.

_Type:_ `raw value -> boolean`

## trivial\.mapAttrsetImports

If an attrset has an imports list, map a function over the imported modules
\(importing paths/strings first\)\.

_Type:_ `(raw value -> raw value) -> raw value -> raw value`

## trivial\.mapFunctionArgs

Wrap a function to rewrite its argument declaration and argument value before
calling it\.

_Type:_
`(raw value -> raw value -> raw value) -> raw value -> raw value -> raw value`

## trivial\.mapFunctionResult

Wrap a function so its result is transformed by a mapper while preserving
declared function arguments\.

_Type:_ `(raw value -> raw value -> raw value) -> raw value -> raw value`

## trivial\.toFunctor

Convert a function to a functor attrset \(or pass through an existing functor\),
throwing on other values\.

_Type:_ `raw value -> raw value`
