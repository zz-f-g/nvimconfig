local local_snippet_sources = { "lsp", "path", "local_snippets", "buffer" }
local tex_sources = { "lsp", "omni", "path", "local_snippets", "buffer" }

return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        list = {
          selection = { auto_insert = false },
        },
        menu = {
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "source_name" },
            },
          },
        },
      },
      sources = {
        per_filetype = {
          markdown = local_snippet_sources,
          tex = tex_sources,
          plaintex = tex_sources,
          opencode_ask = { "lsp", "buffer" },
        },
        providers = {
          -- Use VimTeX's project-aware citation, label, command, and environment completion.
          omni = {
            name = "VimTeX",
            enabled = function()
              return vim.bo.omnifunc == "vimtex#complete#omnifunc"
            end,
            override = {
              get_trigger_characters = function()
                return { "\\", "{", "," }
              end,
            },
          },
          -- Separate from the default provider so friendly-snippets' global snippets are excluded too.
          local_snippets = {
            name = "Local Snippets",
            module = "blink.cmp.sources.snippets",
            score_offset = -1,
            opts = { friendly_snippets = false },
            override = {
              get_trigger_characters = function()
                return { "^" }
              end,
            },
          },
        },
      },
      keymap = {
        preset = "default",
        ["<Tab>"] = {
          "snippet_forward",
          function(cmp)
            if cmp.snippet_active() then
              return cmp.accept()
            else
              return cmp.select_and_accept()
            end
          end,
          "fallback",
        },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },
    },
  },
}
