-- Discovery for zemRip's in-repo manual-review plugin (tools/nvim-review).
--
-- nvim-review is not its own repository: it ships inside the zemRip monorepo
-- next to the backend it drives (apps/local/db/db.sh review-serve), so it can
-- be neither a GitHub pin in lazy-lock.json nor a dev/ fleet member. lazy.nvim
-- loads it from a checkout by directory instead. This module only decides
-- which checkout, so the plugin spec stays declarative and the decision is
-- testable with an injected runtime, the way config.git_panel is.
local M = {}

M.PLUGIN_SUBDIR = "tools/nvim-review"
M.ENTRYPOINT = "lua/review/init.lua"
-- Environment override for a checkout kept somewhere else. It is consulted
-- before the defaults and must name the zemRip repository root, not the
-- plugin directory.
M.ENV = "NVIM_ZEMRIP_ROOT"
-- Order matters: the zemrip-ai agent container keeps its canonical clone at
-- ~/zemrip; the zemrip-server operator plane keeps it at ~/works/zemrip.
M.DEFAULT_ROOTS = { "~/zemrip", "~/works/zemrip" }

local function is_set(value)
  return type(value) == "string" and value ~= ""
end

--- Candidate zemRip roots, most preferred first. Paths are expanded but not
--- checked for existence.
function M.candidates(runtime)
  runtime = runtime or {}
  local env = runtime.env or vim.env
  local expand = runtime.expand or vim.fn.expand
  local roots = {}
  local override = env[M.ENV]
  if is_set(override) then
    table.insert(roots, expand(override))
  end
  for _, root in ipairs(M.DEFAULT_ROOTS) do
    table.insert(roots, expand(root))
  end
  return roots
end

--- The first candidate that actually carries the plugin, or nil. A checkout
--- that predates tools/nvim-review is skipped rather than half-loaded.
function M.locate(runtime)
  runtime = runtime or {}
  local readable = runtime.readable or function(path) return vim.fn.filereadable(path) == 1 end
  for _, root in ipairs(M.candidates(runtime)) do
    local plugin_dir = root .. "/" .. M.PLUGIN_SUBDIR
    if readable(plugin_dir .. "/" .. M.ENTRYPOINT) then
      return { root = root, plugin_dir = plugin_dir }
    end
  end
  return nil
end

--- The lazy.nvim spec. On a machine without a zemRip checkout the plugin is
--- disabled outright: lazy.nvim never touches the directory, `:Lazy clean`
--- ignores directory-loaded plugins, and nothing is written to the lockfile.
function M.spec(runtime)
  local located = M.locate(runtime)
  local candidates = M.candidates(runtime)
  return {
    dir = located and located.plugin_dir or (candidates[1] .. "/" .. M.PLUGIN_SUBDIR),
    name = "nvim-review",
    enabled = located ~= nil,
    main = "review",
    cmd = { "Review", "ReviewSync", "ReviewDiff", "ReviewStop" },
    keys = {
      { "<leader>rv", "<cmd>Review<cr>", desc = "Review dashboard" },
    },
    opts = {
      -- The backend is resolved from this root, so :Review works from any
      -- working directory instead of only from inside the checkout.
      cwd = located and located.root or nil,
      open = "buffer",
    },
  }
end

return M
