# CLAUDE.md - Plugins System

This document provides authoritative guidance for developing, testing, and managing Claude Code plugins in this repository.

## Plugin System Architecture

### What are Plugins?

Plugins are **installable packages** distributed via Claude Code's marketplace system. They bundle related functionality into reusable, versioned components.

**Plugins differ from:**
- **Skills** (`.claude/skills/`) - Auto-discovered domain knowledge invoked by Claude based on context
- **Agents** (`.claude/agents/`) - Specialized assistants explicitly delegated for specific tasks
- **Commands** (`.claude/commands/`) - User-invoked workflows with `/command` syntax

**Plugins can contain:** Agents, commands, skills, hooks, and MCP server configurations bundled together.

### Directory Structure

```
plugins/
├── .claude-plugin/
│   └── marketplace.json              # Marketplace registry
├── dotfiles-core/
│   ├── .claude-plugin/
│   │   └── plugin.json               # Plugin metadata (REQUIRED)
│   ├── agents/                       # Specialized agents
│   ├── commands/                     # Slash commands
│   ├── skills/                       # Agent skills
│   ├── hooks/                        # Event handlers
│   └── README.md                     # Plugin documentation
└── [other-plugins]/
```

## Plugin Manifest Schema

### plugin.json (Required)

Located at `.claude-plugin/plugin.json` in each plugin directory.

**Required Fields:**
```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Brief description of the plugin",
  "author": {
    "name": "Author Name",
    "email": "author@example.com"
  }
}
```

