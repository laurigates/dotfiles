#!/usr/bin/env bash
# Generate zsh completion for Claude CLI
# This script parses `claude --help` and subcommand outputs to automatically
# create and maintain the zsh completion function

set -euo pipefail

# Colors and formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Directories and files
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly COMPLETION_FILE="${DOTFILES_DIR}/dot_zfunc/_claude"
readonly TEMP_DIR="$(mktemp -d)"

# Cleanup temp directory on exit
trap 'rm -rf "${TEMP_DIR}"' EXIT

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

# Check if claude CLI is available
check_claude_cli() {
    if ! command -v claude >/dev/null 2>&1; then
        error "Claude CLI not found in PATH"
    fi
    log "Found claude CLI: $(claude --version 2>/dev/null | head -1 || echo 'unknown version')"
}

# Parse help output to extract commands and options
parse_help() {
    local help_output="$1"
    local section="$2"  # "Commands" or "Options"

    echo "$help_output" | awk -v section="$section" '
        BEGIN { in_section = 0 }
        $0 ~ "^" section ":" { in_section = 1; next }
        /^[A-Z][a-z]+:/ && in_section && $0 !~ "^" section ":" { in_section = 0 }
        in_section && /^  / {
            # Remove leading spaces and extract command/option and description
            gsub(/^  /, "")
            split($0, parts, " ", sep)
            if (NF >= 1) {
                cmd = parts[1]
                desc = ""
                for (i = 2; i <= NF; i++) {
                    desc = desc (i > 2 ? " " : "") $i
                }
                gsub(/^ */, "", desc)  # Remove leading spaces from description
                gsub(/"/, "\\\"", desc)  # Escape quotes
                print cmd ":" desc
            }
        }
    '
}

# Parse options more precisely to handle various formats
parse_options() {
    local help_output="$1"

    echo "$help_output" | awk '
        BEGIN { in_options = 0 }
        /^Options:/ { in_options = 1; next }
        /^[A-Z][a-z]+:/ && in_options { in_options = 0 }
        in_options && /^  / {
            gsub(/^  /, "")

            # Handle different option formats
            if ($0 ~ /^-[a-zA-Z], --[a-zA-Z-]+/) {
                # -d, --debug format
                short = substr($1, 1, 2)
                long = substr($1, 4)
                gsub(/,/, "", long)
                desc = ""
                for (i = 2; i <= NF; i++) {
                    desc = desc (i > 2 ? " " : "") $i
                }
            } else if ($0 ~ /^--[a-zA-Z-]+ <[^>]+>/) {
                # --option <arg> format
                long = $1
                desc = ""
                for (i = 3; i <= NF; i++) {
                    desc = desc (i > 3 ? " " : "") $i
                }
                short = ""
            } else if ($0 ~ /^--[a-zA-Z-]+/) {
                # --option format
                long = $1
                desc = ""
                for (i = 2; i <= NF; i++) {
                    desc = desc (i > 2 ? " " : "") $i
                }
                short = ""
            } else if ($0 ~ /^-[a-zA-Z]/) {
                # -o format
                short = $1
                desc = ""
                for (i = 2; i <= NF; i++) {
                    desc = desc (i > 2 ? " " : "") $i
                }
                long = ""
            }

            gsub(/^ */, "", desc)
            gsub(/\[/, "\\[", desc)
            gsub(/\]/, "\\]", desc)
            gsub(/"/, "\\\"", desc)

            if (short != "" && long != "") {
                printf "('\''%s %s'\'')%s%s,--'%s'\''}'[%s]'\''\n", short, long, "{", short, substr(long, 3), desc
            } else if (long != "") {
                printf "'\''%s[%s]'\''\n", long, desc
            } else if (short != "") {
                printf "'\''%s[%s]'\''\n", short, desc
            }
        }
    '
}

