{ self, lib, ... }:

{
  flake.lib.eval.preEval =
    self.lib.docs.function
      {
        description = ''
          Safely evaluate a list of modules
          patching up any args they might need with null
          if not available in "specialArgs".
        '';
        type = self.lib.types.function lib.types.attrs (
          self.lib.types.function lib.types.deferredModule (
            self.lib.types.function (lib.types.listOf lib.types.deferredModule) lib.types.raw
          )
        );
      }
      (
        specialArgs: evalModule: modules:
        let
          mappedModules = builtins.map (self.lib.module.patch (_: args: args) (
            function: args:
            let
              requestedArgs = lib.functionArgs function;
            in
            builtins.mapAttrs (name: _: if args ? ${name} then args.${name} else null) requestedArgs
          ) (_: result: result)) modules;

          eval = lib.evalModules {
            inherit specialArgs;
            modules = [ evalModule ] ++ mappedModules;
          };
        in
        eval
      );

  flake.lib.eval.filter =
    self.lib.docs.function
      {
        description = ''
          Filters an attrset of modules based on a predicate
          that runs during module evaluation.
        '';
        type = self.lib.types.function lib.types.attrs (
          self.lib.types.function (self.lib.types.function lib.types.raw (self.lib.types.function lib.types.raw lib.types.bool)) (
            self.lib.types.function lib.types.attrs lib.types.attrs
          )
        );
        tests =
          let
            specialArgs = { inherit lib; };

            filter = self.lib.eval.filter;

            modules = {
              foo =
                { lib, ... }:
                {
                  _file = ./eval.nix;
                  key = "foo";

                  options.fooOpt = lib.mkOption {
                    type = lib.types.str;
                    default = "hi";
                  };
                };

              bar =
                { ... }:
                {
                  _file = ./eval.nix;
                  key = "bar";

                  config.barVal = 123;
                };

              baz =
                { ... }:
                {
                  _file = ./eval.nix;
                  key = "baz";
                };
            };

            filterModule =
              originalOptionsLists: originalConfigLists:
              let
                optionsNonEmpty = builtins.any (
                  module:
                  (builtins.removeAttrs module [
                    "_file"
                    "key"
                  ]) != { }
                ) originalOptionsLists;
                configNonEmpty = builtins.any (
                  module:
                  (builtins.removeAttrs module [
                    "_file"
                    "key"
                  ]) != { }
                ) originalConfigLists;
              in
              optionsNonEmpty || configNonEmpty;

            filterResult = filter specialArgs filterModule modules;
          in
          {
            keeps_only_nonempty = (filterResult ? foo) && (filterResult ? bar) && !(filterResult ? baz);

            runs_foo =
              let
                evalFoo = (filterResult.foo { inherit lib; });
              in
              evalFoo ? options && evalFoo.options ? fooOpt;

            runs_bar =
              let
                evalBar = (filterResult.bar { });
              in
              evalBar ? config && evalBar.config ? barVal;
          };
      }
      (
        specialArgs: filterModule: modules:
        let
          mappedModules = builtins.map (
            module:
            self.lib.module.patch (_: args: args) (_: args: args) (
              _: result:
              let
                config =
                  if result ? config then
                    [ result.config ]
                  else if result ? options then
                    [ ]
                  else
                    [ result ];
                options = if result ? options then [ result.options ] else [ ];
              in
              {
                original.config.${module} = config;
                original.options.${module} = options;
              }
            ) modules.${module}
          ) (builtins.attrNames modules);

          filteringModule =
            { lib, config, ... }:
            {
              _file = ./eval.nix;
              key = ./eval.nix;

              options.original.options = lib.mkOption {
                type = lib.types.attrsOf self.lib.types.list;
                default = { };
              };

              options.original.config = lib.mkOption {
                type = lib.types.attrsOf self.lib.types.list;
                default = { };
              };

              options.filtered = lib.mkOption {
                type = lib.types.attrsOf lib.types.bool;
                default = { };
              };

              config._module.args = {
                flakeModules = modules;
              };

              config.filtered = builtins.listToAttrs (
                builtins.map (module: {
                  name = module;
                  value = filterModule config.original.options.${module} config.original.config.${module};
                }) (builtins.attrNames modules)
              );
            };

          eval = self.lib.eval.preEval specialArgs filteringModule mappedModules;
        in
        builtins.listToAttrs (
          builtins.filter ({ value, ... }: value != null) (
            builtins.map (module: {
              name = module;
              value = if eval.config.filtered.${module} then modules.${module} else null;
            }) (builtins.attrNames modules)
          )
        )
      );

  flake.lib.eval.flake =
    self.lib.docs.function
      {
        description = ''
          Evaluate a list of input modules and an attrset of flake modules.

          This occurs in two stages:

          Stage 1: evaluate to discover policy
          (allowed args + which config paths are public/private).

          Stage 2: re-evaluate with arg filtering and config path filtering applied,
          and produce "flake.modules" suitable for consumption by other flakes
          (including a generated "default" module).
        '';
        type = self.lib.types.function lib.types.attrs (
          self.lib.types.function (lib.types.listOf lib.types.deferredModule) (
            self.lib.types.function (lib.types.attrsOf lib.types.deferredModule) lib.types.raw
          )
        );
        tests =
          let
            specialArgs = { inherit lib; };

            flake = self.lib.eval.flake;

            inputModules = [
              (
                {
                  specialArgs,
                  flakeModules,
                  lib,
                  allowed,
                  ...
                }:
                {
                  _file = ./eval.nix;
                  key = "input";

                  options = {
                    private = lib.mkOption {
                      type = lib.types.attrs;
                      default = { };
                    };

                    public = lib.mkOption {
                      type = lib.types.attrs;
                      default = { };
                    };
                  };

                  config.eval.privateConfig = [ [ "private" ] ];
                  config.eval.publicConfig = [ [ "public" ] ];
                  config.eval.allowedArgs = [ "allowed" ];

                  config.private.input = {
                    input = "input";
                    allowed = allowed;
                  };

                  config.public.input =
                    let
                      eval = lib.evalModules {
                        specialArgs = specialArgs // {
                          allowed = "inputAllowed";
                        };
                        modules = (builtins.attrValues flakeModules) ++ [
                          {
                            options.public = lib.mkOption {
                              type = lib.types.attrs;
                              default = { };
                            };
                            options.private = lib.mkOption {
                              type = lib.types.attrs;
                              default = { };
                            };
                          }
                        ];
                      };
                    in
                    if eval.config.private ? self then
                      {
                        self = eval.config.private.self.allowed;
                        input = "input";
                        allowed = allowed;
                      }
                    else
                      {
                        input = "input";
                        allowed = allowed;
                      };
                }
              )
            ];

            selfModules = {
              self =
                { lib, allowed, ... }:
                {
                  _file = ./eval.nix;
                  key = "self";

                  config.private.self = {
                    self = "self";
                    allowed = allowed;
                  };

                  config.public.self = {
                    self = "self";
                    allowed = allowed;
                  };
                };
            };

            flakeResult = flake specialArgs inputModules selfModules;
          in
          {
            config_ok =
              let
                config = self.lib.attrset.removeAttrByPath [ "flake" "modules" "self" ] flakeResult.config;
              in
              # NOTE: flake.modules.default contains functions
              (lib.recursiveUpdate config { flake.modules.default = null; }) == {
                eval.privateConfig = [
                  [
                    "flake"
                    "modules"
                  ]
                  [ "private" ]
                ];
                eval.publicConfig = [
                  [
                    "eval"
                    "privateConfig"
                  ]
                  [
                    "eval"
                    "publicConfig"
                  ]
                  [
                    "eval"
                    "allowedArgs"
                  ]
                  [ "public" ]
                ];
                eval.allowedArgs = [ "allowed" ];

                public.input = {
                  self = "inputAllowed";
                  input = "input";
                  allowed = null;
                };

                private.self = {
                  self = "self";
                  allowed = null;
                };

                public.self = {
                  self = "self";
                  allowed = null;
                };

                flake.modules.default = null;
              };

            exported_public_only =
              let
                eval = flake (
                  specialArgs
                  // {
                    allowed = "eval_exported_flake_public_only";
                  }
                ) (inputModules ++ (builtins.attrValues flakeResult.config.flake.modules)) { };
              in
              # NOTE: flake.modules.default.imports.0._file points to local file
              # because flake.modules gets stripped from public cuz its private config
              (builtins.length eval.config.flake.modules.default.imports) == 1
              && (
                builtins.attrNames (builtins.head eval.config.flake.modules.default.imports) == [
                  "_file"
                  "imports"
                ]
              )
              && (builtins.head eval.config.flake.modules.default.imports).imports == [ { imports = [ ]; } ]
              &&
                (lib.recursiveUpdate eval.config {
                  flake.modules.default = null;
                }) == {
                  eval.privateConfig = [
                    [
                      "flake"
                      "modules"
                    ]
                    [ "private" ]
                  ];
                  eval.publicConfig = [
                    [
                      "eval"
                      "privateConfig"
                    ]
                    [
                      "eval"
                      "publicConfig"
                    ]
                    [
                      "eval"
                      "allowedArgs"
                    ]
                    [ "public" ]
                  ];
                  eval.allowedArgs = [ "allowed" ];

                  private = { };

                  public.input = {
                    input = "input";
                    allowed = "eval_exported_flake_public_only";
                  };

                  public.self = {
                    self = "self";
                    allowed = "eval_exported_flake_public_only";
                  };

                  flake = {
                    modules = {
                      default = null;
                    };
                  };
                };
          };
      }
      (
        specialArgs: inputModules: selfModules:
        let
          selfModuleList = builtins.attrValues selfModules;

          stageOneEvalModule = {
            _file = ./eval.nix;
            key = "evalStageOne";

            imports = [ self.lib.eval.flakeEvalModule ];

            config = {
              _module.args = {
                flakeModules = selfModules;
              };
            };
          };

          stageOneEval = self.lib.eval.preEval specialArgs stageOneEvalModule (
            inputModules ++ selfModuleList
          );

          privateAttrs = builtins.concatLists (
            builtins.map (path: [
              ([ "config" ] ++ path)
              path
            ]) stageOneEval.config.eval.privateConfig
          );
          publicAttrs =
            (builtins.concatLists (
              builtins.map (path: [
                ([ "config" ] ++ path)
                path
              ]) stageOneEval.config.eval.publicConfig
            ))
            ++ [
              [ "_file" ]
              [ "key" ]
              [ "disabledModules" ]
              [ "imports" ]
              [ "options" ]
            ];
          allowedArgs = stageOneEval.config.eval.allowedArgs;

          stageTwoModules =
            builtins.map
              (self.lib.module.patch (_: args: lib.filterAttrs (name: _: !(builtins.elem name allowedArgs)) args)
                (
                  function: args:
                  let
                    requestedArgs = lib.functionArgs function;
                  in
                  builtins.mapAttrs (name: _: if args ? ${name} then args.${name} else null) (
                    lib.filterAttrs (name: value: args ? ${name} || builtins.elem name allowedArgs) requestedArgs
                  )
                )
                (_: result: result)
              )
              (
                (builtins.map (self.lib.module.patch (_: args: args) (_: args: args) (
                  _: result: self.lib.attrset.removeAttrsByPath privateAttrs result
                )) inputModules)
                ++ selfModuleList
              );

          flakeModules = (
            builtins.mapAttrs (
              _:
              self.lib.module.patch (_: args: builtins.removeAttrs args (builtins.attrNames specialArgs)) (
                _: args: args // specialArgs
              ) (_: result: self.lib.attrset.keepAttrsByPath publicAttrs result)
            ) selfModules
          );

          stageTwoEvalModule = {
            _file = ./eval.nix;
            key = "evalStageTwo";

            imports = [ self.lib.eval.flakeEvalModule ];

            config = {
              _module.args = {
                flakeModules = selfModules;
              };

              flake.modules = flakeModules // {
                default = {
                  imports = builtins.attrValues flakeModules;
                };
              };
            };
          };

          stageTwoEval = lib.evalModules {
            inherit specialArgs;
            class = "flake";
            modules = [ stageTwoEvalModule ] ++ stageTwoModules;
          };
        in
        stageTwoEval
      );

  # NOTE: function so "flake.lib" option shuts up
  flake.lib.eval.flakeEvalModule =
    self.lib.docs.function
      {
        description = ''
          Internal module that defines the options used by "flake.lib.eval.flake" to control what is considered public/private config,
          and which ""_module.args" are allowed through during evaluation.
          Exposed as a function only to satisfy module/type expectations during evaluation.
        '';
        type = self.lib.types.function lib.types.attrs lib.types.attrs;
      }
      (
        { ... }:
        {
          _file = ./eval.nix;
          key = "eval";

          options = {
            eval.privateConfig = lib.mkOption {
              type = lib.types.listOf (lib.types.listOf lib.types.str);
              default = [ ];
              description = "Private configuration paths not exposed in output flake modules";
            };

            eval.publicConfig = lib.mkOption {
              type = lib.types.listOf (lib.types.listOf lib.types.str);
              default = [ ];
              description = "Public configuration paths are exposed in output flake modules";
            };

            eval.allowedArgs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of allowed argument names for module evaluation";
            };

            flake.modules = lib.mkOption {
              type = lib.types.attrsOf lib.types.deferredModule;
              default = { };
              description = "Modules prepared for use in other flakes";
            };
          };

          config = {
            eval.privateConfig = [
              [
                "flake"
                "modules"
              ]
            ];

            eval.publicConfig = [
              [
                "eval"
                "privateConfig"
              ]
              [
                "eval"
                "publicConfig"
              ]
              [
                "eval"
                "allowedArgs"
              ]
            ];
          };
        }
      );
}
