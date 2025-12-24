# Terminal and multiplexer configuration
# Kitty, Tmux, Zellij from dotfiles

{ config, pkgs, lib, ... }:

{
  # Kitty terminal (from dotfiles preferences)
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    shellIntegration = {
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
    settings = {
      # Font settings
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      font_features = "JetBrainsMonoNF-Regular +zero +cv14";

      # Cursor
      cursor_shape = "block";
      cursor_blink_interval = 0;

      # Scrollback
      scrollback_lines = 10000;
      scrollback_pager = "less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER";

      # Mouse
      mouse_hide_wait = 3;
      copy_on_select = "clipboard";

      # Bell
      enable_audio_bell = false;
      visual_bell_duration = 0;

      # Window
      window_padding_width = 4;
      confirm_os_window_close = 0;
      hide_window_decorations = false;
      remember_window_size = true;
      initial_window_width = "120c";
      initial_window_height = "40c";

      # Tab bar
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "{index}: {title}";

      # Colors - TokyoNight Storm (from dotfiles theme preference)
      background = "#24283b";
      foreground = "#c0caf5";
      selection_background = "#364A82";
      selection_foreground = "#c0caf5";
      url_color = "#73daca";
      cursor = "#c0caf5";

      # Normal colors
      color0 = "#1D202F";
      color1 = "#f7768e";
      color2 = "#9ece6a";
      color3 = "#e0af68";
      color4 = "#7aa2f7";
      color5 = "#bb9af7";
      color6 = "#7dcfff";
      color7 = "#a9b1d6";

      # Bright colors
      color8 = "#414868";
      color9 = "#f7768e";
      color10 = "#9ece6a";
      color11 = "#e0af68";
      color12 = "#7aa2f7";
      color13 = "#bb9af7";
      color14 = "#7dcfff";
      color15 = "#c0caf5";

      # Other
      term = "xterm-kitty";
      shell_integration = "enabled";
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty";
      macos_option_as_alt = "both";
    };
    keybindings = {
      # Clipboard
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";

      # Tabs
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+q" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+." = "move_tab_forward";
      "ctrl+shift+," = "move_tab_backward";

      # Windows
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+n" = "new_os_window";
      "ctrl+shift+w" = "close_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+[" = "previous_window";

      # Font size
      "ctrl+shift+equal" = "change_font_size all +1.0";
      "ctrl+shift+minus" = "change_font_size all -1.0";
      "ctrl+shift+backspace" = "change_font_size all 0";

      # Scrollback
      "ctrl+shift+k" = "scroll_line_up";
      "ctrl+shift+j" = "scroll_line_down";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";
      "ctrl+shift+h" = "show_scrollback";
    };
  };

  # Tmux (from dotfiles dot_tmux.conf)
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    historyLimit = 50000;
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
    prefix = "C-a";
    sensibleOnTop = true;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
      vim-tmux-navigator
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_window_status_style 'rounded'
        '';
      }
    ];

    extraConfig = ''
      # True color support
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -ga terminal-overrides ",xterm-kitty:Tc"

      # Focus events
      set -g focus-events on

      # Renumber windows
      set -g renumber-windows on

      # Activity monitoring
      setw -g monitor-activity on
      set -g visual-activity off

      # Vi-style pane selection
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Alt-arrow pane switching
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Shift-arrow window switching
      bind -n S-Left previous-window
      bind -n S-Right next-window

      # Pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # New window in current path
      bind c new-window -c "#{pane_current_path}"

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Copy mode
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel "xclip -selection clipboard"
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "xclip -selection clipboard"

      # Fast window switching
      bind -n C-M-h previous-window
      bind -n C-M-l next-window

      # Sync panes toggle
      bind S setw synchronize-panes
    '';
  };

  # Zellij (modern terminal multiplexer, from dotfiles)
  programs.zellij = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
      default_shell = "zsh";
      pane_frames = true;
      auto_layout = true;
      default_layout = "default";
      mouse_mode = true;
      scroll_buffer_size = 10000;
      copy_command = "xclip -selection clipboard";
      copy_on_select = true;
      scrollback_editor = "nvim";

      ui = {
        pane_frames = {
          rounded_corners = true;
          hide_session_name = false;
        };
      };

      # Keybindings similar to tmux
      keybinds = {
        normal = {
          "bind \"Ctrl a\"" = { SwitchToMode = "tmux"; };
        };
        tmux = {
          "bind \"Ctrl a\"" = { Write = [ 1 ]; SwitchToMode = "Normal"; };
          "bind \"|\"" = { NewPane = "Right"; SwitchToMode = "Normal"; };
          "bind \"-\"" = { NewPane = "Down"; SwitchToMode = "Normal"; };
          "bind \"c\"" = { NewTab = { }; SwitchToMode = "Normal"; };
          "bind \"x\"" = { CloseFocus = { }; SwitchToMode = "Normal"; };
          "bind \"h\"" = { MoveFocus = "Left"; SwitchToMode = "Normal"; };
          "bind \"j\"" = { MoveFocus = "Down"; SwitchToMode = "Normal"; };
          "bind \"k\"" = { MoveFocus = "Up"; SwitchToMode = "Normal"; };
          "bind \"l\"" = { MoveFocus = "Right"; SwitchToMode = "Normal"; };
          "bind \"n\"" = { GoToNextTab = { }; SwitchToMode = "Normal"; };
          "bind \"p\"" = { GoToPreviousTab = { }; SwitchToMode = "Normal"; };
          "bind \"d\"" = { Detach = { }; };
          "bind \"z\"" = { ToggleFocusFullscreen = { }; SwitchToMode = "Normal"; };
        };
      };
    };
  };

  # Alacritty (alternative terminal, minimal config)
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 4;
          y = 4;
        };
        dynamic_title = true;
        decorations = "full";
      };

      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 12;
      };

      cursor = {
        style = {
          shape = "Block";
          blinking = "Off";
        };
      };

      # TokyoNight Storm colors
      colors = {
        primary = {
          background = "#24283b";
          foreground = "#c0caf5";
        };
        normal = {
          black = "#1d202f";
          red = "#f7768e";
          green = "#9ece6a";
          yellow = "#e0af68";
          blue = "#7aa2f7";
          magenta = "#bb9af7";
          cyan = "#7dcfff";
          white = "#a9b1d6";
        };
        bright = {
          black = "#414868";
          red = "#f7768e";
          green = "#9ece6a";
          yellow = "#e0af68";
          blue = "#7aa2f7";
          magenta = "#bb9af7";
          cyan = "#7dcfff";
          white = "#c0caf5";
        };
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };
    };
  };
}
