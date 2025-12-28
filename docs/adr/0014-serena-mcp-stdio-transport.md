# ADR-0014: Serena MCP Server stdio Transport Over Streamable HTTP

## Status

Accepted

## Date

2025-12-27

## Context

Serena is an MCP server providing semantic code retrieval and editing capabilities through Language Server Protocol (LSP) integration. It supports three transport modes:

1. **stdio** (default): Client spawns server as subprocess, communicates via stdin/stdout
2. **Streamable HTTP**: Server runs persistently, clients connect via HTTP endpoint
3. **SSE** (deprecated): Server-Sent Events transport

We evaluated running Serena in Streamable HTTP mode to enable:
- Single persistent server instance
- Reduced overhead from repeated server/LSP startup
- Shared language server state across multiple Claude Code instances

### Transport Comparison

| Aspect | stdio | Streamable HTTP |
|--------|-------|-----------------|
| Server lifecycle | Client-controlled | User-controlled |
| Startup overhead | Per-session | Once |
| LSP initialization | Per-session | Once |
| Multi-client | No | Yes |
| Project context | Automatic | Manual activation required |
| Network exposure | None | localhost (or remote) |
| Configuration | Simple `.mcp.json` | Service manager + client config |

### The Project Context Problem

Serena maintains project-scoped state including:
- Active project path
- Language server connections
- Symbol caches
- Memory files

When running in stdio mode, each Claude Code session:
1. Spawns its own Serena instance
2. Serena reads project context from the working directory
3. LSP connections are established for that specific project

When running in Streamable HTTP mode:
1. Single Serena instance serves all clients
2. Project must be explicitly activated via `activate_project` tool
3. Switching projects affects ALL connected clients
4. No isolation between concurrent Claude Code sessions

This creates a fundamental conflict: **if Instance A is working on `chezmoi` and Instance B activates `claude-plugins`, Instance A's context is corrupted**.

### Investigated Alternatives

**Alternative 1: Multiple HTTP Servers (One Per Project)**

Run separate Serena instances on different ports:
- `localhost:9121/mcp` → chezmoi
- `localhost:9122/mcp` → claude-plugins
- etc.

**Problems:**
- Defeats the purpose of reduced overhead
- Requires complex port management
- Client must know which port maps to which project
- No dynamic project switching within a session

**Alternative 2: Session-Aware Routing**

Modify Serena to support session isolation within a single HTTP server.

**Problems:**
- Requires upstream changes to Serena
- Adds complexity to MCP protocol handling
- LSP connections are inherently single-project

**Alternative 3: Accept Single-Project Limitation**

Use HTTP mode only when working on a single project for extended periods.

**Problems:**
- Workflow friction when context-switching between projects
- Easy to forget which project is active
- Debugging issues from stale project context

## Decision

**Continue using stdio transport for Serena MCP server.**

The perceived overhead savings from persistent HTTP mode do not justify the project context isolation problems. The stdio model provides:

1. **Automatic project detection**: Serena infers project from working directory
2. **Session isolation**: Each Claude Code instance has its own Serena instance
3. **Simplicity**: No service management, port allocation, or manual activation
4. **Reliability**: No cross-session state corruption

## Consequences

### Positive

- **Zero configuration**: Works out of the box with standard `.mcp.json`
- **Project isolation**: Multiple Claude instances can work on different projects simultaneously
- **Predictable behavior**: No hidden state from previous sessions
- **Simpler debugging**: Each session is independent

### Negative

- **Startup overhead**: LSP initialization occurs each session (typically 2-5 seconds)
- **Memory usage**: Each Claude instance runs separate Serena + LSP processes
- **No shared caches**: Symbol resolution repeated across sessions

### Acceptable Trade-offs

The startup overhead is acceptable because:
- LSP initialization is fast for most projects (< 5 seconds)
- Sessions typically last long enough to amortize startup cost
- Memory overhead is negligible on modern systems
- Project isolation is more valuable than shared caching

## Configuration

Standard stdio configuration in `.mcp.json`:

```json
{
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": [
        "--from", "git+https://github.com/oraios/serena",
        "serena", "start-mcp-server",
        "--context", "claude-code"
      ]
    }
  }
}
```

## References

- [Serena GitHub Repository](https://github.com/oraios/serena)
- [Serena Running Documentation](https://oraios.github.io/serena/02-usage/020_running.html)
- [MCP Transports Specification](https://modelcontextprotocol.io/specification/2025-03-26/basic/transports)
- [ADR-0008: Project-Scoped MCP Servers](0008-project-scoped-mcp-servers.md)
