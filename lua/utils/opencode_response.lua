local M = {}

-- These server/discovery helpers are internal to opencode.nvim's V2 implementation.
local function response_text(message)
  if message.type ~= "assistant" or not message.time or type(message.time.completed) ~= "number" then
    return
  end
  local parts = {}
  for _, part in ipairs(message.content or {}) do
    if part.type == "text" and type(part.text) == "string" and part.text:match("%S") then
      parts[#parts + 1] = part.text
    end
  end
  if #parts > 0 then
    return table.concat(parts, "\n\n")
  end
end

-- Fetch until a page contains usable replies or the history is exhausted.
local function response_page(server, session_id, cursor, seen)
  local Promise = require("opencode.promise")
  local path = "/api/session/" .. vim.uri_encode(session_id) .. "/message?type=assistant&limit=50"
  path = path .. (cursor and ("&cursor=" .. vim.uri_encode(cursor)) or "&order=desc")

  return server:request(path, "GET"):next(function(response)
    local items = {}
    for _, message in ipairs(response and response.data or {}) do
      local text = response_text(message)
      if text then
        items[#items + 1] = { text = text, message_id = message.id, time = message.time.completed }
      end
    end

    local next_cursor = response and response.cursor and response.cursor.next
    if type(next_cursor) == "string" and next_cursor ~= "" and not seen[next_cursor] then
      seen[next_cursor] = true
    else
      next_cursor = nil
    end
    if #items == 0 and next_cursor then
      return response_page(server, session_id, next_cursor, seen)
    end
    return Promise.resolve({ items = items, cursor = next_cursor })
  end)
end

local function capture_target()
  local buf = vim.api.nvim_get_current_buf()
  return {
    buf = buf,
    row = vim.api.nvim_win_get_cursor(0)[1],
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
  }
end

local function append_response(result, target)
  local buf = target.buf
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    error("The original buffer was closed; response was not inserted.", 0)
  end
  if not vim.bo[buf].modifiable then
    error("The original buffer is not modifiable; response was not inserted.", 0)
  end
  if vim.api.nvim_buf_get_changedtick(buf) ~= target.changedtick then
    error("The original buffer changed; invoke the shortcut again to choose a new insertion point.", 0)
  end
  vim.api.nvim_buf_set_lines(buf, target.row, target.row, false, vim.split(result.text, "\n", { plain = true }))
end

local function notify(err)
  if err then
    vim.notify(tostring(err), vim.log.levels.WARN, { title = "OpenCode Responses" })
  end
end

local function with_session(callback)
  local cwd = vim.fn.getcwd()
  local Promise = require("opencode.promise")
  return require("opencode.server.discovery")
    .get()
    :next(function(server)
      -- Match opencode.nvim's session policy, but freeze the directory at keypress
      -- time rather than reading a possibly changed CWD after service discovery.
      local path = "/api/session?directory=" .. vim.uri_encode(cwd)
        .. "&order=desc&parentID=null&archived=false&limit=1"
      return server:request(path, "GET"):next(function(response)
        local session = response and response.data and response.data[1]
        if not session then
          return Promise.reject("No OpenCode session found for `" .. cwd .. "`. Start one in the TUI.")
        end
        return callback(server, session, cwd)
      end)
    end)
    :catch(notify)
end

function M.open()
  local target = capture_target()
  return with_session(function(server, session)
    return response_page(server, session.id, nil, {}):next(function(page)
      if not page.items[1] then
        return require("opencode.promise").reject("No completed OpenCode response with text found in this session.")
      end
      append_response(page.items[1], target)
    end)
  end)
end

function M.history()
  local target = capture_target()
  return with_session(function(server, session, cwd)
    local seen = {}
    return response_page(server, session.id, nil, seen):next(function(page)
      if #page.items == 0 then
        return require("opencode.promise").reject("No completed OpenCode response with text found in this session.")
      end
      local items, ids = {}, {}
      local cursor, loading = page.cursor, false
      local function append(responses)
        for _, result in ipairs(responses) do
          if not ids[result.message_id] then
            ids[result.message_id] = true
            local summary = vim.trim(result.text):match("[^\r\n]+") or ""
            -- OpenCode timestamps are milliseconds since the Unix epoch.
            items[#items + 1] = {
              text = result.text:gsub("%s+", " "),
              label = os.date("%Y-%m-%d %H:%M", math.floor(result.time / 1000)) .. "  " .. summary,
              preview = { text = result.text, ft = "markdown", loc = false },
              response = result,
            }
          end
        end
      end
      append(page.items)
      require("snacks.picker")({
        title = "OpenCode Responses (loaded only; Ctrl-l: older)",
        cwd = cwd,
        finder = function() return items end,
        format = function(item) return { { item.label } } end,
        preview = "preview",
        -- Keep API order when unfiltered, and stable chronological tie-breaks.
        sort = { fields = { "score:desc", "idx" } },
        matcher = { sort_empty = false, file_pos = false },
        layout = { preset = "default", preview = true },
        win = {
          input = { keys = {
            ["<C-l>"] = { "load_older", mode = { "n", "i" }, desc = "Load older responses" },
            ["<Esc>"] = { "cancel", mode = { "n", "i" } },
          } },
          list = { keys = {
            ["<C-l>"] = "load_older",
            ["<Esc>"] = "cancel",
          } },
        },
        actions = {
          load_older = function(picker)
            if loading then
              return
            end
            if not cursor then
              vim.notify("All OpenCode responses loaded.", vim.log.levels.INFO)
              return
            end
            loading = true
            -- Only commit pagination state after success so failed loads can retry.
            local next_seen = vim.deepcopy(seen)
            response_page(server, session.id, cursor, next_seen):next(function(older)
              loading = false
              if picker.closed then
                return
              end
              seen = next_seen
              cursor = older.cursor
              append(older.items)
              picker:find()
            end):catch(function(err)
              loading = false
              if not picker.closed then
                notify(err)
              end
            end)
          end,
        },
        confirm = function(picker, item)
          if not item then
            return
          end
          picker:close()
          local ok, err = pcall(append_response, item.response, target)
          if not ok then
            notify(err)
          end
        end,
      })
    end)
  end)
end

return M
