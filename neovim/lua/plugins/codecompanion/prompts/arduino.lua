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
          name = "Setup Test",
          role = "user",
          opts = { auto_submit = false },
          content = function()
            -- Leverage auto_tool_mode which disables the requirement of approvals and automatically saves any edited buffer
            vim.g.codecompanion_auto_tool_mode = true

            -- Some clear instructions for the LLM to follow
            return [[### Instructions

Your instructions here

### Steps to Follow

You are required to write code following the instructions provided above and test the correctness by running the designated test suite. Follow these steps exactly:

1. Update the code in #buffer{watch} using the @editor tool
2. Then use the @arduino_compile tool to compile the code (do this after you have updated the code)
3. If the program was compiled successfully, use the @arduino_upload tool to upload the compiled program to the board
4. If the program was uploaded successfully, use the @arduino_monitor tool to monitor the serial output of the board to see if it works as expected

We'll repeat this cycle at least until the program compiles. If the uploading and monitoring are successful, repeat until those produce expected results as well.
Ensure no deviations from these steps.

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
    },
  },
}