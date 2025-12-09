# MCP Code Execution Patterns

**Source**: [Code Execution with MCP - Anthropic Engineering](https://www.anthropic.com/engineering/code-execution-with-mcp)
**Date**: December 2025
**Status**: Reference architecture (not yet available in Claude Code CLI)

## Executive Summary

This document captures insights from Anthropic's article on code execution with MCP and analyzes their relevance to our Claude Code dotfiles configuration. While the specific implementation described is for Anthropic's internal hosted systems, the architectural principles validate and inform our current MCP management approach.

**TL;DR**: Our project-scoped MCP architecture already embodies the efficiency patterns Anthropic promotes. No immediate changes needed.

---

## The Problem: Context Inefficiency

Anthropic identified two critical inefficiencies in traditional agent-MCP integration:

### 1. Tool Definition Overhead
- **Issue**: Loading all tool definitions upfront consumes excessive context tokens
- **Scale**: With thousands of tools, agents process "hundreds of thousands of tokens before reading a request"
- **Impact**: Wasted context window, slower responses, higher costs

### 2. Intermediate Result Duplication
- **Issue**: Data flows through the model multiple times unnecessarily
- **Example**: A 2-hour transcript consumes an extra 50,000 tokens when passed between tool calls
- **Impact**: Large documents can exceed context limits entirely

---

## The Solution: Code-Driven MCP Integration

Instead of direct tool calls, agents interact with MCP servers through a **code API approach**:

```
Traditional:                    Code Execution:
┌──────────┐                   ┌──────────┐
│  Agent   │◄──────────────────┤  Agent   │
└────┬─────┘                   └────┬─────┘
     │ call tool1()                 │ run code:
     ▼                              │   data = call tool1()
┌──────────┐                        │   filtered = process(data)
│ MCP Tool │                        │   return filtered
└────┬─────┘                        ▼
     │ return 10K rows         ┌──────────────┐
     ▼                         │ Execution    │
┌──────────┐                   │ Environment  │
│  Agent   │                   │ ┌──────────┐ │
└────┬─────┘                   │ │MCP Tools │ │
     │ 10K rows in context     │ └──────────┘ │
     │ call tool2()            └──────────────┘
     ▼                              │
┌──────────┐                        │ return 5 rows
│ MCP Tool │                        ▼
└──────────┘                   ┌──────────┐
                               │  Agent   │
Result: High context usage     └──────────┘
Multiple round trips           Result: 98.7% token savings
                               Single round trip
```

### Key Implementation Details

**File-Based Tool Discovery**:
```typescript
// Tools exposed as TypeScript files
./servers/google-drive/getDocument.ts
./servers/salesforce/updateRecord.ts

// Agent explores and reads on-demand
const tools = await searchTools("spreadsheet");
```

**In-Environment Data Processing**:
```typescript
// Filter before returning to model
const sheet = await gdrive.getSpreadsheet({ id: 'abc123' });
const filtered = sheet.rows.filter(row =>
  row.status === 'pending' && row.priority === 'high'
);
return filtered; // Only 5 rows instead of 10,000
```

**Reusable Skill Modules**:
```typescript
// ./skills/save-sheet-as-csv.ts
export async function saveSheetAsCSV(docId: string) {
  const data = await gdrive.getSpreadsheet({ documentId: docId });
  const csv = convertToCSV(data);
  await filesystem.write('output.csv', csv);
  return 'output.csv';
}
```

### Measured Benefits

**Performance Improvements**:
- 98.7% token reduction (150,000 → 2,000 tokens)
- Faster latency through reduced round trips
- Progressive tool discovery vs. upfront loading

**Privacy & Security**:
- Sensitive data stays in execution environment
- Automatic PII tokenization
- No accidental exposure in logs

---

## Relevance to Our Dotfiles

### ❌ Not Directly Applicable

The article's implementation requires infrastructure not available in Claude Code CLI:

| Requirement | Availability |
|-------------|--------------|
| File-based tool discovery (`./servers/`) | ❌ Not exposed in CLI |
| Sandboxed code execution environment | ❌ Internal to Anthropic |
| TypeScript runtime for tool chaining | ❌ CLI uses different model |

### ✅ Architecturally Aligned

Our current setup already implements the **core principles**:

| Anthropic Pattern | Our Implementation |
|-------------------|-------------------|
| **Progressive tool disclosure** | Project-scoped `.mcp.json` instead of global `~/.claude/settings.json` |
| **Context efficiency** | MCP Management skill suggests only relevant servers per project |
| **Reusable code modules** | 33 skills in `.claude/skills/` for automatic capability discovery |
| **Smart tool discovery** | Skills analyze project structure to suggest MCP servers |
| **State persistence** | Skills can read/write files, store intermediate results |

### Our Current MCP Philosophy

From `CLAUDE.md`:

```markdown
**Philosophy**: MCP servers are managed **project-by-project** to avoid context bloat.

✅ **New approach** (project-scoped in `.mcp.json`):
- Clean context - only relevant MCP servers per project
- Explicit project dependencies
- Team-shareable configuration

❌ **Old approach** (user-scoped in `~/.claude/settings.json`):
- Bloated context in every repository
- All MCP tools available everywhere (even when not needed)
- Hidden dependencies not shared with team
```

This approach **already solves** the tool definition overhead problem Anthropic describes.

---

## Potential Improvements Inspired by the Article

While we can't implement the exact architecture, we can adopt these patterns:

### 1. Data-Processing Skills

Create skills that filter large datasets before presenting to Claude:

```markdown
## Skill: GitHub Issue Processor

When working with large numbers of GitHub issues:
1. Fetch all issues via GitHub MCP
2. Filter based on criteria (labels, state, date)
3. Summarize to key fields only
4. Return compact representation

Example:
- Input: 500 issues (200K tokens)
- Output: 20 matching issues, 5 fields each (2K tokens)
- Savings: 99% context reduction
```

### 2. MCP Tool Chaining Skills

Skills that combine multiple MCP operations:

```markdown
## Skill: GitHub-to-Sentry Workflow

Automates: Fetch GitHub issue → Process → Create Sentry alert

Benefits:
- Single skill invocation vs. 3+ tool calls
- Intermediate data stays in skill logic
- Reusable pattern for common workflows
```

### 3. Tool Discovery Helper

A command or skill for exploring available MCP tools:

```bash
/mcp-tools search "authentication"
# Returns:
# - github: createIssue, updateIssue
# - argocd: syncApplication
```

Similar to the article's `searchTools()` function.

---

## Implementation Roadmap

### Phase 1: Document Current Patterns ✅
- [x] Create this reference document
- [x] Validate alignment with Anthropic's principles
- [x] Identify improvement opportunities

### Phase 2: Data-Processing Skills (Future)
- [ ] Create `github-issue-filter` skill
- [ ] Create `vectorcode-summarizer` skill (for large codebases)
- [ ] Create `playwright-test-reporter` skill (filter verbose logs)

### Phase 3: Tool Chaining Skills (Future)
- [ ] GitHub → Sentry integration skill
- [ ] ArgoCD → Podio sync skill
- [ ] Multi-MCP workflow templates

### Phase 4: Tool Discovery (Future)
- [ ] `/mcp-tools` command for interactive exploration
- [ ] Auto-suggest MCP tools based on conversation context
- [ ] MCP tool usage analytics

---

## Key Takeaways

### What We're Doing Right

✅ **Project-scoped MCP** prevents context bloat from unused tools
✅ **Intelligent MCP suggestions** via MCP Management skill
✅ **Reusable skills directory** enables code-like patterns
✅ **Explicit configuration** in `.mcp.json` for team sharing

### What We're Watching For

🔍 **If Anthropic releases code execution API for Claude Code CLI**:
- File-based tool discovery interface
- Sandboxed execution environment
- TypeScript/JavaScript runtime for tool chaining

🔍 **Community developments**:
- MCP server frameworks that implement filtering patterns
- Tool chaining libraries for Claude Code
- Best practices for context-efficient MCP usage

### Validation

The article **validates our architecture choices** rather than suggesting major changes. Our project-scoped MCP approach already achieves the efficiency goals Anthropic describes, just through configuration rather than code execution.

---

## References

- [Code Execution with MCP - Anthropic Engineering](https://www.anthropic.com/engineering/code-execution-with-mcp)
- [Our MCP Management Documentation](../skills/mcp-management/SKILL.md)
- [Our MCP Philosophy](../../CLAUDE.md#mcp-server-management)

## Changelog

- **2025-12-09**: Initial document created based on Anthropic article analysis
