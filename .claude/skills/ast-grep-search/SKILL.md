---
name: ast-grep Search
description: AST-based code search using ast-grep for structural pattern matching. Use when searching for code patterns, refactoring, or performing semantic code analysis across multiple languages.
allowed-tools: Bash, Read, Grep, Glob
---

# ast-grep Search

Expert knowledge for using `ast-grep` as a powerful AST-based code search and refactoring tool with structural pattern matching across 20+ programming languages.

## Core Expertise

**ast-grep Advantages**
- AST-based matching (more precise than text-based tools)
- Extremely fast (written in Rust, multi-core processing)
- Supports 20+ languages via tree-sitter
- Pattern code syntax (write code to match code)
- Built-in rewriting capabilities
- Interactive mode for safe transformations
- Language server protocol support

**Supported Languages**
JavaScript, TypeScript, Python, Java, Go, Rust, C++, C, C#, Ruby, PHP, Swift, Kotlin, Scala, HTML, CSS, YAML, JSON, and more.

## Basic Usage

### Simple Pattern Search
```bash
# Basic pattern matching
ast-grep -p 'console.log($MSG)' --lang js
ast-grep -p 'function $NAME($$$ARGS) { $$$ }' --lang js
ast-grep -p 'def $FUNC($$$): $$$' --lang py

# Search in specific files/directories
ast-grep -p 'import $PKG' src/
ast-grep -p 'class $NAME:' tests/ --lang py
```

### Pattern Syntax

**Meta Variables (Wildcards)**
- `$VAR` - Match any single AST node (named node)
- `$$VAR` - Match any single unnamed node
- `$$$ARGS` - Match zero or more nodes (e.g., function arguments)
- `$_` - Match single node without capturing

**Naming Rules**
- Must start with `$`
- Followed by uppercase letters, underscores, or digits
- Valid: `$MATCH`, `$META_VAR`, `$VAR1`, `$_`, `$_123`
- Invalid: `$invalid`, `$Svalue`, `$KEBAB-CASE`

### Language Selection
```bash
# Specify language explicitly
ast-grep -p 'pattern' --lang js
ast-grep -p 'pattern' --lang py
ast-grep -p 'pattern' --lang rs
ast-grep -p 'pattern' --lang go

# Common language codes
# js/ts/jsx/tsx - JavaScript/TypeScript
# py - Python
# rs - Rust
# go - Go
# java - Java
# cpp/c - C++/C
# rb - Ruby
# php - PHP
```

## Advanced Pattern Matching

### Capturing and Reusing Variables
```bash
# Match same variable used twice
ast-grep -p '$A == $A' --lang js  # Matches: x == x (not x == y)

# Multiple captures with same name must match identically
ast-grep -p 'if ($COND) { $$$ } else if ($COND) { $$$ }' --lang js

# Use underscore prefix to allow different matches
ast-grep -p '$_VAR == $_VAR' --lang js  # Matches: x == y
```

### Multi-node Matching
```bash
# Match function calls with any number of arguments
ast-grep -p 'console.log($$$)' --lang js
# Matches: console.log(), console.log(x), console.log(x, y, z)

# Match function definitions with any parameters
ast-grep -p 'function $NAME($$$PARAMS) { $$$BODY }' --lang js

# Match try-catch blocks
ast-grep -p 'try { $$$ } catch ($ERR) { $$$ }' --lang js
```

### Nested Patterns
```bash
# Find nested function calls
ast-grep -p 'React.useState($$$)' --lang jsx

# Find method chains
ast-grep -p '$OBJ.$METHOD1().$METHOD2()' --lang js

# Find specific imports
ast-grep -p "import { $$$IMPORTS } from '$PKG'" --lang js
```

## Code Search and Rewrite

### Search and Replace
```bash
# Basic rewrite
ast-grep -p 'var $VAR = $VAL' -r 'let $VAR = $VAL' --lang js

# Update function syntax
ast-grep -p 'function($$$ARGS) { $$$BODY }' \
         -r '($$$ARGS) => { $$$BODY }' --lang js

# Replace deprecated API calls
ast-grep -p 'oldAPI($$$ARGS)' -r 'newAPI($$$ARGS)' --lang py
```

### Interactive Mode
```bash
# Review changes before applying
ast-grep -p 'var $V = $X' -r 'let $V = $X' -i --lang js

# Update all automatically (use with caution)
ast-grep -p 'console.log($$$)' -r '// removed log' -U --lang js
```

### Dry Run and Preview
```bash
# Show what would be changed without modifying files
ast-grep -p 'pattern' -r 'replacement' --lang js
# (Default behavior - shows matches and proposed changes)

# Apply changes to all files
ast-grep -p 'pattern' -r 'replacement' -U --lang js
```

## Command-Line Options

### Main Commands

