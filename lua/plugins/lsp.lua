return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = { -- pyright but based. manually install off PyPI
          mason = false,
          settings = {
            basedpyright = {
              analysis = {
                autoImportCompletions = true, -- offer auto-import completions
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly", -- "workspace"
                useLibraryCodeForTypes = true,
                -- https://detachhead.github.io/basedpyright/#/configuration?id=diagnostic-settings-defaults
                -- TLDR: change this for less strict checking (less errors)
                -- typeCheckingMode = "standard", -- basedpyright default is "all"
                diagnosticSeverityOverrides = {
                  -- https://detachhead.github.io/basedpyright/#/configuration?id=type-check-diagnostics-settings
                  -- one of: error, warning, information, true, false, none
                  reportMissingTypeStubs = "information", -- import has no type stub file
                  reportAny = false, -- bans all usage of 'Any' type
                  reportUnusedCallResult = false, -- call statements with return value that is not used (e.g. not _ = call())
                  reportMissingParameterType = false, -- function or method input parameters without type definition
                  -- reportOptionalMemberAccess = "warning",  -- access to member of object that has Optional[] type (e.g. obj.append() on Optional[list])
                  reportUnknownArgumentType = false, -- unknown (not statically typed/not inferrable) types
                  reportUnknownLambdaType = false,
                  reportUnknownMemberType = false,
                  reportUnknownParameterType = false,
                  reportUnknownVariableType = false,
                  -- include basedpyright-only options, even if "standard" is selected (defaults to only in "all")
                  -- https://detachhead.github.io/basedpyright/#/configuration?id=based-options
                  reportIgnoreCommentWithoutRule = "warning",
                  reportUnreachable = "error",
                  reportPrivateLocalImportUsage = "error",
                  reportImplicitRelativeImport = "error",
                  reportInvalidCast = "error",
                  reportMissingSuperCall = false,
                },
              },
            },
          },
        },
        clangd = {
          mason = false,
          keys = {
            { "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
          },
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern(
              "Makefile",
              "configure.ac",
              "configure.in",
              "config.h.in",
              "meson.build",
              "meson_options.txt",
              "build.ninja"
            )(fname) or require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt")(
              fname
            ) or require("lspconfig.util").find_git_ancestor(fname)
          end,
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
        },
        rust_analyzer = {},
      },
    },
  },
}
