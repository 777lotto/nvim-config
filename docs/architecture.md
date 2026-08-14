# Architecture and UI layers

## Startup flow

`init.lua` is an ordered entrypoint:

```text
environment policy → options → keymaps → diagnostic policy → autocmds → lazy.nvim
                                                                        └─ imports lua/plugins/*.lua
```

The `lua/config/` modules control Neovim itself. The `lua/plugins/` modules
return lazy.nvim specifications grouped by concern. Reusable code belongs under
`local-plugins/`, not inside either kind of config module.

This separation keeps three jobs distinct:

- configuration chooses behavior for this setup;
- plugin specifications install and configure third-party packages;
- plugin packages expose reusable commands and Lua APIs.

## Environment boundaries

`lua/config/environment.lua` is the single place for behavior that depends on
how Neovim was launched. It currently detects SSH sessions, selects the
clipboard policy, and exposes `:EnvironmentInfo` for inspecting inherited
desktop, terminal, session, and SSH-agent variables.

The default clipboard mode is automatic: local sessions leave provider
selection to Neovim, while SSH sessions use copy-only OSC 52. The
`NVIM_CLIPBOARD` environment variable can override that decision with `native`
or `osc52`. Clipboard reads over OSC 52 are deliberately disabled; paste is
handled by the client terminal instead.

This module does not try to detect or launch an external desktop terminal or
file manager. ToggleTerm uses Neovim's configured shell, and nvim-tree and Oil
are internal editor interfaces, so all three are portable. Thunar and the
`.desktop` entry run before Neovim starts and must receive the correct XFCE
session environment independently.

## How the UI layers fit together

A colorscheme is a program that assigns colors and attributes to named
**highlight groups**. Highlight groups are the interface; the theme is one
implementation of that interface.

```text
colorscheme ────────────────┐
                            v
syntax captures ─────> highlight groups ─────> colored cells
Treesitter captures ────────^
LSP semantic tokens ────────^
plugin extmarks ────────────^

LSP + linters ──> diagnostic items ──> signs / underline / virtual text
                                      virtual lines / float / lists
```

| Layer | What it contributes |
| --- | --- |
| Editor groups | Normal text, cursor line, selections, menus, splits, status lines |
| Treesitter | Parses syntax and assigns captures such as function, string, type, and comment |
| LSP semantic tokens | Refines meaning using project knowledge, such as distinguishing a type from a variable |
| LSP features | Completion, hover, definitions, references, rename, code actions, symbols, and diagnostics |
| Linters | Additional diagnostics based on style, correctness, or project rules |
| Diagnostic renderer | Chooses where diagnostic data appears; it does not discover errors itself |
| Plugins | Add UI and their own groups/extmarks, such as Git signs or rendered Markdown |

Precedence can vary by extmark priority and group links. If one token looks
wrong, inspect it with `:Inspect` and inspect the final group with
`:highlight GroupName`. That identifies whether the source is Treesitter, an
LSP semantic token, a diagnostic, or a plugin.

## Themes versus highlight groups

Changing a highlight group with:

```lua
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", {
  fg = "#ed8796",
  italic = true,
})
```

takes effect immediately, but a later `:colorscheme` call may overwrite it.
Permanent overrides should therefore be reapplied on the `ColorScheme`
autocommand.

lualine's `theme = "auto"` derives its palette from the active colorscheme.
bufferline, Trouble, Telescope, GitPanel, and render-markdown also use named
groups, so most of their UI follows a theme switch automatically. A plugin may
still need a small override when its default link has poor contrast.

render-markdown is not a general syntax highlighter. It interprets Markdown
structure and adds concealment, icons, padding, and extmarks. Treesitter and LSP
support are the general filetype layers for TypeScript, JavaScript, CSS, HTML,
JSON, Python, and similar source files.

## A live theme workshop is feasible

Neovim redraws highlight changes immediately. A dedicated local plugin could:

1. open a scratch tab containing representative editor UI and sample Lua,
   TypeScript, JSON, CSS, HTML, Markdown, and diagnostics;
2. show the group/capture under the cursor using the same information as
   `:Inspect`;
3. edit foreground, background, style, links, and blend values;
4. apply changes through `nvim_set_hl()` as values change;
5. reapply overrides after `ColorScheme`;
6. export the result as a small colorscheme or override module.

Automatic updates can be driven safely by explicit mappings, a picker, or a
`BufWritePost` reload of a theme file. A filesystem watcher is possible but is
usually less predictable than applying changes from inside Neovim.

That workshop should be a separate plugin from the eventual colorscheme:
the workshop is an editor/debugger, while the colorscheme is the generated,
shareable palette.

## Adding a language

Language support is deliberately layered rather than hidden in one large table:

1. add a Treesitter parser and FileType activation in
   `lua/plugins/treesitter.lua`;
2. add the LSP server and any server-specific settings in
   `lua/plugins/lsp.lua`;
3. add only a documented formatter mapping in
   `lua/plugins/languages.lua`;
4. add a linter there if the language benefits from one;
5. mirror Mason and parser changes in `bootstrap.sh`;
6. open a representative file and verify `:Inspect`, `:LspInfo`,
   `:ConformInfo`, and `:checkhealth`.

Do not assign Prettier to a filetype merely because no formatter is configured.
Use a formatter that actually parses that language.
