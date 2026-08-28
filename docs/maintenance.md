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

## Optional Mise task façade

`mise.toml` at the repository root is a thin façade over `bin/nvim-config`
plus fleet operations on `dev/`. It declares no `[tools]`: `lua/config/toolchain.lua`,
Mason, and the machine's own Mise configuration already own tool provisioning,
and a second version source would be free to drift. Mise stays optional -
nothing in the editor, `bootstrap.sh`, or `bin/nvim-config` invokes or requires
it, and every task has a documented direct equivalent.

| Task | Runs |
| --- | --- |
| `mise run update` | `bin/nvim-config update` |
| `mise run doctor` | `bin/nvim-config doctor` |
| `mise run sync` | `bin/nvim-config sync` |
| `mise run plugins:clone` | ensure every fleet checkout exists under `dev/` |
| `mise run plugins:pull` | fast-forward every `dev/` checkout |
| `mise run plugins:status` | one line of branch/dirty/ahead-behind per checkout |
| `mise run plugins:check` | compile-check every `dev/` plugin that has Lua |
| `mise run test-sync` | `update`, then `plugins:pull`, then `doctor` |

### Manual testing loop

To exercise integration-branch config against integration-branch plugins:

```sh
mise run test-sync
```

That fast-forwards the config, fast-forwards every `dev/` plugin checkout, and
re-runs the doctor. Restart Neovim afterwards - lazy.nvim resolves dev plugins
at startup, so a running session keeps the checkouts it loaded with.

`plugins:pull` refuses loudly on a dirty or diverged checkout rather than
touching your work; resolve those in the plugin's own repository. `dev/` is
gitignored and never enters a commit here, and none of these tasks write
`lazy-lock.json`: a dependency pin still moves only through the documented
dependency-refresh flow.

## Version policy

`lua/config/toolchain.lua` is the source of truth:

- Neovim 0.12.0 is the minimum; 0.12.4 is the tested release.
- Node 22 is the compatibility floor.
- Node 24 is the recommended/default CI lane.
- Node 26 is the forward-looking canary lane.
- Treesitter parsers, Mason package names, and LSP server names are centralized
  so bootstrap, startup, CI, and docs cannot silently drift.

The managed parser list includes Bash, TOML, and KDL for the optional Mise
query extensions. `nvim-config sync` installs any missing parser, while
`nvim-config sync --latest` refreshes parsers and their upstream queries. These
operations do not install or invoke Mise itself.

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
