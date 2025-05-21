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

  abbr -a vim nvim
end
