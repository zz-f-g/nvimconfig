return {
  {
    "ywsrock/nvim-md-preview",
    lazy = true,
    ft = "markdown",
    cmd = {
      "MarkdownPreview",
      "MarkdownPreviewStop",
      "MarkdownPreviewToggle",
      "MdPreview",
      "MdPreviewStop",
      "MdPreviewInstall",
      "MdPreviewInfo",
      "MdPreviewDiff",
      "MdPreviewExport",
    },
    -- Upstream installer downloads the preview binary and export tools.
    build = ":MdPreviewInstall",
    main = "md_preview",
    opts = {
      filetypes = { "markdown" },
    },
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Markdown Preview" },
    },
  },
}
