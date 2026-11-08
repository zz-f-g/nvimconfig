return {
  {
    "bngarren/checkmate.nvim",
    ft = "markdown", -- Lazy loads for Markdown files matching patterns in 'files'
    opts = function(_, opts)
      -- Checkmate does not merge custom keys with its defaults.
      opts.keys = vim.deepcopy(opts.keys or require("checkmate.config.defaults").keys)
      opts.keys["<leader>TR"] = {
        rhs = "<cmd>Checkmate metadata remove_all<CR>",
        desc = "Remove all metadata from a todo item",
        modes = { "n", "v" },
      }
      return vim.tbl_deep_extend("force", opts, {
        todo_states = {
          checked = {
            marker = "[x]", -- how it appears in Neovim
            order = 1,
          },
          unchecked = {
            marker = "[ ]", -- how it appears in Neovim
            order = 2,
          },
        },
        -- files = { "*.md" }, -- any .md file (instead of defaults)
        metadata = {
          -- Example: A @priority tag that has dynamic color based on the priority value
          priority = {
            style = function(context)
              local value = context.value:lower()
              if value == "high" then
                return { fg = "#ff5555", bold = true }
              elseif value == "medium" then
                return { fg = "#ffb86c" }
              elseif value == "low" then
                return { fg = "#8be9fd" }
              else -- fallback
                return { fg = "#8be9fd" }
              end
            end,
            get_value = function()
              return "medium" -- Default priority
            end,
            choices = function()
              return { "low", "medium", "high" }
            end,
            key = "<leader>Tp",
            sort_order = 10,
            jump_to_on_insert = "value",
            select_on_insert = true,
          },
          -- Example: A @started tag that uses a default date/time string when added
          started = {
            aliases = { "init" },
            style = { fg = "#9fd6d5" },
            get_value = function()
              return tostring(os.date("%y-%m-%d %H:%M"))
            end,
            key = "<leader>Ts",
            sort_order = 20,
          },
          -- Example: A @done tag that also sets the todo item state when it is added and removed
          done = {
            aliases = { "completed", "finished" },
            style = { fg = "#96de7a" },
            get_value = function()
              return tostring(os.date("%y-%m-%d %H:%M"))
            end,
            key = "<leader>Td",
            on_add = function(todo)
              require("checkmate").set_todo_state(todo, "checked")
            end,
            on_remove = function(todo)
              require("checkmate").set_todo_state(todo, "unchecked")
            end,
            sort_order = 30,
          },
          -- Short work summary; keep longer details in the indented Markdown body
          note = {
            style = { fg = "#9fd6d5" },
            get_value = function()
              return ""
            end,
            key = "<leader>Tm",
            sort_order = 40,
            jump_to_on_insert = false,
            select_on_insert = false,
            on_add = function(todo)
              -- Run after the metadata transaction; position and enter Insert together.
              local win = vim.api.nvim_get_current_win()
              vim.schedule(function()
                if not vim.api.nvim_win_is_valid(win)
                  or vim.api.nvim_get_current_win() ~= win
                  or vim.api.nvim_win_get_buf(win) ~= todo.bufnr
                then
                  return
                end
                local line = vim.api.nvim_buf_get_lines(todo.bufnr, todo.row, todo.row + 1, false)[1]
                local start = line and line:find("@note()", 1, true)
                if start then
                  -- Insert before the closing parenthesis of the empty note.
                  vim.api.nvim_win_set_cursor(win, { todo.row + 1, start + #"@note(" - 1 })
                  vim.cmd("startinsert")
                end
              end)
            end,
          },
        },
      })
    end,
  }
}
