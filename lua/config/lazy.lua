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

require("lazy").setup("plugins", {
  -- Maintenance jobs may run this config from an isolated checkout. Normal
  -- sessions use stdpath(config); the explicit root keeps lockfile writes in
  -- the repository being updated instead of whichever config is installed.
  lockfile = (vim.env.NVIM_CONFIG_ROOT or vim.fn.stdpath("config")) .. "/lazy-lock.json",
  -- Resolve this account's own plugins from working checkouts under dev/ when
  -- that directory exists, so config and plugins can be tested together before
  -- either is published. dev/ is gitignored and absent on every ordinary
  -- install; fallback keeps those machines resolving from the GitHub pins in
  -- lazy-lock.json.
  --
  -- Maintenance runs opt out. lazy.nvim treats a plugin resolved outside its
  -- root as local and omits local plugins from the lockfile it writes, so a
  -- `nvim-config sync` on a machine with dev/ populated would silently delete
  -- exactly those plugins' committed pins. NVIM_TOOLCHAIN_SYNC already marks
  -- every bin/nvim-config run and the dependency refresh; with dev matching
  -- off they resolve from the pins and rewrite the lock faithfully.
  dev = {
    path = (vim.env.NVIM_CONFIG_ROOT or vim.fn.stdpath("config")) .. "/dev",
    patterns = vim.env.NVIM_TOOLCHAIN_SYNC == "1" and {} or { "777lotto" },
    fallback = true,
  },
})
