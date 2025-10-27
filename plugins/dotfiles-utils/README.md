# Dotfiles Utils Plugin

Shared utilities for Claude Code session management, parsing, and workflow automation.

## Purpose

This plugin provides reusable shell utilities and libraries that other plugins depend on. It's designed to be a lightweight dependency that provides common functionality across the dotfiles plugin ecosystem.

## Components

### Session Parser Library

`lib/claude-session-parser.sh` - Comprehensive session parsing utilities:
- Extract session information from Claude Code
- Parse git repository data
- Format timestamps and durations
- Handle multi-session scenarios

### Status Utilities

`lib/status/` - Status management and display:
- Session status tracking
- Progress indicators
- Status formatting helpers

### Task Utilities

`lib/tasks/` - Task management helpers:
- Task tracking and organization
- Progress monitoring
- Task state management

### Workflow Utilities

`lib/workflows/` - Workflow automation support:
- Common workflow patterns
- Script helpers
- Process management

## Usage

Other plugins can source utilities from this plugin:

```bash
# Source the session parser
source "$HOME/.local/share/claude/plugins/dotfiles-utils/lib/claude-session-parser.sh"

# Use parsing functions
parse_claude_session
get_git_info
format_duration
```

## Dependencies

None - this is a foundational utility plugin.

## Dependent Plugins

The following plugins depend on dotfiles-utils:
- **dotfiles-ui-hooks** - Uses session parser for status overlay and logging
- Other plugins may add dependencies on these utilities

## Installation

### Via Marketplace

```bash
/plugin install dotfiles-utils
```

This plugin is typically installed automatically as a dependency when installing other plugins that require it.

## Documentation

- `docs/claude-config.md` - Claude Code configuration guide
- `docs/plugins-setup.md` - Plugin system setup and usage

## Library Reference

### claude-session-parser.sh

Functions provided:
- `parse_claude_session` - Extract session data from environment
- `get_git_info` - Parse git repository information
- `format_duration` - Convert timestamps to readable durations
- `get_session_status` - Determine session state
- `format_output` - Format output for display

See library source for detailed function documentation.

## Development

### Adding New Utilities

1. Add utility scripts to appropriate `lib/` subdirectory
2. Document functions with comments
3. Update this README with new capabilities
4. Version bump in plugin.json
5. Update dependent plugins if interfaces change

## License

Same license as the dotfiles repository.

## Author

**Lauri Gates**
- GitHub: [@laurigates](https://github.com/laurigates)
- Email: laurigates@users.noreply.github.com
