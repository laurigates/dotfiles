# Claude Code Configuration Guide

## Settings Structure

The `dot_claude/settings.json.tmpl` file is a chezmoi template that generates `~/.claude/settings.json`.

### Key Sections

#### 1. Permissions

Controls what tools and operations Claude can access:

```json
"permissions": {
  "allow": [
    "Bash(find:*)",           // Allow all find commands
    "mcp__context7",          // Allow entire MCP server
    "mcp__zen-mcp-server__debug",  // Allow specific tool
    "WebFetch(domain:docs.anthropic.com)"  // Domain-restricted web fetch
  ],
  "deny": [
    "Bash(git add .)",        // Prevent dangerous git operations
    "Bash(git add -A)",
    "Bash(git add --all)"
  ],
  "ask": [],                   // Require permission each time
  "additionalDirectories": [   // Extra directories to access
    "~/Documents/FVH Vault",
    "~/repos/infrastructure.wiki"
  ]
}
```

**Permission Patterns:**
- `Bash(command:*)` - Allow bash command with any args
- `mcp__server` - Allow entire MCP server
- `mcp__server__tool` - Allow specific MCP tool
- `WebFetch(domain:example.com)` - Domain-restricted web access

#### 2. Hooks

Execute scripts at specific points in Claude's workflow:

```json
"hooks": {
  "UserPromptSubmit": [/* Run when user submits prompt */],
  "PreToolUse": [/* Run before tool execution */],
  "Stop": [/* Run when Claude stops generating */]
}
```

**Hook Configuration:**
- Dynamically configured via `.chezmoidata.toml` variables
- Can be enabled/disabled individually
- Support timeouts and command execution

See [hooks-guide.md](./hooks-guide.md) for details.

#### 3. Status Line

Custom status bar in Claude Code UI:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline-command.sh"
}
```

The script displays:
- Current git branch and status
- Mise tool versions
- Custom project info

#### 4. Marketplace & Plugins

**Local Marketplace:**
```json
"extraKnownMarketplaces": {
  "dotfiles": {
    "source": {
      "source": "directory",
      "path": "/Users/USERNAME/.local/share/chezmoi/plugins"
    }
  }
}
```

**Enabled Plugins:**
```json
"enabledPlugins": {
  "dotfiles-core@dotfiles": true,
  "dotfiles-experimental@dotfiles": true,
  "dotfiles-fvh@dotfiles": true
}
```

Toggle plugins by setting to `false`.

#### 5. Model Selection

```json
"model": "sonnet"  // or "opus", "haiku"
```

Preserved across chezmoi applies via template logic.

## Chezmoi Template Features

### Preserving User Settings

The template preserves existing user choices:

```go-template
{{- $settingsFile := joinPath .chezmoi.homeDir ".claude" "settings.json" }}
{{- if stat $settingsFile }}
{{- $existing := $settingsFile | include | fromJson }}
  "model": {{ if hasKey $existing "model" }}{{ $existing.model | toJson }}{{ else }}"sonnet"{{ end }},
{{- end }}
```

### Conditional Hook Configuration

Hooks can be enabled/disabled via `.chezmoidata.toml`:

```toml
[claude_hooks]
enable_sketchybar = true
enable_obsidian_logging = true
enable_voice_notifications = true
enable_pre_commit_formatting = true
enable_gh_context = true
```

### Dynamic Source Directory

Uses chezmoi variables for portability:

```go-template
"path": "{{ .chezmoi.sourceDir }}/plugins"
```

## MCP Server Integration

Enabled MCP servers in `.claude/settings.local.json`:

```json
"enabledMcpjsonServers": [
  "context7",          // Documentation lookup
  "github",            // GitHub integration
  "sequential-thinking",  // Complex reasoning
  "zen-mcp-server",    // Advanced AI workflows
  "playwright"         // Browser automation
]
```

MCP server configurations managed separately via MCP settings files.

## Configuration Hierarchy

1. **Enterprise policies** (if applicable)
2. **Command-line arguments**
3. **Local project settings** (`.claude/settings.local.json`)
4. **Shared project settings** (`~/.claude/settings.json` from template)
5. **User settings** (lowest priority)

Local settings override shared settings, allowing per-project customization.

## Best Practices

1. **Edit source, not target**: Always edit `dot_claude/settings.json.tmpl`, never `~/.claude/settings.json`
2. **Test with diff**: Run `chezmoi diff` before applying
3. **Use .chezmoidata**: Configure toggles in `.chezmoidata.toml` instead of hardcoding
4. **Version control**: Commit settings template, ignore local settings
5. **Permission scope**: Start restrictive, expand as needed

## Applying Changes

```bash
# Review what will change
chezmoi diff dot_claude/settings.json.tmpl

# Apply to ~/.claude/settings.json
chezmoi apply -v dot_claude/settings.json.tmpl

# Or apply everything
chezmoi apply -v
```

Claude Code automatically reloads settings when the file changes.
