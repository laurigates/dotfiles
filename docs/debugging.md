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
    :checkhealth vim.lsp
    :lua vim.cmd('edit ' .. vim.lsp.log.get_filename())
    :checkhealth
    ```
    *(Note: `:LspInfo` and `:LspLog` come from nvim-lspconfig, which this config does not install; use the built-in equivalents above.)*

## Debugging Zsh Completions

If completions are not working correctly:

```bash
rm -f ~/.zcompdump* # Remove existing dump files
exec zsh # Restart Zsh to regenerate completions
```
