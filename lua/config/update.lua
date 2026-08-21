local api = vim.api

local M = { running = false }

local function config_root()
  return vim.env.NVIM_CONFIG_ROOT or vim.fn.stdpath("config")
end

local function show_report(title, result)
  local chunks = {}
  for _, chunk in ipairs({ result.stdout, result.stderr }) do
    chunk = (chunk or ""):gsub("%s+$", "")
    if chunk ~= "" then table.insert(chunks, chunk) end
  end
  local output = table.concat(chunks, "\n")
  local lines = vim.split(output ~= "" and output or "(no output)", "\n", { plain = true })
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

local function run(action)
  if M.running then
    return vim.notify("nvim-config: another maintenance command is still running", vim.log.levels.WARN)
  end
  local executable = config_root() .. "/bin/nvim-config"
  if vim.fn.executable(executable) ~= 1 then
    return vim.notify("nvim-config CLI is missing or not executable: " .. executable, vim.log.levels.ERROR)
  end

  M.running = true
  vim.notify("nvim-config: " .. action .. " started in the background", vim.log.levels.INFO)
  vim.system({ executable, action, "--no-color" }, {
    text = true,
    cwd = config_root(),
  }, function(result)
    vim.schedule(function()
      M.running = false
      show_report("NvimConfig " .. action, result)
      local level = result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
      vim.notify("nvim-config: " .. action .. (result.code == 0 and " completed" or " failed"), level)
    end)
  end)
end

function M.setup()
  api.nvim_create_user_command("NvimConfigUpdate", function() run("update") end, {
    desc = "Fast-forward this config and reconcile changed dependencies",
  })
  api.nvim_create_user_command("NvimConfigDoctor", function() run("doctor") end, {
    desc = "Check Neovim config, Git, Node, and toolchain prerequisites",
  })
end

return M
