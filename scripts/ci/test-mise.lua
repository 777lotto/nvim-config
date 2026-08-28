local root = assert(arg[1], "repository root argument is required")
root = vim.fs.normalize(vim.fn.fnamemodify(root, ":p"))

vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:append(vim.fs.joinpath(root, "after"))
vim.opt.runtimepath:prepend(vim.fs.joinpath(vim.fn.stdpath("data"), "site"))

local toolchain = require("config.toolchain")
local version = vim.version()
local actual_version = ("%d.%d.%d"):format(version.major, version.minor, version.patch)
assert(actual_version == toolchain.neovim.tested, "tests must run on Neovim " .. toolchain.neovim.tested)

local function to_set(values)
  local result = {}
  for _, value in ipairs(values) do
    result[value] = true
  end
  return result
end

local parsers = to_set(toolchain.parsers)
local parser_filetypes = to_set(toolchain.parser_filetypes)
if vim.env.NVIM_TEST_INSTALL_MISE_PARSERS == "1" then
  require("nvim-treesitter").setup({
    install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
  })
  local installed = require("nvim-treesitter").install({ "bash", "toml", "kdl" }):wait(300000)
  assert(installed, "failed to install Mise test parsers")
  print("Installed isolated Mise test parsers")
  return
end

for parser, filetype in pairs({ bash = "sh", toml = "toml", kdl = "kdl" }) do
  assert(parsers[parser], "missing managed parser: " .. parser)
  assert(parser_filetypes[filetype], "missing managed parser filetype: " .. filetype)
  local ok, message = pcall(vim.treesitter.get_string_parser, "", parser)
  assert(ok, ("parser %s is not installed: %s"):format(parser, message))
end

local mise = require("config.mise")
mise.setup()
assert(vim.list_contains(vim.treesitter.query.list_predicates(), "is-mise?"))

local recognized_paths = {
  "/workspace/mise.toml",
  "/workspace/.mise.toml",
  "/workspace/mise.local.toml",
  "/workspace/.mise.production.local.toml",
  "/workspace/mise/config.toml",
  "/workspace/.mise/config.production.toml",
  "/workspace/mise/conf.d/node-tools.toml",
  "/workspace/.mise/conf.d/tasks.toml",
  "/workspace/.config/mise.toml",
  "/workspace/.config/mise/config.toml",
  "/home/user/.config/mise/conf.d/10-tools.toml",
  "/etc/mise/config.toml",
}

for _, path in ipairs(recognized_paths) do
  assert(mise.is_config_path(path), "expected a recognized Mise config path: " .. path)
end

local ordinary_paths = {
  "/workspace/config.toml",
  "/workspace/promise.toml",
  "/workspace/mise-config.toml",
  "/workspace/tasks.toml",
  "/workspace/conf.d/tools.toml",
  "/workspace/.miserc.toml",
  "/workspace/mise/conf.d/.hidden.toml",
  "/workspace/mise/conf.d/tools.txt",
}

for _, path in ipairs(ordinary_paths) do
  assert(not mise.is_config_path(path), "expected an ordinary TOML path: " .. path)
end

local expected_query_files = {
  bash = vim.fs.joinpath(root, "after/queries/bash/injections.scm"),
  toml = vim.fs.joinpath(root, "after/queries/toml/injections.scm"),
}

for language, expected_file in pairs(expected_query_files) do
  assert(vim.treesitter.query.get(language, "injections"), "missing injection query for " .. language)
  local found = false
  for _, path in ipairs(vim.api.nvim_get_runtime_file("queries/" .. language .. "/injections.scm", true)) do
    if vim.fs.normalize(path) == expected_file then
      found = true
      break
    end
  end
  assert(found, "query is not on runtimepath: " .. expected_file)
end

local function parse_injections(path, language, source)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buffer, path)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, vim.split(source, "\n", { plain = true }))

  local parser = vim.treesitter.get_parser(buffer, language)
  local tree = assert(parser:parse(true)[1], "parser returned no tree for " .. language)
  local query = assert(vim.treesitter.query.get(language, "injections"))
  local matches = {}

  for pattern, match, metadata in query:iter_matches(tree:root(), buffer, 0, -1) do
    local injection_language = metadata["injection.language"]
    for capture_id, nodes in pairs(match) do
      if query.captures[capture_id] == "injection.language" then
        injection_language = vim.treesitter.get_node_text(nodes[1], buffer, {
          metadata = metadata[capture_id],
        })
      end
    end

    local ranges = {}
    for capture_id, nodes in pairs(match) do
      if query.captures[capture_id] == "injection.content" then
        for _, node in ipairs(nodes) do
          local range = vim.treesitter.get_range(node, buffer, metadata[capture_id])
          table.insert(ranges, {
            range = { range[1], range[2], range[4], range[5] },
            text = source:sub(range[3] + 1, range[6]),
          })
        end
      end
    end

    table.sort(ranges, function(left, right)
      if left.range[1] == right.range[1] then return left.range[2] < right.range[2] end
      return left.range[1] < right.range[1]
    end)
    if injection_language and #ranges > 0 then
      table.insert(matches, {
        combined = metadata["injection.combined"] ~= nil,
        language = injection_language,
        pattern = pattern,
        ranges = ranges,
      })
    end
  end

  vim.api.nvim_buf_delete(buffer, { force = true })
  return matches
