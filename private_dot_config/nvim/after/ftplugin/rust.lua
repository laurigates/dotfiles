-- Rust-specific settings
-- Include underscores (for snake_case) and exclude colons (for easier path navigation)
vim.opt_local.iskeyword:append("_")
vim.opt_local.iskeyword:remove(":")
