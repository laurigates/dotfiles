# CLAUDE.md

Chezmoi dotfiles repository with cross-platform development environment configuration.

## Structure

- Files ending in `.tmpl` are processed by chezmoi's templating engine
- `private_` prefixed files prevent accidental exposure
- `dot_` prefixed files become hidden when applied
- `run_*` scripts execute during chezmoi operations

## Essential Commands

```bash
# Checking differences
chezmoi diff                          # Shows changes between source and target (ALL files)
chezmoi diff ~/.config/nvim           # Shows changes for a specific TARGET path
chezmoi diff --reverse                # Shows what would be REMOVED from source
chezmoi status                        # Shows quick status (A=add, M=modify, D=delete)

# Applying changes
chezmoi apply --dry-run               # Test what would be applied (safer than direct apply)
chezmoi apply -v ~/.config/nvim       # Apply changes to specific TARGET path
chezmoi apply -v                      # Apply all changes (only after user reviews and approves)

# Managing orphaned files (renamed/deleted in source)
chezmoi apply --dry-run               # Preview all changes INCLUDING removals
chezmoi apply                         # Apply changes and process .chezmoiremove entries

# Other commands
chezmoi verify .                      # Verify integrity
chezmoi managed                       # List all managed files
chezmoi forget ~/.config/old-tool     # Stop managing a file/directory
./run_once_update-all.sh              # Update all tools
```

### Chezmoi Best Practices

#### CRITICAL: Always Work in Source Directory
- **NEVER edit files in target locations** (e.g., `~/.claude/`, `~/.config/`)
- **ALWAYS edit source files** in `~/.local/share/chezmoi/`
- **Source is the single source of truth** - target files will be overwritten on next apply

#### Safe Application Workflow
- **ALWAYS run `chezmoi diff` before any apply operation** to review what will change
- **Use TARGET paths with `chezmoi diff`** - e.g., `chezmoi diff ~/.claude/hooks/` to see changes for that directory
- **Use `chezmoi apply --dry-run`** to safely test changes without actually applying them
- **Never run `chezmoi apply` directly** - let the user decide when to apply after reviewing
- Use `chezmoi diff | head -50` for quick preview of large changesets
- Use `chezmoi status` for a quick overview of pending changes (A=add, M=modify, D=delete)

### Important Note on Paths

- **Source paths**: Files in the chezmoi directory (e.g., `/Users/lgates/.local/share/chezmoi/dot_claude/`)
- **Target paths**: Where files are applied (e.g., `~/.claude/`)
- `chezmoi diff` and `chezmoi apply` expect **TARGET paths**, not source paths

### Working with Chezmoi Files

#### Source vs Target Files
- **Source files**: `~/.local/share/chezmoi/` - EDIT THESE
- **Target files**: `~/.*` (home directory dotfiles) - NEVER EDIT THESE DIRECTLY
- Target files are generated from source and will be overwritten

#### File Naming Conventions in Source
- `dot_*` → `.` (hidden files in target)
- `private_*` → prevents world-readable permissions
- `executable_*` → sets executable bit
- `readonly_*` → sets read-only permissions
- `.tmpl` suffix → processed as template

#### Examples
```bash
# WRONG: Editing target file
vim ~/.claude/agents/python-development.md  # ❌ Will be overwritten!

# CORRECT: Editing source file
vim ~/.local/share/chezmoi/dot_claude/agents/python-development.md  # ✅

# After editing, check changes:
chezmoi diff ~/.claude/agents/
chezmoi apply --dry-run
```

### Managing Orphaned Files (Renamed/Deleted Files)

When you rename or delete files in the chezmoi source, they become "orphaned" in the target directory. Chezmoi doesn't automatically remove these files for safety reasons.

#### Using `.chezmoiremove`
The `.chezmoiremove` file tells chezmoi which files to delete from the target:

```bash
# Example .chezmoiremove content:
~/.claude/agents/old-agent-name.md
~/.config/deprecated-tool/
```

#### Workflow for Renaming Files
1. Rename file in source directory
2. Add old filename to `.chezmoiremove`
3. Run `chezmoi apply --dry-run` to preview
4. Run `chezmoi apply` to apply changes and removals
5. Remove entry from `.chezmoiremove` after all machines updated

