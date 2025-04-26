# Debugging

## Debugging PATH

To see how the `PATH` variable is constructed, especially with `mise` integration:

```bash
zsh -x -c 'printenv PATH' 2>&1 | rg PATH
```
Or use `mise`'s built-in debugging:
```bash
mise doctor
mise exec -- zsh -x -c 'printenv PATH' 2>&1 | rg PATH
```


## Debugging Neovim Configuration

-   **Start Neovim in a clean state:**
    ```bash
    nvim --clean
    ```
    *(Note: Modern Neovim often doesn't require `-u init.lua` if `init.lua` is standard)*

-   **Debug LSP configuration:**
    ```
    :LspInfo
    :LspLog
    :checkhealth
    ```
    *(Note: `:Neoconf` might be specific to a plugin; standard commands are `:LspInfo`, `:LspLog`, `:checkhealth`)*

## Debugging Zsh Completions

If completions are not working correctly:

```bash
rm -f ~/.zcompdump* # Remove existing dump files
exec zsh # Restart Zsh to regenerate completions
```
