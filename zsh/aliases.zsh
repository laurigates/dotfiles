# use nvim if it exists
type nvim >/dev/null 2>&1 && alias vim="nvim"

# easy vimrc editing
alias vimrc='vim ~/dotfiles/neovim/init.lua'

# easy zshrc editing
alias zshrc='vim ~/.zshrc && source ~/.zshrc'
alias zshenv='vim ~/dotfiles/zsh/zshenv'

# use bat if it exists
#type bat >/dev/null 2>&1 && alias cat="bat"

# fzf preview
alias preview="fzf --preview 'bat --color \"always\" {}'"

alias icat="kitty +kitten icat"

alias ls='ls --color=auto'
