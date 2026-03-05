-- Luacheck configuration for Neovim dotfiles
-- Defines globals provided by Neovim runtime

globals = {
    "vim",
    "Snacks",
}

-- Ignore unused self warnings (common in Lua OOP patterns)
self = false

-- Max line length (match stylua settings)
max_line_length = 120
