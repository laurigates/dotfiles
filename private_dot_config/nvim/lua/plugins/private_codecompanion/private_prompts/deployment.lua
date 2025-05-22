return {
  ["Deployment configuration workflow"] = {
    strategy = "workflow",
    description = "Use a workflow to guide an LLM in writing configuration for Skaffold, Dockerfile, ArgoCD.",
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
2. Then use the @cmd_runner tool to run the test suite with `skaffold build` (do this after you have updated the code)
3. Make sure you trigger both tools in the same response

We'll repeat this cycle until the tests pass. Ensure no deviations from these steps.

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
