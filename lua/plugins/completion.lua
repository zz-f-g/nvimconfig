local local_snippet_filetypes = { markdown = true, tex = true }

return {
  {
    'saghen/blink.cmp',
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      completion = {
        documentation = {
          auto_show = true,
        }
      },
      sources = {
        providers = {
          snippets = {
            override = {
              get_trigger_characters = function()
                return { "^" }
              end,
            },
            transform_items = function(_, items)
              if not local_snippet_filetypes[vim.bo.filetype] then
                return items
              end

              local seen = {}
              return vim.tbl_filter(function(item)
                if seen[item.label] then
                  return false
                end
                seen[item.label] = true
                return true
              end, items)
            end,
          },
        },
      },
      keymap = {
        preset = "default",
        ['<Tab>'] = {
          'snippet_forward',
          function(cmp)
            if cmp.snippet_active() then
              return cmp.accept()
            else
              return cmp.select_and_accept()
            end
          end,
          'fallback'
        },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
      }
    }
  }
}
