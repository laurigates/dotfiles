return {
  chat = {
    adapter = "anthropic",
    tools = {
      arduino_compile = {
        { "arduino-cli compile --export-binaries --fqbn esp32:esp32:esp32 <sketch_path>" },
      },
      arduino_upload = {
        { "arduino-cli upload -p /dev/cu.usbserial-0001 --fqbn esp32:esp32:esp32 <sketch_path>" },
      },
      arduino_monitor = {
        { "arduino-cli monitor -p /dev/tty.usbserial-0001 --config baudrate=115200" },
      },
      git_diff = {
        { "git diff --staged --word-diff --histogram" },
      },
    },
    slash_commands = {
      ["git_files"] = {
        description = "List git files",
        ---@param chat CodeCompanion.Chat
        callback = function(chat)
          local handle = io.popen("git ls-files")
          if handle ~= nil then
            local result = handle:read("*a")
            handle:close()
            chat:add_reference({ content = result }, "git", "<git_files>")
          else
            return vim.notify("No git files available", vim.log.levels.INFO, { title = "CodeCompanion" })
          end
        end,
        opts = {
          contains_code = false,
        },
      },
    },
  },
  inline = {
    adapter = "anthropic",
  },
  cmd = {
    adapter = "anthropic",
  },
}