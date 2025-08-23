# quickpr.md - Quick Pull Request Instructions for Claude

When the user types `/quickpr`, follow these instructions to execute a quick workflow that branches, commits current changes intelligently, pushes branch, and creates a pull request.

## Step-by-Step Instructions

- Use this command to get the repo name with owner: `gh repo view --json nameWithOwner`
- If on the main branch, create a new branch using `git switch -c <branch_name>`
- View the diff using `git diff --word-diff --diff-algorithm=histogram`
- Group the changes into a logical set of commits. Keep commits to a manageable size for readability and so they are easy to understand
  - Write a concise and humble conventional commit messages based on the staged content
- Push to origin and create a pull request
  - Write a concise and humble PR description using the GitHub MCP
