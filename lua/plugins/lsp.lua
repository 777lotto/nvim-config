return {
{
  "williamboman/mason.nvim",
  config = function()
    require("mason").setup()
  end,
},

-- 2. Mason-LSPConfig + Nvim-LSPConfig (The Glue + The Setup)
{
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "williamboman/mason.nvim",
    "b0o/SchemaStore.nvim",
    -- Loaded here (not only via nvim-cmp) so the capabilities call below still
    -- works after nvim-cmp is lazy-loaded on InsertEnter.
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    local toolchain = require("config.toolchain")
    -- Make nvim-cmp's enhanced capabilities the default for EVERY server.
    -- Neovim 0.11 + mason-lspconfig v2 enable servers via automatic_enable /
    -- vim.lsp.enable(), so the old per-server `handlers` block no longer runs.
    -- Capabilities must therefore be registered on the global ("*") config.
    vim.lsp.config("*", {
      capabilities = require("cmp_nvim_lsp").default_capabilities(),
    })

    -- jsonls supplies validation, completion, hover documentation, and schema
    -- awareness for both JSON and JSON-with-comments files. SchemaStore adds
    -- the maintained catalog used by common files such as package.json.
    vim.lsp.config("jsonls", {
      settings = {
        json = {
          schemas = require("schemastore").json.schemas(),
          validate = { enable = true },
        },
      },
    })

    -- Unversioned server names mean the newest Mason registry releases. The
    -- config updater refreshes them; CI covers the supported Node range.
    require("mason-lspconfig").setup({
      ensure_installed = vim.env.NVIM_TOOLCHAIN_SYNC == "1" and {} or toolchain.lsp_servers,
    })

    -- SETUP KEYMAPS (LspAttach Autocommand)
    vim.api.nvim_create_autocmd('LspAttach', {
      desc = 'LSP actions',
      callback = function(event)
        local buf = event.buf

        -- LSP Keymaps.
        -- Neovim 0.11 already provides these defaults on LspAttach, so they are
        -- NOT re-mapped here: K (hover), grn (rename), gra (code action),
        -- grr (references), gri (implementation), gO (document symbols).
        -- 'gi' is intentionally left to its built-in meaning (insert at last
        -- insert location); use gri for implementation.
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = buf, desc = "Go to declaration" })
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = buf, desc = "Go to definition" })
        -- Keep the code-action mnemonic alongside Neovim's gra default.
        -- Symbol rename is globally discoverable under <leader>wr (word).
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = buf, desc = "Code action" })
      end,
    })
  end,
},

-- 3. Autocompletion Engine
{
  "hrsh7th/nvim-cmp",
  -- CmdlineEnter is required so the cmp.setup.cmdline(':') block below works
  -- from a fresh session (InsertEnter alone would defer cmdline completion).
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),

        -- OPTION 1 APPLIED: select = false
        -- Pressing Enter now inserts a newline normally.
        -- It only inserts a suggestion if you manually highlighted one first.
        ['<CR>'] = cmp.mapping.confirm({ select = false }),

        ['<C-e>'] = cmp.mapping.abort(),

        -- OPTIONAL: Add Tab/Shift-Tab to scroll through the menu
        ['<Tab>'] = cmp.mapping.select_next_item(),
        ['<S-Tab>'] = cmp.mapping.select_prev_item(),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "buffer" },
        { name = "path" },
      }),
    })

    -- Enable command-line completion
    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = 'path' }
      }, {
        { name = 'cmdline' }
      })
    })
  end,
},
}
