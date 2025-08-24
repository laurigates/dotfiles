#!/bin/bash

# Claude Code Status Overlay
# Displays a comprehensive dashboard of all active Claude sessions
# Triggered by kitty overlay hotkey (Cmd+Shift+C)

set -euo pipefail

# Source the shared parsing library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/claude-session-parser.sh"

# Colors for status display
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Status icons and colors
get_status_display() {
    local status="$1"
    case "$status" in
        "active")
            echo -e "${GREEN}🟢 Active${NC}"
            ;;
        "needs_input")
            echo -e "${RED}🔴 Input${NC}"
            ;;
        "idle")
            echo -e "${GRAY}⚪ Idle${NC}"
            ;;
        *)
            echo -e "${YELLOW}❓ Unknown${NC}"
            ;;
    esac
}

# Format todo count with visual indicators
format_todo_count() {
    local total="$1"
    local pending="$2"
    local completed="$3"

    if [[ "$total" == "0" ]]; then
        echo -e "${GRAY}0/0 ✓${NC}"
    elif [[ "$pending" == "0" ]]; then
        echo -e "${GREEN}${completed}/${total} ✓${NC}"
    else
        echo -e "${CYAN}${pending}/${total} 📝${NC}"
    fi
}

# Truncate project name to fit display
truncate_project() {
    local project="$1"
    local max_length=20

    if [[ ${#project} -gt $max_length ]]; then
        echo "${project:0:$((max_length-3))}..."
    else
        printf "%-${max_length}s" "$project"
    fi
}

# Truncate branch name
truncate_branch() {
    local branch="$1"
    local max_length=12

    if [[ ${#branch} -gt $max_length ]]; then
        echo "${branch:0:$((max_length-3))}..."
    else
        printf "%-${max_length}s" "$branch"
    fi
}

# Display the main dashboard
show_dashboard() {
    clear

    # Header
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│                           Claude Code Sessions                                │${NC}"
    echo -e "${WHITE}├─────────────────────┬─────────────┬──────────────┬────────┬──────────────────┤${NC}"
    echo -e "${WHITE}│       Project       │   Branch    │    Todos     │  Last  │      Status      │${NC}"
    echo -e "${WHITE}├─────────────────────┼─────────────┼──────────────┼────────┼──────────────────┤${NC}"

    local session_count=0
    local has_sessions=false

    # Process each active session
    while IFS= read -r session_line; do
        if [[ -n "$session_line" ]]; then
            has_sessions=true
            local full_status
            full_status=$(get_full_session_status "$session_line")
            IFS='|' read -r project_name git_branch status total_todos pending_todos completed_todos time_ago session_id <<< "$full_status"

            local project_display branch_display todo_display status_display
            project_display=$(truncate_project "$project_name")
            branch_display=$(truncate_branch "$git_branch")
            todo_display=$(format_todo_count "$total_todos" "$pending_todos" "$completed_todos")
            status_display=$(get_status_display "$status")

            echo -e "${WHITE}│${NC} $project_display ${WHITE}│${NC} $branch_display ${WHITE}│${NC} $todo_display ${WHITE}│${NC} $(printf "%6s" "$time_ago") ${WHITE}│${NC} $status_display ${WHITE}│${NC}"
            ((session_count++))
        fi
    done < <(get_active_sessions)

    if [[ "$has_sessions" == "false" ]]; then
        echo -e "${WHITE}│${NC}                           ${GRAY}No active sessions found${NC}                           ${WHITE}│${NC}"
    fi

    echo -e "${WHITE}└─────────────────────┴─────────────┴──────────────┴────────┴──────────────────┘${NC}"
    echo ""

    # Summary line
    if [[ $session_count -gt 0 ]]; then
        local summary
        summary=$(get_status_summary)
        IFS='|' read -r total active needs_input idle overall <<< "$summary"

        echo -e "${CYAN}Sessions:${NC} $total total, ${GREEN}$active active${NC}, ${RED}$needs_input need input${NC}, ${GRAY}$idle idle${NC}"
    fi

    echo ""
    echo -e "${GRAY}Press 'r' to refresh, 'h' for help, 'q' or Esc to close${NC}"
}

# Show help
show_help() {
    clear
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│                         Claude Code Monitor - Help                            │${NC}"
    echo -e "${WHITE}├────────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│${NC}                                                                                ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Status Indicators:${NC}                                                          ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}   🟢 Active      - Session active within last 2 minutes                      ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}   🔴 Input       - Session waiting for user input                            ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}   ⚪ Idle        - Session inactive for more than 10 minutes                ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}                                                                                ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Todo Indicators:${NC}                                                           ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}   ✓             - All todos completed                                         ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}   📝            - Pending todos remaining                                     ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}   0/0 ✓         - No todos in this session                                   ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}                                                                                ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Time Format:${NC}                                                              ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}   s/m/h/d       - Seconds/Minutes/Hours/Days since last activity            ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}                                                                                ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Data Source:${NC}                                                              ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}   Reads ~/.claude/projects/ and ~/.claude/todos/ for session information    ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}                                                                                ${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${GRAY}Press any key to return to dashboard${NC}"
}

# Interactive mode
interactive_mode() {
    while true; do
        show_dashboard

        # Read single character without pressing Enter
        read -n1 -s key

        case "$key" in
            'r'|'R')
                continue  # Refresh dashboard
                ;;
            'h'|'H')
                show_help
                read -n1 -s  # Wait for any key
                ;;
            'q'|'Q'|$'\e')  # q, Q, or Esc
                break
                ;;
            *)
                # Any other key, just refresh
                continue
                ;;
        esac
    done
}

# Main execution
main() {
    # Ensure the parsing library is available
    if [[ ! -f "$SCRIPT_DIR/lib/claude-session-parser.sh" ]]; then
        echo "Error: Claude session parser library not found at $SCRIPT_DIR/lib/claude-session-parser.sh"
        echo "Please ensure the monitoring system is properly installed."
        exit 1
    fi

    # Check if Claude directory exists
    if [[ ! -d "$HOME/.claude" ]]; then
        echo "Error: ~/.claude directory not found."
        echo "This script requires Claude Code to be installed and configured."
        exit 1
    fi

    # Set terminal title
    printf '\033]0;Claude Code Monitor\007'

    # Start interactive mode
    interactive_mode

    # Clear and exit
    clear
    echo "Claude Code Monitor closed."
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
