return {
{
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  ft = { "markdown", "markdown.mdx" },
  config = function()
    require("render-markdown").setup({})
    vim.keymap.set("n", "<leader>cm", "<cmd>RenderMarkdown toggle<cr>",
      { desc = "Markdown: toggle in-buffer rendering" })
  end,
},

-- Auto-install CLI tools used by Treesitter, the formatter, and the linter.
{
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    require("mason-tool-installer").setup({
      ensure_installed = { "tree-sitter-cli", "prettier", "markdownlint-cli2" },
    })
  end,
},

-- Prettier formats every core language it supports. It is intentionally not
-- assigned to Lua, Python, C, or plain text because Prettier has no parser for
-- those languages. Conform prefers a project's node_modules binary and falls
-- back to Mason's installation. <leader>cf also formats selections manually.
{
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function() require("conform").format({ async = true, lsp_format = "never" }) end,
      mode = { "n", "v" },
      desc = "Format buffer / selection",
    },
  },
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        css = { "prettier" },
        graphql = { "prettier" },
        handlebars = { "prettier" },
        html = { "prettier" },
        htmlangular = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        json5 = { "prettier" },
        less = { "prettier" },
        markdown = { "prettier" },
        ["markdown.mdx"] = { "prettier" },
        scss = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        yaml = { "prettier" },
      },
      format_on_save = { timeout_ms = 2000, lsp_format = "never" },
    })
  end,
},

-- Linting (markdownlint-cli2). Runs on read/save/leave-insert; diagnostics
-- show inline and in your existing Trouble panel (<leader>xx).
{
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      markdown = { "markdownlint-cli2" },
    }
    local grp = vim.api.nvim_create_augroup("nvim-lint-markdown", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      group = grp,
      callback = function()
        require("lint").try_lint()
      end,
    })
  end,
},
}
