# Git configuration
# Extrapolated from dotfiles: .gitconfig, .gitignore_global

{ config, pkgs, lib, user, ... }:

{
  programs.git = {
    enable = true;
    userName = user.fullName;
    userEmail = user.email;

    # Core settings
    extraConfig = {
      init.defaultBranch = "main";

      core = {
        editor = "nvim";
        autocrlf = "input";
        whitespace = "trailing-space,space-before-tab";
        pager = "delta";
      };

      # Delta pager (from dotfiles)
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        light = false;
        side-by-side = false;
        line-numbers = true;
        syntax-theme = "Dracula";
      };

      # Merge/diff settings
      merge = {
        conflictStyle = "diff3";
        ff = "only";
      };
      diff.colorMoved = "default";

      # Pull/push settings
      pull.rebase = true;
      push = {
        default = "current";
        autoSetupRemote = true;
        followTags = true;
      };
      fetch = {
        prune = true;
        pruneTags = true;
      };

      # Rebase settings
      rebase = {
        autoSquash = true;
        autoStash = true;
      };

      # Branch settings
      branch = {
        sort = "-committerdate";
        autoSetupMerge = "always";
      };

      # Tag sorting
      tag.sort = "version:refname";

      # Rerere (reuse recorded resolution)
      rerere.enabled = true;

      # Column output
      column.ui = "auto";

      # Help autocorrect
      help.autocorrect = "prompt";

      # Credential helper
      credential.helper = "store";

      # URL rewrites
      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
        "git@gitlab.com:" = {
          insteadOf = "https://gitlab.com/";
        };
      };

      # GPG signing (optional - uncomment to enable)
      # commit.gpgSign = true;
      # tag.gpgSign = true;
      # user.signingKey = "YOUR_KEY_ID";
    };

    # Aliases (comprehensive from dotfiles)
    aliases = {
      # Shortcuts
      co = "checkout";
      ci = "commit";
      br = "branch";
      st = "status";
      df = "diff";
      lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";

      # Undo
      undo = "reset --soft HEAD~1";
      amend = "commit --amend --no-edit";
      unstage = "reset HEAD --";

      # Info
      last = "log -1 HEAD --stat";
      hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";
      contributors = "shortlog --summary --numbered";
      aliases = "config --get-regexp alias";

      # Stash operations
      sl = "stash list";
      sp = "stash pop";
      ss = "stash save";

      # Branch management
      cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d";
      recent = "branch --sort=-committerdate --format='%(committerdate:short) %(refname:short)'";

      # Working with remotes
      sync = "!git fetch --all --prune && git pull --rebase";
      publish = "push -u origin HEAD";

      # Diff variants
      dfw = "diff --word-diff";
      dfs = "diff --staged";
      dfc = "diff --cached";

      # Log variants
      lol = "log --graph --decorate --oneline";
      lola = "log --graph --decorate --oneline --all";

      # Find
      find = "!git ls-files | grep -i";
      grep = "grep -Ii";

      # Maintenance
      optimize = "!git gc --prune=now && git remote prune origin";
    };

    # LFS
    lfs.enable = true;

    # Global ignore patterns (from dotfiles)
    ignores = [
      # OS generated
      ".DS_Store"
      ".DS_Store?"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      "ehthumbs.db"
      "Thumbs.db"
      "Desktop.ini"

      # Editor/IDE
      "*.swp"
      "*.swo"
      "*~"
      ".idea/"
      "*.iml"
      ".vscode/"
      "*.code-workspace"
      ".project"
      ".settings/"
      ".classpath"
      "*.sublime-*"

      # Build artifacts
      "*.o"
      "*.pyc"
      "*.pyo"
      "__pycache__/"
      "*.class"
      "*.egg-info/"
      "dist/"
      "build/"
      "*.egg"
      ".eggs/"
      "*.so"
      "*.dylib"

      # Package managers
      "node_modules/"
      ".npm"
      ".yarn"
      "bower_components/"
      "vendor/"

      # Environment
      ".env"
      ".env.local"
      ".env.*.local"
      "*.env"
      ".venv/"
      "venv/"
      "env/"
      ".python-version"

      # Secrets & credentials
      "*.pem"
      "*.key"
      "*.crt"
      "*.p12"
      "credentials.json"
      "secrets.yaml"
      "secrets.yml"
      ".secrets"
      ".api_tokens"

      # Logs & temp
      "*.log"
      "logs/"
      "tmp/"
      "temp/"
      ".cache/"

      # Coverage & testing
      "coverage/"
      ".coverage"
      "htmlcov/"
      ".pytest_cache/"
      ".tox/"
      ".nox/"

      # Terraform
      ".terraform/"
      "*.tfstate"
      "*.tfstate.backup"
      "*.tfvars"

      # Misc
      ".direnv/"
      ".envrc"
      "*.bak"
      "*.backup"
    ];

    # Delta for diffs
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = false;
        line-numbers = true;
        syntax-theme = "Dracula";
        plus-style = "syntax #003800";
        minus-style = "syntax #3f0001";
        decorations = {
          commit-decoration-style = "bold yellow box ul";
          file-style = "bold yellow ul";
          file-decoration-style = "none";
        };
      };
    };
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      editor = "nvim";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
        pl = "pr list";
        pc = "pr create";
        rv = "repo view";
      };
    };
    extensions = with pkgs; [
      gh-dash
      gh-markdown-preview
    ];
  };

  # Git credential helper
  programs.git-credential-oauth.enable = true;

  # Lazygit TUI
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          lightTheme = false;
          selectedLineBgColor = [ "default" ];
        };
        showIcons = true;
        nerdFontsVersion = "3";
      };
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
      };
      os = {
        editCommand = "nvim";
        editCommandTemplate = "{{editor}} {{filename}}";
      };
    };
  };
}
