-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- terminal double escape to normal mode
vim.api.nvim_create_autocmd({ "TermOpen" }, {
  group = nativeTermGroup,
  pattern = "term://*",
  callback = function(event)
    local buf = event.buf
    -- vim.keymap.set("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window", buffer = buf, nowait = true })
    -- vim.keymap.set("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Above Window", buffer = buf, nowait = true })
    vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode", buffer = buf, nowait = true })
  end,
})

-- auto save buffer when escaping insert mode
local function save()
  local buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent! write")
  end)
end

vim.api.nvim_create_augroup("AutoSave", {
  clear = true,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  callback = function()
  save()
  end,
  pattern = "*",
  group = "AutoSave",
})

-- turn off spell checking in md file
local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = false -- overwrite default true
  end,
})
