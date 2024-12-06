-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
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
