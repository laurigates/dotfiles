# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# environment configuration

# write host history in separate files
export HISTFILE="${HOME}/.bash_history/$(hostname)"

# set vim as default editor
export EDITOR=vim
export VISUAL=vim

# set vi -mode for bash
#set -o vi

# disable non-breaking space with altgr+space (fixes the problem with non-breaking space causing an invalid command when pressing space quickly after the pipe character)
setxkbmap -option "nbsp:none"
