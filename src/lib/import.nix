# NOTE: do not reference self.lib here because it is used in initial import of perch
# NOTE: be very careful with this one because its needed to create the unit test harness

{ lib, ... }:

let
  importDirToAttrsWithMap =
    let
      initial =
        importDirToAttrsWithMap: prefix:
        {
          map,
          dir,
          separator ? "-",
          nameRegex ? null,
          pathRegex ? null,
          ignoreDefaults ? false,
        }:
        builtins.listToAttrs (
          builtins.filter (x: x != null) (
            builtins.map (
              name:
              let
                type = (builtins.readDir dir)."${name}";
                nameWithoutExtension = builtins.replaceStrings [ ".nix" ] [ "" ] name;
                prefixedName =
                  if prefix == "" then nameWithoutExtension else "${prefix}${separator}${nameWithoutExtension}";

                makeLeaf =
                  {
                    path,
                    type,
                    value,
                  }:
                  let
                    meta = {
                      __import = {
                        inherit path type value;
                        name = prefixedName;
                      };
                    };
                  in
                  if
                    let
                      nameOk = if nameRegex == null then true else (builtins.match nameRegex prefixedName) != null;
                      pathOk = if pathRegex == null then true else (builtins.match pathRegex path) != null;
                    in
                    nameOk && pathOk
                  then
                    {
                      name = if type == "regular" then nameWithoutExtension else name;
                      value = map meta;
                    }
                  else
                    null;
              in
              if type == "regular" then
                if lib.hasSuffix ".nix" name then
                  makeLeaf {
                    path = "${dir}/${name}";
                    type = "regular";
                    value = import "${dir}/${name}";
                  }
                else
                  makeLeaf {
                    path = "${dir}/${name}";
                    type = "unknown";
                    value = null;
                  }

              else if !ignoreDefaults && builtins.pathExists "${dir}/${name}/default.nix" then
                makeLeaf {
                  path = "${dir}/${name}/default.nix";
                  type = "default";
                  value = import "${dir}/${name}/default.nix";
                }

              else
                let
                  child = importDirToAttrsWithMap importDirToAttrsWithMap prefixedName {
                    inherit
                      map
                      separator
                      nameRegex
                      pathRegex
                      ignoreDefaults
                      ;
                    dir = "${dir}/${name}";
                  };
                in
                if child == { } then
                  null
                else
                  {
                    name = name;
                    value = child;
                  }
            ) (builtins.attrNames (builtins.readDir dir))
          )
        );
    in
    initial initial "";

  importDirToListWithMap =
    {
      map,
      dir,
      separator ? "-",
      nameRegex ? null,
      pathRegex ? null,
      ignoreDefaults ? false,
    }:
    builtins.map map (
      lib.collect (builtins.hasAttr "__import") (importDirToAttrsWithMap {
        # NOTE: identity map here because lib.collect needs the __import metadata to exist
        map = (module: module);
        inherit
          separator
          dir
          nameRegex
          pathRegex
          ignoreDefaults
          ;
      })
    );

  importDirToFlatAttrsWithMap =
    {
      map,
      dir,
      separator ? "-",
      nameRegex ? null,
      pathRegex ? null,
      ignoreDefaults ? false,
    }:
    builtins.listToAttrs (
      builtins.map
        (module: {
          name = module.__import.name;
          value = map module;
        })
        (importDirToListWithMap {
          map = (module: module);
          inherit
            separator
            dir
            nameRegex
            pathRegex
            ignoreDefaults
            ;
        })
    );
in
{
  flake.lib.import = {
    dirToAttrsWithMap = importDirToAttrsWithMap;

    dirToAttrsWithMetadata = args: importDirToAttrsWithMap (args // { map = (imported: imported); });

    dirToValueAttrs =
      args: importDirToAttrsWithMap (args // { map = (imported: imported.__import.value); });

    dirToPathAttrs =
      args: importDirToAttrsWithMap (args // { map = (imported: imported.__import.path); });

    dirToListWithMap = importDirToListWithMap;

    dirToListWithMetadata = args: importDirToListWithMap (args // { map = (imported: imported); });

    dirToValueList =
      args: importDirToListWithMap (args // { map = (imported: imported.__import.value); });

    dirToPathList =
      args: importDirToListWithMap (args // { map = (imported: imported.__import.path); });

    dirToFlatAttrsWithMap = importDirToFlatAttrsWithMap;

    dirToFlatAttrsWithMetadata =
      args: importDirToFlatAttrsWithMap (args // { map = (imported: imported); });

    dirToFlatValueAttrs =
      args: importDirToFlatAttrsWithMap (args // { map = (imported: imported.__import.value); });

    dirToFlatPathAttrs =
      args: importDirToFlatAttrsWithMap (args // { map = (imported: imported.__import.path); });
  };
}
