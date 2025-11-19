# CLAUDE.md - Maintenance Scripts

Utility scripts for maintaining and automating Claude Code infrastructure in this dotfiles repository.

## Scripts Overview

| Script | Purpose | When to Use |
|--------|---------|-------------|
| **`generate-claude-completion.sh`** | Generate zsh completions for Claude CLI | After Claude CLI updates or when completions are outdated |
| **`generate-claude-completion-simple.sh`** | Simplified version of completion generator | Fallback if main generator fails; faster but less dynamic |
| **`migrate-command-namespaces.sh`** | Migrate commands to new namespace structure | During command reorganization or namespace refactoring |
| **`update-command-references.sh`** | Update documentation references after migration | After running `migrate-command-namespaces.sh` |

## Script Details

### generate-claude-completion.sh

**Purpose:** Automatically generates zsh completion functions for the Claude CLI by parsing `claude --help` output.

**Features:**
- Parses main commands, subcommands, and options dynamically
- Generates context-aware completions for `config`, `mcp`, and `install` subcommands
- Extracts model names, config keys, and MCP server names
- Validates generated completion syntax
- Auto-tracks completion file in git if not already tracked

**Output:** `dot_zfunc/_claude` (zsh completion file)

**Usage:**
```bash
# Generate completions
./scripts/generate-claude-completion.sh

# Apply to chezmoi target
chezmoi apply ~/.zfunc/_claude

# Test completions
exec zsh
claude <TAB>
```

**How it works:**
1. Checks for Claude CLI availability
2. Captures help output from `claude --help`, `claude config --help`, etc.
3. Parses commands and options using AWK
4. Dynamically discovers models, config keys, and MCP servers
5. Generates zsh completion functions with proper syntax
6. Validates with `zsh -n`
7. Writes to `dot_zfunc/_claude`

**Troubleshooting:**
- **Error: "Claude CLI not found"** - Ensure `claude` is in your PATH
- **Syntax errors** - Completion validation failed; check AWK parsing logic
- **Completions not working** - Run `exec zsh` or `source ~/.zfunc/_claude`

---

### generate-claude-completion-simple.sh

**Purpose:** Simplified, more robust completion generator using straightforward parsing.

**Differences from full generator:**
- Uses simpler sed/awk parsing (less prone to edge cases)
- Hardcoded model and config key lists (fallback approach)
- Faster execution
- More compatible with older bash versions

**When to use:**
- Main generator encounters parsing errors
- Need faster generation during development
- Working with beta/unstable Claude CLI versions

**Usage:**
```bash
./scripts/generate-claude-completion-simple.sh
```

---

### migrate-command-namespaces.sh

**Purpose:** Refactor Claude Code commands from flat structure to organized namespace hierarchy.

**Features:**
- Migrates commands to namespace directories (`git/`, `code/`, `project/`, etc.)
- Renames commands to follow namespace:command pattern
- Handles associated files (PRD files, related docs)
- Dry-run mode for safe previewing
- Tracks migration statistics

**Usage:**
```bash
# Preview changes without modifying files
./scripts/migrate-command-namespaces.sh --dry-run

# Execute migration
./scripts/migrate-command-namespaces.sh

# Apply changes via chezmoi
chezmoi diff
chezmoi apply
```

**Namespace Structure:**
| Namespace | Purpose | Example Commands |
|-----------|---------|------------------|
| `git:` | Git and GitHub operations | `git:commit`, `git:issues`, `git:fix-pr` |
| `code:` | Code quality and review | `code:review`, `code:refactor` |
| `config:` | Configuration management | `config:audit`, `config:assimilate` |
| `project:` | Project setup and maintenance | `project:new`, `project:modernize` |
| `test:` | Testing infrastructure | `test:run`, `test:setup` |
| `docs:` | Documentation generation | `docs:generate`, `docs:build` |
| `workflow:` | Development workflows | `workflow:dev`, `workflow:dev-zen` |
| `sync:` | Synchronization tasks | `sync:daily`, `sync:github-podio` |
| `deploy:` | Deployment operations | `deploy:release`, `deploy:handoff` |
| `tools:` | Tool initialization | `tools:vectorcode` |

**Migration Process:**
1. Creates namespace directories if needed
2. Moves command files to new locations
3. Renames files to match new namespace pattern
4. Migrates associated files (PRDs, etc.)
5. Provides summary statistics

**Example Migration:**
```
OLD: .claude/commands/smartcommit.md
NEW: .claude/commands/git/commit.md

Command reference changes:
/smartcommit → /git:commit
```

---

### update-command-references.sh

**Purpose:** Update all markdown documentation to reflect new command namespace references after migration.

**Features:**
- Scans all markdown files in repository
- Updates slash command references (`/old-name` → `/namespace:new-name`)
- Updates file path references (`.claude/commands/old.md` → `.claude/commands/namespace/new.md`)
- Dry-run mode for previewing changes
- Shows statistics (files modified, total replacements)