**Optional Fields:**
```json
{
  "homepage": "https://docs.example.com",
  "repository": "https://github.com/user/repo",
  "license": "MIT",
  "keywords": ["tag1", "tag2"],
  "dependencies": {
    "other-plugin@marketplace": "^1.0.0"
  },
  "commands": "./custom-commands",
  "agents": "./custom-agents",
  "hooks": "./custom-hooks/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

**Important Notes:**
- ⚠️ **DO NOT** include a `components` field - it's not part of the schema and causes validation errors
- Skills are auto-discovered from `skills/` and don't require manifest declaration
- Custom paths must be relative and start with `./`
- Dependencies reference other plugins: `"plugin-name@marketplace-name": "version"`

### marketplace.json (Marketplace Registry)

Located at `.claude-plugin/marketplace.json` in the `plugins/` root.

```json
{
  "name": "marketplace-name",
  "owner": {
    "name": "owner-username"
  },
  "description": "Marketplace description",
  "plugins": [
    {
      "name": "plugin-name",
      "source": "./plugin-directory",
      "description": "Plugin description"
    }
  ]
}
```

**Critical Rules:**
1. Every plugin in `plugins/` MUST be registered in marketplace.json
2. The `source` path is relative to the `plugins/` directory
3. Plugin `name` must match the directory name and plugin.json name

## Available Plugins

### dotfiles-core
**Version:** 3.0.0
**Purpose:** Core development toolkit with 17 skills, 14 agents, and 20+ commands

**Components:**
- **14 Agents:** Code review, refactoring, documentation, security audit, git operations, CI/CD, and more
- **20+ Commands:** Test execution, linting, dependency management, git workflows, project setup
- **17 Skills:** Chezmoi, shell scripting, fd/rg tools, Git, GitHub Actions, Neovim, Python, Rust, Node.js, C++, containers, Kubernetes, Terraform, embedded systems

**Use Cases:** Comprehensive development workflows, code quality, documentation generation

### dotfiles-toolkit
**Version:** 1.0.0
**Purpose:** Comprehensive development toolkit (legacy structure - being migrated to dotfiles-core)

**Components:** Specialized agents for chezmoi, git operations, code review, documentation, containers, infrastructure

### dotfiles-utils
**Version:** 1.0.0
**Purpose:** Shared utilities for session management, parsing, and workflow automation

**Components:** Library functions used by other plugins (no commands/agents)

### dotfiles-ui-hooks
**Version:** 1.0.0
**Purpose:** Voice notifications, Obsidian logging, SketchyBar integration, status overlays

**Components:**
- Hooks for UI integration
- Voice notification scripts
- Obsidian workspace logging
- SketchyBar status updates

**Dependencies:** Requires `dotfiles-utils@dotfiles ^1.0.0`

### dotfiles-experimental
**Version:** 2.0.0
**Purpose:** Experimental features and bleeding-edge automation

**Components:**
- `/experimental:devloop` - Automated development loop with TDD
- `/experimental:devloop-zen` - AI-powered dev loop with Zen MCP
- `/experimental:modernize` - Codebase modernization tools

### dotfiles-fvh
**Version:** 2.0.0
**Purpose:** FVH-specific workflows and integrations

**Components:**
- `/dotfiles-fvh:build-knowledge-graph` - Obsidian vault knowledge graphs
- `/dotfiles-fvh:disseminate` - GitHub ↔ Podio bidirectional sync
- `/dotfiles-fvh:handoff` - Deployment handoff documentation

## Plugin Development Workflow

### Creating a New Plugin

1. **Create Plugin Directory**
   ```bash
   mkdir plugins/my-plugin
   cd plugins/my-plugin
   ```

2. **Create Manifest**
   ```bash
   mkdir .claude-plugin
   cat > .claude-plugin/plugin.json << 'EOF'
   {
     "name": "my-plugin",
     "version": "1.0.0",
     "description": "Brief description",
     "author": {
       "name": "Your Name",
       "email": "your.email@example.com"
     }
   }
   EOF
   ```

3. **Add Components**
   ```bash
   mkdir -p commands agents skills hooks
   # Add your .md files to respective directories
   ```

4. **Register in Marketplace**
   Edit `plugins/.claude-plugin/marketplace.json`:
   ```json
   {
     "plugins": [
       {
         "name": "my-plugin",
         "source": "./my-plugin",
         "description": "Brief description"
       }
     ]
   }
   ```

5. **Document the Plugin**
   Create `README.md` with usage instructions and examples

6. **Test Locally**
   ```bash
   # Restart Claude Code and run
   /plugin list
   ```

### Validation Checklist

Before committing plugin changes:

- [ ] `plugin.json` uses valid schema (no `components` field)
- [ ] Plugin is registered in `marketplace.json`
- [ ] All three `name` fields match (directory, plugin.json, marketplace.json)
- [ ] Version follows semantic versioning (X.Y.Z)
- [ ] Dependencies are correctly declared with marketplace suffix
- [ ] README.md documents all commands and agents
- [ ] Skills have proper `SKILL.md` files
- [ ] Commands use correct markdown format
- [ ] No syntax errors in JSON manifests

### Testing Strategy

**Local Testing:**
1. Edit plugin files in `~/.local/share/chezmoi/plugins/`
2. Run `/plugin` to check for errors
3. Test commands with `/namespace:command`
4. Verify agents are discoverable
5. Check skills are auto-invoked in relevant contexts

**Validation Commands:**
```bash
# Check JSON syntax
jq empty plugins/*/.claude-plugin/plugin.json
jq empty plugins/.claude-plugin/marketplace.json

# Validate plugin structure
ls -R plugins/my-plugin/

# Check for common issues
grep -r "components" plugins/*/.claude-plugin/plugin.json  # Should be empty
```

## Best Practices

### Naming Conventions
- **Plugins:** `kebab-case` (e.g., `dotfiles-core`)
- **Commands:** `kebab-case` (e.g., `git:smartcommit`)
- **Agents:** `kebab-case` (e.g., `code-review`)
- **Skills:** `kebab-case` (e.g., `python-development`)

### Organization
- Group related commands in subdirectories: `commands/git/`, `commands/test/`
- Keep agent markdown files focused on single responsibilities
- Use skills for domain knowledge that should be automatically available
- Place shared utilities in `dotfiles-utils` to avoid duplication

### Documentation
- Every plugin MUST have a comprehensive README.md
- Document all commands with examples and parameters
- Explain when to use each agent
- Include version history in CHANGELOG.md
- Reference related skills and their capabilities

### Versioning
- Follow semantic versioning: `MAJOR.MINOR.PATCH`
- Increment MAJOR for breaking changes
- Increment MINOR for new features
- Increment PATCH for bug fixes
- Update plugin.json version on every change

### Dependencies
- Minimize dependencies between plugins
- Use `dotfiles-utils` for shared code
- Declare dependencies explicitly in plugin.json
- Test dependency resolution after changes

## Common Issues & Solutions

### "Unrecognized key 'components' in object"
**Cause:** Invalid field in plugin.json
**Solution:** Remove the `components` field - skills/agents/commands are auto-discovered

### "Plugin not found in marketplace"
**Cause:** Plugin not registered in marketplace.json
**Solution:** Add plugin entry to `plugins/.claude-plugin/marketplace.json`

### "Plugin has invalid manifest"
**Cause:** JSON syntax error or invalid schema
**Solution:** Validate with `jq empty plugin.json` and check schema above

### Commands not appearing
**Cause:** Files not in `commands/` directory or missing `.md` extension
**Solution:** Ensure `commands/*.md` files exist with proper frontmatter

### Skills not auto-invoked
**Cause:** Missing `SKILL.md` file in skills subdirectory
**Solution:** Create `skills/skill-name/SKILL.md` with proper structure

## Migration Notes

### From dotfiles-toolkit to dotfiles-core
The repository is migrating from `dotfiles-toolkit` (legacy) to `dotfiles-core` (current).

**Changes:**
- Skills moved to `.claude/skills/` for automatic discovery
- Commands consolidated with consistent namespacing
- Agents refactored for better separation of concerns
- Documentation improved with examples

**Timeline:** Complete migration by Q1 2025

## References

- [Claude Code Plugin Documentation](https://docs.claude.com/en/docs/claude-code/plugins)
- [Plugin Reference Schema](https://docs.claude.com/en/docs/claude-code/plugins-reference)
- [Creating Custom Agents](https://docs.claude.com/en/docs/claude-code/agents)
- [Writing Slash Commands](https://docs.claude.com/en/docs/claude-code/commands)
- [Agent Skills Guide](https://docs.claude.com/en/docs/claude-code/skills)
