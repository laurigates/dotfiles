return {
	["Arduino Code workflow"] = {
		strategy = "workflow",
		description = "Use a workflow to guide an LLM in writing code for Arduino/ESP32/STM32",
		opts = {
			-- index = 4,
			-- is_default = true,
			-- short_name = "acw",
		},
		prompts = {
			{
				{
					name = "Setup Arduino Workflow",
					role = "user",
					opts = { auto_submit = false },
					content = function()
						-- Leverage auto_tool_mode which disables the requirement of approvals and automatically saves any edited buffer
						vim.g.codecompanion_auto_tool_mode = true

						-- Some clear instructions for the LLM to follow
						return [[### Instructions

You will help me write, compile, upload, and monitor code for an Arduino-compatible board. I will provide the initial request. You **must** use the specific Board FQBN, Sketch Path (usually the buffer being edited), Serial Port, and Baud Rate provided by me (the user) when invoking the tools.

**Required Information (User must provide this context):**
*   Board FQBN (e.g., `arduino:avr:uno`)
*   Sketch Path (this will typically be the buffer we are editing, `#buffer`)
*   Serial Port (e.g., `/dev/cu.usbserial-0001`)
*   Baud Rate for monitor (e.g., `115200`, defaults to 9600 if not specified by user)

### Steps to Follow

You are required to write code following my instructions and then test the correctness by compiling, uploading, and monitoring. Follow these steps exactly:

1.  Update the code in the current buffer (`#buffer{watch}`) using the `@editor` tool based on my request.
2.  After updating the code, use the `@arduino_compile` tool. Ensure you correctly provide the `board_fqbn` and `sketch_path` parameters in the tool's XML request, using the values I provided.
3.  **If** the compilation (`@arduino_compile`) is successful (check the tool's output message), **then** use the `@arduino_upload` tool. Ensure you correctly provide the `port`, `board_fqbn`, and `sketch_path` parameters in the tool's XML request, using the values I provided.
4.  **If** the upload (`@arduino_upload`) is successful, **then** use the `@arduino_monitor` tool. Ensure you correctly provide the `port` and `baudrate` parameters in the tool's XML request, using the values I provided (or the default baud rate if none was specified).
5.  Analyze the output from the compile, upload, and monitor steps. If there are errors reported by the tools or the monitor output indicates incorrect behavior, propose fixes using the `@editor` tool and repeat the cycle from step 2.

We'll repeat this cycle until the program compiles, uploads, and runs correctly according to the monitor output and my instructions. Ensure no deviations from these steps. Always use the specific parameters (FQBN, port, sketch path, baud rate) provided by me when calling the tools.

When providing code solutions, please apply these key principles:

1. YAGNI (You Aren't Gonna Need It): Implement only what's immediately necessary.
2. KISS (Keep It Simple, Stupid): Prefer simple, understandable solutions over complex ones.
3. DRY (Don't Repeat Yourself): Eliminate duplication by abstracting common functionality.
4. SOLID:
   - Single Responsibility: Each class/module has one job
   - Open/Closed: Extensible without modification
   - Liskov Substitution: Subtypes must be substitutable for base types
   - Interface Segregation: Specific interfaces over general ones
   - Dependency Inversion: Depend on abstractions, not implementations
5. SOC (Separation of Concerns): Keep distinct aspects of functionality separate.
6. Fail Fast: Detect and report errors as soon as possible.
7. Convention over Configuration: Follow established patterns to minimize decisions.
8. JEDI (Just Enough Design Initially): Balance planning with flexibility for future changes.]]
					end,
				},
			},
			-- Potentially add more steps here for reflection/refinement based on tool output
			{
				{
					name = "Repeat On Failure",
					role = "user",
					opts = {
						auto_submit = true,
						submit_delay = 2000, -- Allow time to read tool output
					},
					-- Only trigger if the last tool run reported an error or unexpected output
					-- (This requires more complex state tracking or specific flags from tools)
					-- For now, let's simplify and assume user interaction guides repetition,
					-- or add a simpler check like:
					condition = function(chat)
						-- Basic check: see if the last message indicates failure
						local last_msg = chat.messages[#chat.messages]
						return last_msg and last_msg.role == "user" and string.match(last_msg.content, "(failed|error)")
					end,
					-- repeat_until = function(chat) ... end -- Add logic if needed
					content = "The previous step failed or produced unexpected results. Please analyze the output, propose a fix using the @editor tool, and repeat the compile/upload/monitor cycle starting from step 2.",
				},
			},
		},
	},
}

