# Verifying Zsh Environment

After installation, check the following Zsh features:

-   `git <tab>`: Should trigger FZF-based completions (potentially via `fzf-tab`).
-   `kubectl <tab>`: Should provide Kubernetes completions.
-   `ctrl+r`: Opens FZF history search.
-   `alt/option+c`: Opens FZF directory search (`cd` into selected directory).
-   `ctrl+t`: Opens FZF file search (insert selected file path).
-   `fzf` (command): Should display syntax-highlighted previews if `bat` is integrated.
-   `stty -a`: Displays current terminal settings.
