{ self, lib, ... }:

{
  flake.lib.trivial.isFunctor = self.lib.docs.function {
    description = "Return true if a value is a functor attrset (has a functional __functor field).";
    type = self.lib.types.function lib.types.raw lib.types.bool;
  } (x: builtins.isAttrs x && x ? __functor && builtins.isFunction x.__functor);

  flake.lib.trivial.toFunctor =
    self.lib.docs.function
      {
        description = "Convert a function to a functor attrset (or pass through an existing functor), throwing on other values.";
        type = self.lib.types.function lib.types.raw lib.types.raw;
      }
      (
        x:
        if (builtins.isAttrs x && x ? __functor) then
          x
        else if builtins.isFunction x then
          {
            __functionArgs = builtins.functionArgs x;
            __functor = _self: x;
          }
        else
          throw "perch.lib.trivial.toFunctor: expected a function or a functor attrset"
      );

  flake.lib.trivial.mapFunctionResult =
    self.lib.docs.function
      {
        description = "Wrap a function so its result is transformed by a mapper while preserving declared function arguments.";
        type = self.lib.types.function (self.lib.types.function lib.types.raw (self.lib.types.function lib.types.raw lib.types.raw)) (
          self.lib.types.function lib.types.raw lib.types.raw
        );
      }
      (
        mapResult: function:
        let
          args = lib.functionArgs function;
          mapped = args: mapResult function (function args);
        in
        lib.setFunctionArgs mapped args
      );

  flake.lib.trivial.mapFunctionArgs =
    self.lib.docs.function
      {
        description = "Wrap a function to rewrite its argument declaration and argument value before calling it.";
        type = self.lib.types.function (self.lib.types.function lib.types.raw (self.lib.types.function lib.types.raw lib.types.raw)) (
          self.lib.types.function lib.types.raw (self.lib.types.function lib.types.raw lib.types.raw)
        );
      }
      (
        mapArgsDeclaration: mapArgsDefinition: function:
        let
          args = mapArgsDeclaration function (lib.functionArgs function);
          mapped = args: function (mapArgsDefinition function args);
        in
        lib.setFunctionArgs mapped args
      );

  flake.lib.trivial.importIfPath =
    self.lib.docs.function
      {
        description = "If given a path/string, import it and attach {_file,key}; otherwise pass through the module and still attach those when possible.";
        type = self.lib.types.function lib.types.raw lib.types.raw;
      }
      (
        module:
        let
          pathPart =
            if (builtins.isPath module) || (builtins.isString module) then
              let
                path = module;
              in
              {
                _file = path;
                key = path;
              }
            else
              { };

          imported = if (builtins.isPath module) || (builtins.isString module) then import module else module;
        in
        if lib.isFunction imported then
          let
            function = imported;
          in
          self.lib.trivial.mapFunctionResult (_: attrset: attrset // pathPart) function
        else
          let
            attrset = imported;
          in
          attrset // pathPart
      );

  flake.lib.trivial.mapAttrsetImports =
    self.lib.docs.function
      {
        description = "If an attrset has an imports list, map a function over the imported modules (importing paths/strings first).";
        type = self.lib.types.function (self.lib.types.function lib.types.raw lib.types.raw) (
          self.lib.types.function lib.types.raw lib.types.raw
        );
      }
      (
        mapImported: attrset:
        if attrset ? imports then
          attrset
          // {
            imports = builtins.map (module: mapImported (self.lib.trivial.importIfPath module)) attrset.imports;
          }
        else
          attrset
      );
}
