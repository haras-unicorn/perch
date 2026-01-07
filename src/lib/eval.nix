{ self, lib, ... }:

{
  flake.lib.eval.preEval =
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
    eval;

  flake.lib.eval.filter =
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
            type = lib.types.attrsOf (lib.types.listOf lib.types.raw);
            default = { };
          };

          options.original.config = lib.mkOption {
            type = lib.types.attrsOf (lib.types.listOf lib.types.raw);
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
    );

  flake.lib.eval.flake =
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
    stageTwoEval;

  # NOTE: function so `flake.lib` option shuts up
  flake.lib.eval.flakeEvalModule =
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
    };
}