# Extract argument completions from help text
parse_arguments() {
    local help_output="$1"

    echo "$help_output" | awk '
        /^Arguments:/ { in_args = 1; next }
        /^Options:/ && in_args { in_args = 0 }
        in_args && /^  / {
            gsub(/^  /, "")
            if (NF >= 1) {
                arg = $1
                desc = ""
                for (i = 2; i <= NF; i++) {
                    desc = desc (i > 2 ? " " : "") $i
                }
                gsub(/^ */, "", desc)
                print arg ":" desc
            }
        }
    '
}

# Get available models dynamically
get_claude_models() {
    local models_output
    # Try to get models from config or use fallback
    if models_output=$(claude config get model 2>/dev/null); then
        # Parse available models if possible
        echo "sonnet:Latest Sonnet model"
        echo "opus:Latest Opus model"
        echo "haiku:Latest Haiku model"
        echo "claude-sonnet-4-20250514:Claude Sonnet 4"
        echo "claude-3-5-sonnet-20241022:Claude 3.5 Sonnet"
        echo "claude-3-5-haiku-20241022:Claude 3.5 Haiku"
        echo "claude-3-opus-20240229:Claude 3 Opus"
    else
        # Fallback to known models
        echo "sonnet:Latest Sonnet model"
        echo "opus:Latest Opus model"
        echo "haiku:Latest Haiku model"
    fi
}

# Get available config keys dynamically
get_config_keys() {
    local config_output
    if config_output=$(claude config list 2>/dev/null); then
        echo "$config_output" | grep -E '^[a-zA-Z]' | while read -r key _; do
            echo "${key}:Configuration key"
        done
    else
        # Fallback to known keys
        cat << 'EOF'
theme:UI theme setting
allowedTools:Allowed tool names
disallowedTools:Disallowed tool names
hasTrustDialogAccepted:Trust dialog acceptance status
hasCompletedProjectOnboarding:Project onboarding status
permissionMode:Default permission mode
model:Default model
fallbackModel:Fallback model
EOF
    fi
}

# Get available MCP servers dynamically
get_mcp_servers() {
    local servers_output
    if servers_output=$(claude mcp list 2>/dev/null); then
        echo "$servers_output" | grep -E '^[a-zA-Z0-9_-]+:' | while read -r line; do
            local server_name="${line%%:*}"
            local description="${line#*:}"
            echo "${server_name}:${description}"
        done
    else
        # Fallback to common servers
        cat << 'EOF'
playwright:Playwright MCP server
context7:Context7 MCP server
github:GitHub MCP server
zen-mcp-server:Zen MCP server
vectorcode:VectorCode MCP server
graphiti-memory:Graphiti Memory MCP server
sequential-thinking:Sequential Thinking MCP server
sentry:Sentry MCP server
EOF
    fi
}

# Generate the main completion function
generate_main_function() {
    local main_help
    main_help=$(claude --help 2>/dev/null)

    local commands
    commands=$(parse_help "$main_help" "Commands")

    local options
    options=$(parse_options "$main_help")

    cat << 'EOF'
#compdef claude

# Zsh completion for Claude Code CLI
# Auto-generated by scripts/generate-claude-completion.sh
# Maintained as part of chezmoi dotfiles configuration

_claude() {
    local -a commands
    local context state state_descr line
    typeset -A opt_args

    commands=(
EOF

    # Add commands
    echo "$commands" | while IFS=: read -r cmd desc; do
        echo "        '$cmd:$desc'"
    done

    cat << 'EOF'
    )

    _arguments -C \
EOF

    # Add options
    echo "$options" | sed 's/^/        /' | sed 's/$/ \\/'

    cat << 'EOF'
        '1: :->command' \
        '*: :->args' && return 0

    case $state in
        command)
            _describe -t commands 'claude commands' commands
            ;;
        args)
            case $words[1] in
                config)
                    _claude_config
                    ;;
                mcp)
                    _claude_mcp
                    ;;
                install)
                    _claude_install
                    ;;
                *)
                    _message 'prompt text'
                    ;;
            esac
            ;;
    esac
}
EOF
}

