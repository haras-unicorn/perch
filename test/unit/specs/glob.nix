{ self, ... }:

let
  toRegex = self.lib.glob.toRegex;

  expects =
    {
      glob,
      regex,
      ok ? [ ],
      bad ? [ ],
    }:
    let
      produced = toRegex glob;
      okResults = builtins.all (s: (builtins.match produced s) != null) ok;
      badResults = builtins.all (s: (builtins.match produced s) == null) bad;
    in
    produced == regex && okResults && badResults;
in
{
  glob_toRegex_empty = expects {
    glob = "";
    regex = "^$";
    ok = [ "" ];
    bad = [
      "a"
      "/"
    ];
  };

  glob_toRegex_literal = expects {
    glob = "Cargo.toml";
    regex = "^Cargo\\.toml$";
    ok = [ "Cargo.toml" ];
    bad = [
      "Cargo-toml"
      "Cargo.toml.bak"
    ];
  };

  glob_toRegex_star = expects {
    glob = "*.nix";
    regex = "^[^/]*\\.nix$";
    ok = [
      "foo.nix"
      ".nix"
      "bar123.nix"
    ];
    bad = [
      "dir/foo.nix"
      "foo.nix.bak"
    ];
  };

  glob_toRegex_starstar = expects {
    glob = "**/*.nix";
    regex = "^(.*/)?[^/]*\\.nix$";
    ok = [
      "foo.nix"
      "dir/foo.nix"
      "a/b/c/foo.nix"
    ];
    bad = [
      "foo.nix.bak"
      "a/b/c/foo.txt"
    ];
  };

  glob_toRegex_starstar_prefix = expects {
    glob = "**/Cargo.toml";
    regex = "^(.*/)?Cargo\\.toml$";
    ok = [
      "Cargo.toml"
      "a/b/Cargo.toml"
    ];
    bad = [
      "a/b/Cargo-toml"
      "a/b/Cargo.toml.bak"
    ];
  };

  glob_toRegex_qmark = expects {
    glob = "a?c";
    regex = "^a[^/]c$";
    ok = [
      "abc"
      "a_c"
    ];
    bad = [
      "ac"
      "a/c"
      "ab/c"
    ];
  };

  glob_toRegex_braces_simple = expects {
    glob = "{foo,bar}.nix";
    regex = "^(foo|bar)\\.nix$";
    ok = [
      "foo.nix"
      "bar.nix"
    ];
    bad = [
      "baz.nix"
      "foobar.nix"
      "dir/foo.nix"
    ];
  };

  glob_toRegex_braces_in_path = expects {
    glob = "src/{foo,bar}/*.nix";
    regex = "^src/(foo|bar)/[^/]*\\.nix$";
    ok = [
      "src/foo/a.nix"
      "src/bar/main.nix"
    ];
    bad = [
      "src/baz/a.nix"
      "src/foo/a.txt"
      "src/foo/x/y.nix"
    ];
  };

  glob_toRegex_braces_with_starstar = expects {
    glob = "**/*.{nix,md}";
    regex = "^(.*/)?[^/]*\\.(nix|md)$";
    ok = [
      "a.nix"
      "b.md"
      "x/y/z/readme.md"
    ];
    bad = [
      "a.txt"
      "x/y/z/readme.markdown"
    ];
  };
}
