-- Smart file navigation function for terminal output
-- Supports multiple formats: GDB output, Python tracebacks, IPython output, filename(line), file:line
local function smart_goto_file(terminal_instance)
  -- Get current line content
  local current_line = vim.api.nvim_get_current_line()

  local file_path, line_num, col_num

  -- Pattern 1: GDB/debugger format "at src/main.rs:21"
  file_path, line_num = current_line:match("at%s+([^:]+):(%d+)")

  -- Pattern 2: Python traceback format "File "/path/file.py", line 123"
  if not file_path then
    file_path, line_num = current_line:match('File%s+"([^"]+)",%s+line%s+(%d+)')
  end

  -- Pattern 3: Python IPython format "> /path/to/main.py(1)<module>()"
  if not file_path then
    file_path, line_num = current_line:match(">%s+([^(]+)%((%d+)%)")
  end

  -- Pattern 4: Python IPython line format "----> 123 some code"
  if not file_path then
    line_num = current_line:match("%-%-%-?>%s+(%d+)%s+")
    if line_num then
      -- Search for file path in previous lines
      local buf = vim.api.nvim_get_current_buf()
      local current_row = vim.api.nvim_win_get_cursor(0)[1]
      for i = current_row - 1, math.max(1, current_row - 10), -1 do
        local prev_line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1] or ""
        local prev_file = prev_line:match(">%s+([^(]+)%(")
        if prev_file then
          file_path = prev_file
          break
        end
      end
    end
  end

  -- Pattern 5: Rust panic format or other file path patterns
  if not file_path then
    file_path, line_num = current_line:match("([^%s]+%.rs):(%d+)")
  end

  -- Pattern 6: General filename(lineno) format
  if not file_path then
    local cword = vim.fn.expand("<cWORD>")
    file_path, line_num = cword:match("^([^(]+)%((%d+)%)$")
  end

  -- Pattern 7: Standard format "filename:line" or "filename:line:col" (fallback)
  if not file_path then
    local cword = vim.fn.expand("<cWORD>")
    file_path, line_num, col_num = cword:match("^([^:]+):(%d+):?(%d*)$")
  end

  if not file_path then
    Snacks.notify.warn("No file:line pattern found")
    return
  end

  -- Check if file exists
  local full_path = vim.fn.findfile(file_path, "**")
  if full_path == "" then
    -- If findfile fails, try direct path check
    if vim.fn.filereadable(file_path) == 1 then
      full_path = file_path
    else
      Snacks.notify.warn("File not found: " .. file_path)
      return
    end
  end

  -- Hide terminal
  terminal_instance:hide()

  -- Navigate to file and specified line
  vim.schedule(function()
    vim.cmd("e " .. vim.fn.fnameescape(full_path))

    -- Jump to specified line
    local line = tonumber(line_num)
    if line and line > 0 then
      vim.api.nvim_win_set_cursor(0, {line, 0})

      -- If column number exists, jump to specified column
      if col_num and col_num ~= "" then
        local col = tonumber(col_num)
        if col and col > 0 then
          vim.api.nvim_win_set_cursor(0, {line, col - 1}) -- Neovim column index starts from 0
        end
      end

      -- Center the target line in view
      vim.cmd("normal! zz")
    end
  end)
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        interactive = false,
        win = {
          -- position = "float",
          keys = {
            gF = smart_goto_file,
          }
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
      -- image = {
      -- },
    },
  },
}
