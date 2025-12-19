{
  outputs =
    { perch, ... }@inputs:
    perch.lib.flake.make {
      inherit inputs;
      root = ./.;
      prefix = "flake";
    };
}
