{
  self,
  ...
}:

{
  flake.lib.submodules.make =
    {
      flakeModules,
      specialArgs,
      config,
      defaultConfig,
    }:
    let
      filterModule =
        _: configs:
        builtins.any (conf: conf ? ${config} || conf ? config && conf.config ? ${config}) configs;

      filteredModules = self.lib.eval.filter specialArgs filterModule flakeModules;

      filterDefaultModule =
        _: configs:
        builtins.any (
          conf:
          (conf ? ${defaultConfig} && conf.${defaultConfig})
          || (conf ? config && conf.config ? ${defaultConfig} && conf.config.${defaultConfig})
        ) configs;

      defaultModule =
        let
          defaultModules = builtins.attrValues (
            self.lib.eval.filter specialArgs filterDefaultModule filteredModules
          );
        in
        if (builtins.length defaultModules) == 0 then
          {
            default = {
              imports = builtins.attrValues filteredModules;
            };
          }
        else
          {
            default = builtins.head defaultModules;
          };

      configModules = builtins.mapAttrs (
        _:
        self.lib.module.patch (_: args: builtins.removeAttrs args (builtins.attrNames specialArgs))
          (_: args: args // specialArgs)
          (
            _: result:
            if result ? ${config} then
              result.${config}
            else if result ? config && result.config ? ${config} then
              result.config.${config}
            else
              { }
          )
      ) (filteredModules // defaultModule);
    in
    configModules;
}
