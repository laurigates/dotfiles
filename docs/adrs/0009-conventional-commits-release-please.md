# ADR-0009: Conventional Commits and Release-Please Automation

## Status

Accepted

## Date

2024-12 (retroactively documented 2025-12)

## Context

The dotfiles repository and its plugins require versioning and changelog management. Traditional approaches involve:
- Manual version bumps in package manifests
- Hand-written CHANGELOG.md entries
- Remembering to tag releases
- Coordinating version numbers across multiple files

### The Manual Versioning Problem

Manual version management caused:

1. **Inconsistent versions** - Different files showing different versions
2. **Forgotten changelogs** - Features shipped without documentation
3. **Merge conflicts** - Multiple PRs editing CHANGELOG.md simultaneously
4. **Human error** - Wrong version numbers, duplicate entries
5. **Release friction** - Tedious manual steps delayed releases

### Conventional Commits Standard

The [Conventional Commits](https://www.conventionalcommits.org/) specification provides:
- Structured commit messages with semantic meaning
- Machine-readable format for automation
- Human-readable history for understanding changes

**Format:**
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types:**
| Type | Purpose | Version Bump |
|------|---------|--------------|
| `feat` | New feature | Minor (0.x.0) |
| `fix` | Bug fix | Patch (0.0.x) |
| `feat!` | Breaking feature | Major (x.0.0) |
| `BREAKING CHANGE:` | Breaking change footer | Major (x.0.0) |
| `chore` | Maintenance | None |
| `docs` | Documentation | None |
| `refactor` | Code improvement | None |

### Release-Please Tool

Google's [release-please](https://github.com/googleapis/release-please) automates:
1. Analyzing conventional commits since last release
2. Determining semantic version bump
3. Generating CHANGELOG.md entries
4. Updating version fields in manifests
5. Creating release PRs
6. Tagging releases when merged

## Decision

**Adopt conventional commits with release-please automation**, enforced by skill-based protection and permission system.

### Commit Message Convention

All commits must follow conventional commit format:

**Feature (minor bump):**
```
feat(auth): add OAuth2 support

Implements OAuth2 authentication with PKCE.
Includes refresh token rotation.

Refs: #42
```

**Bug fix (patch bump):**
```
fix(api): handle timeout edge case

Fixes race condition in token refresh.

Fixes: #123
```

**Breaking change (major bump):**
```
feat(api)!: redesign authentication

BREAKING CHANGE: Auth endpoint now requires OAuth2.
Migration guide: docs/migration/v2.md
```

### Protected Files

**Hard protection (permission system blocks edits):**
- `**/CHANGELOG.md` - All changelog files

**Soft protection (skill warns before edits):**
- `package.json` - version field
- `pyproject.toml` - version field
- `Cargo.toml` - version field
- `.claude-plugin/plugin.json` - version field

### Permission System Configuration

In `~/.claude/settings.json`:
```json
{
  "permissions": {
    "deny": [
      "Edit(**/CHANGELOG.md)",
      "Write(**/CHANGELOG.md)",
      "MultiEdit(**/CHANGELOG.md)"
    ]
  }
}
```

### Skill-Based Detection

The `release-please-protection` skill:
1. Detects edit attempts to protected files
2. Explains why manual edits cause problems
3. Provides conventional commit templates
4. Suggests proper workflow

**Example response when CHANGELOG.md edit attempted:**
```
⚠️ CHANGELOG.md Protection Active

I cannot edit CHANGELOG.md - it's managed by release-please automation.

**Proper workflow:**
1. Make changes with conventional commit messages
2. Release-please automatically generates changelog entries
3. Review and merge the release PR

**For your change, use:**
feat(scope): your feature description
```

### Automated Workflow

```
Developer commits    →  Conventional commit format
                          ↓
Release-please       →  Analyzes commits since last release
                          ↓
Creates Release PR   →  Updates CHANGELOG.md + version fields
                          ↓
PR merged            →  Tags release, publishes
```

### Emergency Override

For exceptional cases requiring manual edits:

```bash
# 1. Temporarily disable protection
vim ~/.claude/settings.json
# Comment out CHANGELOG.md deny rules

# 2. Make edits

# 3. Re-enable protection
# Uncomment the deny rules

# 4. Sync with chezmoi
chezmoi apply
```

## Consequences

### Positive

1. **Automated changelogs** - No manual CHANGELOG maintenance
2. **Consistent versioning** - Semantic versions derived from commits
3. **No merge conflicts** - Automated PRs don't conflict
4. **Clear history** - Commit messages explain "why"
5. **Reduced friction** - Releases happen automatically
6. **Team alignment** - Everyone follows same convention

### Negative

1. **Learning curve** - Team must learn conventional commit format
2. **Commit discipline** - Requires consistent message formatting
3. **Automation dependency** - Release process depends on tooling
4. **Override complexity** - Emergency manual edits are awkward

### Enforcement Layers

| Layer | Mechanism | Scope |
|-------|-----------|-------|
| Permission system | `deny` rules in settings.json | CHANGELOG.md blocked |
| Skill detection | release-please-protection | Version fields warned |
| Pre-commit hooks | commitlint | Commit format validated |
| CI/CD | GitHub Actions | PR validation |

### Commit Message Checklist

- [ ] Starts with valid type (`feat`, `fix`, `chore`, etc.)
- [ ] Scope in parentheses if applicable
- [ ] Colon and space after type/scope
- [ ] Description in imperative mood
- [ ] Body explains "why" not "what"
- [ ] Footer references issues if applicable
- [ ] Breaking changes marked with `!` or `BREAKING CHANGE:`

## Alternatives Considered

### Manual Versioning
Continue with manual version bumps and changelogs.

**Rejected because**: Error-prone, inconsistent, creates merge conflicts.

### Semantic-Release
Use semantic-release instead of release-please.

**Not rejected**: Both are viable; release-please chosen for its PR-based workflow and multi-language support.

### Git Tags Only
Use git tags for versioning without changelog automation.

**Rejected because**: Loses changelog documentation; doesn't update manifest files.

### Changelog Generator Scripts
Custom scripts to generate changelogs.

**Rejected because**: Reinventing release-please; maintenance burden.

## Related Decisions

- ADR-0006: Documentation-First Development (commits document changes)
- ADR-0004: Subagent-First Delegation (git-commit-workflow skill)
- ADR-0005: Namespace-Based Command Organization (/git:commit command)

## References

- Conventional Commits: https://www.conventionalcommits.org/
- Release-Please: https://github.com/googleapis/release-please
- Protection skill: `exact_dot_claude/skills/release-please-protection/`
- Git commit skill: `exact_dot_claude/skills/git-commit-workflow/`
- Root CLAUDE.md: Release-Please Automation section
