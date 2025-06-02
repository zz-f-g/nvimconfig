return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o", "v" }, false },
      { "r", mode = { "n", "x", "o", "v" }, false },
      { "R", mode = { "n", "x", "o", "v" }, false },
      { "<c-s>", mode = { "n", "x", "o", "v" }, false },
    },
  }
}
