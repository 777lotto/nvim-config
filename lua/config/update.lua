local api = vim.api

local M = { running = false }

local function config_root()
  return vim.env.NVIM_CONFIG_ROOT or vim.fn.stdpath("config")
end

local function show_report(title, result, footer)
  local chunks = {}
  for _, chunk in ipairs({ result.stdout, result.stderr }) do
    chunk = (chunk or ""):gsub("%s+$", "")
    if chunk ~= "" then table.insert(chunks, chunk) end
  end
  local output = table.concat(chunks, "\n")
  local lines = vim.split(output ~= "" and output or "(no output)", "\n", { plain = true })
  if footer then
    table.insert(lines, "")
    table.insert(lines, footer)
  end
  table.insert(lines, 1, "")
  table.insert(lines, 1, title .. (result.code == 0 and " completed" or " failed"))

  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "log"
  vim.bo[buf].modifiable = false

  local width = math.max(1, math.min(100, vim.o.columns - 4))
  local height = math.max(1, math.min(#lines + 1, vim.o.lines - 4))
  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })
  vim.wo[win].wrap = true
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<cr>", { buffer = buf, silent = true, nowait = true })
  end
end

local function run(action, executable_name, extra_args, options)
  options = options or {}
  if M.running then
    return vim.notify("nvim-config: another maintenance command is still running", vim.log.levels.WARN)
  end
  executable_name = executable_name or "nvim-config"
  local executable = config_root() .. "/" .. (options.directory or "bin") .. "/" .. executable_name
  local report_title = options.title or (executable_name == "nvim-update" and "NvimUpdate"
    or "NvimConfig " .. action
  )
  if vim.fn.executable(executable) ~= 1 then
    return vim.notify("missing or not executable: " .. executable, vim.log.levels.ERROR)
  end

  M.running = true
  local action_label = options.action_label or action
  vim.notify(executable_name .. ": " .. action_label .. " started in the background",
    vim.log.levels.INFO)
  local command = { executable }
  if executable_name ~= "nvim-update" then command[#command + 1] = action end
  vim.list_extend(command, extra_args or {})
  -- Only the nvim-config CLI takes this flag; scripts/ helpers do not.
  if options.no_color ~= false then
    command[#command + 1] = "--no-color"
  end
  vim.system(command, {
    text = true,
    cwd = config_root(),
    -- Merged into the inherited environment; vim.system only replaces it
    -- wholesale when clear_env is set, which nothing here wants.
    env = options.env,
  }, function(result)
    vim.schedule(function()
      M.running = false
      local footer = result.code == 0 and options.success_footer or nil
      show_report(report_title, result, footer)
      local level = result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
      vim.notify(executable_name .. ": " .. action_label
        .. (result.code == 0 and " completed" or " failed"), level)
    end)
  end)
end

local function dev_directory()
  local configured = vim.env.NVIM_DEV_DIR
  if configured and configured ~= "" then return configured end
  return config_root() .. "/dev"
end

--- Fetch and fast-forward this account's own plugins on bluff.
---
--- lazy.nvim never does this: every one of its Git tasks skips a plugin it
--- resolved outside its own root, so `:Lazy update` silently passes over the
--- dev/ fleet. scripts/dev-plugins.sh is what actually moves them -- it
--- preflights the whole fleet before updating any checkout, so a network
--- failure or a dirty plugin leaves every existing checkout untouched. This is
--- the editor entry point for the same fixed-branch fleet operation.
function M.dev_plugins()
  -- Refuse rather than clone. dev-plugins.sh creates the whole fleet when it
  -- is absent, which is right for an explicit CLI call and wrong for a
  -- mistyped command on an ordinary install that has no fleet by design.
  local directory = dev_directory()
  if vim.fn.isdirectory(directory) ~= 1 then
    return vim.notify(
      "nvim-config: no plugin fleet at " .. directory
        .. "; create one with 'mise run plugins:clone'",
      vim.log.levels.ERROR)
  end

  run("sync", "dev-plugins.sh", nil, {
    directory = "scripts",
    no_color = false,
    title = "DevPlugins",
    action_label = "sync bluff",
    success_footer = "Restart Neovim to load the updated plugins.",
  })
end

function M.setup()
  api.nvim_create_user_command("NvimUpdate", function() run("update", "nvim-update") end, {
    desc = "Fast-forward the config and local plugin fleet, then reconcile dependencies",
  })
  api.nvim_create_user_command("NvimConfigUpdate", function() run("update", "nvim-update") end, {
    desc = "Fast-forward this config and reconcile changed dependencies",
  })
  api.nvim_create_user_command("DevPlugins", function()
    M.dev_plugins()
  end, {
    desc = "Fetch and fast-forward this account's own plugins on bluff",
  })
  api.nvim_create_user_command("NvimConfigDoctor", function() run("doctor") end, {
    desc = "Check Neovim config, Git, Node, and toolchain prerequisites",
  })
end

return M
