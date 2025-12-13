# Tool Selection

## Primary Strategy - Use Subagents

1. **Explore agent** - For code exploration, codebase research, finding patterns
   - Instead of: Manual Grep/Glob searches across multiple files
   - Use when: Need to understand code structure, find implementations, trace dependencies

2. **Specialized domain agents** - Match task to appropriate agent:
   - `test-runner` → Test execution, failure analysis, concise reporting
   - `test-architecture` → Test strategies, coverage analysis, framework selection
   - `security-audit` → Security analysis, vulnerability assessment
   - `code-review` → Code quality, architecture, performance review
   - `system-debugging` → Complex debugging, root cause analysis
   - `documentation` → Generate docs from code, API references
   - `cicd-pipelines` → GitHub Actions, deployment automation
   - `code-refactoring` → Quality improvements, SOLID principles

3. **General-purpose agent** - For multi-step tasks not matching specific domains

## Secondary Strategy - Direct Tools (Rare)

- **Read** - Single file context gathering (when you know exact file path)
- **Edit** - Simple, single-file edits with clear requirements
- **Write** - Creating new files (only when necessary, prefer editing existing)
- **Bash** - Terminal operations (git, npm, docker - NOT file operations)

## Supporting Tools

- **context7** - Research documentation before implementation (documentation-first principle)
- **sequential-thinking** - Complex reasoning when planning delegation strategy
- **TodoWrite** - Always use for task planning and tracking

## Examples

### CORRECT - Using Subagents

- User: "Find where error handling is implemented" → Use **Explore agent**
- User: "Review this code for security issues" → Use **security-audit agent**
- User: "Debug this performance problem" → Use **system-debugging agent**
- User: "Help me understand the authentication flow" → Use **Explore agent**
- User: "Review, test, and check for security issues" → Launch **code-review** + **test-runner** + **security-audit** in parallel

### INCORRECT - Manual Tool Usage

- User: "Find where error handling is implemented" → Don't use manual Grep/Glob searches
- User: "Review this code" → Don't manually read files and provide ad-hoc review
- User: "This code is broken" → Don't manually debug, use system-debugging agent
- User: "How does auth work?" → Don't manually explore, use Explore agent
