return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "markdownlint-cli2",
        "markdown-toc",
        "basedpyright",
        "clangd",
        "rust-analyzer",
      }
    },
  },
}
