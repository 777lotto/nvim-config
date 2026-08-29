local function report(message)
  io.stdout:write(message .. "\n")
  io.stdout:flush()
end

local function measure(label, iterations, budget_us, callback)
  collectgarbage("collect")
  callback()
  local started = vim.uv.hrtime()
  for _ = 1, iterations do callback() end
  local elapsed_us = (vim.uv.hrtime() - started) / 1000
  local per_call_us = elapsed_us / iterations
  report(("UX benchmark: %-24s %9.2f us/call (%d iterations; budget %.0f us)"):format(
    label, per_call_us, iterations, budget_us
  ))
  assert(per_call_us <= budget_us,
    ("%s exceeded its %.0f us budget: %.2f us"):format(label, budget_us, per_call_us))
end

local chrome = require("ux_chrome")
measure("Chrome tabline render", 2000, 1000, function() chrome.tabline() end)
measure("Chrome statusline render", 2000, 1000, function() chrome.statusline() end)
measure("Chrome external refresh", 100, 10000, function()
  local ok, err = chrome.refresh()
  assert(ok, tostring(err))
end)

local styling_started = vim.uv.hrtime()
vim.cmd("UXStyling")
local styling = require("ux_styling")
local styling_startup_ms = (vim.uv.hrtime() - styling_started) / 1000000
report(("UX benchmark: Styling first open      %9.2f ms (budget 1500 ms)"):format(styling_startup_ms))
assert(styling_startup_ms <= 1500,
  ("Styling first open exceeded its 1500 ms budget: %.2f ms"):format(styling_startup_ms))
assert(styling.close())
measure("Styling catalog refresh", 10, 300000, function()
  local refreshed, err = styling.refresh()
  assert(refreshed, tostring(err))
end)

local adapter_timings = {}
for _, descriptor in ipairs(styling.adapters().bundled) do
  local started = vim.uv.hrtime()
  local refreshed, err = styling.refresh(descriptor.plugin_id)
  assert(refreshed, tostring(err))
  adapter_timings[#adapter_timings + 1] = {
    plugin_id = descriptor.plugin_id,
    elapsed_ms = (vim.uv.hrtime() - started) / 1000000,
  }
end
table.sort(adapter_timings, function(left, right) return left.elapsed_ms > right.elapsed_ms end)
for index = 1, math.min(5, #adapter_timings) do
  local timing = adapter_timings[index]
  report(("UX benchmark: adapter %-28s %8.2f ms"):format(timing.plugin_id, timing.elapsed_ms))
end
local foundation = require("ux_foundation")
measure("Foundation registrations", 5, 500000, function() foundation.registrations() end)
measure("Foundation property list", 5, 500000, function() foundation.list_properties() end)
measure("Foundation transaction", 5, 500000, function()
  local transaction, err = foundation.begin_transaction()
  assert(transaction, tostring(err))
  local committed, commit_error = transaction:commit()
  assert(committed, tostring(commit_error))
end)
measure("Styling open/close", 5, 500000, function()
  assert(styling.open())
  assert(styling.close())
end)

report("UX performance budgets passed")
vim.cmd("quitall!")
