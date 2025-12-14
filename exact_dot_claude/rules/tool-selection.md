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

## Secondary Strategy - Direct Search Tools

For quick, targeted searches, use these CLI tools directly via Bash instead of delegating:

- **fd** - Fast file finding by name, extension, or pattern
  - `fd -e ts` - Find all TypeScript files
  - `fd -t f config` - Find files with "config" in name
  - `fd -e md -x head -5` - Find markdown files and preview
- **rg** (ripgrep) - Fast text/regex search across files
  - `rg "TODO|FIXME"` - Find all TODOs
  - `rg -t py "def.*async"` - Find async functions in Python
  - `rg -l "import React"` - List files importing React
- **ast-grep** - Structural/semantic code search using AST patterns
  - `ast-grep -p '$FUNC($ARGS)'` - Find function calls
  - `ast-grep -p 'console.log($MSG)'` - Find console.log statements
  - `ast-grep -p 'if ($COND) { return }' --lang ts` - Find early returns

### When to use direct search vs. Explore agent

| Scenario | Tool |
|----------|------|
| Find files by name/extension | `fd` |
| Find specific text/pattern | `rg` |
| Find code structure/pattern | `ast-grep` |
| Understand how code works | Explore agent |
| Trace dependencies/flow | Explore agent |
| Multi-step investigation | Explore agent |

## Other Direct Tools (Rare)

- **Read** - Single file context gathering (when you know exact file path)
- **Edit** - Simple, single-file edits with clear requirements
- **Write** - Creating new files (only when necessary, prefer editing existing)
- **Bash** - Terminal operations (git, npm, docker - NOT file operations)

## Supporting Tools

- **context7** - Research documentation before implementation (documentation-first principle)
- **sequential-thinking** - Complex reasoning when planning delegation strategy
- **TodoWrite** - Always use for task planning and tracking

## Examples

### CORRECT - Quick Searches with CLI Tools

- User: "Find all TypeScript files" → `fd -e ts`
- User: "Find files with 'config' in the name" → `fd config`
- User: "Where is TODO used?" → `rg TODO`
- User: "Find all async functions" → `rg "async function"` or `ast-grep -p 'async function $NAME($$$) { $$$ }'`
- User: "Find console.log statements" → `ast-grep -p 'console.log($$$)'`
- User: "Find React useState hooks" → `ast-grep -p 'const [$STATE, $SETTER] = useState($INIT)'`

### CORRECT - Using Subagents (for understanding/investigation)

- User: "How does error handling work in this codebase?" → Use **Explore agent**
- User: "Review this code for security issues" → Use **security-audit agent**
- User: "Debug this performance problem" → Use **system-debugging agent**
- User: "Help me understand the authentication flow" → Use **Explore agent**
- User: "Review, test, and check for security issues" → Launch **code-review** + **test-runner** + **security-audit** in parallel

### INCORRECT - Wrong Tool Choice

- User: "Find all .yaml files" → Don't use Explore agent, just `fd -e yaml`
- User: "Where is SECRET_KEY defined?" → Don't delegate, just `rg "SECRET_KEY"`
- User: "How does the auth system work?" → Don't use rg/fd, use Explore agent
- User: "Review this code" → Don't manually read files, use code-review agent
