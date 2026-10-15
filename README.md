# Neovim Configuration

A personal [LazyVim](https://www.lazyvim.org/) configuration for programming,
Markdown notes, LaTeX, and Typst. It uses lazy.nvim for plugin management, with
GitHub repositories cloned over SSH and language tools installed separately.

This README focuses on the changes to LazyVim and the additional capabilities
provided by this configuration. Unlisted keymaps generally retain their
[LazyVim defaults](https://www.lazyvim.org/keymaps). `<leader>` is Space and
`<localleader>` is backslash.

## Changes to LazyVim Defaults

### Editing and File Handling

| Area | Behavior in this configuration |
| --- | --- |
| Formatting | Automatic formatting is disabled by default. Manual formatting remains available with `<leader>cf`. |
| Autosave | Modified, writable files are saved immediately on `InsertLeave` and `TextChanged`, without a debounce timer. Unnamed buffers, special buffers, readonly files, and unmodified files are skipped. Save failures are reported. |
| Root detection | LazyVim's root-based operations use the current working directory (CWD), rather than an inferred LSP or Git root. Language servers still use their upstream project-root detection. |
| Files outside CWD | On first opening an existing or new named file, paths outside CWD become both `readonly` and `nomodifiable`. Symlinks are resolved and directory boundaries are checked. The default Snacks scratch directory is exempt. |
| Readonly lifetime | The opening-time decision stays with the buffer. Changing CWD does not unlock or relock it; rereading a locked file restores its restrictions. |
| Wrapping and spelling | Soft wrapping is enabled by default. Markdown and Git commit buffers have spelling disabled; other text filetypes retain LazyVim's filetype defaults. |
| Markdown display | `conceallevel = 0` keeps Markdown markup visible. |
| Folding | Indentation-based folding is used; LazyVim's automatic LSP folding setup is disabled. |
| Appearance | Gruvbox replaces the default theme. Snacks animations are disabled. A right-aligned winbar shows the file name/path and modified indicator. `scrolloff` is set to zero. |
| Undo | Persistent undo is retained, with undo files stored in `~/.undodir`. |
| Line movement | LazyVim's Alt-j / Alt-k move-line mappings are removed in normal, insert, and visual modes. |

**Start Neovim from the project directory you intend to edit.** For example:

```sh
cd /path/to/project
nvim
```

The CWD restriction also applies to files reached through LSP navigation or
terminal jumps. Dependency sources outside the project can be viewed, but are
not editable under this policy.

### Completion

[blink.cmp](https://cmp.saghen.dev/) remains the completion engine, with these
changes in [completion.lua](lua/plugins/completion.lua):

- The `default` keymap preset replaces LazyVim's `enter` preset: Enter is not
  assigned to accepting completion items by this configuration.
- Tab first jumps to the next snippet placeholder. If there is no forward jump,
  it attempts to accept a completion, then falls back to normal Tab behavior.
  Shift-Tab jumps backward through placeholders.
- The first candidate remains preselected, but selecting a candidate does not
  automatically insert a preview into the buffer.
- The menu displays each candidate's source, including `Local Snippets`.
- Markdown, TeX, and plain TeX use only the local snippet provider, excluding
  both language-specific and global friendly-snippets. Their other sources are
  still LSP, paths, and buffer words. TeX/plain TeX additionally use VimTeX's
  omnifunc for project-aware citations, labels, commands, and environments,
  displayed as `VimTeX` in the menu. Completion can trigger after `\`, `{`, or
  `,`, as well as while typing a keyword; Ctrl-Space opens the menu manually.
- Other languages retain the default snippet source and friendly-snippets.
- Typing `^` can trigger the local snippet source; it does not automatically
  expand a snippet.
- OpenCode prompt buffers use only LSP and buffer completion sources.

Automatic completion documentation is inherited from LazyVim. Common controls
are Ctrl-Space to show completion, Ctrl-n / Ctrl-p to select candidates, Ctrl-y
to accept, and Ctrl-e to cancel. Command-line completion uses its own inherited
keymaps.

### Navigation, Terminals, and SSH

- **Yazi is the primary file manager** on `<leader>e` and `<leader>E`. Neo-tree
  remains available, but these bindings and its startup-directory hook are
  overridden. Netrw's directory plugin is disabled, and Yazi is not configured
  to automatically open for directory buffers.
- **Flash:** `s` retains labeled jumps. The default Flash bindings for `S`,
  operator-pending `r`, visual/operator-pending `R`, and command-line Ctrl-s are
  disabled in their corresponding modes.
- **Trouble:** `<leader>cs` toggles the symbols view and focuses it.
- **Snacks terminals:** `interactive = false` disables the default automatic
  insert-mode entry and automatic close behavior. Double Escape returns to
  normal mode; buffer-local Ctrl-h/j/k/l navigation mappings are removed when
  entering terminal mode so those keys reach the running application. The
  OpenCode terminal has its own explicit terminal options.
- **Terminal file jumps:** `gF` opens a file at its reported line and optional
  column, hides the terminal without destroying its output, and centers the
  location. It supports `file:line[:column]`, `file(line[:column])`, GDB/Rust
  locations, Python tracebacks, and IPython frame/arrow output.
- Relative terminal paths use a shell-reported OSC 7 directory when available,
  otherwise the terminal's startup directory. OSC 7 tracking does not change
  Neovim's CWD. The implementation is in [terminal.lua](lua/utils/terminal.lua).
- **SSH clipboard:** explicit `"+y` / `"*y` copies through OSC 52. Clipboard
  query/paste callbacks return no content, avoiding terminal-response waits.
  Paste external text in insert mode using the terminal's paste shortcut, such
  as Ctrl-Shift-V. Under SSH, ordinary `y` / `p` keep using Neovim registers;
  `"+p` / `"*p` do not retrieve the local clipboard.
- **Dashboard:** shows a header, up to 15 recent projects, and startup information.
  Snacks image rendering is disabled.

### Plugin and Tool Management

- Both the lazy.nvim bootstrap and GitHub plugin cloning use SSH URLs.
- Mason and mason-lspconfig are disabled. Language servers and formatters must
  be provided on `PATH`.
- nvim-treesitter and nvim-treesitter-textobjects are disabled. This does not
  remove Neovim's built-in Tree-sitter APIs; features needing a parser require
  one to be installed separately.
- Plugin versions are recorded in [lazy-lock.json](lazy-lock.json). The update
  checker is enabled with notifications suppressed.
- [lazyvim.json](lazyvim.json) has no explicitly enabled extras. Language
  configuration is supplied by the custom plugin specs below, alongside
  LazyVim's automatically selected core components.

## Added Plugins and Capabilities

| Plugin | Added capability | Entry point |
| --- | --- | --- |
| [gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) | Gruvbox colorscheme | Applied at startup |
| [yazi.nvim](https://github.com/mikavilpas/yazi.nvim) | Yazi file manager in a borderless, full-size floating window | `<leader>e`, `<leader>E`, `<leader><C-e>` |
| [nvim-surround](https://github.com/kylechui/nvim-surround) | Add, change, and delete surrounding delimiters | Default `ys`, `cs`, and `ds` mappings |
| [outline.nvim](https://github.com/hedyhli/outline.nvim) | Dedicated symbol outline, using available symbol providers | `<leader>o`, `:Outline` |
| [tabular](https://github.com/godlygeek/tabular) | Align text around a delimiter | `:Tabularize /pattern/` |
| [img-clip.nvim](https://github.com/HakonHarnes/img-clip.nvim) | Save clipboard images and insert filetype-specific references | `<leader>p`, `:PasteImage` |
| [vivify.vim](https://github.com/jannis-baum/vivify.vim) | Markdown preview with content and cursor synchronization | `:Vivify`; requires the `viv` application |
| [checkmate.nvim](https://github.com/bngarren/checkmate.nvim) | Markdown task lists with checked/unchecked states and metadata | Matching Markdown task files; metadata bindings below |
| [vimtex](https://github.com/lervag/vimtex) | LaTeX compilation, document navigation, and Sioyek integration | `:VimtexCompile`, `:VimtexView`, default VimTeX mappings |
| [typst-preview.nvim](https://github.com/chomosuke/typst-preview.nvim) | Live Typst preview with source/preview navigation | Loaded for `typst`; `:TypstPreview`, `:TypstPreviewToggle` |
| [clangd_extensions.nvim](https://github.com/p00f/clangd_extensions.nvim) | Clang AST, type hierarchy, symbol information, and memory usage | `:ClangdAST`, `:ClangdTypeHierarchy`, `:ClangdSymbolInfo`, `:ClangdMemoryUsage` |
| [opencode.nvim](https://github.com/nickjvandyke/opencode.nvim) | Context-aware OpenCode prompts, actions, and an integrated terminal | `<leader>aa`, `<leader>as`, `<leader>at`, `go`, `goo` |

### Markdown Tasks and OpenCode

Checkmate uses its default filename patterns; it is not enabled for every
Markdown file. Its custom metadata includes:

- `@priority`: low, medium, or high; default medium (`<leader>Tp`).
- `@started`: insertion timestamp, with `init` as an alias (`<leader>Ts`).
- `@done`: completion timestamp, with `completed` and `finished` as aliases
  (`<leader>Td`). Adding it checks the task; removing it unchecks the task.

OpenCode runs as `opencode --port` in a right-side Snacks terminal occupying
40% of the editor width. It does not automatically enter insert mode or take
focus when started through the server hook. The action menu includes explain,
review, fix, optimize, document, implement, test, and diagnostics prompts.
`go{motion}` appends a range as context, while `goo` appends the current line.
The ask and action bindings also work on visual selections.

## Language Support

Server defaults, project-root detection, and inherited commands come from
nvim-lspconfig. This configuration adds personal settings rather than copying
the upstream server implementations.

| Language | Language support | Formatting and additional features |
| --- | --- | --- |
| Python | `basedpyright-langserver` | Black; argument-name and return-type inlay hints enabled, variable-type and generic-type hints disabled. Python parenthesis indentation is customized. |
| C / C++ | `clangd`, plus clangd extensions | LSP formatting fallback, source/header switching, symbol information, AST, and type hierarchy. Upstream clangd filetypes also include Objective-C, Objective-C++, and CUDA. |
| Rust | `rust-analyzer` | rustfmt; Cargo workspace detection; asynchronous runnable execution with working directory, environment, executable arguments, and Cargo override support. |
| Typst | `tinymist` | typstyle through Conform and Tinymist; PDF export on typing; Tinymist semantic tokens disabled; live preview opened in Firefox. |
| LaTeX / plain TeX | VimTeX | Compilation and Sioyek forward/inverse search; local mathematical and environment snippets. No TeX LSP is explicitly added. |
| Lua | LazyVim's `lua_ls` and lazydev integration | StyLua; Neovim API completion and library-aware Lua development support. |
| Markdown | Vivify, Checkmate, and local snippets | Visible markup, wrapping, task metadata, image references, and TeX-style mathematical snippets. |

Manual formatting uses Conform with a three-second timeout and LSP fallback
when an external formatter is unavailable. Autosaving does not enable automatic
formatting.

Useful inherited server commands include:

```vim
:LspPyrightOrganizeImports
:LspPyrightSetPythonPath /path/to/python
:LspClangdSwitchSourceHeader
:LspClangdShowSymbolInfo
:LspCargoReload
```

### Local Snippets

VS Code-style snippets live in [snippets/](snippets/), with language registration
in [package.json](snippets/package.json). Expansion and placeholder navigation
use Neovim's native snippet engine.

| Prefix | Expansion / purpose |
| --- | --- |
| `frac`, `dfrac` | Fractions with separate numerator and denominator placeholders |
| `inte` | Integral with default limits `0` and `\infty` |
| `summ`, `produ` | Sum/product with default limits `i=1` and `N` |
| `hat`, `dot`, `ov`, `sq`, `bb` | Common mathematical accents, square roots, and fonts |
| `alpha`, `beta`, `Gamma`, etc. | Greek symbols |
| `beg` | Begin/end environment with a shared environment-name placeholder |
| `__`, `^^`, `begin` | Additional TeX/plain TeX subscript, superscript, and environment snippets |

The mathematical snippets in `markdown.json` are shared with TeX and plain TeX;
they insert TeX commands, not Markdown math delimiters.

## Requirements and Setup

Use a recent Neovim version compatible with the locked LazyVim/nvim-lspconfig
versions, Git, and working GitHub SSH authentication. Linux is the main target;
browser, PDF viewer, shell, and clipboard choices may need adjustment elsewhere.
A Nerd Font is useful for the UI icons.

Place this repository in `~/.config/nvim`, then start Neovim from a project
directory. lazy.nvim bootstraps and installs plugin repositories using SSH.
Install the external tools needed for your workflows separately:

| Workflow | External tools |
| --- | --- |
| File search / browsing | `rg`, `fd`, `fzf`, `yazi`, `ya` |
| Python | `basedpyright-langserver`, `black`, and the project Python environment |
| C / C++ | `clangd` and the project's compilation database/configuration |
| Rust | `rust-analyzer`, `cargo`, `rustfmt`, and the project toolchain |
| Lua | `lua-language-server`, `stylua` |
| Typst | `tinymist`, `typstyle`, Firefox; preview dependencies described below |
| LaTeX | A TeX distribution, `latexmk`, and `sioyek` |
| Markdown preview | The Vivify `viv` application and `curl` |
| AI integration | An installed `opencode` CLI and its model/provider setup |

Image pasting needs a platform clipboard backend supported by img-clip.
Checkmate needs a Markdown Tree-sitter parser even though nvim-treesitter's
automatic parser management is disabled.

## SSH-Only and Offline Use

**SSH plugin cloning does not make the configuration fully offline-ready.**
Current behavior includes:

- **blink.cmp:** the default Rust fuzzy matcher may download a shared library
  and checksum from GitHub Releases over HTTPS. The current configuration does
  not disable this download. Plugin code alone is insufficient for an offline
  Rust matcher deployment.
- **Typst preview:** initialization checks/downloads Tinymist and websocat over
  HTTPS. It is deferred until a Typst buffer loads the plugin, so ordinary
  non-Typst use does not initialize the preview plugin. No local dependency
  paths are explicitly configured.
- **On-demand features:** remote image operations in img-clip, Snacks icon
  data, and fzf-lua's online theme installer can access HTTP/HTTPS independently
  of lazy.nvim.
- **lazy.nvim:** missing plugin installation and periodic update checks remain
  enabled. Completely offline use requires the plugin repositories to be
  available already. The lockfile records versions, not plugin contents or
  executable dependencies.
- **Local services:** Vivify, OpenCode integration, and Typst preview use local
  HTTP/WebSocket communication. Their availability is separate from external
  HTTP access; OpenCode's model backend has its own connectivity requirements.

Before moving to an offline machine, prepare plugin repositories, any required
binary artifacts, language tools, parsers, and project dependencies. Typst
preview's downloaded binaries are stored under
`stdpath("data") .. "/typst-preview/"`; blink's Rust library is stored under its
plugin directory in `target/release/`.

## Configuration Layout

```text
init.lua                  lazy.nvim bootstrap entry point
lua/config/
  lazy.lua                plugin imports and manager settings
  options.lua             editor options and SSH clipboard provider
  keymaps.lua             overrides of global LazyVim keymaps
  autocmds.lua            autosave, opening-time readonly policy, terminal behavior
lua/plugins/              plugin additions and overrides
lua/utils/terminal.lua    terminal location parsing and file jumps
snippets/                 local snippets and language registration
lazy-lock.json            locked plugin revisions
lazyvim.json              LazyVim metadata and extras selection
```

The four standard files in `lua/config/` are loaded by LazyVim at the appropriate
time. Additional helper modules belong in `lua/utils/`. Plugin specs in
`lua/plugins/` are imported by lazy.nvim; `example.lua` is an inactive starter
example and returns an empty spec.
