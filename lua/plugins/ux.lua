local channel = require("config.channel").current()
local foundation_opts = { load_active = false }

local function external_ownership()
  return {
    tabline = "external",
    statusline = "external",
    winbar = "external",
    statuscolumn = "external",
    windows = "external",
    scrollbar = "external",
  }
end

return {
  {
    "777lotto/UX-foundation.nvim",
    branch = channel,
    lazy = false,
    opts = foundation_opts,
  },
  {
    "777lotto/UX-chrome.nvim",
    branch = channel,
    lazy = false,
    dependencies = { "777lotto/UX-foundation.nvim" },
    opts = {
      foundation = foundation_opts,
      -- Register the complete Chrome contract without replacing Bufferline,
      -- Lualine, or any native surface during the compatibility soak.
      ownership = external_ownership(),
    },
  },
  {
    "777lotto/UX-styling.nvim",
    branch = channel,
    dependencies = { "777lotto/UX-foundation.nvim" },
    cmd = "UXStyling",
    opts = function()
      local baselines = require("config.ux_baselines")
      return {
        foundation = foundation_opts,
        -- Keep the raw browser available without multiplying the initial tree
        -- by its full default page during the compatibility soak.
        raw_limit = 25,
        bufferline = { baseline_setup = baselines.get("bufferline") },
        nvim_tree = { baseline_setup = baselines.get("nvim_tree") },
        telescope = { baseline_setup = baselines.get("telescope") },
      }
    end,
  },
}
