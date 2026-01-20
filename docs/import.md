# `flake.lib.import` (manual docs)

This part of the library is documented a bit differently from most of the rest
of `perch`.

## Why this is documented manually

These functions are used **very early** during `perch` bootstrapping, including
building the unit-test harness and importing other library bits from disk.

That creates a small but important constraint:

- In many other modules, we export functions like:
  - `flake.lib.foo.bar = self.lib.docs.function { ... } fooBar;`

- But here, referencing `self.lib` can be a problem because `self.lib` may be
  _constructed using these very functions_.

So: **circular dependency risk** 🌀 If `import` needs `self.lib` to define
itself, you can end up with “I need me to build me” kind of recursion.

**Pattern used here instead:**

- Keep `flake.lib.import` as a plain attrset of functions.
- Document the behavior and calling conventions in Markdown.
- (Optionally later) wrap them with `self.lib.docs.function` once the library is
  fully available, or in a later “post-bootstrap” pass.

This keeps the import machinery reliable and boring (the best kind of reliable).

---

## The mental model: one engine, three shapes

There’s basically one core idea:

> Walk a directory tree, “import things that look importable”, attach metadata,
> and then provide different views of the results.

You can think of it as three _shapes_ you can ask for:

1. **Tree-shaped attrset** Preserves directory structure.

2. **Flat list** Collects all “leaf imports” into a list.

3. **Flat attrset** Like the flat list, but keyed by a generated name (so you
   can look things up by name).

All of them are powered by the same underlying scan logic and the same metadata
format.

---

## Key concept: leaf metadata (`__import`)

Whenever something is treated as an import “leaf”, it gets metadata like:

- `__import.path`: the path that was imported (or examined)
- `__import.type`: `"regular"`, `"default"`, or `"unknown"`
- `__import.value`: the imported value (if importable; otherwise `null`)
- `__import.name`: a generated name (based on path + separator + nesting)

This is super useful for debugging, filtering, and building harnesses.

---

## Filtering: `nameRegex` and `pathRegex`

Most of the functions take an args attrset that can include:

- `nameRegex`: match against the generated `__import.name`
- `pathRegex`: match against the string form of the file path used

If a leaf fails either filter, it’s excluded.

This gives you a simple “import only tests”, “import only modules under X”,
etc., without hardcoding lists.

---

## The core function: `dirToAttrsWithMap`

### What it does

`dirToAttrsWithMap` walks a directory and returns a nested attrset. At every
leaf, it calls your `map` function with a metadata-wrapped value (the thing that
contains `__import = { ... }`).

### Signature (conceptually)

- Input: an args attrset with at least:
  - `dir` (path)
  - `separator` (string)
  - `map` (function)
  - optional `nameRegex`, `pathRegex`
- Output: nested attrset

### What counts as a leaf?

- `foo.nix` (a regular file ending in `.nix`) -> imported via
  `import "${dir}/foo.nix"`

- `someDir/default.nix` (a directory containing `default.nix`) -> imported via
  `import "${dir}/someDir/default.nix"`

- Anything else becomes `"unknown"` with `value = null` (but can still be mapped
  in, depending on your use)

### Example usage pattern

- “Give me a tree of imported values”
  - Use a `map` that returns `imported.__import.value`

- “Give me a tree of paths”
  - Use a `map` that returns `imported.__import.path`

That’s exactly the pattern the convenience helpers follow.

---

## Convenience wrappers (pattern, not exhaustive)

These helpers are basically “same scan, different projection”.

### Example 1: `dirToValueAttrs`

- Shape: tree-shaped attrset
- Leaves: imported values
- Implementation idea: call `dirToAttrsWithMap` with
  `map = imported: imported.__import.value`

Use when you want modules by directory structure.

### Example 2: `dirToFlatValueAttrs`

- Shape: flat attrset
- Keys: generated `__import.name` (prefix + separator + file/dir name)
- Values: imported values
- Implementation idea:
  - collect all leaves into a list
  - convert to attrset keyed by `__import.name`

Use when you want “everything addressable by a stable-ish name”.

---

## When to use which shape

- Use **tree-shaped attrsets** when structure matters (mirroring folders).
- Use **flat lists** when you just want to iterate (tests, lint passes, bulk
  eval).
- Use **flat attrsets** when you want lookup by name (registries, named suites).

---

## Notes / gotchas

- The generated name is based on directory nesting and `separator`. Pick a
  separator that won’t collide with your actual file names if you care about
  reversibility.
- `"unknown"` leaves exist so you can detect “non-nix stuff” if you want, but
  most callers will ignore them by filtering via regex or by mapping to
  `__import.value` (which will be `null`).
- This code does real directory reading + imports, so it’s best used in tooling
  / module aggregation layers, not in hot inner loops.

---

## Suggested doc-wrapping strategy (optional)

If you still want `self.lib.docs.function` wrappers for these later, a safe
pattern is:

- define the raw functions here (bootstrap-safe)
- in a later stage (after `self.lib` exists), re-export/wrap them with docs

That keeps bootstrapping simple and still gives you structured docs once
everything is loaded.
