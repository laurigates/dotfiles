# Development environment configuration
# Language runtimes, tools, and configurations

{ config, pkgs, lib, inputs, ... }:

{
  # Python development
  home.file.".config/ruff/ruff.toml".text = ''
    # Ruff configuration (from dotfiles preferences)
    line-length = 100
    indent-width = 4

    [format]
    quote-style = "double"
    indent-style = "space"
    skip-magic-trailing-comma = false
    line-ending = "auto"

    [lint]
    select = [
      "E",   # pycodestyle errors
      "W",   # pycodestyle warnings
      "F",   # Pyflakes
      "I",   # isort
      "B",   # flake8-bugbear
      "C4",  # flake8-comprehensions
      "UP",  # pyupgrade
      "SIM", # flake8-simplify
      "RUF", # Ruff-specific rules
    ]
    ignore = [
      "E501",  # line too long (handled by formatter)
    ]

    [lint.isort]
    known-first-party = ["src"]
  '';

  # Go development
  home.file.".config/golangci-lint/.golangci.yml".text = ''
    run:
      timeout: 5m
      go: "1.23"

    linters:
      enable:
        - errcheck
        - gosimple
        - govet
        - ineffassign
        - staticcheck
        - unused
        - gofmt
        - goimports
        - gosec
        - misspell
        - unconvert
        - unparam

    linters-settings:
      gofmt:
        simplify: true
      goimports:
        local-prefixes: github.com/

    issues:
      exclude-use-default: false
      max-issues-per-linter: 0
      max-same-issues: 0
  '';

  # Rust development
  home.file.".cargo/config.toml".text = ''
    [build]
    # Use sccache if available
    # rustc-wrapper = "sccache"

    [target.x86_64-unknown-linux-gnu]
    linker = "clang"
    rustflags = ["-C", "link-arg=-fuse-ld=lld"]

    [target.aarch64-unknown-linux-gnu]
    linker = "clang"
    rustflags = ["-C", "link-arg=-fuse-ld=lld"]

    [registries.crates-io]
    protocol = "sparse"

    [net]
    git-fetch-with-cli = true

    [alias]
    b = "build"
    c = "check"
    t = "test"
    r = "run"
    rr = "run --release"
    br = "build --release"
    w = "watch"
    fmt = "fmt --all"
    clippy = "clippy --all-targets --all-features"
  '';

  # EditorConfig (from dotfiles preferences)
  home.file.".editorconfig".text = ''
    # EditorConfig - https://editorconfig.org
    root = true

    [*]
    charset = utf-8
    end_of_line = lf
    indent_style = space
    indent_size = 2
    insert_final_newline = true
    trim_trailing_whitespace = true

    [*.{py,pyi}]
    indent_size = 4

    [*.go]
    indent_style = tab
    indent_size = 4

    [*.rs]
    indent_size = 4

    [*.md]
    trim_trailing_whitespace = false

    [Makefile]
    indent_style = tab

    [{*.yaml,*.yml}]
    indent_size = 2

    [*.{json,jsonc}]
    indent_size = 2

    [*.lua]
    indent_size = 2

    [*.nix]
    indent_size = 2

    [*.tf]
    indent_size = 2

    [*.sh]
    indent_size = 2
    shell_variant = bash
  '';

  # Prettier configuration
  home.file.".prettierrc".text = ''
    {
      "semi": true,
      "singleQuote": false,
      "tabWidth": 2,
      "trailingComma": "es5",
      "printWidth": 100,
      "bracketSpacing": true,
      "arrowParens": "always",
      "endOfLine": "lf"
    }
  '';

  # NPM configuration
  home.file.".npmrc".text = ''
    # NPM configuration
    prefix=~/.npm-global
    fund=false
    audit=true
    save-exact=false
    init-author-name=
    init-author-email=
    init-license=MIT
  '';

  # pip configuration
  home.file.".config/pip/pip.conf".text = ''
    [global]
    require-virtualenv = true
    disable-pip-version-check = true

    [install]
    no-cache-dir = false
  '';

  # Just (command runner) configuration
  programs.just = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  # ripgrep configuration
  home.file.".config/ripgrep/config".text = ''
    # ripgrep configuration

    # Smart case search
    --smart-case

    # Hidden files (respects .gitignore)
    --hidden

    # Follow symlinks
    --follow

    # Max columns before truncating
    --max-columns=200
    --max-columns-preview

    # Sort by path
    --sort=path

    # Ignore patterns
    --glob=!.git/
    --glob=!node_modules/
    --glob=!vendor/
    --glob=!.venv/
    --glob=!__pycache__/
    --glob=!*.min.js
    --glob=!*.min.css
    --glob=!package-lock.json
    --glob=!yarn.lock
    --glob=!Cargo.lock
    --glob=!go.sum
  '';

  # fd configuration
  home.file.".config/fd/ignore".text = ''
    # fd ignore patterns
    .git/
    node_modules/
    vendor/
    .venv/
    __pycache__/
    .cache/
    .terraform/
    target/
    dist/
    build/
  '';

  # Pre-commit configuration (template)
  home.file.".config/pre-commit/default.yaml".text = ''
    # Default pre-commit configuration
    repos:
      - repo: https://github.com/pre-commit/pre-commit-hooks
        rev: v4.5.0
        hooks:
          - id: trailing-whitespace
          - id: end-of-file-fixer
          - id: check-yaml
          - id: check-json
          - id: check-toml
          - id: check-added-large-files
          - id: detect-private-key
          - id: check-merge-conflict
          - id: check-symlinks

      - repo: https://github.com/Yelp/detect-secrets
        rev: v1.4.0
        hooks:
          - id: detect-secrets
            args: ['--baseline', '.secrets.baseline']

      - repo: https://github.com/shellcheck-py/shellcheck-py
        rev: v0.9.0.6
        hooks:
          - id: shellcheck
  '';

  # Docker configuration
  home.file.".docker/config.json".text = ''
    {
      "detachKeys": "ctrl-z,ctrl-z",
      "psFormat": "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
    }
  '';

  # Kubectl configuration directory
  home.file.".kube/.keep".text = "";

  # Terraform configuration
  home.file.".terraformrc".text = ''
    plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
    disable_checkpoint = true
  '';

  home.file.".terraform.d/plugin-cache/.keep".text = "";

  # AWS configuration directory
  home.file.".aws/config".text = ''
    [default]
    region = eu-north-1
    output = json
    cli_pager = less

    [profile dev]
    region = eu-north-1
    output = json
  '';
}
