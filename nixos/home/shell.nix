# Shell configuration - Zsh and Fish
# Extrapolated from dotfiles: dot_zshrc.tmpl, aliases.zsh

{ config, pkgs, lib, ... }:

{
  # Zsh (primary shell from dotfiles)
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    # History configuration
    history = {
      size = 50000;
      save = 50000;
      path = "${config.xdg.dataHome}/zsh/history";
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };

    # Zsh options (from dotfiles)
    defaultKeymap = "emacs";
    autocd = true;

    # Environment variables
    sessionVariables = {
      # Already defined in home.nix, add Zsh-specific ones here
    };

    # Aliases (from aliases.zsh)
    shellAliases = {
      # Editor shortcuts
      vimrc = "nvim ~/.config/nvim/init.lua";
      zshrc = "nvim ~/.zshrc";
      zshenv = "nvim ~/.zshenv";

      # Modern replacements
      cat = "bat --paging=never";
      ls = "eza --icons --group-directories-first";
      ll = "eza -la --icons --group-directories-first";
      la = "eza -a --icons --group-directories-first";
      lt = "eza --tree --icons --group-directories-first";
      tree = "eza --tree --icons";

      # Git aliases (comprehensive from dotfiles)
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gap = "git add -p";
      gb = "git branch";
      gba = "git branch -a";
      gbd = "git branch -d";
      gbD = "git branch -D";
      gc = "git commit -v";
      gcm = "git commit -m";
      gca = "git commit -v --amend";
      gco = "git checkout";
      gcb = "git checkout -b";
      gcp = "git cherry-pick";
      gd = "git diff";
      gds = "git diff --staged";
      gdsw = "git diff --staged --word-diff";
      gdw = "git diff --word-diff";
      gf = "git fetch";
      gfa = "git fetch --all --prune";
      gfap = "git fetch --all --prune";
      gl = "git pull";
      glog = "git log --oneline --decorate --graph";
      glol = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'";
      glola = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all";
      glg = "git log --stat";
      glgp = "git log --stat -p";
      glgg = "git log --graph --decorate --all";
      gm = "git merge";
      gmm = "git merge main";
      gp = "git push";
      gpf = "git push --force-with-lease";
      gpo = "git push origin";
      gpu = "git push -u origin HEAD";
      grb = "git rebase";
      grba = "git rebase --abort";
      grbc = "git rebase --continue";
      grbi = "git rebase -i";
      grbm = "git rebase main";
      grh = "git reset HEAD";
      grhh = "git reset HEAD --hard";
      grs = "git restore";
      grss = "git restore --staged";
      gst = "git status";
      gss = "git status -s";
      gsw = "git switch";
      gswc = "git switch -c";
      gsta = "git stash push";
      gstp = "git stash pop";
      gstl = "git stash list";

      # Docker aliases
      d = "docker";
      dc = "docker compose";
      dcu = "docker compose up";
      dcd = "docker compose down";
      dcb = "docker compose build";
      dps = "docker ps";
      dpsa = "docker ps -a";
      di = "docker images";
      dex = "docker exec -it";
      dlog = "docker logs -f";

      # Kubernetes aliases
      k = "kubectl";
      kx = "kubectx";
      kn = "kubens";
      kg = "kubectl get";
      kgp = "kubectl get pods";
      kgs = "kubectl get svc";
      kgd = "kubectl get deployments";
      kga = "kubectl get all";
      kd = "kubectl describe";
      kdp = "kubectl describe pod";
      kds = "kubectl describe svc";
      kdd = "kubectl describe deployment";
      kl = "kubectl logs -f";
      ke = "kubectl exec -it";
      ka = "kubectl apply -f";
      kdel = "kubectl delete";

      # Terraform
      tf = "terraform";
      tfi = "terraform init";
      tfp = "terraform plan";
      tfa = "terraform apply";
      tfd = "terraform destroy";
      tff = "terraform fmt";
      tfv = "terraform validate";

      # System
      reload = "source ~/.zshrc";
      path = "echo $PATH | tr ':' '\\n'";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";

      # Safety
      rm = "rm -i";
      cp = "cp -i";
      mv = "mv -i";
      mkdir = "mkdir -pv";

      # Nix
      nrs = "sudo nixos-rebuild switch --flake .#";
      nrt = "sudo nixos-rebuild test --flake .#";
      nrb = "sudo nixos-rebuild boot --flake .#";
      nfu = "nix flake update";
      nfc = "nix flake check";
      nfs = "nix flake show";
      ngc = "nix-collect-garbage -d";
      nsgc = "sudo nix-collect-garbage -d";

      # Quick edits
      enix = "nvim ~/.config/nixos/flake.nix";
      ehome = "nvim ~/.config/nixos/home.nix";
    };

    # Init extra (from dotfiles)
    initExtra = ''
      # Completion settings
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*' group-name '''
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

      # Vi mode settings
      bindkey -v
      export KEYTIMEOUT=1

      # Keep common emacs bindings in vi mode
      bindkey '^A' beginning-of-line
      bindkey '^E' end-of-line
      bindkey '^K' kill-line
      bindkey '^U' backward-kill-line
      bindkey '^W' backward-kill-word
      bindkey '^R' history-incremental-search-backward
      bindkey '^P' up-history
      bindkey '^N' down-history

      # Edit command in editor
      autoload -U edit-command-line
      zle -N edit-command-line
      bindkey -M vicmd 'v' edit-command-line

      # Word navigation
      bindkey '^[[1;5C' forward-word   # Ctrl+Right
      bindkey '^[[1;5D' backward-word  # Ctrl+Left

      # Help function
      autoload -Uz run-help
      (( ''${+aliases[run-help]} )) && unalias run-help
      alias help=run-help

      # FZF configuration
      export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

      export FZF_CTRL_T_OPTS="
        --preview 'bat -n --color=always --line-range :500 {}'
        --bind 'ctrl-/:change-preview-window(down|hidden|)'"

      export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

      # Use fd for path completion
      _fzf_compgen_path() {
        fd --hidden --follow --exclude ".git" . "$1"
      }

      _fzf_compgen_dir() {
        fd --type d --hidden --follow --exclude ".git" . "$1"
      }
    '';

    # Plugins
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "v1.1.2";
          sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
        };
      }
      {
        name = "zsh-autopair";
        src = pkgs.fetchFromGitHub {
          owner = "hlissner";
          repo = "zsh-autopair";
          rev = "v1.0";
          sha256 = "sha256-wd/6x2p5QOSFqWYgQ1BTYBUGNR06Pr2viGjV/JqoG8A=";
        };
      }
    ];
  };

  # Fish (alternative shell from dotfiles)
  programs.fish = {
    enable = true;

    shellAliases = config.programs.zsh.shellAliases;

    shellInit = ''
      # Disable greeting
      set -g fish_greeting

      # Vi mode
      fish_vi_key_bindings

      # Keep emacs bindings in insert mode
      bind -M insert \ca beginning-of-line
      bind -M insert \ce end-of-line
      bind -M insert \ck kill-line
      bind -M insert \cu backward-kill-line
    '';

    interactiveShellInit = ''
      # FZF integration
      set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
      set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
      set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
    '';

    plugins = [
      {
        name = "fzf.fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "autopair.fish";
        src = pkgs.fishPlugins.autopair.src;
      }
    ];
  };

  # Starship prompt (from dotfiles starship.toml)
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    settings = {
      # Format (7 segments from dotfiles)
      format = lib.concatStrings [
        "$os"
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$c"
        "$elixir"
        "$elm"
        "$golang"
        "$haskell"
        "$java"
        "$julia"
        "$nodejs"
        "$nim"
        "$python"
        "$rust"
        "$scala"
        "$docker_context"
        "$nix_shell"
        "$time"
        "$line_break"
        "$character"
      ];

      # Character
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold green)";
      };

      # OS icon
      os = {
        disabled = false;
        style = "bold blue";
      };

      os.symbols = {
        NixOS = " ";
        Linux = " ";
        Macos = " ";
        Windows = " ";
      };

      # Username
      username = {
        show_always = false;
        style_user = "bold yellow";
        style_root = "bold red";
        format = "[$user]($style)@";
      };

      # Hostname
      hostname = {
        ssh_only = true;
        format = "[$hostname](bold green) ";
      };

      # Directory
      directory = {
        truncation_length = 4;
        truncation_symbol = "…/";
        style = "bold cyan";
        read_only = " 🔒";
      };

      # Git
      git_branch = {
        symbol = " ";
        style = "bold purple";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style = "bold yellow";
        conflicted = "⚔️ ";
        ahead = "⇡$count ";
        behind = "⇣$count ";
        diverged = "⇕⇡$ahead_count⇣$behind_count ";
        untracked = "?$count ";
        stashed = "📦 ";
        modified = "!$count ";
        staged = "+$count ";
        renamed = "»$count ";
        deleted = "✘$count ";
      };

      # Languages
      python = {
        symbol = " ";
        format = "[$symbol($version )(($virtualenv) )]($style)";
      };

      nodejs = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      rust = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      golang = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      lua = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      # Docker
      docker_context = {
        symbol = " ";
        format = "[$symbol$context]($style) ";
        only_with_files = true;
      };

      # Nix shell
      nix_shell = {
        symbol = " ";
        format = "[$symbol$state( ($name))]($style) ";
        impure_msg = "impure";
        pure_msg = "pure";
      };

      # Time
      time = {
        disabled = false;
        format = "[$time]($style) ";
        style = "bold dimmed white";
        time_format = "%H:%M";
      };
    };
  };

  # FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--info=inline"
      "--color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796"
      "--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6"
      "--color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"
    ];

    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat -n --color=always --line-range :500 {}'"
    ];

    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --color=always {} | head -200'"
    ];
  };

  # Bat (cat replacement)
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      pager = "less -FR";
      style = "numbers,changes,header";
    };
  };

  # Eza (modern ls)
  programs.eza = {
    enable = true;
    enableZshIntegration = false; # We use custom aliases
    enableFishIntegration = false;
    icons = "auto";
    git = true;
    extraOptions = [
      "--group-directories-first"
    ];
  };
}
