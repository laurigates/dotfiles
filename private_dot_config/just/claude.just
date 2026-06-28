# Claude Code setup — canonical recipes (single source of truth).
#
# Imported by BOTH:
#   • the dotfiles repo justfile (so `just mcp-*` / `just settings-audit` work here), and
#   • the global ~/.config/just/justfile (so `just -g mcp-*` works from ANY directory).
#
# The mcp-* / cclsp / claude-setup recipes run `claude mcp add-json -s project`
# against the CURRENT repo, so being globally invokable from inside any target
# repo is exactly what you want. settings-audit sweeps the ~/repos portfolio
# tree (consistent with plugins-audit in plugins.just, which also hardcodes it).
#
# chezmoi applies this file to ~/.config/just/claude.just; the global justfile
# imports that applied copy. Edit here, then `chezmoi apply`.

# Add Sentry MCP server to project
[group: "claude"]
mcp-sentry:
    claude mcp add-json -s project sentry '{"type": "http", "url": "https://mcp.sentry.dev/mcp"}'

# Add GitHub MCP server to project
[group: "claude"]
mcp-github:
    claude mcp add-json -s project github '{"command": "go", "args": ["run", "github.com/github/github-mcp-server/cmd/github-mcp-server@latest", "stdio"], "env": {"GITHUB_PERSONAL_ACCESS_TOKEN": "$GITHUB_PERSONAL_ACCESS_TOKEN"}}'

# Add Context7 MCP server (documentation lookup)
[group: "claude"]
mcp-context7:
    claude mcp add-json -s project context7 '{"command": "bunx", "args": ["-y", "@upstash/context7-mcp"]}'

# Add Playwright MCP server (browser automation)
[group: "claude"]
mcp-playwright:
    claude mcp add-json -s project playwright '{"command": "bunx", "args": ["-y", "@playwright/mcp@latest"]}'

# Add Sequential Thinking MCP server (multi-step reasoning)
[group: "claude"]
mcp-sequential-thinking:
    claude mcp add-json -s project sequential-thinking '{"command": "bunx", "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]}'

# Add Chrome DevTools MCP server
[group: "claude"]
mcp-chrome-devtools:
    claude mcp add-json -s project chrome-devtools '{"type": "stdio", "command": "bunx", "args": ["chrome-devtools-mcp@latest"], "env": {}}'

# Set up Claude Code Language Server Protocol
[group: "claude"]
cclsp:
    bunx cclsp@latest setup

# Add all MCP servers and set up cclsp
[group: "claude"]
claude-setup: mcp-sentry mcp-github mcp-context7 mcp-playwright mcp-sequential-thinking mcp-chrome-devtools cclsp

