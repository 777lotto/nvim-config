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

-- Auto-install CLI tools used by Treesitter, the formatters, and the linter.
{
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    local toolchain = require("config.toolchain")
    require("mason-tool-installer").setup({
      ensure_installed = toolchain.mason_packages,
      -- Headless bootstrap/update commands perform one deliberate synchronous
      -- pass instead of racing the ordinary startup installer.
      run_on_start = vim.env.NVIM_TOOLCHAIN_SYNC ~= "1",
    })
  end,
},

-- Biome formats the source languages it parses and dprint formats Markdown;
-- the mapping and the Prettier retirement rationale live in
-- lua/config/formatting.lua. Conform prefers a project's node_modules binary
-- and falls back to Mason's installation. <leader>cf also formats selections
-- manually.
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
    local formatting = require("config.formatting")
    require("conform").setup({
      formatters_by_ft = formatting.formatters_by_ft,
      formatters = formatting.formatters,
      format_on_save = { timeout_ms = 2000, lsp_format = "never" },
    })
  end,
},

-- Linting (markdownlint-cli2). Runs on read and after save, so dprint can
-- normalize Markdown before the linter reports layout diagnostics.
{
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      markdown = { "markdownlint-cli2" },
    }
    local grp = vim.api.nvim_create_augroup("nvim-lint-markdown", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
      group = grp,
      callback = function()
        require("lint").try_lint()
      end,
    })
  end,
},
}
