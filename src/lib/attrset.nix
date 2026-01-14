{ self, lib, ... }:

let
  removeAttrByPath =
    path: attrs:
    if path == [ ] then
      attrs
    else
      let
        key = builtins.head path;
        tail = builtins.tail path;
      in
      if tail == [ ] then
        builtins.removeAttrs attrs [ key ]
      else if attrs ? ${key} && builtins.isAttrs attrs.${key} then
        attrs
        // {
          ${key} = removeAttrByPath tail attrs.${key};
        }
      else
        attrs;

  removeAttrsByPath =
    paths: attrs: builtins.foldl' (acc: next: self.lib.attrset.removeAttrByPath next acc) attrs paths;

  keepAttrByPath =
    path: attrs:
    if path == [ ] then
      attrs
    else
      let
        key = builtins.head path;
        tail = builtins.tail path;
      in
      if !(attrs ? ${key}) then
        { }
      else if tail == [ ] then
        { ${key} = attrs.${key}; }
      else if builtins.isAttrs attrs.${key} then
        let
          sub = keepAttrByPath tail attrs.${key};
        in
        if sub == { } then { } else { ${key} = sub; }
      else
        { };

  recursiveMerge =
    lhs: rhs:
    let
      keys = builtins.attrNames lhs ++ builtins.attrNames rhs;
      uniq = builtins.listToAttrs (
        builtins.map
          (key: {
            name = key;
            value = null;
          })
          (
            builtins.attrNames (
              builtins.listToAttrs (
                builtins.map (k: {
                  name = k;
                  value = 1;
                }) keys
              )
            )
          )
      );
      mergeKey =
        key:
        if (lhs ? ${key}) && (rhs ? ${key}) then
          if builtins.isAttrs lhs.${key} && builtins.isAttrs rhs.${key} then
            recursiveMerge lhs.${key} rhs.${key}
          else
            rhs.${key}
        else if lhs ? ${key} then
          lhs.${key}
        else
          rhs.${key};
    in
    builtins.mapAttrs (key: _: mergeKey key) uniq;

  keepAttrsByPath =
    paths: attrs: builtins.foldl' (acc: path: recursiveMerge acc (keepAttrByPath path attrs)) { } paths;
in
{
  flake.lib.attrset.removeAttrByPath = self.lib.docs.function {
    description = ''
      Remove a nested attribute specified by a path from an attrset.
    '';
    type = self.lib.types.function (lib.types.listOf lib.types.str) (
      self.lib.types.function (lib.types.attrsOf lib.types.raw) (lib.types.attrsOf lib.types.raw)
    );
  } removeAttrByPath;

  flake.lib.attrset.removeAttrsByPath = self.lib.docs.function {
    description = ''
      Remove multiple nested attributes specified by a list of paths from an attrset.
    '';
    type = self.lib.types.function (lib.types.listOf (lib.types.listOf lib.types.str)) (
      self.lib.types.function (lib.types.attrsOf lib.types.raw) (lib.types.attrsOf lib.types.raw)
    );
  } removeAttrsByPath;

  flake.lib.attrset.keepAttrByPath = self.lib.docs.function {
    description = ''
      Keep only the nested attribute specified by a path,
      returning a minimal attrset (or empty if missing).
    '';
    type = self.lib.types.function (lib.types.listOf lib.types.str) (
      self.lib.types.function (lib.types.attrsOf lib.types.raw) (lib.types.attrsOf lib.types.raw)
    );
  } keepAttrByPath;

  flake.lib.attrset.keepAttrsByPath = self.lib.docs.function {
    description = ''
      Keep only the nested attributes specified by a list of paths,
      merging the kept results into one attrset.
    '';
    type = self.lib.types.function (lib.types.listOf (lib.types.listOf lib.types.str)) (
      self.lib.types.function (lib.types.attrsOf lib.types.raw) (lib.types.attrsOf lib.types.raw)
    );
  } keepAttrsByPath;
}
