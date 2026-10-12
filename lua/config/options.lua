-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.autoformat = false
vim.g.root_spec = { "cwd" }
vim.g.snacks_animate = false
vim.g.python_indent = {
  closed_paren_align_last_line = false,
  open_paren = "shiftwidth()",
}
-- Copy to the local clipboard over SSH; paste using the terminal's Ctrl-Shift-V.
if vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")
  -- The provider requires paste callbacks. Return no text instead of querying the terminal.
  local function no_paste()
    return {}
  end
  vim.g.clipboard = {
    name = "OSC 52 (copy only)",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = no_paste,
      ["*"] = no_paste,
    },
  }
end

local opt = vim.opt
-- opt.expandtab = false
opt.wrap = true
opt.winbar = "%=%m %f" -- display current file abspath
opt.spell = false
opt.scrolloff = 0
opt.foldmethod = "indent"
opt.undofile = true                      -- Enable persistent undo
opt.undodir = vim.fn.expand("~/.undodir") -- Set custom undo directory
