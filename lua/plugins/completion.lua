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
      -- sources = {
      --   providers = {
      --     snippets = {score_offset = 1000},
      --   }
      -- },
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
