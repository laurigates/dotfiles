# MCP Server Configuration

This plugin bundles the following MCP servers:

## graphiti-memory
Knowledge graph and memory management for Obsidian vault integration.

**Configuration:** See `.mcp.json` in plugin root
**Environment Variables Required:**
- `GRAPHITI_API_KEY` - Your Graphiti API key

## podio-mcp
Podio integration for FVH-specific workflows and bidirectional sync.

**Configuration:** See `.mcp.json` in plugin root
**Environment Variables Required:**
- `PODIO_CLIENT_ID` - Your Podio OAuth client ID
- `PODIO_CLIENT_SECRET` - Your Podio OAuth client secret
- `PODIO_APP_ID` - Your Podio app ID
- `PODIO_APP_TOKEN` - Your Podio app token

## Setup

These MCP servers are automatically configured when you enable the plugin. You need to provide the environment variables either:

1. In your shell environment before starting Claude Code
2. Via `.env` file (not committed to git)
3. Via environment management tool like direnv

## Usage

Once configured, the following commands will have access to these MCP servers:
- `/dotfiles-fvh:build-knowledge-graph` - Uses graphiti-memory
- `/dotfiles-fvh:disseminate` - Uses podio-mcp

**Note:** The exact command and arguments for these MCP servers may need adjustment based on the actual package names and configuration requirements.
