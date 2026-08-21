# Configuration maintenance

The repository separates installation, routine updates, and dependency
upgrades so each operation has one predictable responsibility.

## Commands

| Command | Purpose |
| --- | --- |
| `bootstrap.sh` | Clone when needed and provision the checkout already on disk |
| `nvim-config doctor` | Validate Git, Neovim, Node/npm, supporting tools, upstream, and worktree state |
| `nvim-config update` | Fetch the configured upstream, fast-forward, and reconcile affected dependencies |
| `nvim-config sync` | Restore locked plugins and install missing managed tools/parsers |
| `nvim-config sync --latest` | Update unpinned Mason tools and Treesitter parsers |
| `:NvimConfigUpdate` | Run the same whole-config update asynchronously from Neovim |
| `:NvimConfigDoctor` | Run the doctor asynchronously from Neovim |

The updater requires a clean, attached worktree with an upstream. It reads the
existing branch/remote relationship, runs a fetch on that remote, and accepts
only a fast-forward. It does not edit Git remotes, SSH configuration, tunnels,
WireGuard, nftables, routes, or host aliases. Divergence is reported for manual
resolution.

## Version policy

`lua/config/toolchain.lua` is the source of truth:

- Neovim 0.12.0 is the minimum; 0.12.4 is the tested release.
- Node 22 is the compatibility floor.
- Node 24 is the recommended/default CI lane.
- Node 26 is the forward-looking canary lane.
- Treesitter parsers, Mason package names, and LSP server names are centralized
  so bootstrap, startup, CI, and docs cannot silently drift.

lazy.nvim dependencies use exact commits in `lazy-lock.json`. This is the
latest-tested model: automation proposes current commits, CI tests them, and
merging the PR advances the reproducible lock. Mason entries intentionally have
no version suffix, so Mason resolves the latest registry release when
`MasonToolsUpdateSync` runs. Node compatibility CI executes current Prettier,
markdownlint-cli2, Pyright, and typescript-language-server releases across all
three Node lanes.

## Automation

`.github/workflows/dependency-update.yml` runs weekly and can also receive a
`plugin-release` repository dispatch with a `plugin` payload of
`git-panel.nvim` or `mcp-buff`. A manual run can select the same focused target
or refresh every lazy.nvim dependency. The workflow opens a PR into `bluff`;
normal repository promotion rules remain in force.

For PR checks to run on an automation-created PR, configure a fine-grained
`DEPENDENCY_UPDATE_TOKEN` repository secret with contents and pull-request
write access. Without it, the workflow falls back to `GITHUB_TOKEN`; GitHub may
suppress workflows triggered by that token.

Plugin repositories may publish a release hook using a fine-grained
`NVIM_CONFIG_DISPATCH_TOKEN` secret and this request shape:

```sh
gh api --method POST repos/777lotto/nvim-config/dispatches \
  --raw-field event_type=plugin-release \
  --field 'client_payload[plugin]=git-panel.nvim'
```

Use `mcp-buff` as the payload for that repository. Tokens remain repository
secrets and are never stored in this config.

## MCP Buff boundary

The managed MCP Buff spec uses only `http://127.0.0.1:8792`. Installing or
updating the config does not open a tunnel or change an SSH host. Operators
bring up and tear down the documented external tunnel separately; the panel
cannot reach a bridge address, container address, or Cloudflare directly.
