{ self, ... }:

{
  defaults_systems_contains_4 = builtins.length self.lib.defaults.systems == 4;
}
