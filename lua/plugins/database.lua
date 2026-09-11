-- nvim-dbee: the zemRip mirror database panel. Which route reaches the
-- mirror on this plane, and the SSH forward's lifetime, live in
-- lua/config/mirror.lua; this spec only installs the client and hands it
-- that policy.

local uv = vim.uv or vim.loop

-- The Go backend for the platforms this configuration supports, keyed the
-- way dbee's install manifest is.
local ARCH_ALIASES = {
  x86_64 = "amd64",
  aarch64 = "arm64",
  arm64 = "arm64",
}

local function manifest_key()
  local uname = uv.os_uname()
  local arch = ARCH_ALIASES[uname.machine] or uname.machine
  return ("%s/%s"):format(uname.sysname:lower(), arch)
end

local function run(command)
  local result = vim.system(command, { text = true }):wait()
  if result.code ~= 0 then
    local detail = vim.trim(table.concat({ result.stdout or "", result.stderr or "" }, "\n"))
    error(("`%s` failed with exit %d%s"):format(
      table.concat(command, " "), result.code, detail ~= "" and (": " .. detail) or ""))
  end
end

-- dbee's own `require("dbee").install()` spawns curl and tar with libuv
-- callbacks and returns immediately, so a headless `Lazy! restore` followed
-- by `+qa` (what `nvim-config sync` runs) exits before the archive lands.
-- This performs the same three steps synchronously, from the same manifest,
-- into the same directory dbee prepends to PATH, and stamps the manifest
-- version so an unchanged pin is a no-op.
local function install_dbee_backend(plugin)
  local manifest = dofile(plugin.dir .. "/lua/dbee/install/__manifest.lua")
  local key = manifest_key()
  local url = manifest.urls[key]
  if not url then
    error(("dbee publishes no backend for %s; see %s/lua/dbee/install/__manifest.lua"):format(key, plugin.dir))
  end

  local install_dir = vim.fn.stdpath("data") .. "/dbee/bin"
  local binary = install_dir .. "/dbee"
  local stamp = install_dir .. "/dbee.version"
  if vim.fn.executable(binary) == 1 and vim.fn.filereadable(stamp) == 1
    and vim.trim(table.concat(vim.fn.readfile(stamp), "\n")) == manifest.version then
    coroutine.yield("dbee backend " .. manifest.version .. " already installed")
    return
  end

  local build_dir = vim.fn.stdpath("cache") .. "/dbee/build"
  local archive = build_dir .. "/dbee.tar.gz"
  vim.fn.mkdir(install_dir, "p")
  vim.fn.mkdir(build_dir, "p")

  coroutine.yield("downloading dbee backend " .. manifest.version .. " for " .. key)
  run({ "curl", "-sfLo", archive, url })
  run({ "tar", "-xzf", archive, "-C", install_dir })
  vim.fn.setfperm(binary, "rwxr-xr-x")
  if vim.fn.executable(binary) ~= 1 then
    error("dbee backend archive did not contain an executable at " .. binary)
  end
  vim.fn.writefile({ manifest.version }, stamp)
  vim.fn.delete(archive)
  coroutine.yield("installed dbee backend at " .. binary)
end

return {
  {
    "kndndrj/nvim-dbee",
    dependencies = { "MunifTanjim/nui.nvim" },
    build = install_dbee_backend,
    cmd = { "Dbee" },
    keys = {
      { "<leader>ad", "<cmd>Mirror<cr>", desc = "Mirror database" },
    },
    config = function()
      require("dbee").setup(require("config.mirror").dbee_options())
    end,
  },
}
