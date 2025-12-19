{ self, ... }:

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
    a: b:
    let
      keys = builtins.attrNames a ++ builtins.attrNames b;
      uniq = builtins.listToAttrs (
        builtins.map
          (k: {
            name = k;
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
        k:
        if (a ? ${k}) && (b ? ${k}) then
          if builtins.isAttrs a.${k} && builtins.isAttrs b.${k} then recursiveMerge a.${k} b.${k} else b.${k}
        else if a ? ${k} then
          a.${k}
        else
          b.${k};
    in
    builtins.mapAttrs (k: _: mergeKey k) uniq;

  keepAttrsByPath =
    paths: attrs: builtins.foldl' (acc: path: recursiveMerge acc (keepAttrByPath path attrs)) { } paths;
in
{
  flake.lib.attrset.removeAttrByPath = removeAttrByPath;

  flake.lib.attrset.removeAttrsByPath = removeAttrsByPath;

  flake.lib.attrset.keepAttrByPath = keepAttrByPath;

  flake.lib.attrset.keepAttrsByPath = keepAttrsByPath;
}
