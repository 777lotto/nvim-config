local api = vim.api
local channel = require("config.channel")

local M = { running = false }
local loaded_channel = channel.current()

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
  local executable = config_root() .. "/bin/" .. executable_name
  local report_title = options.title or (executable_name == "nvim-update" and "NvimUpdate"
    or "NvimConfig " .. action
  )
  if vim.fn.executable(executable) ~= 1 then
    return vim.notify("nvim-config CLI is missing or not executable: " .. executable, vim.log.levels.ERROR)
  end

  M.running = true
  local action_label = options.action_label or action
  vim.notify(executable_name .. ": " .. action_label .. " started in the background",
    vim.log.levels.INFO)
  local command = { executable, action }
  vim.list_extend(command, extra_args or {})
  command[#command + 1] = "--no-color"
  vim.system(command, {
    text = true,
    cwd = config_root(),
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

local CHANNELS = {
  { id = "bet", label = "bet — production" },
  { id = "bluff", label = "bluff — integration" },
}

function M.channel_choices()
  local requested = channel.current()
  local choices = vim.deepcopy(CHANNELS)
  for _, choice in ipairs(choices) do
    choice.loaded = choice.id == loaded_channel
    choice.requested = choice.id == requested
  end
  return choices
end

local function confirm_channel(selected)
  local confirmation = {
    { id = "switch", label = "Switch, update, and require a restart" },
    { id = "cancel", label = "Cancel" },
  }
  vim.ui.select(confirmation, {
    prompt = ("Change Neovim channel from %s to %s?"):format(loaded_channel, selected),
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice or choice.id ~= "switch" then return end
    run("channel", "nvim-config", { selected }, {
      title = "NvimChannel",
      action_label = "channel " .. selected,
      success_footer = "Restart Neovim to load channel " .. selected .. ".",
    })
  end)
end

function M.select_channel(selected)
  if selected and selected ~= "" then return confirm_channel(selected) end
  vim.ui.select(M.channel_choices(), {
    prompt = "Neovim configuration channel:",
    format_item = function(choice)
      local markers = {}
      if choice.loaded then markers[#markers + 1] = "loaded" end
      if choice.requested and not choice.loaded then markers[#markers + 1] = "requested" end
      return choice.label .. (#markers > 0 and (" (" .. table.concat(markers, ", ") .. ")") or "")
    end,
  }, function(choice)
    if choice then confirm_channel(choice.id) end
  end)
end

function M.setup()
  api.nvim_create_user_command("NvimUpdate", function() run("update", "nvim-update") end, {
    desc = "Update the persistent config/plugin channel and reconcile dependencies",
  })
  api.nvim_create_user_command("NvimConfigUpdate", function() run("update", "nvim-update") end, {
    desc = "Fast-forward this config and reconcile changed dependencies",
  })
  api.nvim_create_user_command("NvimConfigDoctor", function() run("doctor") end, {
    desc = "Check Neovim config, Git, Node, and toolchain prerequisites",
  })
  api.nvim_create_user_command("NvimChannel", function(options)
    M.select_channel(options.args)
  end, {
    desc = "Select and update the persistent Neovim configuration channel",
    nargs = "?",
    complete = function() return { "bet", "bluff" } end,
  })
end

return M