**Usage:**
```bash
# Preview changes
./scripts/update-command-references.sh --dry-run

# Apply updates
./scripts/update-command-references.sh

# Review and commit
git diff
git add .
git commit -m "refactor: update command namespace references"
```

**What it updates:**
- **Slash command references:** `/smartcommit` → `/git:commit`
- **File path references:** `.claude/commands/smartcommit.md` → `.claude/commands/git/commit.md`
- **Cross-references in documentation**

**Example output:**
```
📄 Finding markdown files...
  Found 127 markdown files

🔄 Processing files...
  ✓ CLAUDE.md (4 changes)
  ✓ .claude/skills/git-commit-workflow/SKILL.md (2 changes)
  ✓ README.md (1 changes)

═══════════════════════════════════════════════════════════
  Update Summary
═══════════════════════════════════════════════════════════
  Total files scanned:     127
  Files modified:          23
  Total replacements:      47
```

**Compatibility:**
- Compatible with bash 3.2+ (macOS default)
- Uses BSD sed syntax (`sed -i ''`)
- Portable across Linux and macOS

---

## Workflow: Command Migration

When reorganizing Claude Code commands, follow this sequence:

```bash
# 1. Preview migration
./scripts/migrate-command-namespaces.sh --dry-run

# 2. Execute migration
./scripts/migrate-command-namespaces.sh

# 3. Apply to target via chezmoi
chezmoi apply

# 4. Preview documentation updates
./scripts/update-command-references.sh --dry-run

# 5. Apply documentation updates
./scripts/update-command-references.sh

# 6. Review all changes
git status
git diff

# 7. Stage and commit
git add .
git commit -m "refactor: reorganize commands with namespace structure"
```

## Workflow: Updating Completions

After Claude CLI updates:

```bash
# 1. Generate new completions
./scripts/generate-claude-completion.sh

# 2. Review changes
chezmoi diff

# 3. Apply to target
chezmoi apply ~/.zfunc/_claude

# 4. Test in new shell
exec zsh
claude <TAB>

# 5. Commit if satisfied
git add dot_zfunc/_claude
git commit -m "chore: update Claude CLI completions"
```

## Best Practices

### Script Modifications

When modifying these scripts:

1. **Always test with dry-run first**
   ```bash
   ./scripts/script-name.sh --dry-run
   ```

2. **Validate bash syntax**
   ```bash
   shellcheck scripts/*.sh
   ```

3. **Test on sample data before production**
   - Create test directory with sample commands
   - Run script on test data
   - Verify expected behavior

### Chezmoi Integration

These scripts modify files in the chezmoi source directory:
- **Source:** `~/.local/share/chezmoi/`
- **Target:** `~/` (after `chezmoi apply`)

Always run `chezmoi apply` after script execution to sync changes to target locations.

### Git Workflow

1. **Before running scripts:**
   ```bash
   git status  # Ensure clean working directory
   git diff    # Verify no uncommitted changes
   ```

2. **After running scripts:**
   ```bash
   git status  # Review what changed
   git diff    # Inspect specific changes
   git add .   # Stage changes
   git commit  # Commit with descriptive message
   ```

## Extending the Scripts

### Adding New Command Namespaces

Edit `migrate-command-namespaces.sh`:

1. Add namespace to `NAMESPACES` array:
   ```bash
   declare -a NAMESPACES=(
       ...
       "new-namespace"
   )
   ```

2. Add migration mappings to `MIGRATIONS` array:
   ```bash
   "old-path.md|new-namespace|new-name.md"
   ```

3. Update `update-command-references.sh` `MAPPINGS` array:
   ```bash
   "/old-command|/new-namespace:new-command"
   ```

### Adding Custom Completions

Edit `generate-claude-completion.sh` or `generate-claude-completion-simple.sh`:

1. Add new helper function:
   ```bash
   _claude_custom_completion() {
       local -a items
       items=(
           'item1:Description 1'
           'item2:Description 2'
       )
       _describe -t items 'custom items' items
   }
   ```

2. Reference in argument specification:
   ```bash
   _arguments \
       '1:item:_claude_custom_completion'
   ```

## Troubleshooting

### Script Errors

**"Command not found" errors:**
- Ensure scripts are executable: `chmod +x scripts/*.sh`
- Check bash path in shebang: `#!/usr/bin/env bash`

**Permission denied:**
```bash
chmod +x scripts/*.sh
```

**Unexpected behavior:**
```bash
# Enable debug mode
bash -x scripts/script-name.sh

# Check for syntax errors
shellcheck scripts/script-name.sh
```

### Chezmoi Issues

**Changes not appearing in target:**
```bash
# Force re-apply
chezmoi apply --force

# Check what chezmoi sees
chezmoi status
chezmoi diff
```

**Files not tracked:**
```bash
# Add to git
git add scripts/*.sh

# Verify tracking
git ls-files scripts/
```

## See Also

- **Root CLAUDE.md** - Overall repository guidance
- **`.claude/CLAUDE.md`** - High-level design and delegation strategy
- **docs/claude-completion.md** - Detailed completion system documentation
- **Chezmoi Expert Skill** - Automatic guidance for chezmoi operations
