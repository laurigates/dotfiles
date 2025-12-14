# Release-Please Automation

**CRITICAL RULE:** Never manually edit files managed by release-please automation.

## Protected Files

### Hard Protection (Permission System Blocks)

- `plugins/**/CHANGELOG.md` - Auto-generated from conventional commits
- **Any** `CHANGELOG.md` file across all projects

These files are **blocked** via Claude Code's permission system. Attempts to edit them will fail.

### Soft Protection (Skill Detection & Warning)

- `plugins/**/.claude-plugin/plugin.json` - Version field only
- `.claude-plugin/marketplace.json` - Version references
- `package.json` - Version field in Node.js projects
- `pyproject.toml` - Version field in Python projects
- `Cargo.toml` - Version field in Rust projects

## Why This Matters

Manual edits to these files cause:
- **Merge conflicts** with automated release PRs
- **Version inconsistencies** across packages
- **Duplicate or lost** CHANGELOG entries
- **Broken release workflows** requiring manual intervention

## Proper Workflow

Instead of manually editing version or changelog files:

### 1. Use Conventional Commit Messages

```bash
# For new features (minor version bump)
git commit -m "feat(auth): add OAuth2 support"

# For bug fixes (patch version bump)
git commit -m "fix(api): handle timeout edge case"

# For breaking changes (major version bump)
git commit -m "feat(api)!: redesign authentication

BREAKING CHANGE: Auth endpoint now requires OAuth2."
```

### 2. Release-Please Automatically

- Analyzes conventional commits
- Determines semantic version bump
- Updates CHANGELOG.md with grouped entries
- Updates version fields in all manifests
- Creates a release PR for review

### 3. Review and Merge the Release PR

- Verify version bump is correct
- Check CHANGELOG entries are accurate
- Merge to trigger tagged release

## Conventional Commit Types

| Type | Version Bump | Description |
|------|--------------|-------------|
| `feat:` | Minor | New features |
| `fix:` | Patch | Bug fixes |
| `feat!:` or `BREAKING CHANGE:` | Major | Breaking changes |
| `chore:`, `docs:`, `style:`, `refactor:` | None | No version bump |

## Emergency Override

If you **absolutely must** manually edit protected files:

1. Temporarily disable protection in `~/.claude/settings.json`
2. Make your edits
3. Re-enable protection immediately
4. Sync with chezmoi if needed

**Use this only for emergencies** - the automation exists to prevent errors.
