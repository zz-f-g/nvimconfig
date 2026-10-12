-- Runnable arguments: https://rust-analyzer.github.io/book/contributing/lsp-extensions.html#runnables
local function run_rust_runnable(command)
  local runnable = command.arguments[1]
  local args = runnable.args
  local cmd
  if runnable.kind == "shell" then
    cmd = vim.list_extend({ args.program }, args.args)
  else
    cmd = vim.list_extend({ args.overrideCargo or "cargo" }, args.cargoArgs)
    if args.executableArgs and #args.executableArgs > 0 then
      vim.list_extend(cmd, { "--" })
      vim.list_extend(cmd, args.executableArgs)
    end
  end

  local ok, err = pcall(vim.system, cmd, {
    cwd = args.cwd,
    env = args.environment,
    text = true,
  }, function(result)
    vim.schedule(function()
      local output = vim.trim((result.stdout or "") .. (result.stderr or ""))
      if output == "" then
        output = ("Runnable exited with code %d"):format(result.code)
      end
      vim.notify(output, result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
  end)
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    -- https://www.lazyvim.org/plugins/lsp
    opts = {
      folds = { enabled = false }, -- Use the indent folding configured in config/options.lua.
      -- Inherit server defaults and commands from nvim-lspconfig; only override personal preferences.
      servers = {
        basedpyright = {
          mason = false,
          -- https://docs.basedpyright.com/latest/configuration/language-server-settings/
          settings = {
            basedpyright = {
              analysis = {
                inlayHints = {
                  variableTypes = false,
                  callArgumentNames = true,
                  functionReturnTypes = true,
                  genericTypes = false,
                },
              },
            },
          },
        },
        clangd = { mason = false },
        rust_analyzer = {
          mason = false,
          -- Client commands take precedence over the upstream synchronous global handler.
          commands = {
            ["rust-analyzer.runSingle"] = run_rust_runnable,
          },
        },
        tinymist = {
          mason = false,
          -- https://github.com/Myriad-Dreamin/tinymist/blob/main/editors/neovim/README.md
          settings = {
            formatterMode = "typstyle",
            exportPdf = "onType",
            semanticTokens = "disable",
          },
        },
      },
    },
  },
}
