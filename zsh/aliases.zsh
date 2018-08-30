# use nvim if it exists
type nvim >/dev/null 2>&1 && alias vim="nvim"

# make common r10k deploy easier
alias deploy='sudo r10k deploy environment -v info'

# easy vimrc editing
alias vimrc='vim ~/.vimrc'
