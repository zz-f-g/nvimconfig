return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        interactive = false,
        win = {
          keys = {
            gF = {
              function(terminal)
                require("utils.terminal").goto_file(terminal)
              end,
              desc = "Go to File and Line",
            },
          },
        },
      },
      dashboard = {
        sections = {
          { section = "header" },
          { title = "Projects", padding = 1 },
          { section = "projects", padding = 1, limit = 15 },
          { section = "startup" },
        },
      },
      image = {
        enabled = false,
      },
    },
  },
}
