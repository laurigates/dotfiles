# use nvim if it exists
type nvim >/dev/null 2>&1 && alias vim="nvim"

# make common r10k deploy easier
# alias deploy='sudo r10k deploy environment -v info'

# easy vimrc editing
alias vimrc='vim ~/dotfiles/neovim/init.lua'

# easy zshrc editing
alias zshrc='vim ~/dotfiles/zsh/zshrc'
alias zshenv='vim ~/dotfiles/zsh/zshenv'

# fzf preview
alias preview="fzf --preview 'bat --color \"always\" {}'"

alias icat="kitty +kitten icat"
