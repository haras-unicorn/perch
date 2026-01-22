# Import library (`flake.lib.import`)

Directory-scanning import helpers used **very early** in Perch’s bootstrap (unit
test harness, loading other lib bits from disk, etc.).

Because of that, this module **must not reference `self.lib`** (circular “I need
me to build me” risk). So it exports plain functions and is documented a bit
more “by hand”, but in the **same style** as the rest of the library docs.

---

## Mental model (shared across functions)

These helpers:

1. walk a directory tree (`builtins.readDir`)
2. treat certain entries as “import leaves”
3. attach leaf metadata under `__import`
4. return results in one of 3 shapes:
   - **tree attrset** (preserves directory structure)
   - **flat list** (all leaves)
   - **flat attrset** (all leaves keyed by generated name)

### Leaf metadata (`__import`)

Each imported/examined leaf has:

- `__import.path`: string path examined/imported
- `__import.type`: `"regular"` (a `*.nix` file), `"default"` (a `default.nix` in
  a dir), `"unknown"`
- `__import.value`: imported value (or `null` for unknown)
- `__import.name`: generated name based on nesting + `separator`

### Filtering

Most entrypoints accept:

- `nameRegex` (matches `__import.name`)
- `pathRegex` (matches `__import.path`)

Leaves failing either filter are excluded.

This can be used to filter via glob patterns using the `perch.lib.glob.toRegex`
function.

### Default.nix behavior

By default, directories containing `default.nix` are treated as a leaf. Set
`ignoreDefaults = true` to force recursion instead.

---

## import.dirToAttrsWithMap

Walk a directory and return a **tree-shaped attrset**, calling `map` on each
leaf (metadata included).

_Type:_

```text
{
  map: raw value -> raw value,
  dir: absolute path,
  separator: string,
  nameRegex: null or string,
  pathRegex: null or string,
  ignoreDefaults: boolean,
  ...
} -> attribute set
```

---

## import.dirToListWithMap

Walk a directory and return a **flat list** of mapped leaves.

_Type:_

```text
{
  map: raw value -> raw value,
  dir: absolute path,
  separator: string,
  nameRegex: null or string,
  pathRegex: null or string,
  ignoreDefaults: boolean,
  ...
} -> list of raw value
```

---

## import.dirToFlatAttrsWithMap

Walk a directory and return a **flat attrset** keyed by `__import.name`.

_Type:_

```text
{
  map: raw value -> raw value,
  dir: absolute path,
  separator: string,
  nameRegex: null or string,
  pathRegex: null or string,
  ignoreDefaults: boolean,
  ...
} -> attribute set
```

---

## Convenience projections (same scan, different “view”)

These are all just preset `map` functions over the same core scan:

- `dirToAttrsWithMetadata`: tree of metadata (leaves are the
  `{ __import = ...; }` wrapper)
- `dirToValueAttrs`: tree of `__import.value`
- `dirToPathAttrs`: tree of `__import.path`

- `dirToListWithMetadata`: list of metadata wrappers
- `dirToValueList`: list of `__import.value`
- `dirToPathList`: list of `__import.path`

- `dirToFlatAttrsWithMetadata`: flat attrset of metadata wrappers (keyed by
  `__import.name`)
- `dirToFlatValueAttrs`: flat attrset of `__import.value`
- `dirToFlatPathAttrs`: flat attrset of `__import.path`

---

## Notes / gotchas

- Generated names depend on `separator` + nesting; pick a separator that won’t
  collide with real names if you care about readability.
- `"unknown"` leaves exist so tooling can notice non-nix files; most callers map
  to `__import.value` (which becomes `null`) or filter via regex.
- This does real directory reads + imports: great for aggregation/tooling, not
  something you want in hot inner loops.
