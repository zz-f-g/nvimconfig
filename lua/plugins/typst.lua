return {
  {
    'chomosuke/typst-preview.nvim',
    lazy = true,
    ft = 'typst',
    version = '1.*',
    opts = {
      open_cmd = 'firefox %s'
    }, -- lazy.nvim will implicitly calls `setup {}`
  }
}
