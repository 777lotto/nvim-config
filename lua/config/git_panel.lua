local M = {}

local function standard_profiles()
  return {
    ["github-cli"] = {
      label = "GitHub CLI",
      description = "Use an externally authenticated gh installation.",
      transport = "gh",
      gh_command = "gh",
      api_url = "",
      remote_path_prefix = "",
      allow_insecure_http = false,
      merge_backend = "api",
    },
    ["public-rest"] = {
      label = "Public REST",
      description = "Use anonymous curl access for public repositories.",
      transport = "curl",
      api_url = "",
      remote_path_prefix = "",
      allow_insecure_http = false,
      merge_backend = "api",
    },
  }
end

function M.options(runtime)
  runtime = runtime or {}
  local expand = runtime.expand or vim.fn.expand
  local executable = runtime.executable or function(path) return vim.fn.executable(path) == 1 end
  local profiles = standard_profiles()

  -- gh-agent is a marker for the credential-free zemrip-ai broker plane. It is
  -- intentionally not passed as github.gh_command: its API syntax differs from
  -- gh. GitPanel talks to the broker's reviewed REST route with anonymous curl,
  -- and the host injects the short-lived repository credential upstream.
  local agent_cli = expand("~/.local/bin/gh-agent")
  if executable(agent_cli) then
    local broker = {
      label = "Zemrip GitHub broker",
      description = "Use the credential-free host broker available inside zemrip-ai.",
      transport = "curl",
      remote_path_prefix = "github/git",
      api_url = "http://10.77.0.1:8790/github/api",
      allow_insecure_http = true,
      merge_backend = "api",
      timeout = 60000,
    }
    profiles["zemrip-broker"] = broker
    return {
      github = {
        -- Flat settings keep the broker working with the proxy-aware release
        -- that predates named profiles; the selected profile is the durable UI.
        profile = "zemrip-broker",
        profiles = profiles,
        transport = broker.transport,
        remote_path_prefix = broker.remote_path_prefix,
        api_url = broker.api_url,
        allow_insecure_http = broker.allow_insecure_http,
        merge_backend = broker.merge_backend,
        timeout = broker.timeout,
      },
    }
  end

  local app_cli = expand("~/.local/bin/gh-app")
  if executable(app_cli) then
    profiles["github-app"] = {
      label = "Repository GitHub App",
      description = "Use the workstation's repository-scoped App wrapper and signed Git merges.",
      transport = "gh",
      gh_command = app_cli,
      api_url = "",
      remote_path_prefix = "",
      allow_insecure_http = false,
      merge_backend = "signed_git",
      timeout = 60000,
    }
    return {
      github = {
        profile = "github-app",
        profiles = profiles,
        transport = "gh",
        gh_command = app_cli,
        merge_backend = "signed_git",
        timeout = 60000,
      },
    }
  end

  return { github = { profiles = profiles, merge_backend = "api" } }
end

return M
