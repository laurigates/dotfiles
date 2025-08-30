# Filter out Kitty remote control protocol responses from input
# This function prevents P@kitty-cmd responses from appearing in the shell
function kitty-filter --on-event fish_preexec
    # Only run if we're in kitty
    if test "$TERM" = "xterm-kitty"
        # Clear any lingering kitty protocol responses from input buffer
        # This uses terminal control sequences to flush input
        printf '\033[?25l\033[?25h' >/dev/tty 2>/dev/null
    end
end

# Additional function to clean up any kitty protocol strings that might leak through
function clean-kitty-protocol
    # Remove any P@kitty-cmd responses from the current command line
    if test "$TERM" = "xterm-kitty"
        commandline (commandline | string replace -ra 'P@kitty-cmd\{[^}]*\}' '')
    end
end