**ast-grep run** - One-time search or rewrite (default)
```bash
ast-grep run -p 'pattern' [PATHS]
ast-grep -p 'pattern' -r 'rewrite' -l js src/
```

**ast-grep scan** - Scan using YAML configuration
```bash
ast-grep scan -c sgconfig.yml
ast-grep scan -r rule-name
ast-grep scan --filter 'pattern'
```

**ast-grep test** - Test ast-grep rules
```bash
ast-grep test
ast-grep test -c custom-config.yml
```

**ast-grep new** - Create new project/rules/tests
```bash
ast-grep new project my-linter
ast-grep new rule no-console-log
ast-grep new test test-suite
```

### Common Flags

| Flag | Purpose | Example |
|------|---------|---------|
| `-p, --pattern` | Search pattern | `ast-grep -p 'console.log($MSG)'` |
| `-r, --rewrite` | Replacement pattern | `ast-grep -p 'var $V' -r 'let $V'` |
| `-l, --lang` | Target language | `ast-grep -p 'pattern' -l js` |
| `-i, --interactive` | Interactive mode | `ast-grep -p 'old' -r 'new' -i` |
| `-U, --update-all` | Auto-apply all changes | `ast-grep -p 'old' -r 'new' -U` |
| `--json` | JSON output | `ast-grep -p 'pattern' --json` |
| `-A, -B, -C` | Context lines | `ast-grep -p 'pattern' -A 3` |
| `--color` | Color output | `ast-grep -p 'pattern' --color always` |

### Output Formats

```bash
# Default: colorized, grouped by file
ast-grep -p 'pattern'

# JSON output (for tooling integration)
ast-grep -p 'pattern' --json

# Pretty JSON
ast-grep -p 'pattern' --json=pretty

# Stream JSON (one result per line)
ast-grep -p 'pattern' --json=stream

# Compact JSON
ast-grep -p 'pattern' --json=compact
```

## Language-Specific Patterns

### JavaScript/TypeScript
```bash
# Find React hooks
ast-grep -p 'const [$STATE, $SETTER] = useState($INIT)' --lang jsx

# Find async functions
ast-grep -p 'async function $NAME($$$) { $$$ }' --lang js

# Find class methods
ast-grep -p 'class $CLASS { $METHOD($$$) { $$$ } }' --lang ts

# Find import statements
ast-grep -p "import $NAME from '$PKG'" --lang js
```

### Python
```bash
# Find class definitions
ast-grep -p 'class $NAME($$$BASES): $$$' --lang py

# Find decorators
ast-grep -p '@$DECORATOR\ndef $FUNC($$$): $$$' --lang py

# Find comprehensions
ast-grep -p '[$EXPR for $VAR in $ITER]' --lang py

# Find context managers
ast-grep -p 'with $RESOURCE as $VAR: $$$' --lang py
```

### Rust
```bash
# Find function definitions
ast-grep -p 'fn $NAME($$$) -> $RET { $$$ }' --lang rs

# Find struct definitions
ast-grep -p 'struct $NAME { $$$FIELDS }' --lang rs

# Find impl blocks
ast-grep -p 'impl $TRAIT for $TYPE { $$$ }' --lang rs

# Find unsafe blocks
ast-grep -p 'unsafe { $$$ }' --lang rs
```

### Go
```bash
# Find function definitions
ast-grep -p 'func $NAME($$$) $RET { $$$ }' --lang go

# Find struct definitions
ast-grep -p 'type $NAME struct { $$$FIELDS }' --lang go

# Find defer statements
ast-grep -p 'defer $FUNC($$$)' --lang go

# Find goroutines
ast-grep -p 'go $FUNC($$$)' --lang go
```

## Practical Use Cases

### Code Quality and Linting
```bash
# Find console.log statements (debugging leftovers)
ast-grep -p 'console.log($$$)' --lang js

# Find TODO comments embedded in code
ast-grep -p '// TODO: $$$' --lang js

# Find magic numbers
ast-grep -p 'if ($VAR > 100)' --lang py

# Find unused variables (simple heuristic)
ast-grep -p 'const $VAR = $$$' --lang js | grep -v 'used'
```

### Security Analysis
```bash
# Find eval usage
ast-grep -p 'eval($$$)' --lang js

# Find SQL string concatenation (potential injection)
ast-grep -p '"SELECT * FROM " + $VAR' --lang py

# Find password variables
ast-grep -p 'password = $$$' --lang py

# Find dangerous shell calls
ast-grep -p 'os.system($$$)' --lang py
```

### Refactoring Patterns
```bash
# Replace var with let/const
ast-grep -p 'var $V = $X' -r 'const $V = $X' --lang js -U

# Convert function to arrow function
ast-grep -p 'function($$$ARGS) { return $EXPR }' \
         -r '($$$ARGS) => $EXPR' --lang js -i

# Update import paths
ast-grep -p "import $NAME from '@old/$PATH'" \
         -r "import $NAME from '@new/$PATH'" --lang ts -U

# Rename API calls
ast-grep -p 'oldAPI.$METHOD($$$)' \
         -r 'newAPI.$METHOD($$$)' --lang py -i
```

