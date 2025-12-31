local function set_python_path(command)
  local path = command.args
  local clients = vim.lsp.get_clients {
    bufnr = vim.api.nvim_get_current_buf(),
    name = 'basedpyright',
  }
  for _, client in ipairs(clients) do
    if client.settings then
      ---@diagnostic disable-next-line: param-type-mismatch
      client.settings.python = vim.tbl_deep_extend('force', client.settings.python or {}, { pythonPath = path })
    else
      client.config.settings = vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
    end
    client:notify('workspace/didChangeConfiguration', { settings = nil })
  end
end

local function switch_source_header(bufnr, client)
  local method_name = 'textDocument/switchSourceHeader'
  ---@diagnostic disable-next-line:param-type-mismatch
  if not client or not client:supports_method(method_name) then
    return vim.notify(('method %s is not supported by any servers active on the current buffer'):format(method_name))
  end
  local params = vim.lsp.util.make_text_document_params(bufnr)
  ---@diagnostic disable-next-line:param-type-mismatch
  client:request(method_name, params, function(err, result)
    if err then
      error(tostring(err))
    end
    if not result then
      vim.notify('corresponding file cannot be determined')
      return
    end
    vim.cmd.edit(vim.uri_to_fname(result))
  end, bufnr)
end

local function symbol_info(bufnr, client)
  local method_name = 'textDocument/symbolInfo'
  ---@diagnostic disable-next-line:param-type-mismatch
  if not client or not client:supports_method(method_name) then
    return vim.notify('Clangd client not found', vim.log.levels.ERROR)
  end
  local win = vim.api.nvim_get_current_win()
  local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
  ---@diagnostic disable-next-line:param-type-mismatch
  client:request(method_name, params, function(err, res)
    if err or #res == 0 then
      -- Clangd always returns an error, there is no reason to parse it
      return
    end
    local container = string.format('container: %s', res[1].containerName) ---@type string
    local name = string.format('name: %s', res[1].name) ---@type string
    vim.lsp.util.open_floating_preview({ name, container }, '', {
      height = 2,
      width = math.max(string.len(name), string.len(container)),
      focusable = false,
      focus = false,
      title = 'Symbol Info',
    })
  end, bufnr)
end

---@class ClangdInitializeResult: lsp.InitializeResult
---@field offsetEncoding? string

local function reload_workspace(bufnr)
  local clients = vim.lsp.get_clients { bufnr = bufnr, name = 'rust_analyzer' }
  for _, client in ipairs(clients) do
    vim.notify 'Reloading Cargo Workspace'
    ---@diagnostic disable-next-line:param-type-mismatch
    client:request('rust-analyzer/reloadWorkspace', nil, function(err)
      if err then
        error(tostring(err))
      end
      vim.notify 'Cargo workspace reloaded'
    end, 0)
  end
end

