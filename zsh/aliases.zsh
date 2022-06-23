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

# alias ls='ls --color=auto'

alias ls='lsd'
alias tree='lsd --tree'

### Git aliases
# Mostly cherry-picked from the oh-my-zsh git plugin:
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh

alias ga='git add'
alias gc='git commit -v'
alias gl='git pull'
alias gp='git push'

alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'

alias gd='git diff'
alias gdca='git diff --cached'
alias gdcw='git diff --cached --word-diff'

alias gm='git merge'

alias gst='git status'

alias gsw='git switch'

alias gupa='git pull --rebase --autostash'
