local function keyed_projects(opts, keys)
  local items = Snacks.dashboard.sections.projects(opts)
  for i, item in ipairs(items) do
    item.key = keys:sub(i, i)
    item.autokey = false
  end
  items.padding = opts.padding
  return items
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        interactive = false,
        win = {
          keys = {
            gF = {
              function(terminal)
                require("utils.terminal").goto_file(terminal)
              end,
              desc = "Go to File and Line",
            },
          },
        },
      },
      dashboard = {
        sections = {
          { section = "header" },
          { title = "Repos", padding = 1 },
          function()
            return keyed_projects({ padding = 1, limit = 8 }, "0123456789")
          end,
          { title = "Recents", padding = 1 },
          function()
            return keyed_projects({
              padding = 1,
              limit = 8,
              dirs = function()
                local sessions = require("persistence").list()
                local session_dir = require("persistence.config").options.dir
                local dirs, seen = {}, {}
                -- Match Persistence's session selector: newest session first, one entry per directory.
                for _, session in ipairs(sessions) do
                  local name = session:sub(#session_dir + 1, -5)
                  local dir = vim.split(name, "%%", { plain = true })[1]:gsub("%%", "/")
                  if jit.os:find("Windows") then
                    dir = dir:gsub("^(%w)/", "%1:/")
                  end
                  if not seen[dir] and vim.fn.isdirectory(dir) == 1 then
                    seen[dir] = true
                    dirs[#dirs + 1] = dir
                  end
                end
                return dirs
              end,
              action = function(dir)
                vim.fn.chdir(dir)
                require("persistence").load()
              end,
            }, "abcdefghijklmnopqrstuvwxyz")
          end,
          { section = "startup" },
        },
      },
      image = {
        enabled = false,
      },
    },
  },
}
