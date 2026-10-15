-- Loaded automatically after LazyVim's defaults.
-- https://www.lazyvim.org/configuration/general#auto-commands
local function augroup(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

local function is_file_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return false
  end
  local name = vim.api.nvim_buf_get_name(buf)
  return vim.bo[buf].buftype == "" and name ~= "" and not name:match("^%a[%w+.-]*://")
end

-- Save modified, writable files immediately on either event, without debouncing.
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  group = augroup("autosave"),
  desc = "Save modified files on InsertLeave and TextChanged",
  nested = true, -- Allow normal BufWritePre/BufWritePost hooks, including LazyVim's directory creation.
  callback = function(event)
    local buf = event.buf
    if not is_file_buffer(buf) or not vim.bo[buf].modified or vim.bo[buf].readonly or not vim.bo[buf].modifiable then
      return
    end
    local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd("silent update")
    end)
    if not ok then
      vim.notify("Auto-save failed: " .. vim.api.nvim_buf_get_name(buf) .. "\n" .. tostring(err), vim.log.levels.ERROR)
    end
  end,
})

local function canonical_path(path)
  return vim.fs.normalize(vim.uv.fs_realpath(path) or vim.fn.resolve(vim.fn.fnamemodify(path, ":p")))
end

local function is_subpath(path, parent)
  parent = parent:gsub("/+$", "")
  return path == parent or vim.startswith(path, parent .. "/")
end

-- Decide once, when opening a file. Directory changes do not unlock or relock buffers.
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = augroup("cwd_readonly"),
  desc = "Disallow editing files opened outside CWD",
  callback = function(event)
    local buf = event.buf
    if not is_file_buffer(buf) then
      return
    end
    local filename = vim.api.nvim_buf_get_name(buf)
    local first_open = not vim.b[buf].cwd_readonly_checked
    if first_open then
      local path = canonical_path(filename)
      local cwd = canonical_path(vim.fn.getcwd())
      local scratch = canonical_path(vim.fn.stdpath("data") .. "/scratch")
      vim.b[buf].cwd_readonly_locked = not (is_subpath(path, cwd) or is_subpath(path, scratch))
      vim.b[buf].cwd_readonly_checked = true
    end
    if not vim.b[buf].cwd_readonly_locked then
      return
    end

    -- Reading the file again can reset these options; restore the original decision.
    vim.bo[buf].readonly = true
    vim.bo[buf].modifiable = false
    if first_open then
      vim.notify("Opened outside CWD, set to readonly and nomodifiable: " .. filename, vim.log.levels.WARN)
    end
  end,
})

-- Override these filetypes without clearing LazyVim's wrap/spell defaults for other text files.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("text_options"),
  pattern = { "gitcommit", "markdown" },
  desc = "Wrap text without spell checking; show Markdown markup",
  callback = function(event)
    vim.opt_local.wrap = true
    vim.opt_local.spell = false
    if vim.bo[event.buf].filetype == "markdown" then
      vim.opt_local.conceallevel = 0
    end
  end,
})

local terminal_group = augroup("native_terminal")
-- Track shell-reported CWD for relative file jumps, without changing Neovim's CWD.
-- https://neovim.io/doc/user/terminal/#terminal-osc7
vim.api.nvim_create_autocmd("TermRequest", {
  group = augroup("terminal_cwd"),
  desc = "Track terminal working directory from OSC 7",
  callback = function(event)
    local uri = event.data.sequence:match("^\027%]7;(file://[^%z\1-\31]+)")
    if uri then
      local dir = vim.uri_to_fname(uri)
      if vim.fn.isdirectory(dir) == 1 then
        vim.b[event.buf].osc7_dir = dir
      end
    end
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = terminal_group,
  desc = "Double Escape to normal mode in native terminals",
  callback = function(event)
    -- Snacks terminals already implement double Escape.
    -- if not vim.b[event.buf].snacks_terminal then
    vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", {
      desc = "Enter Normal Mode",
      buffer = event.buf,
    })
    -- end
  end,
})

vim.api.nvim_create_autocmd("TermEnter", {
  group = terminal_group,
  desc = "Pass Ctrl-h/j/k/l through to the terminal",
  callback = function(event)
    for _, key in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
      -- These buffer-local navigation mappings may not exist in native terminals.
      pcall(vim.keymap.del, "t", key, { buffer = event.buf })
    end
  end,
})
