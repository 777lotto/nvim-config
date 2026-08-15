return {
{
  "777lotto/git-panel.nvim",
  cmd = { "GitPanel", "GitPanelSplit" },
  keys = {
    { "<leader>gg", "<cmd>GitPanel<cr>", desc = "Git panel (custom dashboard)" },
    { "<leader>gG", "<cmd>GitPanelSplit<cr>", desc = "Git panel (left split)" },
  },
},

{
  "lewis6991/gitsigns.nvim",
  config = function()
    require("gitsigns").setup()
  end,
},

-- ---------------------------------------------------------------------------
-- DIFFVIEW — scrollable, side-by-side diff overlay (opens in its own tabpage)
-- Used both on its own keys below AND as Neogit's diff viewer (the `d` ->
-- "Diff this" action inside the Neogit status buffer).
-- ---------------------------------------------------------------------------
{
  "sindrets/diffview.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = {
    "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles",
    "DiffviewFocusFiles", "DiffviewFileHistory", "DiffviewRefresh",
  },
  keys = {
    -- Working tree: left = index (staged), right = working dir (unstaged),
    -- both compared against HEAD. This is the staged + unstaged overlay.
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff: working tree (staged + unstaged)" },
    -- Review a whole branch/rev. Prompts so nothing is hardcoded; try a bare
    -- branch ("bet") or a merge-base range ("origin/bet...HEAD", PR-style).
    {
      "<leader>gD",
      function()
        vim.ui.input({ prompt = "Diff against (branch / rev, e.g. bet or origin/bet...HEAD): " }, function(rev)
          if rev and rev ~= "" then vim.cmd("DiffviewOpen " .. rev) end
        end)
      end,
      desc = "Diff: against a branch / rev",
    },
    { "<leader>gh", "<cmd>DiffviewFileHistory<cr>",   desc = "Diff: repo commit history" },
    { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "Diff: current file history" },
    { "<leader>gq", "<cmd>DiffviewClose<cr>",         desc = "Diff: close the diff view" },
  },
  opts = {
    use_icons = true,
    watch_index = true, -- auto-refresh when the git index changes
    view = {
      default = { layout = "diff2_horizontal" }, -- side-by-side, scrollable
      merge_tool = { layout = "diff3_mixed" },
    },
    file_panel = { listing_style = "tree" },
  },
  config = function(_, opts)
    require("diffview").setup(opts)
  end,
},

-- ---------------------------------------------------------------------------
-- NEOGIT — Magit-style popups on <leader>gn (kept as a power-user fallback;
-- the custom GitPanel plugin owns <leader>gg). A status
-- buffer with SEPARATE, labeled, foldable sections: Untracked files /
-- Unstaged changes / Staged changes / Recent commits. Inside it:
--   <tab>  expand/collapse a file's inline diff
--   d      Diff popup -> "Diff this" opens it in Diffview (scrollable overlay)
--   s / u  stage / unstage at point      x  discard      c  commit popup
--   b      Branch popup (checkout/create/rename)
--   w      Worktree popup (checkout / create / goto / move / delete)
--   ?      show all keybindings          q  close
-- ---------------------------------------------------------------------------
{
  "NeogitOrg/neogit",
  cmd = "Neogit",
  dependencies = {
    "sindrets/diffview.nvim",        -- scrollable diffs for the `d` popup
    "nvim-telescope/telescope.nvim", -- branch / worktree selection menus
  },
  keys = {
    { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit popups (commit / rebase / merge) — fallback to the <leader>gg panel" },
  },
  opts = {
    kind = "tab",          -- full-screen tab (robust). Use "floating" for a popup window.
    graph_style = "unicode",
    integrations = {
      diffview = true,     -- `d` -> "Diff this" opens a scrollable Diffview overlay
      telescope = true,    -- fuzzy menus for branches / worktrees
    },
    -- Each section is independently labeled + foldable. Expand the three the
    -- user cares about by default so unstaged, staged AND committed changes
    -- are visible the moment the panel opens.
    sections = {
      untracked = { folded = false, hidden = false },
      unstaged  = { folded = false, hidden = false },
      staged    = { folded = false, hidden = false },
      stashes   = { folded = true,  hidden = false },
      recent    = { folded = false, hidden = false }, -- Recent (committed) changes
    },
  },
  config = function(_, opts)
    require("neogit").setup(opts)
  end,
},
}
