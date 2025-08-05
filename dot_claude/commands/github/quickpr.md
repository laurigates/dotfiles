# quickpr.md - Quick Pull Request Instructions for Claude

When the user types `/quickpr`, follow these instructions to execute a quick workflow that branches, commits current changes intelligently, pushes branch, and creates a pull request.

## Overview

Execute a streamlined workflow that:

1. Creates a new branch with intelligent naming
2. Detects and excludes build artifacts from commits
3. Stages files in meaningful chunks (not "git add .")
4. Generates intelligent commit messages
5. Pushes branch and creates pull request via GitHub MCP

## Step-by-Step Instructions

- Create branch if on main branch and switch to it
- Intelligent File Staging and Commit
- Detect and handle build artifacts
- Scan for common build artifacts and add missing patterns to `.gitignore`
- Check if .gitignore exists, create if not
  - For each detected build artifact type, add patterns if not already present
  - Only add patterns for artifacts that actually exist in the repository
- Stage all relevant files explicitly in one `git add` command. Never use `git add .`
- Generate intelligent commit message
- Analyze staged files to create meaningful conventional commit
  - Create commit
  - Create PR using GitHub MCP

## Command Options Handling

Handle these command variations:

**Basic usage:**

- `/quickpr` - Auto-generate everything
- `/quickpr feature/new-auth "feat: add authentication"` - Specify branch and message

**With options:**

- `/quickpr --auto` - Explicit auto-generation mode
- `/quickpr --draft` - Create as draft PR
- `/quickpr --issue 123` - Link to specific issue
- `/quickpr --type feat --scope auth` - Override detected type/scope

**Interactive prompting when missing:**

1. Branch name (show auto-generated suggestion)
2. Commit message (show generated suggestion)
3. PR title (defaults to commit message)
4. Draft status confirmation
5. Issue linking (optional)

## Error Handling

**No changes found after filtering:**

```
❌ No changes found to commit after excluding build artifacts

Found but excluded:
🚫 Build artifacts: __pycache__/, node_modules/, dist/

Suggestions:
- Check 'git status' for actual changes
- Use 'git add --force <file>' to include specific files if needed
- Review updated .gitignore for new exclusions
```

**Build artifacts detected:**

```
⚠️  Build artifacts detected and automatically excluded:
- __pycache__/ (Python bytecode)
- node_modules/ (Node.js dependencies)
- target/ (Rust build output)

✅ Added to .gitignore:
- __pycache__/
- *.pyc
- node_modules/

To force include build artifacts: git add --force <filename>
```

**Branch already exists:**

```
❌ Branch {branch-name} already exists

Options:
1. Switch to existing branch: git checkout {branch-name}
2. Use different branch name
3. Delete existing branch: git branch -D {branch-name} (if safe)
```

**No GitHub MCP available:**

```
❌ GitHub MCP not available for PR creation

Branch created and pushed: {branch-name}
Manual PR creation required at: https://github.com/{owner}/{repo}/compare/{branch-name}
```

## Success Reporting

Report detailed results:

```
✅ /quickpr completed successfully!

📊 **Commit Summary:**
📁 Source files: src/auth.py, src/utils.js (2 files)
🧪 Test files: tests/test_auth.py (1 file)
⚙️ Config files: pyproject.toml (1 file)
🚫 Build artifacts excluded: __pycache__/, *.pyc

🌿 **Branch:** feature/user-authentication
📝 **Commit:** feat(auth): add user authentication system
🔗 **PR:** #123 - Add user authentication system
🌐 **URL:** https://github.com/owner/repo/pull/123

🛡️ **.gitignore updated with:**
- __pycache__/
- *.pyc
- dist/

📋 **Next steps:**
- Monitor CI pipeline status
- Request reviews when ready
- Address any feedback or failing checks
```

## Integration Requirements

**Required tools:**

- Git command line access
- GitHub MCP for PR creation and repository context
- **Context7 MCP for documentation lookup (when working with package managers or tools)**
- Clean working directory or user confirmation
- Modern package managers: uv (Python), npm/bun (JavaScript), cargo (Rust)

**Repository requirements:**

- Write access to repository
- Remote repository configured
- Appropriate branch permissions

**Best practices:**

- Always exclude build artifacts automatically
- Stage files in logical, meaningful groups
- Generate conventional commit messages
- Maintain clean .gitignore
- Use GitHub MCP's context toolset for repository awareness
- **Use Context7 MCP for current documentation when encountering package management or build tool files**
- **For package managers (uv, npm, bun, etc.)**: Always verify current best practices via Context7 before suggesting commands
- Provide clear feedback on what was included/excluded
