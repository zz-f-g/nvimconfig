-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

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

local function is_subpath(path, parent)
    local real_path = vim.fn.resolve(path)
    local real_parent = vim.fn.resolve(parent)
    return vim.startswith(real_path, real_parent)
end

-- set readonly if file opened not under cwd
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local buf = args.buf
    local filename = vim.api.nvim_buf_get_name(buf)
    local cwd = vim.fn.getcwd()
    if filename ~= "" and not is_subpath(filename, cwd) then
      vim.bo[buf].readonly = true
      vim.bo[buf].modifiable = false
      vim.notify("Opened outside CWD, set to readonly: " .. filename, vim.log.levels.WARN)
    end
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client:supports_method('textDocument/foldingRange') then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
    end
  end,
})
