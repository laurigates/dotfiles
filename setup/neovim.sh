#!/bin/zsh -e

# Always run install_nvim so it's at the latest version.
# Too many things break otherwise.
# Defined in ~/.zshenv
install_nvim
if npm --version > /dev/null 2>&1; then
    npm install -g neovim
fi

# Installs and updates tree-sitter parsers.
# Create a snapshot of the current plugins, then clean and update them.
# The autocommand is used to quit neovim after PackerSync has finished.
# The commands use the synchronous versions so that they work in headless mode.
nvim --headless -c "PackerSnapshot $(date +%Y-%m-%d_%H-%M-%S)" -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
nvim --headless -c "LspInstall --sync tsserver terraformls yamlls ansiblels bashls dockerls sumneko_lua" -c q
nvim --headless -c 'TSInstallSync all' -c 'TSUpdateSync' -c q
