-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.autoformat = false
vim.g.root_spec = { "cwd" }
vim.g.snacks_animate = false
-- CLipboard over ssh
local ssh_connection = vim.fn.getenv("SSH_CONNECTION")
if ssh_connection ~= vim.NIL then
    vim.g.clipboard = {
        name = 'OSC 52',
        copy = {
            ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
            ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
            ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
            ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        },
    }
end

local opt = vim.opt
-- opt.expandtab = false
opt.wrap = true
opt.winbar = "%=%m %f" -- display current file abspath
opt.foldmethod = "indent"
opt.spell = false
