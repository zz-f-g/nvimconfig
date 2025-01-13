-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.autoformat = false
vim.g.root_spec = { "cwd" }

local opt = vim.opt
-- opt.expandtab = false
opt.wrap = true
opt.winbar = "%=%m %f" -- display current file abspath
opt.foldmethod = "indent"
opt.spell = false
opt.mouse = ""