### Finding Definitions
```bash
# Find all function definitions
ast-grep -p 'function $NAME($$$) { $$$ }' --lang js
ast-grep -p 'def $NAME($$$): $$$' --lang py
ast-grep -p 'fn $NAME($$$) { $$$ }' --lang rs

# Find all class definitions
ast-grep -p 'class $NAME { $$$ }' --lang js
ast-grep -p 'class $NAME: $$$' --lang py
ast-grep -p 'struct $NAME { $$$ }' --lang rs

# Find all interface definitions
ast-grep -p 'interface $NAME { $$$FIELDS }' --lang ts
```

### Finding Usage
```bash
# Find function calls
ast-grep -p '$FUNC($$$)' --lang js

# Find method calls
ast-grep -p '$OBJ.$METHOD($$$)' --lang py

# Find specific library usage
ast-grep -p 'requests.get($$$)' --lang py
ast-grep -p 'axios.post($$$)' --lang js
```

## Configuration-Based Scanning

### YAML Rule Files

Create a `sgconfig.yml` file:

```yaml
rules:
  - id: no-console-log
    message: Remove console.log
    severity: warning
    language: JavaScript
    pattern: console.log($$$)

  - id: prefer-const
    message: Use const instead of var
    severity: error
    language: JavaScript
    pattern: var $VAR = $VAL
    fix: const $VAR = $VAL
```

Then run:
```bash
ast-grep scan
ast-grep scan -r no-console-log
ast-grep scan --filter 'console'
```

## Integration with Other Tools

### Pipe to other commands
```bash
# Count matches
ast-grep -p 'pattern' --json=stream | wc -l

# Extract matched files
ast-grep -p 'pattern' --json=stream | jq -r '.file' | sort -u

# Open files in editor
ast-grep -p 'TODO' --json=stream | jq -r '.file' | xargs nvim

# Combine with grep for post-filtering
ast-grep -p 'function $NAME($$$) { $$$ }' --lang js | grep -i 'async'
```

### Combine with fd/find
```bash
# Search only in specific file patterns
fd -e js -e ts | xargs ast-grep -p 'pattern'

# Search in git-tracked files only
git ls-files '*.py' | xargs ast-grep -p 'pattern'
```

## Performance Tips

**Fast Searches**
- Use specific language with `-l/--lang` flag
- Narrow down search paths (e.g., `src/` instead of `.`)
- Use simpler patterns when possible
- Leverage multi-core processing (default)

**Large Codebases**
- Use `--json=stream` for incremental processing
- Combine with `fd` to filter files first
- Use configuration files instead of CLI for complex rules
- Consider running on subsets and combining results

## Best Practices

**When to Use ast-grep**
- Structural code refactoring
- Finding complex code patterns
- Multi-language code analysis
- Precise code transformations
- Custom linting rules
- Semantic code search

**When to Use grep/ripgrep Instead**
- Simple text search
- Searching non-code files
- Literal string matching
- When language is unknown
- Quick one-off searches

**Common Mistakes to Avoid**
- Forgetting to specify language (`--lang`)
- Using too generic patterns that match unintended code
- Not testing rewrites in interactive mode first
- Forgetting that `$VAR` matches single nodes (use `$$$` for multiple)
- Not escaping special characters in patterns

## Quick Reference

### Essential Pattern Syntax

| Pattern | Matches | Example |
|---------|---------|---------|
| `$VAR` | Single named AST node | `console.log($MSG)` |
| `$$VAR` | Single unnamed node | `$$EXPR` |
| `$$$ARGS` | Zero or more nodes | `func($$$ARGS)` |
| `$_` | Unnamed capture | `$_ == $_` |

### Common Language Codes

| Code | Language |
|------|----------|
| `js` | JavaScript |
| `ts` | TypeScript |
| `jsx` | JavaScript (JSX) |
| `tsx` | TypeScript (JSX) |
| `py` | Python |
| `rs` | Rust |
| `go` | Go |
| `java` | Java |
| `cpp` | C++ |
| `c` | C |
| `rb` | Ruby |
| `php` | PHP |

### Common Workflow Commands

```bash
# 1. Search for pattern
ast-grep -p 'pattern' --lang js src/

# 2. Preview rewrite
ast-grep -p 'old' -r 'new' --lang py

# 3. Interactive rewrite
ast-grep -p 'old' -r 'new' -i --lang js

# 4. Batch rewrite
ast-grep -p 'old' -r 'new' -U --lang ts

# 5. Configuration-based scan
ast-grep scan -c sgconfig.yml

# 6. Test rules
ast-grep test
```

This makes ast-grep an invaluable tool for precise, AST-based code search and transformation across polyglot codebases.
