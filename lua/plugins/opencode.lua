local cmd = "opencode"

local terminal_opts = {
  count = 1,
  auto_insert = false,
  start_insert = false,
  auto_close = true,
  win = {
    position = "right",
    width = 0.4,
    enter = false,
  },
}

return {
  {
    "nickjvandyke/opencode.nvim",
    -- Stable releases support OpenCode v1; main targets OpenCode v2.
    branch = "main",
    version = false,
    dependencies = { "folke/snacks.nvim" },
    init = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          start = function()
            require("snacks.terminal").get(cmd, terminal_opts):show()
          end,
        },
        select = {
          prompts = {
            explain = "Explain @this and its context, including the key logic.",
            review = "Review @this for correctness and readability. Explain specific issues without editing files.",
            fix = "Use @this to investigate and fix @diagnostics with minimal changes. Explain the changes.",
            optimize = "Optimize @this for readability and performance while preserving behavior. Explain the changes.",
            document = "Add concise comments documenting @this, following the project's style.",
            implement = "Implement @this following the project's conventions. Explain the changes.",
            test = "Add focused tests for @this using the project's existing test framework. Explain the coverage.",
            diagnostics = "Explain @diagnostics, including likely causes and suggested fixes.",
          },
        },
      }
    end,
    keys = {
      {
        "<leader>aa",
        function() require("opencode").ask("@this: ") end,
        mode = { "n", "x" },
        desc = "Ask OpenCode",
      },
      {
        "<leader>as",
        function() require("opencode").select() end,
        mode = { "n", "x" },
        desc = "OpenCode Actions",
      },
      {
        "<leader>at",
        function() require("snacks.terminal").toggle(cmd, terminal_opts) end,
        desc = "Toggle OpenCode",
      },
      {
        "go",
        -- A trailing space appends context without submitting the prompt.
        function() return require("opencode").operator("@this ") end,
        mode = { "n", "x" },
        expr = true,
        desc = "Append Range to OpenCode",
      },
      {
        "goo",
        function() return require("opencode").operator("@this ") .. "_" end,
        expr = true,
        desc = "Append Line to OpenCode",
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>a", group = "OpenCode", mode = { "n", "x" } },
      },
    },
  },
}
