-- Environment-dependent policy belongs here instead of in plugin specs.
-- Keep the defaults portable and expose small overrides for machines whose
-- terminal or clipboard behavior differs from the current Debian setup.
local M = {}

local function is_set(value)
  return type(value) == "string" and value ~= ""
end

local function first_set(...)
  for index = 1, select("#", ...) do
    local value = select(index, ...)
    if is_set(value) then
      return value
    end
  end
  return "unset"
end

M.is_ssh = is_set(vim.env.SSH_TTY) or is_set(vim.env.SSH_CONNECTION)
M.desktop = first_set(vim.env.XDG_CURRENT_DESKTOP, vim.env.DESKTOP_SESSION)
M.session_type = first_set(vim.env.XDG_SESSION_TYPE)
M.terminal = first_set(vim.env.TERM_PROGRAM, vim.env.COLORTERM, vim.env.TERM)
M.ssh_auth_sock = first_set(vim.env.SSH_AUTH_SOCK)

local valid_clipboard_modes = {
  auto = true,
  native = true,
  osc52 = true,
}

local function requested_clipboard_mode()
  local mode = (vim.env.NVIM_CLIPBOARD or "auto"):lower()
  if mode == "" then
    mode = "auto"
  end

  if valid_clipboard_modes[mode] then
    return mode
  end

  vim.schedule(function()
    vim.notify(
      ("Ignoring invalid NVIM_CLIPBOARD=%q; expected auto, native, or osc52"):format(mode),
      vim.log.levels.WARN,
      { title = "Environment policy" }
    )
  end)
  return "auto"
end

local function setup_osc52_copy()
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste_with_terminal()
    -- OSC 52 clipboard reads are not consistently supported and can expose
    -- clipboard contents to remote programs. Use the client terminal's paste
    -- action instead; bracketed paste lets Neovim receive it safely.
    return { {}, "" }
  end

  vim.g.clipboard = {
    name = "OSC 52 (copy only)",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = paste_with_terminal,
      ["*"] = paste_with_terminal,
    },
  }
end

function M.setup()
  local mode = requested_clipboard_mode()
  if mode == "auto" then
    mode = M.is_ssh and "osc52" or "native"
  end

  -- "native" deliberately leaves g:clipboard unset so Neovim can choose the
  -- available local clipboard provider itself.
  vim.opt.clipboard = "unnamedplus"
  if mode == "osc52" then
    setup_osc52_copy()
  end
  M.clipboard_mode = mode

  vim.api.nvim_create_user_command("EnvironmentInfo", function()
    local lines = {
      "SSH session: " .. tostring(M.is_ssh),
      "Desktop: " .. M.desktop,
      "Session type: " .. M.session_type,
      "Terminal: " .. M.terminal,
      "Clipboard policy: " .. M.clipboard_mode,
      "SSH_AUTH_SOCK: " .. M.ssh_auth_sock,
    }
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Neovim environment" })
  end, {
    desc = "Show detected desktop, terminal, clipboard, and SSH environment",
    force = true,
  })
end

return M
