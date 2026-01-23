{ self, lib, ... }:

{
  flake.lib.docs.moduleOptionsMarkdown =
    self.lib.docs.function
      {
        description = ''
          Render module options docs as markdown.

          It also hides "_module.*" options and strips "declarations".
        '';
        type = self.lib.types.function (self.lib.types.args (
          { lib, ... }:
          {
            options = {
              pkgs = lib.mkOption {
                type = lib.types.raw;
                description = ''A "pkgs" set providing "nixosOptionsDoc".'';
              };

              specialArgs = lib.mkOption {
                type = lib.types.attrs;
                description = ''Special args passed to "lib.evalModules".'';
              };

              modules = lib.mkOption {
                type = lib.types.listOf lib.types.deferredModule;
                description = ''Modules to evaluate and document.'';
              };
            };
          }
        )) lib.types.str;
      }
      (
        {
          pkgs,
          specialArgs,
          modules,
        }:
        pkgs.writeText "perch-lib.md" (
          self.lib.options.toMarkdown {
            transformOptions =
              opt:
              opt
              // {
                visible = opt.visible or true && (builtins.head opt.loc) != "_module";
                declarations = [ ];
              };
            options =
              let
                eval = lib.evalModules {
                  inherit specialArgs;
                  modules = modules ++ [ lib.types.noCheckForDocsModule ];
                };
              in
              eval.options;
          }
        )
      );

  flake.lib.docs.libFunctionsMarkdown =
    self.lib.docs.function
      {
        description = ''
          Render docs for a library attrset as markdown.

          Hides ""_module.*"" options and strips "declarations".
        '';
        type = self.lib.types.function (self.lib.types.args (
          { lib, ... }:
          {
            options = {
              pkgs = lib.mkOption {
                type = lib.types.raw;
                description = ''A "pkgs" set providing "nixosOptionsDoc".'';
              };

              specialArgs = lib.mkOption {
                type = lib.types.attrs;
                description = ''Special args passed to "evalModules".'';
              };

              lib = lib.mkOption {
                type = lib.types.raw;
                description = ''The library attrset to document.'';
              };
            };
          }
        )) lib.types.str;
      }
      (
        let
          nixpkgsLib = lib;
        in
        {
          specialArgs,
          pkgs,
          lib,
        }:
        pkgs.writeText "perch-lib.md" (
          self.lib.options.toMarkdown {
            transformOptions =
              opt:
              opt
              // {
                visible = opt.visible or true && (builtins.head opt.loc) != "_module";
                declarations = [ ];
              };
            options =
              let
                eval = nixpkgsLib.evalModules {
                  inherit specialArgs;
                  modules = [
                    { options = self.lib.docs.libToOptions lib; }
                    nixpkgsLib.types.noCheckForDocsModule
                  ];
                };
              in
              eval.options;
          }
        )
      );

  flake.lib.docs.libToOptions =
    let
      impl = lib.fix (
        libToOptions: options:
        if builtins.isAttrs options then
          if options ? __doc then
            lib.mkOption { inherit (options.__doc) type description; }
          else
            let
              pruned = lib.filterAttrs (_: value: value != null) (
                lib.mapAttrs (_: value: libToOptions value) options
              );
            in
            if pruned == { } then null else pruned
        else
          null
      );
    in
    options:
    let
      result = impl options;
    in
    if result == null then { } else result;

  flake.lib.docs.function =
    let
      makeAsserted =
        asserted: type:
        let
          makeAssertedIfResultIsFunction =
            if type.__signature.resultType.name == "function" then
              makeAsserted asserted type.__signature.resultType
            else
              function: function;
        in
        if asserted == false then
          function: function
        else if asserted == "argument" then
          function: argument:
          assert type.__signature.argumentType.check argument;
          makeAssertedIfResultIsFunction (function argument)
        else if asserted == "result" then
          function: argument:
          let
            result = function argument;
            resultType = type.__signature.resultType;
          in
          assert resultType.check result;
          makeAssertedIfResultIsFunction result
        else
          function: argument:
          assert type.__signature.argumentType.check argument;
          let
            result = function argument;
            resultType = type.__signature.resultType;
          in
          assert resultType.check result;
          makeAssertedIfResultIsFunction result;

      # NOTE: reimplemented here to not cause infinite recursion
      # on the actual function
      toFunctor =
        x:
        if (builtins.isAttrs x && x ? __functor) then
          x
        else if builtins.isFunction x then
          {
            __functionArgs = builtins.functionArgs x;
            __functor = _self: x;
          }
        else
          throw "expected a function or a functor attrset";

      undocumented =
        {
          type,
          description ? "",
          asserted ? false,
        }:
        function:
        (toFunctor (makeAsserted asserted type function))
        // {
          __doc = { inherit description type asserted; };
        };

      opaqueFunctionType = (lib.types.functionTo lib.types.raw) // {
        description = "function";
      };
    in
    undocumented {
      description = ''
        Attach documentation (and optional runtime assertions) to a function.
      '';
      asserted = true;
      type = self.lib.types.function (self.lib.types.args {
        options = {
          type = lib.mkOption {
            description = ''Function type'';
            # TODO: find alternative to addCheck?
            # https://github.com/NixOS/nixpkgs/issues/396021
            type = lib.types.addCheck lib.types.optionType (
              type:
              builtins.isAttrs type
              && type ? name
              && type.name == "function"
              && type ? __signature
              && type.__signature ? argumentType
              && (lib.types.optionType.check type.__signature.argumentType)
              && type.__signature ? resultType
              && (lib.types.optionType.check type.__signature.resultType)
            );
          };
          description = lib.mkOption {
            description = ''Function description'';
            default = "";
            type = lib.types.str;
          };
          asserted = lib.mkOption {
            description = ''Whether the function argument/result will be asserted'';
            default = false;
            type = lib.types.either lib.types.bool (
              lib.types.enum [
                "argument"
                "result"
              ]
            );
          };
        };
      }) (self.lib.types.function opaqueFunctionType opaqueFunctionType);
    } undocumented;
}
