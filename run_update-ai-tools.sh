#!/bin/sh
# Update all AI tools

pipx install "vectorcode[mcp,cli]"
npm i -g @anthropic-ai/claude-code
npm install -g @google/gemini-cli
pipx install git+https://github.com/arben-adm/mcp-sequential-thinking
pipx inject sequential-thinking portalocker
pipx install git+https://github.com/BeehiveInnovations/zen-mcp-server
go install github.com/github/github-mcp-server/cmd/github-mcp-server@latest
claude mcp add --scope=user --transport=sse graphiti-memory -- http://localhost:8000/sse
claude mcp add kicad -- ~/repos/kicad-mcp/.venv/bin/python ~/repos/kicad-mcp/main.py
claude mcp add --scope=user vectorcode -- vectorcode-mcp-server
claude mcp add --scope user zen-mcp-server -- uvx --from git+https://github.com/BeehiveInnovations/zen-mcp-server.git zen-mcp-server
claude mcp add --scope user playwright -- npx -y "@playwright/mcp@latest"
claude mcp add context7 -- npx -y @upstash/context7-mcp
claude mcp add github -- github-mcp-server stdio
claude mcp add --scope=user lsp-typescript -- npx -y tritlo/lsp-mcp typescript ~/.local/share/nvim/mason/bin/typescript-language-server --stdio
claude mcp add --scope=user lsp-clangd -- npx -y tritlo/lsp-mcp clangd ~/.local/share/nvim/mason/bin/clangd --stdio
claude mcp add --scope=user lsp-basedpyright-langserver -- npx -y tritlo/lsp-mcp basedpyright-langserver ~/.local/share/nvim/mason/bin/basedpyright-langserver --stdio
claude mcp add --scope=user podio-mcp -- npx https://github.com/ForumViriumHelsinki/podio-mcp
claude mcp add --scope=user lsp-github-actions -- npx -y tritlo/lsp-mcp github-actions ~/.local/share/nvim/mason/bin/gh-actions-language-server --stdio
claude mcp add --scope=user lsp-terraform -- npx -y tritlo/lsp-mcp terraform ~/.local/share/nvim/mason/bin/terraform-ls --stdio
claude mcp add --scope=user lsp-rust -- npx -y tritlo/lsp-mcp rust ~/.local/share/nvim/mason/bin/rust-analyzer --stdio
claude mcp add --scope=user lsp-lua -- npx -y tritlo/lsp-mcp lua ~/.local/share/nvim/mason/bin/lua-language-server --stdio
claude mcp add --scope=user lsp-yaml -- npx -y tritlo/lsp-mcp yaml ~/.local/share/nvim/mason/bin/yaml-language-server --stdio
claude mcp add --scope=user lsp-docker -- npx -y tritlo/lsp-mcp dockerfile ~/.local/share/nvim/mason/bin/docker-langserver --stdio
claude mcp add --scope=user lsp-json -- npx -y tritlo/lsp-mcp json ~/.local/share/nvim/mason/bin/vscode-json-language-server --stdio
claude mcp add --scope=user lsp-bash -- npx -y tritlo/lsp-mcp bash ~/.local/share/nvim/mason/bin/bash-language-server --stdio
claude mcp add --scope=user lsp-helm -- npx -y tritlo/lsp-mcp helm ~/.local/share/nvim/mason/bin/helm_ls --stdio
claude mcp add --scope=user --transport=http sentry https://mcp.sentry.dev/mcp