local function is_library(fname)
  local user_home = vim.fs.normalize(vim.env.HOME)
  local cargo_home = os.getenv 'CARGO_HOME' or user_home .. '/.cargo'
  local registry = cargo_home .. '/registry/src'
  local git_registry = cargo_home .. '/git/checkouts'

  local rustup_home = os.getenv 'RUSTUP_HOME' or user_home .. '/.rustup'
  local toolchains = rustup_home .. '/toolchains'

  for _, item in ipairs { toolchains, registry, git_registry } do
    if vim.fs.relpath(item, fname) then
      local clients = vim.lsp.get_clients { name = 'rust_analyzer' }
      return #clients > 0 and clients[#clients].config.root_dir or nil
    end
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        ["*"] = function()
          vim.opt.foldmethod = "manual"
          return false
        end,
      },
      servers = {
        basedpyright = { -- pyright but based. manually install off PyPI
          mason = false,
          cmd = { 'basedpyright-langserver', '--stdio' },
          filetypes = { 'python' },
          root_markers = {
            'pyrightconfig.json',
            'pyproject.toml',
            'setup.py',
            'setup.cfg',
            'requirements.txt',
            'Pipfile',
            '.git',
          },
          settings = {
            basedpyright = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = 'openFilesOnly',
              },
            },
          },
          on_attach = function(client, bufnr)
            vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
              local params = {
                command = 'basedpyright.organizeimports',
                arguments = { vim.uri_from_bufnr(bufnr) },
              }

              -- Using client.request() directly because "basedpyright.organizeimports" is private
              -- (not advertised via capabilities), which client:exec_cmd() refuses to call.
              -- https://github.com/neovim/neovim/blob/c333d64663d3b6e0dd9aa440e433d346af4a3d81/runtime/lua/vim/lsp/client.lua#L1024-L1030
              ---@diagnostic disable-next-line: param-type-mismatch
              client.request('workspace/executeCommand', params, nil, bufnr)
            end, {
              desc = 'Organize Imports',
            })

            vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightSetPythonPath', set_python_path, {
              desc = 'Reconfigure basedpyright with the provided python path',
              nargs = 1,
              complete = 'file',
            })
          end,
        },
        clangd = {
          mason = false,
          cmd = { 'clangd' },
          filetypes = { 'h', 'hpp', 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
          root_markers = {
            '.clangd',
            '.clang-tidy',
            '.clang-format',
            'compile_commands.json',
            'compile_flags.txt',
            'configure.ac', -- AutoTools
            '.git',
          },
          capabilities = {
            textDocument = {
              completion = {
                editsNearCursor = true,
              },
            },
            offsetEncoding = { 'utf-8', 'utf-16' },
          },
          ---@param init_result ClangdInitializeResult
          on_init = function(client, init_result)
            if init_result.offsetEncoding then
              client.offset_encoding = init_result.offsetEncoding
            end
          end,
          on_attach = function(client, bufnr)
            vim.api.nvim_buf_create_user_command(bufnr, 'LspClangdSwitchSourceHeader', function()
              switch_source_header(bufnr, client)
            end, { desc = 'Switch between source/header' })

            vim.api.nvim_buf_create_user_command(bufnr, 'LspClangdShowSymbolInfo', function()
              symbol_info(bufnr, client)
            end, { desc = 'Show symbol info' })
          end,
        },
        rust_analyzer = {
          cmd = { 'rust-analyzer' },
          filetypes = { 'rust' },
          root_dir = function(bufnr, on_dir)
            local fname = vim.api.nvim_buf_get_name(bufnr)
            local reused_dir = is_library(fname)
            if reused_dir then
              on_dir(reused_dir)
              return
            end

            local cargo_crate_dir = vim.fs.root(fname, { 'Cargo.toml' })
            local cargo_workspace_root

            if cargo_crate_dir == nil then
              on_dir(
                vim.fs.root(fname, { 'rust-project.json' })
                or vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
              )
              return
            end

            local cmd = {
              'cargo',
              'metadata',
              '--no-deps',
              '--format-version',
              '1',
              '--manifest-path',
              cargo_crate_dir .. '/Cargo.toml',
            }

            vim.system(cmd, { text = true }, function(output)
              if output.code == 0 then
                if output.stdout then
                  local result = vim.json.decode(output.stdout)
                  if result['workspace_root'] then
                    cargo_workspace_root = vim.fs.normalize(result['workspace_root'])
                  end
                end

                on_dir(cargo_workspace_root or cargo_crate_dir)
              else
                vim.schedule(function()
                  vim.notify(('[rust_analyzer] cmd failed with code %d: %s\n%s'):format(output.code, cmd, output.stderr))
                end)
              end
            end)
          end,
          capabilities = {
            experimental = {
              serverStatusNotification = true,
              commands = {
                commands = {
                  'rust-analyzer.showReferences',
                  'rust-analyzer.runSingle',
                  'rust-analyzer.debugSingle',
                },
              },
            },
          },
          settings = {
            ['rust-analyzer'] = {
              lens = {
                debug = { enable = true },
                enable = true,
                implementations = { enable = true },
                references = {
                  adt = { enable = true },
                  enumVariant = { enable = true },
                  method = { enable = true },
                  trait = { enable = true },
                },
                run = { enable = true },
                updateTest = { enable = true },
              },
            },
          },
          before_init = function(init_params, config)
            -- See https://github.com/rust-lang/rust-analyzer/blob/eb5da56d839ae0a9e9f50774fa3eb78eb0964550/docs/dev/lsp-extensions.md?plain=1#L26
            if config.settings and config.settings['rust-analyzer'] then
              init_params.initializationOptions = config.settings['rust-analyzer']
            end
            ---@param command table{ title: string, command: string, arguments: any[] }
            vim.lsp.commands['rust-analyzer.runSingle'] = function(command)
              local r = command.arguments[1]
              local cmd = { 'cargo', unpack(r.args.cargoArgs) }
              if r.args.executableArgs and #r.args.executableArgs > 0 then
                vim.list_extend(cmd, { '--', unpack(r.args.executableArgs) })
              end

              local proc = vim.system(cmd, { cwd = r.args.cwd })

              local result = proc:wait()

              if result.code == 0 then
                vim.notify(result.stdout, vim.log.levels.INFO)
              else
                vim.notify(result.stderr, vim.log.levels.ERROR)
              end
            end
          end,
          on_attach = function(_, bufnr)
            vim.api.nvim_buf_create_user_command(bufnr, 'LspCargoReload', function()
              reload_workspace(bufnr)
            end, { desc = 'Reload current cargo workspace' })
          end,
        },
      },
    },
  },
}
