if status is-interactive
  source ~/.api_tokens
  starship init fish | source
  atuin init fish | source

  abbr -a k kubectl
  abbr -a ll lsd --long --almost-all
  abbr -a tree lsd --tree

  abbr -a gsw git switch
  abbr -a gc git commit -v
  abbr -a gp git push
  abbr -a gd git diff
  abbr -a gm git merge
  abbr -a gst git status
  abbr -a ga git add

  abbr -a vim nvim
  abbr -a ca chezmoi apply
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
