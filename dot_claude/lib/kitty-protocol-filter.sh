#!/bin/bash

# Kitty Protocol Filter Library
# Functions to prevent Kitty remote control protocol responses from leaking into terminal input

# Main function to execute kitty remote commands safely
safe_kitty_command() {
    local cmd="$1"
    shift
    local args=("$@")
    
    # Only run if we're in kitty terminal
    if [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty >/dev/null 2>&1 && [[ -c /dev/tty ]]; then
        # Execute kitty command with proper I/O redirection to prevent protocol leakage
        # - stdin from /dev/null prevents hanging
        # - stdout/stderr to /dev/null prevents protocol responses from appearing
        # - Run in subshell to isolate any side effects
        (
            exec 0</dev/null 1>/dev/null 2>/dev/null
            kitty @ "$cmd" "${args[@]}" || true
        ) || true
    fi
}

# Safe wrapper for set-tab-title specifically
safe_set_tab_title() {
    local title="$1"
    safe_kitty_command "set-tab-title" "$title"
}

# Safe wrapper for send-text commands
safe_send_text() {
    local target="$1"
    local text="$2"
    safe_kitty_command "send-text" "--match" "$target" --stdin <<< "$text"
}

# Clean up any leaked protocol responses from environment
clean_environment() {
    # Clear any environment variables that might contain protocol responses
    unset KITTY_WINDOW_ID KITTY_PID 2>/dev/null || true
    
    # Reset terminal if protocol responses have corrupted it
    if [[ "${TERM}" == "xterm-kitty" ]]; then
        printf '\033c' 2>/dev/null || true  # Reset terminal
    fi
}

# Export functions for use in other scripts
export -f safe_kitty_command safe_set_tab_title safe_send_text clean_environment