# Generate config subcommand completion
generate_config_function() {
    local config_help
    config_help=$(claude config --help 2>/dev/null)

    local commands
    commands=$(parse_help "$config_help" "Commands")

    cat << 'EOF'

_claude_config() {
    local -a config_commands
    config_commands=(
EOF

    echo "$commands" | while IFS=: read -r cmd desc; do
        echo "        '$cmd:$desc'"
    done

    cat << 'EOF'
    )

    _arguments -C \
        '(-h --help)'{-h,--help}'[Display help for command]' \
        '1: :->subcommand' \
        '*: :->args' && return 0

    case $state in
        subcommand)
            _describe -t config-commands 'config commands' config_commands
            ;;
        args)
            case $words[2] in
                get)
                    _arguments \
                        '(-g --global)'{-g,--global}'[Use global config]' \
                        '1:key:_claude_config_keys'
                    ;;
                set)
                    _arguments \
                        '(-g --global)'{-g,--global}'[Use global config]' \
                        '1:key:_claude_config_keys' \
                        '2:value:'
                    ;;
                remove|rm)
                    _arguments \
                        '(-g --global)'{-g,--global}'[Use global config]' \
                        '1:key:_claude_config_keys' \
                        '*:values:'
                    ;;
                list|ls)
                    _arguments \
                        '(-g --global)'{-g,--global}'[Use global config]'
                    ;;
                add)
                    _arguments \
                        '(-g --global)'{-g,--global}'[Use global config]' \
                        '1:key:_claude_config_keys' \
                        '*:values:'
                    ;;
            esac
            ;;
    esac
}
EOF
}

# Generate MCP subcommand completion
generate_mcp_function() {
    local mcp_help
    mcp_help=$(claude mcp --help 2>/dev/null)

    local commands
    commands=$(parse_help "$mcp_help" "Commands")

    cat << 'EOF'

_claude_mcp() {
    local -a mcp_commands
    mcp_commands=(
EOF

    echo "$commands" | while IFS=: read -r cmd desc; do
        echo "        '$cmd:$desc'"
    done

    cat << 'EOF'
    )

    _arguments -C \
        '(-h --help)'{-h,--help}'[Display help for command]' \
        '1: :->subcommand' \
        '*: :->args' && return 0

    case $state in
        subcommand)
            _describe -t mcp-commands 'mcp commands' mcp_commands
            ;;
        args)
            case $words[2] in
                serve)
                    _arguments \
                        '(-d --debug)'{-d,--debug}'[Enable debug mode]' \
                        '--verbose[Override verbose mode setting from config]'
                    ;;
                add)
                    _arguments \
                        '(-s --scope)'{-s,--scope}'[Configuration scope]:scope:(local user project)' \
                        '(-t --transport)'{-t,--transport}'[Transport type]:transport:(stdio sse http)' \
                        '(-e --env)'{-e,--env}'[Set environment variables]:env:' \
                        '(-H --header)'{-H,--header}'[Set WebSocket headers]:header:' \
                        '1:name:' \
                        '2:commandOrUrl:' \
                        '*:args:'
                    ;;
                remove)
                    _arguments \
                        '(-s --scope)'{-s,--scope}'[Configuration scope]:scope:(local user project)' \
                        '1:name:_claude_mcp_servers'
                    ;;
                get)
                    _arguments \
                        '1:name:_claude_mcp_servers'
                    ;;
                add-json)
                    _arguments \
                        '(-s --scope)'{-s,--scope}'[Configuration scope]:scope:(local user project)' \
                        '1:name:' \
                        '2:json:'
                    ;;
                add-from-claude-desktop)
                    _arguments \
                        '(-s --scope)'{-s,--scope}'[Configuration scope]:scope:(local user project)'
                    ;;
            esac
            ;;
    esac
}
EOF
}

