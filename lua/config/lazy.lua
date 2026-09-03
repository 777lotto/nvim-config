-- Bootstrap lazy.nvim, then import every module in lua/plugins/.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local config_root = vim.env.NVIM_CONFIG_ROOT or vim.fn.stdpath("config")
local standard_root = vim.fn.stdpath("config")
local function physical(path)
  return (vim.uv or vim.loop).fs_realpath(path) or vim.fs.normalize(path)
end
local isolated_config = physical(config_root) ~= physical(standard_root)
require("config.ux_baselines")
local use_dev = vim.env.NVIM_TOOLCHAIN_SYNC ~= "1" or vim.env.NVIM_CONFIG_USE_DEV == "1"

-- Maintenance jobs may run this config from an isolated checkout. Normal
-- sessions use stdpath(config); the explicit root keeps a lockfile write in
-- the repository being updated instead of whichever config is installed.
-- Which of the two lockfiles this session may write, and why an editing
-- session may not write the committed one, is config.lockfile.
local lockfile = require("config.lockfile").select({
  config_root = config_root,
  state_dir = vim.fn.stdpath("state") .. "/nvim-config",
  use_dev = use_dev,
  -- NVIM_TOOLCHAIN_SYNC marks every bin/nvim-config run and the dependency
  -- refresh -- the runs whose whole purpose is to record pins. A dev-backed
  -- test still receives the scratch lock because use_dev remains true.
  maintenance = vim.env.NVIM_TOOLCHAIN_SYNC == "1",
})

require("lazy").setup("plugins", {
  lockfile = lockfile,
  -- Resolve this account's own plugins from working checkouts under dev/ when
  -- they are present, so config and plugins can be tested together. An ordinary
  -- install has no dev/ fleet and falls back to the committed GitHub pins.
  --
  -- Maintenance runs opt out. lazy.nvim treats a plugin resolved outside its
  -- root as local and omits local plugins from the lockfile it writes, so a
  -- `nvim-config sync` on a machine with dev/ populated would silently delete
  -- exactly those plugins' committed pins. NVIM_TOOLCHAIN_SYNC already marks
  -- every bin/nvim-config run and the dependency refresh; with dev matching
  -- off they resolve from the pins and rewrite the lock faithfully. An editing
  -- session keeps dev matching and is denied the committed lockfile instead.
  dev = {
    path = vim.env.NVIM_DEV_DIR
      or config_root .. "/dev",
    patterns = use_dev and { "777lotto" } or {},
    fallback = true,
  },
  -- lazy.nvim normally trims runtimepath for startup performance. Preserve an
  -- explicitly selected checkout so its spec modules remain authoritative
  -- when Lazy reloads them during a maintenance operation.
  performance = { rtp = { reset = not isolated_config } },
})