#### Helper Scripts
```bash
# Use the orphan management script to detect orphans
~/scripts/manage_orphans.sh

# Check what files chezmoi manages
chezmoi managed --include=files

# Stop managing a file without deleting it
chezmoi forget ~/.config/old-tool
```

#### Best Practices
- Add date comments to `.chezmoiremove` entries
- Remove entries after changes propagate to all machines
- Always use `--dry-run` first to preview deletions
- Consider backing up before removing many files

## Linting Commands

```bash
shellcheck **/*.sh                    # Shell scripts
luacheck private_dot_config/nvim/lua  # Neovim config
actionlint                            # GitHub Actions
brew bundle check --file=Brewfile     # Brewfile integrity
pre-commit run --all-files            # Run all pre-commit hooks
```

### Secret Scanning
```bash
detect-secrets scan --baseline .secrets.baseline  # Scan for new secrets
detect-secrets audit .secrets.baseline            # Review flagged secrets
pre-commit run detect-secrets --all-files         # Run via pre-commit
```

## Common Pitfalls & Solutions

### ⚠️ WARNING: Interactive Changes Get Lost
**Problem**: Editing files directly in target directories (e.g., through Claude Code) will be lost on next `chezmoi apply`
**Solution**:
1. Copy interactive changes back to source: `chezmoi add ~/.claude/modified-file.md`
2. Or use `chezmoi merge` to merge changes
3. Or use `chezmoi re-add` to update source from target

### ⚠️ WARNING: Orphaned Files Accumulate
**Problem**: Renamed/deleted files in source remain in target
**Solution**: Use `.chezmoiremove` (see Managing Orphaned Files section)

### ⚠️ WARNING: Wrong Directory for Commands
**Problem**: Running chezmoi commands with source paths fails
**Solution**: Most chezmoi commands expect TARGET paths:
```bash
# WRONG
chezmoi diff ~/.local/share/chezmoi/dot_claude/  # ❌

# CORRECT
chezmoi diff ~/.claude/  # ✅
```

## Key Files & Directories

### Chezmoi Special Files
- `.chezmoiremove` - List of files to remove from target
- `.chezmoiignore` - Files to ignore (won't be managed)
- `run_*` scripts - Automatic execution during `chezmoi apply`

### Configuration Files
- `chezmoi.toml.tmpl` - Core chezmoi configuration template
- `private_dot_config/nvim/` - Neovim setup with lazy.nvim
- `private_dot_config/fish/` - Fish shell with cross-platform paths
- `Brewfile` - Homebrew package definitions
- `dot_default-*-packages` - Tool package lists (cargo, npm, uv)

## Templates

- Platform detection: `{{ if eq .chezmoi.os "darwin" }}`
- CPU optimization: `{{ .cpu.threads }}`
- Use templates for cross-platform compatibility

## Tools

- **mise**: Tool version management (`.config/mise/config.toml`)
- **Fish**: Primary shell with Starship prompt
- **Neovim**: Editor with LSP, formatting, debugging
- **Homebrew**: Cross-platform package management

## Documentation Requirements
**ALWAYS check documentation before implementing changes or features.**

### Implementation Checklist
Before implementing any changes or features, complete this checklist:

1. **Read relevant documentation sections thoroughly**
2. **Verify syntax and parameters** in official documentation before coding
3. **Check for breaking changes** and version compatibility requirements
4. **Review best practices** and recommended patterns in the tool's documentation
5. **Validate configuration options** against current documentation versions
6. **Check for deprecated features** that should be avoided
7. **Confirm implementation details match current best practices**

### Critical Documentation Sources
- Tool-specific documentation (mise, Fish, Neovim, Homebrew, chezmoi)
- GitHub Actions documentation for workflow modifications
- Platform-specific guides for cross-platform compatibility
- Security documentation for secrets handling and API token management

## CI Pipeline

Multi-platform testing (Ubuntu/macOS) with linting → build stages in `.github/workflows/smoke.yml`

## Security

- API tokens in `~/.api_tokens` (not in repo)
- Private files use `private_` prefix
- No secrets committed
- **detect-secrets** pre-commit hook prevents accidental secret commits
- **TruffleHog** scans for leaked credentials in git history
- Both tools run automatically on commit via pre-commit hooks