end

local function ranges_match(actual, expected)
  if #actual ~= #expected then return false end
  for index, wanted in ipairs(expected) do
    if not vim.deep_equal(actual[index].range, wanted.range) or actual[index].text ~= wanted.text then
      return false
    end
  end
  return true
end

local function assert_injection(matches, language, expected)
  for _, match in ipairs(matches) do
    if match.language == language and ranges_match(match.ranges, expected) then return match end
  end
  error(("missing %s injection %s\nactual: %s"):format(language, vim.inspect(expected), vim.inspect(matches)))
end

local toml_lines = {
  'run = "echo single"',
  "",
  "[tasks.plain]",
  "run = '''",
  "echo plain",
  "'''",
  "",
  "[tasks.env]",
  "run = '''",
  "#!/usr/bin/env python",
  'print("env")',
  "'''",
  "",
  "[tasks.direct]",
  "run = '''",
  "#!/usr/bin/ruby",
  'puts "direct"',
  "'''",
}
local toml_source = table.concat(toml_lines, "\n")
local toml_matches = parse_injections("/workspace/mise.toml", "toml", toml_source)

assert_injection(toml_matches, "bash", {
  { range = { 0, 7, 0, 18 }, text = "echo single" },
})
assert_injection(toml_matches, "bash", {
  { range = { 3, 9, 5, 0 }, text = "\necho plain\n" },
})
assert_injection(toml_matches, "python", {
  { range = { 8, 9, 11, 0 }, text = '\n#!/usr/bin/env python\nprint("env")\n' },
})
assert_injection(toml_matches, "ruby", {
  { range = { 14, 9, 17, 0 }, text = '\n#!/usr/bin/ruby\nputs "direct"\n' },
})

local target_languages = { bash = true, python = true, ruby = true }
local target_count = 0
for _, match in ipairs(toml_matches) do
  if target_languages[match.language] then target_count = target_count + 1 end
end
assert(target_count == 4, "expected exactly four Mise run injections")

local ordinary_matches = parse_injections("/workspace/settings.toml", "toml", toml_source)
for _, match in ipairs(ordinary_matches) do
  assert(not target_languages[match.language], "ordinary TOML activated a Mise run injection")
end

local bash_lines = {
  "#!/usr/bin/env bash",
  '#MISE description = "plain"',
  "true",
  '#[MISE] alias = "bracketed"',
  "true",
  '# [MISE] sources = ["spaced"]',
  "true",
  '#USAGE arg "<plain>" {',
  '#USAGE   choices "one" "two"',
  "#USAGE }",
  "true",
  '#[USAGE] flag "--bracketed"',
  '#[USAGE] flag "--second"',
  "true",
  '# [USAGE] arg "<spaced>"',
  '# [USAGE] arg "<second>"',
  "true",
}
local bash_source = table.concat(bash_lines, "\n")
local bash_matches = parse_injections("/workspace/.mise/tasks/example", "bash", bash_source)

assert_injection(bash_matches, "toml", {
  { range = { 1, 6, 1, #bash_lines[2] + 1 }, text = 'description = "plain"\n' },
})
assert_injection(bash_matches, "toml", {
  { range = { 3, 8, 3, #bash_lines[4] + 1 }, text = 'alias = "bracketed"\n' },
})
assert_injection(bash_matches, "toml", {
  { range = { 5, 9, 5, #bash_lines[6] + 1 }, text = 'sources = ["spaced"]\n' },
})

local plain_usage = assert_injection(bash_matches, "kdl", {
  { range = { 7, 7, 7, #bash_lines[8] + 1 }, text = 'arg "<plain>" {\n' },
  { range = { 8, 7, 8, #bash_lines[9] + 1 }, text = '  choices "one" "two"\n' },
  { range = { 9, 7, 9, #bash_lines[10] + 1 }, text = "}\n" },
})
local bracketed_usage = assert_injection(bash_matches, "kdl", {
  { range = { 11, 9, 11, #bash_lines[12] + 1 }, text = 'flag "--bracketed"\n' },
  { range = { 12, 9, 12, #bash_lines[13] + 1 }, text = 'flag "--second"\n' },
})
local spaced_usage = assert_injection(bash_matches, "kdl", {
  { range = { 14, 10, 14, #bash_lines[15] + 1 }, text = 'arg "<spaced>"\n' },
  { range = { 15, 10, 15, #bash_lines[16] + 1 }, text = 'arg "<second>"\n' },
})

assert(not plain_usage.combined and not bracketed_usage.combined and not spaced_usage.combined)
print("Mise Treesitter integration passed on Neovim " .. actual_version)
