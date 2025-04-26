-- nvim-bisquits makes large files load extremely slowly
return {
  "code-biscuits/nvim-biscuits",
  opts = {
    cursor_line_only = true,
    default_config = {
      -- max_length = 12,
      -- min_distance = 5,
      prefix_string = "📎",
    },
    -- language_config = {
    --   html = {
    --     prefix_string = " 🌐 "
    --   },
    --   javascript = {
    --     prefix_string = " ✨ ",
    --     max_length = 80
    --   },
    --   python = {
    --     disabled = true
    --   }
    -- }
  },
}
