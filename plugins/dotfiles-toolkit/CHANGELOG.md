# Changelog

All notable changes to the Dotfiles Toolkit plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-22

### Added
- Initial release of the Dotfiles Toolkit plugin
- 30+ specialized agents for development, infrastructure, and operations
  - Dotfiles management: chezmoi-expert, neovim-configuration
  - Development workflows: code-review, code-analysis, code-refactoring, test-architecture
  - Language-specific: python-development, nodejs-development, rust-development, cpp-development, shell-expert
  - Infrastructure: container-development, kubernetes-operations, infrastructure-terraform, cicd-pipelines
  - Git & documentation: git-operations, commit-review, documentation, requirements-documentation
  - System & architecture: system-debugging, service-design, api-integration, memory-management, security-audit
  - Utilities: json-processing, task-logging, plan-critique, template-generation
  - Claude Code tools: claude-code-command-editor, claude-code-subagent-editor
- 20+ slash commands for common workflows
  - Documentation: /docs/docs, /docs/update, /docs/decommission
  - Git operations: /git/smartcommit, /git/repo-maintenance
  - GitHub integration: /github/process-issues, /github/process-single-issue, /github/fix-pr
  - Code quality: /codereview, /refactor, /tdd, /lint/check
  - Project management: /project/init, /setup/new-project, /setup/release, /test/run
  - Development workflows: /deps/install, /build-knowledge-graph, /handoff
  - Chores: /chore/modernize, /chore/refactor
  - Experimental: /experimental/devloop, /experimental/devloop-zen, /experimental/modernize
  - Knowledge management: /assimilate, /disseminate, /google-chat-format
- Claude Code plugin marketplace support
- Comprehensive documentation (README.md, PLUGINS.md)
- Cross-platform support (macOS, Linux, Windows)
- Deep integration with chezmoi dotfiles management

### Changed
- Refactored from direct `dot_claude/` configuration to plugin structure
- Agents and commands now in plugin directory instead of symlinks
- Clear separation between base configuration and advanced features

## Version Guidelines

### Semantic Versioning

- **Major version (X.0.0)**: Breaking changes, significant restructuring, or removed features
- **Minor version (0.X.0)**: New features, new agents/commands, or significant enhancements
- **Patch version (0.0.X)**: Bug fixes, documentation updates, or minor improvements

### When to Bump Versions

- **Major**: Removing agents/commands, changing plugin structure, incompatible changes
- **Minor**: Adding new agents, adding new commands, significant feature additions
- **Patch**: Fixing bugs, updating documentation, improving existing features

### Updating Versions

When bumping versions, update these files:
1. `plugins/dotfiles-toolkit/.claude-plugin/plugin.json` - Update `version` field
2. `plugins/dotfiles-toolkit/CHANGELOG.md` - Add new version section with changes
3. `.claude-plugin/marketplace.json` - If needed for marketplace compatibility

### Changelog Guidelines

For each release, document:
- **Added**: New features, agents, or commands
- **Changed**: Changes to existing functionality
- **Deprecated**: Features marked for removal
- **Removed**: Removed features, agents, or commands
- **Fixed**: Bug fixes
- **Security**: Security improvements or fixes

Example:
```markdown
## [1.1.0] - 2025-XX-XX

### Added
- New agent: example-agent for specific task handling
- New command: /example/command for workflow automation

### Changed
- Improved chezmoi-expert agent with additional templates
- Updated documentation with more examples

### Fixed
- Fixed typo in git-operations agent
- Corrected command path in /github/fix-pr
```
