return {
  {
    "lervag/vimtex",
    lazy = false, -- lazy-loading will disable inverse search
    init = function ()
      vim.g.vimtex_view_method = "sioyek"
      vim.g.vimtex_view_sioyek_exe = "sioyek"
      -- vim.g.vimtex_mappings_prefix = "<leader>t"
    end,
  }
}
