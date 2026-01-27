# Perch

Perch provides a structured framework for
[Nix flakes](https://wiki.nixos.org/wiki/Flakes), offering a stable place to
organize, extend, and refine your configurations.

It does so by importing all nix files in a subdirectory of your repository and
interpreting them as flake modules which define your flake outputs.

<!-- markdownlint-disable MD013 -->

{{ #include ../README.md:6:25 }}

<!-- markdownlint-enable MD013 -->

This will interpret all nix files in the `./flake` subdirectory as flake modules
and produce a flake based off of them.

The [next chapter of this book](./modules.md) explains in more detail on how to
write flake modules.
