-- Which lockfile this session is allowed to write, and why it is usually not
-- the committed one.
--
-- lazy.nvim rewrites its lockfile after every install, update, restore, and
-- clean, from whatever the resolved plugin directories currently hold. Two
-- properties of this configuration make that untrustworthy in an editing
-- session:
--
--   * dev matching resolves this account's own plugins from dev/, outside
--     lazy's root, so lazy treats them as local -- and its writer omits every
--     local plugin. It deletes their committed pins rather than moving them.
--   * the plugin root under stdpath("data") is shared by every checkout and
--     worktree on the machine, so a session records whatever commits those
--     shared directories happen to hold, which an unrelated `:Lazy update` may
--     already have moved.
--
-- Either way the session leaves a modified tracked file, and `nvim-config
-- update` then refuses to fast-forward until it is committed or stashed --
-- the friction this module exists to remove. A session that cannot write the
-- committed lockfile faithfully does not write it at all; it keeps a
-- per-machine scratch copy instead. Pins still move only through the
-- documented dependency-refresh flow, and `nvim-config sync` still restores
-- the committed ones.

local M = {}

local uv = vim.uv or vim.loop

M.SCRATCH_BASENAME = "lazy-lock.local.json"

local function mtime(path)
  local stat = uv.fs_stat(path)
  return stat and stat.mtime and stat.mtime.sec or nil
end

local function copy(source, target)
  local reader = io.open(source, "rb")
  if not reader then return false end
  local contents = reader:read("*a")
  reader:close()
  local writer = io.open(target, "wb")
  if not writer then return false end
  writer:write(contents)
  writer:close()
  return true
end

--- Pick the lockfile path for this session.
---
--- @param options table
---   config_root string  the configuration checkout
---   state_dir   string  per-machine directory holding the scratch copy
---   use_dev     boolean dev matching resolves account plugins from dev/
---   maintenance boolean a bin/nvim-config or CI run rather than an editing session
--- @return string path, boolean committed
function M.select(options)
  local committed = options.config_root .. "/lazy-lock.json"
  -- Only a maintenance run resolving the committed pins writes them back.
  if options.maintenance and not options.use_dev then
    return committed, true
  end

  local scratch = options.state_dir .. "/" .. M.SCRATCH_BASENAME
  -- Mirror the committed pins whenever they are newer, so a session that just
  -- fast-forwarded the configuration restores the pins it received rather than
  -- a stale copy of the ones they replaced. A scratch file newer than the
  -- committed one holds this machine's own results and is left alone.
  local committed_at, scratch_at = mtime(committed), mtime(scratch)
  if committed_at and (not scratch_at or scratch_at < committed_at) then
    vim.fn.mkdir(options.state_dir, "p")
    copy(committed, scratch)
  end
  return scratch, false
end

return M
