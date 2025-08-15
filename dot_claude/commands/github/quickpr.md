# quickpr.md - Quick Pull Request Instructions for Claude

When the user types `/quickpr`, follow these instructions to execute a quick workflow that branches, commits current changes intelligently, pushes branch, and creates a pull request.

## Step-by-Step Instructions

- Create branch if on main branch and switch to it
- Stage only relevant files explicitly in one `git add` command
- Analyze staged files to create meaningful conventional commit
- Push changes to origin
- Create a pull request with a concise description using GitHub MCP or gh cli if GitHub MCP fails
