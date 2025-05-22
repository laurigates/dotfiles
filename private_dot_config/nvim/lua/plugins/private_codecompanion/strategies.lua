return {
  chat = {
    adapter = "gemini",
    model = "gemini-2.5-pro-exp-03-25",
    tools = {
      arduino_compile = {
        description = "Compile an Arduino sketch and export binaries.",
        callback = {
          name = "arduino_compile",
          cmds = {
            { "arduino-cli", "compile", "--export-binaries", "--fqbn", "${board_fqbn}", "${sketch_path}" },
          },
          schema = {
            _attr = { name = "arduino_compile" },
            action = {
              board_fqbn = "board:arch:core",
              sketch_path = "/path/to/sketch",
            },
          },
          system_prompt = function(schema, xml2lua)
            return string.format(
              [[## Arduino Compile Tool (`arduino_compile`)
### Purpose:
- Compile an Arduino sketch and export the binaries.
### When to Use:
- When the user asks to compile a specific Arduino sketch for a given board.
### Execution Format:
- Return an XML markdown code block adhering to the schema.
### XML Schema:
```xml
%s
```
where:
- `board_fqbn` is the Fully Qualified Board Name (e.g., arduino:avr:uno).
- `sketch_path` is the path to the Arduino sketch file or directory.]],
              xml2lua.toXml(schema, "tool")
            )
          end,
          env = function(actions) -- 'actions' is the parsed XML from the LLM
            return {
              board_fqbn = actions.board_fqbn,
              sketch_path = actions.sketch_path,
            }
          end,
          opts = { requires_approval = true },
          output = {
            success = function(agent, cmd, stdout)
              agent.chat:add_buf_message({
                role = "user",
                content = "Compilation successful:\n```\n" .. table.concat(stdout, "\n") .. "\n```",
              })
            end,
            error = function(agent, cmd, stderr)
              agent.chat:add_buf_message({
                role = "user",
                content = "Compilation failed:\n```\n" .. table.concat(stderr, "\n") .. "\n```",
              })
            end,
          },
        },
      },
      arduino_upload = {
        description = "Upload a compiled Arduino sketch to a board.",
        callback = {
          name = "arduino_upload",
          cmds = {
            { "arduino-cli", "upload", "-p", "${port}", "--fqbn", "${board_fqbn}", "${sketch_path}" },
          },
          schema = {
            _attr = { name = "arduino_upload" },
            action = {
              port = "/dev/tty.usbmodemXXXX",
              board_fqbn = "board:arch:core",
              sketch_path = "/path/to/sketch",
            },
          },
          system_prompt = function(schema, xml2lua)
            return string.format(
              [[## Arduino Upload Tool (`arduino_upload`)
### Purpose:
- Upload a compiled Arduino sketch to a connected board.
### When to Use:
- When the user asks to upload a specific Arduino sketch to a board connected via a specified port.
### Execution Format:
- Return an XML markdown code block adhering to the schema.
### XML Schema:
```xml
%s
```
where:
- `port` is the serial port the board is connected to (e.g., /dev/cu.usbserial-0001).
- `board_fqbn` is the Fully Qualified Board Name.
- `sketch_path` is the path to the Arduino sketch file or directory.]],
              xml2lua.toXml(schema, "tool")
            )
          end,
          env = function(actions)
            return {
              port = actions.port,
              board_fqbn = actions.board_fqbn,
              sketch_path = actions.sketch_path,
            }
          end,
          opts = { requires_approval = true },
          output = {
            success = function(agent, cmd, stdout)
              agent.chat:add_buf_message({
                role = "user",
                content = "Upload successful:\n```\n" .. table.concat(stdout, "\n") .. "\n```",
              })
            end,
            error = function(agent, cmd, stderr)
              agent.chat:add_buf_message({
                role = "user",
                content = "Upload failed:\n```\n" .. table.concat(stderr, "\n") .. "\n```",
              })
            end,
          },
        },
      },
      arduino_monitor = {
        description = "Open the serial monitor for a connected Arduino board.",
        callback = {
          name = "arduino_monitor",
          -- Note: 'monitor' is often interactive/long-running. Consider if direct execution is suitable
          -- or if it should just display the command for the user. For simplicity, we execute.
          cmds = {
            { "arduino-cli", "monitor", "-p", "${port}", "--config", "baudrate=${baudrate}" },
          },
          schema = {
            _attr = { name = "arduino_monitor" },
            action = {
              port = "/dev/tty.usbmodemXXXX",
              baudrate = "9600", -- Default baud rate
            },
          },
          system_prompt = function(schema, xml2lua)
            return string.format(
              [[## Arduino Monitor Tool (`arduino_monitor`)
### Purpose:
- Open the serial monitor for a connected Arduino board.
### When to Use:
- When the user asks to monitor the serial output from a board connected via a specified port, optionally specifying the baud rate.
### Execution Format:
- Return an XML markdown code block adhering to the schema.
### XML Schema:
```xml
%s
```
where:
- `port` is the serial port the board is connected to.
- `baudrate` is the communication speed (default 9600).]],
              xml2lua.toXml(schema, "tool")
            )
          end,
          env = function(actions)
            return {
              port = actions.port,
              baudrate = actions.baudrate or "9600",
            }
          end,
          opts = { requires_approval = true },
          -- Output handlers might be less useful for a continuous monitor
          output = {
            success = function(agent, cmd, stdout)
              agent.chat:add_buf_message({
                role = "user",
                content = "Serial monitor started (output may appear in Neovim's terminal or externally).",
              })
            end,
            error = function(agent, cmd, stderr)
              agent.chat:add_buf_message({
                role = "user",
                content = "Failed to start serial monitor:\n```\n" .. table.concat(stderr, "\n") .. "\n```",
              })
            end,
          },
        },
      },
      git_diff = {
        description = "Show staged git changes with word diff.",
        callback = {
          name = "git_diff",
          cmds = {
            { "git", "diff", "--staged", "--word-diff", "--histogram" },
          },
          schema = { -- Simple schema, as no parameters are needed from LLM
            _attr = { name = "git_diff" },
            action = {},
          },
          system_prompt = function(schema, xml2lua)
            return string.format(
              [[## Git Diff Tool (`git_diff`)
### Purpose:
- Show the staged changes using 'git diff --staged --word-diff --histogram'.
### When to Use:
- When the user asks to review staged changes, especially before committing.
- When asked to describe the changes that have been made or staged.
### Execution Format:
- Return an XML markdown code block adhering to the schema.
### XML Schema:
```xml
%s
```]],
              xml2lua.toXml(schema, "tool")
            )
          end,
          -- No env needed as there are no parameters
          opts = { requires_approval = true },
          output = {
            success = function(agent, cmd, stdout)
              agent.chat:add_buf_message({
                role = "user",
                content = "Staged Git Diff:\n```diff\n" .. table.concat(stdout, "\n") .. "\n```",
              })
            end,
            error = function(agent, cmd, stderr)
              agent.chat:add_buf_message({
                role = "user",
                content = "Failed to get git diff:\n```\n" .. table.concat(stderr, "\n") .. "\n```",
              })
            end,
          },
        },
      },
      git_log = {
        description = "Show git commit history.",
        callback = {
          name = "git_log",
          cmds = {
            {
              "git",
              "log",
              "--pretty=format:%h %ad | %s%d [%an]",
              "--graph",
              "--date=short",
              "-n",
              "${num_commits}",
            },
          },
          schema = {
            _attr = { name = "git_log" },
            action = {
              num_commits = "10", -- Default to showing 10 commits
            },
          },
          system_prompt = function(schema, xml2lua)
            return string.format(
              [[## Git Log Tool (`git_log`)
### Purpose:
- Show the git commit history with a nicely formatted output.
### When to Use:
- When the user asks to see recent git commits or git history for a file, function, or general area of the code.
- Useful for understanding the evolution of the codebase or debugging.
### Execution Format:
- Return an XML markdown code block adhering to the schema.
### XML Schema:
```xml
%s
```
where:
- `num_commits` is the number of commits to show (default: 10)]],
              xml2lua.toXml(schema, "tool")
            )
          end,
          env = function(actions)
            return {
              num_commits = actions.num_commits or "10",
            }
          end,
          opts = { requires_approval = true },
          output = {
            success = function(agent, cmd, stdout)
              agent.chat:add_buf_message({
                role = "user",
                content = "Git Commit History:\n```\n" .. table.concat(stdout, "\n") .. "\n```",
              })
            end,
            error = function(agent, cmd, stderr)
              agent.chat:add_buf_message({
                role = "user",
                content = "Failed to get git history:\n```\n" .. table.concat(stderr, "\n") .. "\n```",
              })
            end,
          },
        },
      },

      git_status = {
        description = "Show the working tree status.",
        callback = {
          name = "git_status",
          cmds = {
            { "git", "status" },
          },
          schema = {
            _attr = { name = "git_status" },
            action = {},
          },
          system_prompt = function(schema, xml2lua)
            return string.format(
              [[## Git Status Tool (`git_status`)
### Purpose:
- Show the working tree status using 'git status'.
### When to Use:
- When the user asks to see the git status or check which files are modified, staged, etc.
### Execution Format:
- Return an XML markdown code block adhering to the schema.
### XML Schema:
```xml
%s
```]],
              xml2lua.toXml(schema, "tool")
            )
          end,
          opts = { requires_approval = true },
          output = {
            success = function(agent, cmd, stdout)
              agent.chat:add_buf_message({
                role = "user",
                content = "Git Status:\n```\n" .. table.concat(stdout, "\n") .. "\n```",
              })
            end,
            error = function(agent, cmd, stderr)
              agent.chat:add_buf_message({
                role = "user",
                content = "Failed to get git status:\n```\n" .. table.concat(stderr, "\n") .. "\n```",
              })
            end,
          },
        },
      },

      git_commit = {
        description = "Create a git commit with a message.",
        callback = {
          name = "git_commit",
          cmds = {
            { "git", "commit", "-m", "${commit_message}" },
          },
          schema = {
            _attr = { name = "git_commit" },
            action = {
              commit_message = "Your commit message here",
            },
          },
          system_prompt = function(schema, xml2lua)
            return string.format(
              [[## Git Commit Tool (`git_commit`)
### Purpose:
- Create a git commit with the provided message.
### When to Use:
- After using `git status` and `git diff --staged` to confirm the changes are correct.
- When the user asks to commit staged changes with a specific message.
- Only suggest a commit if there are staged changes.
### Execution Format:
- Return an XML markdown code block adhering to the schema.
### XML Schema:
```xml
%s
```
where:
- `commit_message` is the message for the commit.]],
              xml2lua.toXml(schema, "tool")
            )
          end,
          env = function(actions)
            return {
              commit_message = actions.commit_message,
            }
          end,
          opts = { requires_approval = true },
          output = {
            success = function(agent, cmd, stdout)
              agent.chat:add_buf_message({
                role = "user",
                content = "Commit created successfully:\n```\n" .. table.concat(stdout, "\n") .. "\n```",
              })
            end,
            error = function(agent, cmd, stderr)
              agent.chat:add_buf_message({
                role = "user",
                content = "Failed to create commit:\n```\n" .. table.concat(stderr, "\n") .. "\n```",
              })
            end,
          },
        },
      },

      git_push = {
        description = "Push git commits to a remote repository.",
        callback = {
          name = "git_push",
          cmds = {
            { "git", "push", "${remote}", "${branch}" },
          },
          schema = {
            _attr = { name = "git_push" },
            action = {
              remote = "origin",
              branch = "main",
            },
          },
          system_prompt = function(schema, xml2lua)
            return string.format(
              [[## Git Push Tool (`git_push`)
### Purpose:
- Push committed changes to a remote git repository.
### When to Use:
- After successfully committing changes.
- After using `git status` to confirm you are on the correct branch and there are no unexpected local changes.
- When the user asks to push commits to a remote.
### Execution Format:
- Return an XML markdown code block adhering to the schema.
### XML Schema:
```xml
%s
```
where:
- `remote` is the name of the remote repository (default: origin).
- `branch` is the branch to push to (default: main).]],
              xml2lua.toXml(schema, "tool")
            )
          end,
          env = function(actions)
            return {
              remote = actions.remote or "origin",
              branch = actions.branch or "main",
            }
          end,
          opts = { requires_approval = true },
          output = {
            success = function(agent, cmd, stdout)
              agent.chat:add_buf_message({
                role = "user",
                content = "Push successful:\n```\n" .. table.concat(stdout, "\n") .. "\n```",
              })
            end,
            error = function(agent, cmd, stderr)
              agent.chat:add_buf_message({
                role = "user",
                content = "Push failed:\n```\n" .. table.concat(stderr, "\n") .. "\n```",
              })
            end,
          },
        },
      },
    },
    slash_commands = {
      ["git_files"] = { -- This slash command seems correctly defined already
        description = "List git files",
        ---@param chat CodeCompanion.Chat
        callback = function(chat)
          local handle = io.popen("git ls-files")
          if handle ~= nil then
            local result = handle:read("*a")
            handle:close()
            -- Ensure role is provided for add_reference
            chat:add_reference({ role = "user", content = result }, "git", "<git_files>")
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
    adapter = "gemini",
    model = "gemini-2.5-pro-exp-03-25",
  },
  cmd = {
    adapter = "gemini",
    model = "gemini-2.5-pro-exp-03-25",
  },
}
