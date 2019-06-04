# unalias some unwanted aliases from plugins
unalias fd
unalias ff

# use nvim if it exists
type nvim >/dev/null 2>&1 && alias vim="nvim"

# make common r10k deploy easier
alias deploy='sudo r10k deploy environment -v info'

# easy vimrc editing
alias vimrc='vim ~/.vimrc'

# workaround for problems that are caused by tmux passing tmux-256color as TERM over SSH
alias ssh='TERM=xterm-256color ssh'

# use bat if it exists
type bat >/dev/null 2>&1 && alias cat="bat"

# fzf preview
alias preview="fzf --preview 'bat --color \"always\" {}'"
