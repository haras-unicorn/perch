set windows-shell := ["nu.exe", "-c"]
set shell := ["nu", "-c"]

root := absolute_path('')

default:
    @just --choose

format:
    cd '{{ root }}'; just --unstable --fmt
    prettier --write '{{ root }}'
    nixfmt ...(fd '.*.nix$' '{{ root }}' | lines)

lint:
    cd '{{ root }}'; just --unstable --fmt --check
    prettier --check '{{ root }}'
    nixfmt --check ...(fd '.*.nix$' '{{ root }}' | lines)
    cspell lint '{{ root }}' --no-progress
    markdownlint '{{ root }}'
    markdown-link-check \
      --config .markdown-link-check.json \
      --quiet \
      ...(fd '.*.md' | lines)
    nix flake check
    nix run .#flake-test

repl test *args:
    cd '{{ root }}/test/{{ test }}'; \
      nix repl \
        {{ args }} \
        --override-flake perch '{{ root }}' \
        --no-write-lock-file \
        --show-trace \
        --expr 'rec { \
          perch = "{{ root }}"; \
          perchFlake = builtins.getFlake perch; \
          test = "{{ root }}/test/e2e/{{ test }}"; \
          testFlake = builtins.getFlake test; \
        }'

run test app="" *args:
    cd '{{ root }}/test/e2e/{{ test }}'; \
      nix run \
        '.#{{ app }}' \
        {{ args }} \
        --no-write-lock-file \
        --override-flake perch '{{ root }}'

docs:
    rm -rf '{{ root }}/artifacts'
    "# Options\n\n" + \
      (open --raw \
        (nix build --no-link --print-out-paths --show-trace \
          '{{ root }}#docs-options')) \
      | save -f '{{ root }}/docs/options.md'
    "# Library\n\n" + \
      (open --raw \
        (nix build --no-link --print-out-paths --show-trace \
          '{{ root }}#docs-lib')) \
      | save -f '{{ root }}/docs/library.md'
    prettier --write '{{ root }}/docs/options.md'
    prettier --write '{{ root }}/docs/library.md'
    cd '{{ root }}/docs'; mdbook build
    mv '{{ root }}/docs/book' '{{ root }}/artifacts'
