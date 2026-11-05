local M = {}

-- These server/discovery helpers are internal to opencode.nvim's V2 implementation.
local function last_response(server, session_id, cursor, seen)
  local Promise = require("opencode.promise")
  local path = "/api/session/" .. vim.uri_encode(session_id) .. "/message?type=assistant&limit=50"
  path = path .. (cursor and ("&cursor=" .. vim.uri_encode(cursor)) or "&order=desc")

  return server:request(path, "GET"):next(function(response)
    for _, message in ipairs(response and response.data or {}) do
      if message.type == "assistant" and message.time and type(message.time.completed) == "number" then
        local parts = {}
        for _, part in ipairs(message.content or {}) do
          if part.type == "text" and type(part.text) == "string" and part.text:match("%S") then
            parts[#parts + 1] = part.text
          end
        end
        if #parts > 0 then
          return Promise.resolve({ text = table.concat(parts, "\n\n"), message_id = message.id })
        end
      end
    end

    local next_cursor = response and response.cursor and response.cursor.next
    if type(next_cursor) == "string" and next_cursor ~= "" and not seen[next_cursor] then
      seen[next_cursor] = true
      return last_response(server, session_id, next_cursor, seen)
    end
    return Promise.reject("No completed OpenCode response with text found in this session.")
  end)
end

function M.open()
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
        return last_response(server, session.id, nil, {}):next(function(result)
          -- A normal unnamed buffer can be edited and saved with :w path.md.
          -- Creating it directly avoids replacing an unsaved source buffer.
          local buf = vim.api.nvim_create_buf(true, false)
          vim.bo[buf].swapfile = false
          vim.bo[buf].bufhidden = "hide"
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result.text, "\n", { plain = true }))
          vim.b[buf].opencode_session_id = session.id
          vim.b[buf].opencode_message_id = result.message_id
          vim.b[buf].opencode_directory = cwd
          vim.api.nvim_set_current_buf(buf)
          vim.bo[buf].filetype = "markdown"
          vim.api.nvim_win_set_cursor(0, { 1, 0 })
        end)
      end)
    end)
    :catch(function(err)
      if err then
        vim.notify(tostring(err), vim.log.levels.WARN, { title = "OpenCode Last Response" })
      end
    end)
end

return M