# Audit Claude Code settings files for hygiene issues
[group: "claude"]
settings-audit:
    #!/usr/bin/env bash
    set -euo pipefail

    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    DIM='\033[2m'
    BOLD='\033[1m'
    RESET='\033[0m'

    declare -i critical=0 high=0 medium=0 low=0

    finding() {
        local severity="$1" file="$2" detail="$3"
        case "$severity" in
            CRITICAL) printf "${RED}[CRITICAL]${RESET} %s\n  %s\n" "$file" "$detail"; critical+=1 ;;
            HIGH)     printf "${YELLOW}[HIGH]${RESET}     %s\n  %s\n" "$file" "$detail"; high+=1 ;;
            MEDIUM)   printf "${YELLOW}[MEDIUM]${RESET}   %s\n  %s\n" "$file" "$detail"; medium+=1 ;;
            LOW)      printf "${DIM}[LOW]${RESET}      %s\n  %s\n" "$file" "$detail"; low+=1 ;;
        esac
    }

    # Find all Claude settings files (exclude node_modules, worktrees)
    mapfile -t files < <(fd -t f 'settings(\.local)?\.json$' ~/repos/.claude ~/repos/*/.claude ~/repos/*/*/.claude \
        --exclude node_modules --exclude worktrees 2>/dev/null | sort -u)

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No settings files found."
        exit 0
    fi

    echo "${BOLD}Scanning ${#files[@]} settings files...${RESET}"
    echo ""

    for file in "${files[@]}"; do
        content=$(cat "$file")

        # 1. CRITICAL: Hardcoded credentials in permission strings
        while IFS= read -r match; do
            [[ -z "$match" ]] && continue
            finding "CRITICAL" "$file" "Hardcoded credential: $match"
        done < <(echo "$content" | grep -oE '(PGPASSWORD|TOKEN|SECRET|PASSWORD|API_KEY|PRIVATE_KEY)=[^"\\]+' 2>/dev/null || true)

        # 2. HIGH: Old MCP naming (plugin_ prefix)
        while IFS= read -r match; do
            [[ -z "$match" ]] && continue
            finding "HIGH" "$file" "Old MCP naming: $match"
        done < <(echo "$content" | grep -oE 'mcp__plugin_[a-zA-Z0-9_]+__[a-zA-Z0-9_]+' 2>/dev/null || true)

        # 3. HIGH: Bash loop artifacts
        while IFS= read -r match; do
            [[ -z "$match" ]] && continue
            finding "HIGH" "$file" "Bash loop artifact: $match"
        done < <(echo "$content" | grep -oE 'Bash\((done|do echo|for [a-z]+ in)' 2>/dev/null || true)

        # 4. MEDIUM: Hardcoded absolute paths in Bash permissions
        while IFS= read -r match; do
            [[ -z "$match" ]] && continue
            finding "MEDIUM" "$file" "Hardcoded absolute path: $match"
        done < <(echo "$content" | grep -oE 'Bash\((git -C|cd) /Users/[^"]+' 2>/dev/null || true)

        # 5. MEDIUM: Overly broad wildcards
        while IFS= read -r match; do
            [[ -z "$match" ]] && continue
            finding "MEDIUM" "$file" "Overly broad wildcard: $match"
        done < <(echo "$content" | grep -oE 'Bash\(\* [a-z]+ \*\)' 2>/dev/null || true)
        # mcp__* in shared (non-local) settings
        if [[ "$file" != *".local."* ]]; then
            while IFS= read -r match; do
                [[ -z "$match" ]] && continue
                finding "MEDIUM" "$file" "Broad MCP wildcard in shared settings: $match"
            done < <(echo "$content" | grep -oE '"mcp__\*"' 2>/dev/null || true)
        fi

        # 6. LOW: Global-redundant permissions (tools already in ~/.claude/settings.json global allows)
        # Only check local/project settings, not the global file itself
        if [[ "$file" != "$HOME/.claude/settings.json" ]]; then
            # Only flag wildcard patterns (e.g. "Bash(rg *)") not specific commands
            global_redundant_patterns=('Bash\(rg[ :]?\*' 'Bash\(ls[ :]?\*' 'Bash\(fd[ :]?\*' 'Bash\(grep[ :]?\*' 'Bash\(find[ :]?\*' 'Bash\(jq[ :]?\*' 'Bash\(echo[ :]?\*' 'Bash\(sort[ :]?\*' 'Bash\(wc[ :]?\*' 'Bash\(git status[ :]?\*' 'Bash\(git diff[ :]?\*' 'Bash\(git log[ :]?\*' 'Bash\(gh pr[ :]?\*' 'Bash\(gh issue[ :]?\*')
            for pat in "${global_redundant_patterns[@]}"; do
                while IFS= read -r match; do
                    [[ -z "$match" ]] && continue
                    finding "LOW" "$file" "Redundant with global settings: $match"
                done < <(echo "$content" | grep -oE "${pat}[^\"]*" 2>/dev/null || true)
            done
        fi

        # 7. LOW: MCP contradictions (server in both enabled and disabled)
        if command -v jq &>/dev/null; then
            enabled=$(echo "$content" | jq -r '.enabledMcpjsonServers // [] | .[]' 2>/dev/null || true)
            disabled=$(echo "$content" | jq -r '.disabledMcpjsonServers // [] | .[]' 2>/dev/null || true)
            if [[ -n "$enabled" && -n "$disabled" ]]; then
                while IFS= read -r server; do
                    [[ -z "$server" ]] && continue
                    if echo "$disabled" | grep -qF "$server"; then
                        finding "LOW" "$file" "MCP server in both enabled and disabled: $server"
                    fi
                done <<< "$enabled"
            fi
            # Check for permissions referencing disabled MCP servers
            if [[ -n "$disabled" ]]; then
                while IFS= read -r server; do
                    [[ -z "$server" ]] && continue
                    if echo "$content" | grep -q "mcp__${server}__"; then
                        finding "LOW" "$file" "Permission references disabled MCP server: $server"
                    fi
                done <<< "$disabled"
            fi
        fi
    done

    # Summary
    total=$((critical + high + medium + low))
    echo ""
    if [[ $total -eq 0 ]]; then
        echo "${BOLD}No issues found.${RESET}"
    else
        echo "${BOLD}Summary:${RESET} $total issue(s) found"
        [[ $critical -gt 0 ]] && printf "  ${RED}CRITICAL: %d${RESET}\n" "$critical"
        [[ $high -gt 0 ]]     && printf "  ${YELLOW}HIGH:     %d${RESET}\n" "$high"
        [[ $medium -gt 0 ]]   && printf "  ${YELLOW}MEDIUM:   %d${RESET}\n" "$medium"
        [[ $low -gt 0 ]]      && printf "  ${DIM}LOW:      %d${RESET}\n" "$low"
    fi

    # Exit non-zero if any critical or high issues
    if [[ $((critical + high)) -gt 0 ]]; then
        exit 1
    fi
