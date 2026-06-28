# Neovim maintenance recipes — single source of truth, also imported by the
# dotfiles repo justfile so `just nvim-plugins-audit` works here.

# Audit configured Neovim plugins for archival/staleness + successor hints
[group: "nvim"]
nvim-plugins-audit:
    @uv run scripts/audit-nvim-plugins.py
