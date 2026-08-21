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
})
