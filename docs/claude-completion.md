# Claude CLI Completion System

This document describes the automated zsh completion system for the Claude CLI that's integrated into this dotfiles repository.

## Overview

The completion system automatically generates zsh completion functions for the Claude CLI by parsing the command's help outputs. This ensures that completion suggestions stay current as the CLI evolves.

## Components

### 1. Completion Generator Script
- **Location**: `scripts/generate-claude-completion-simple.sh`
- **Purpose**: Parses `claude --help` and subcommand help outputs to generate zsh completion functions
- **Features**:
  - Extracts commands, options, and descriptions automatically
  - Handles nested subcommands (config, mcp, install)
  - Provides dynamic completion for models, config keys, and MCP servers
  - Includes proper argument completion for complex commands

### 2. Chezmoi Integration
- **Location**: `run_onchange_update-claude-completion.sh`
- **Purpose**: Automatically updates the completion when the script changes or when manually triggered
- **Trigger**: Runs whenever chezmoi detects changes to the script or dotfiles

### 3. Makefile Integration
- **Target**: `make update-claude-completion`
- **Purpose**: Provides an easy way to manually update the completion
- **Integration**: Included in the main `make update` target

### 4. Generated Completion File
- **Location**: `dot_zfunc/_claude`
- **Purpose**: The actual zsh completion function applied to the system
- **Auto-generated**: This file is created and maintained automatically

## Usage

### Manual Update
```bash
# Update just the Claude completion
make update-claude-completion

# Update everything including Claude completion
make update

# Run the generator directly
./scripts/generate-claude-completion-simple.sh
```

### Automatic Updates
The completion is automatically updated when:
- Running `chezmoi apply` after the generator script changes
- Running the general update process
- The Claude CLI is updated (when using the chezmoi workflow)

### Testing Completion
After updating, test the completion:
```bash
# Reload your shell or source the completion
exec zsh
# or
source ~/.zfunc/_claude

# Test completion
claude <TAB>
claude config <TAB>
claude mcp <TAB>
```

## How It Works

### 1. Help Text Parsing
The script runs these commands to gather information:
- `claude --help` - Main command options and subcommands
- `claude config --help` - Config subcommand structure
- `claude mcp --help` - MCP subcommand structure

### 2. Dynamic Completion
For certain completions, the script attempts to get live data:
- **Models**: Tries to detect available models, falls back to known ones
- **Config Keys**: Attempts to list actual config keys via `claude config list`
- **MCP Servers**: Tries to get server list via `claude mcp list`

### 3. Completion Structure
The generated completion supports:
- Main command options (`--model`, `--debug`, etc.)
- Subcommands (`config`, `mcp`, `install`)
- Subcommand options (`config set --global`)
- Context-aware argument completion
- Help text for all options and commands

## Maintenance

### Adding New Commands
When Claude CLI adds new commands or options:
1. The completion will be automatically updated on the next run
2. No manual editing of completion files needed
3. The parsing logic handles most standard help output formats

### Troubleshooting
If completion doesn't work:
1. Check if the generator script is executable: `ls -la scripts/generate-claude-completion-simple.sh`
2. Run the generator manually to see any error messages
3. Verify Claude CLI is available: `which claude`
4. Check the generated completion file for syntax errors: `zsh -n ~/.zfunc/_claude`

### Customization
To customize the completion:
1. Edit `scripts/generate-claude-completion-simple.sh`
2. Modify the parsing logic or add custom completion functions
3. Run the generator to test your changes
4. The `run_onchange_` script will automatically pick up changes

## Integration with Dotfiles

The completion system is fully integrated into the chezmoi dotfiles workflow:
- Completion file is managed by chezmoi as `dot_zfunc/_claude`
- Generator script is version-controlled and portable
- Works across different systems with the dotfiles
- Automatically sets up completion on new installations

## Security Considerations

The completion system:
- Only parses help text output, doesn't execute arbitrary commands
- Falls back to safe defaults if dynamic lookups fail
- Doesn't expose sensitive information in completion suggestions
- Uses standard zsh completion patterns and security practices

## Dependencies

- **zsh**: The completion system is zsh-specific
- **claude CLI**: Must be installed and accessible in PATH
- **Standard Unix tools**: `sed`, `awk`, `grep` for text processing
- **chezmoi**: For automatic integration and deployment

## Files Created/Modified

When you run the completion system:
- `dot_zfunc/_claude` - Generated completion file (managed by chezmoi)
- May update git tracking for the completion file

## Performance

The completion system is designed for minimal performance impact:
- Generated completion is static once created
- Dynamic lookups only occur during generation, not during tab completion
- Falls back to cached values if dynamic lookups fail
- Completion parsing is efficient and fast
