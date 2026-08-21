return {
{
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  dependencies = {
    -- Mason provides tree-sitter-cli >= 0.26.1 before this config runs.
    "williamboman/mason.nvim",
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      branch = "main",
      config = function()
        require("nvim-treesitter-textobjects").setup({
          select = { lookahead = true },
          move = { set_jumps = true },
        })

        local ts_select = require("nvim-treesitter-textobjects.select")
        local function map_select(lhs, capture, desc)
          vim.keymap.set({ "x", "o" }, lhs, function()
            ts_select.select_textobject(capture, "textobjects")
          end, { desc = desc })
        end

        map_select("af", "@function.outer", "Around function")
        map_select("if", "@function.inner", "Inside function")
        map_select("ac", "@class.outer", "Around class")
        map_select("ic", "@class.inner", "Inside class")
        map_select("aa", "@parameter.outer", "Around parameter")
        map_select("ia", "@parameter.inner", "Inside parameter")

        local ts_move = require("nvim-treesitter-textobjects.move")
        local function map_move(lhs, method, capture, desc)
          vim.keymap.set({ "n", "x", "o" }, lhs, function()
            ts_move[method](capture, "textobjects")
          end, { desc = desc })
        end

        map_move("]f", "goto_next_start", "@function.outer", "Next function")
        map_move("]c", "goto_next_start", "@class.outer", "Next class")
        map_move("[f", "goto_previous_start", "@function.outer", "Previous function")
        map_move("[c", "goto_previous_start", "@class.outer", "Previous class")
      end,
    },
  },
  config = function()
    local toolchain = require("config.toolchain")

    local treesitter = require("nvim-treesitter")
    treesitter.setup()

    local function has_supported_cli()
      if vim.fn.executable("tree-sitter") ~= 1 then return false end
      local version = vim.version.parse(vim.fn.system({ "tree-sitter", "--version" }))
      return version ~= nil and vim.version.ge(version, { 0, 26, 1 })
    end

    local function install_parsers()
      if vim.env.NVIM_TREESITTER_SKIP_INSTALL ~= "1" and has_supported_cli() then
        treesitter.install(toolchain.parsers)
      end
    end

    local group = vim.api.nvim_create_augroup("NvimTreesitterMain", { clear = true })
    install_parsers()
    -- Covers a fresh machine where Mason installs tree-sitter-cli later in startup.
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "MasonToolsUpdateCompleted",
      callback = install_parsers,
    })

    -- On main, highlighting is a Neovim feature and indentation is enabled via
    -- nvim-treesitter's indentexpr instead of the removed configs.setup modules.
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = toolchain.parser_filetypes,
      callback = function(event)
        if pcall(vim.treesitter.start, event.buf) then
          vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
},
}
