local M = {}

-- Use Neovim's errorformat parser without changing the user's quickfix list.
-- Capture the path as %m, not %f, so it is not resolved against Neovim's CWD.
local errorformat = table.concat({
  [[File "%m"\, line %l%.%#]],
  "%m(%l:%c)%.%#",
  "%m(%l)%.%#",
  "%m:%l:%c%.%#",
  "%m:%l%.%#",
  "%-G%.%#",
}, ",")

local function parse(text, cwd)
  local items = vim.fn.getqflist({ lines = { vim.trim(text) }, efm = errorformat }).items
  for _, item in ipairs(items) do
    if item.valid == 1 then
      local path = vim.fs.normalize((vim.trim(item.text):gsub([[^[%(%["']+]], ""):gsub([[['"]$]], "")))
      if path:sub(1, 1) ~= "/" then
        path = vim.fs.normalize(cwd .. "/" .. path)
      end
      if vim.fn.filereadable(path) == 1 then
        return { file = path, line = item.lnum, col = item.col }
      end
    end
  end
end

local function header(text)
  text = vim.trim(text)
  if text:match('^File%s+"') then
    return text
  end
  return text:match("^>%s+(.+)$") or text:match("^File%s+(.+)$")
end

local function location(buf, cwd)
  local text = vim.trim(vim.api.nvim_get_current_line())
  -- IPython places the active line below its frame header, sometimes more than ten lines away.
  local line = text:match("^%-+>%s*(%d+)%s")
  if line then
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local previous = vim.api.nvim_buf_get_lines(buf, 0, row - 1, false)
    for i = #previous, 1, -1 do
      local frame = header(previous[i])
      if frame then
        local item = parse(frame, cwd)
        if not item then
          return -- Do not fall back to a different, older traceback frame.
        end
        item.line = tonumber(line)
        item.col = 0
        return item
      end
      if previous[i]:match("^In %[") or previous[i]:match("^Traceback") then
        break
      end
    end
    return
  end

  -- Structured frames preserve full paths, including spaces, regardless of cursor position.
  local frame = text:match("%f[%a]at%s+(.+)$") or header(text)
  if frame then
    return parse(frame, cwd)
  end
  -- Otherwise prefer the token under the cursor when a line contains multiple locations.
  return parse(vim.fn.expand("<cWORD>"), cwd) or parse(text, cwd)
end

function M.goto_file(terminal)
  local buf = vim.api.nvim_get_current_buf()
  local cwd = vim.b[buf].osc7_dir
    or (vim.b[buf].snacks_terminal or {}).cwd
    or vim.api.nvim_buf_get_name(buf):match("^term://(.-)//%d+:")
    or vim.fn.getcwd()
  local item = location(buf, cwd)
  if not item then
    vim.notify("No readable file:line location found (terminal CWD: " .. cwd .. ")", vim.log.levels.WARN)
    return
  end

  terminal:hide()
  local win = vim.api.nvim_get_current_win()
  local function is_editor(w)
    return vim.api.nvim_win_get_config(w).relative == ""
      and vim.bo[vim.api.nvim_win_get_buf(w)].buftype == ""
  end
  if not is_editor(win) then
    for _, other in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if is_editor(other) then
        win = other
        break
      end
    end
  end
  if not is_editor(win) then
    vim.cmd("new")
    win = vim.api.nvim_get_current_win()
  end

  -- Keep the destination window fixed even if focus changes before the callback runs.
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(win) then
      return
    end
    local ok, err = pcall(vim.api.nvim_win_call, win, function()
      -- Buffer numbers avoid filename expansion and escaping issues in :edit.
      local target = vim.fn.bufadd(item.file)
      vim.bo[target].buflisted = true
      vim.cmd.buffer(target)
      local row = math.min(math.max(item.line, 1), vim.api.nvim_buf_line_count(target))
      local text = vim.api.nvim_buf_get_lines(target, row - 1, row, false)[1]
      local col = math.min(math.max(item.col - 1, 0), math.max(#text - 1, 0))
      vim.api.nvim_win_set_cursor(win, { row, col })
      vim.cmd("normal! zvzz")
    end)
    if not ok then
      vim.notify("Terminal file jump failed: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

return M