# Generate install subcommand completion
generate_install_function() {
    cat << 'EOF'

_claude_install() {
    local -a install_targets
    install_targets=(
        'stable:Install stable version'
        'latest:Install latest version'
    )

    _arguments \
        '--force[Force installation even if already installed]' \
        '(-h --help)'{-h,--help}'[Display help for command]' \
        '1: :->target' && return 0

    case $state in
        target)
            _describe -t install-targets 'install targets' install_targets
            _message 'or specific version'
            ;;
    esac
}
EOF
}

# Generate helper functions
generate_helper_functions() {
    cat << 'EOF'

# Helper function to complete model names
_claude_models() {
    local -a models
    models=(
EOF

    get_claude_models | while IFS=: read -r model desc; do
        echo "        '$model:$desc'"
    done

    cat << 'EOF'
    )
    _describe -t models 'claude models' models
}

# Helper function to complete config keys
_claude_config_keys() {
    local -a config_keys
    config_keys=(
EOF

    get_config_keys | while IFS=: read -r key desc; do
        echo "        '$key:$desc'"
    done

    cat << 'EOF'
    )
    _describe -t config-keys 'config keys' config_keys
}

# Helper function to complete MCP server names
_claude_mcp_servers() {
    local -a servers
    # Try to get actual server names, fallback to common ones
    if command -v claude >/dev/null 2>&1; then
        servers=(${(f)"$(claude mcp list 2>/dev/null | grep -E '^[a-zA-Z0-9_-]+:' | cut -d: -f1)"})
    fi

    # Fallback to common server names if the command fails
    if [[ ${#servers} -eq 0 ]]; then
        servers=(
EOF

    get_mcp_servers | while IFS=: read -r server desc; do
        echo "            '$server:$desc'"
    done

    cat << 'EOF'
        )
    fi
    _describe -t mcp-servers 'MCP servers' servers
}

_claude "$@"
EOF
}

# Main function to generate the complete completion file
generate_completion() {
    local temp_completion="${TEMP_DIR}/_claude"

    log "Generating Claude CLI completion..."

    {
        generate_main_function
        generate_config_function
        generate_mcp_function
        generate_install_function
        generate_helper_functions
    } > "$temp_completion"

    # Validate the generated completion file
    if ! zsh -n "$temp_completion" 2>/dev/null; then
        error "Generated completion file has syntax errors"
    fi

    # Create the directory if it doesn't exist
    mkdir -p "$(dirname "$COMPLETION_FILE")"

    # Compare with existing file to see if update is needed
    if [[ -f "$COMPLETION_FILE" ]] && cmp -s "$temp_completion" "$COMPLETION_FILE"; then
        log "Completion file is already up to date"
        return 0
    fi

    # Install the new completion file
    cp "$temp_completion" "$COMPLETION_FILE"
    success "Updated Claude CLI completion: $COMPLETION_FILE"

    # Show diff if there was an existing file
    if [[ -f "$COMPLETION_FILE.bak" ]]; then
        log "Changes made:"
        diff -u "$COMPLETION_FILE.bak" "$COMPLETION_FILE" || true
        rm -f "$COMPLETION_FILE.bak"
    fi
}

# Add the completion file to git if it's not tracked
track_completion_file() {
    if [[ -f "$COMPLETION_FILE" ]] && ! git -C "$DOTFILES_DIR" ls-files --error-unmatch "$COMPLETION_FILE" >/dev/null 2>&1; then
        log "Adding completion file to git..."
        git -C "$DOTFILES_DIR" add "$COMPLETION_FILE"
        success "Added completion file to git tracking"
    fi
}

# Main execution
main() {
    log "Starting Claude CLI completion generation"

    check_claude_cli
    generate_completion
    track_completion_file

    success "Claude CLI completion generation complete!"
    echo
    echo "To use the updated completion:"
    echo "  1. Reload your shell: exec zsh"
    echo "  2. Or source the completion: source $COMPLETION_FILE"
    echo "  3. Test with: claude <TAB>"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
