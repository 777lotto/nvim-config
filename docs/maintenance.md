# Configuration maintenance

The repository separates installation, routine updates, and dependency
upgrades so each operation has one predictable responsibility.

## Commands

| Command                        | Purpose                                                                                                 |
| ------------------------------ | ------------------------------------------------------------------------------------------------------- |
| `bootstrap.sh`                 | Clone when needed and provision the checkout already on disk; an explicit branch also seeds its channel |
| `nvim-update`                  | Converge config and account-owned plugins on the persistent channel                                     |
| `nvim-update channel <branch>` | Persist, switch, and update another shared branch (`bet` is the rollback)                               |
| `nvim-config doctor`           | Validate Git, Neovim, Node/npm, supporting tools, upstream, and worktree state                          |
| `nvim-config update`           | Backward-compatible implementation behind `nvim-update`                                                 |
| `nvim-config sync`             | Restore locked plugins and install missing managed tools/parsers                                        |
| `nvim-config sync --latest`    | Update unpinned Mason tools and Treesitter parsers                                                      |
| `:NvimUpdate`                  | Run the same channel-aware update asynchronously from Neovim                                            |
| `:NvimConfigUpdate`            | Backward-compatible alias for `:NvimUpdate`                                                             |
| `:NvimConfigDoctor`            | Run the doctor asynchronously from Neovim                                                               |
| `:NvimChannel`                 | Select `bet` or `bluff`, confirm, then run the guarded channel update                                   |

The updater requires clean, attached checkouts. It reads the persisted channel
from `${XDG_STATE_HOME:-$HOME/.local/state}/nvim-config/channel` (default
`bet`), fetches that same branch from the existing remote, safely switches the
config, and accepts only fast-forwards. On non-`bet` channels it preflights the
whole `dev/` fleet before switching any existing plugin branch, then
compile-checks every Lua plugin. Returning to `bet` likewise converges an
existing developer fleet but does not create one on an ordinary production
install. It does not edit Git remote URLs, SSH configuration, tunnels,
WireGuard, nftables, routes, or host aliases. Divergence is reported for manual
resolution. A failed channel change keeps the requested state so fixing the
reported checkout and rerunning
`nvim-update` resumes the same operation; `nvim-update channel bet` is the
explicit undo.

The CLI and Lua runtime share exactly
`${XDG_STATE_HOME:-$HOME/.local/state}/nvim-config/channel`. The Lua reader must
not use Neovim's application-specific `stdpath("state")`, because that appends
an extra `nvim/` component and would make the editor silently load a different
channel from the updater. `:NvimChannel` shows the channel loaded by the current
process separately from a newly requested selection and requires a restart
after the update succeeds.

## Optional Mise task façade

`mise.toml` at the repository root is a thin façade over `bin/nvim-config`
plus fleet operations on `dev/`. It declares no `[tools]`: `lua/config/toolchain.lua`,
Mason, and the machine's own Mise configuration already own tool provisioning,
and a second version source would be free to drift. Mise stays optional -
nothing in the editor, `bootstrap.sh`, or `bin/nvim-config` invokes or requires
it, and every task has a documented direct equivalent.

| Task                      | Runs                                                               |
| ------------------------- | ------------------------------------------------------------------ |
| `mise run update`         | `bin/nvim-update`                                                  |
| `mise run doctor`         | `bin/nvim-config doctor`                                           |
| `mise run sync`           | `bin/nvim-config sync`                                             |
| `mise run plugins:clone`  | ensure every fleet checkout exists under `dev/`                    |
| `mise run plugins:pull`   | select and fast-forward the channel in every `dev/` checkout       |
| `mise run plugins:sync`   | explicit alias for the same fleet convergence                      |
| `mise run plugins:status` | one line of branch/dirty/ahead-behind per checkout                 |
| `mise run plugins:check`  | compile-check every `dev/` plugin that has Lua                     |
| `mise run test-sync`      | backward-compatible alias for `bin/nvim-update`                    |
| `mise run verify`         | shell, core, updater, fleet, UX integration, and performance gates |

Always use the explicit `mise run <task>` form. Mise ships its own top-level
`doctor` and `sync` subcommands, so a bare `mise doctor` or `mise sync` runs
Mise's command rather than this repository's task, and exits 0 without
indicating that anything was shadowed.

### Manual testing loop

To keep this machine on integration config and plugins until explicitly
changed back:

```sh
nvim-update channel bluff
nvim-update
```

The first command persists the selection and converges immediately; future
`nvim-update` calls keep using it. Restart Neovim afterwards—lazy.nvim resolves
non-production account plugins from the selected `dev/` checkouts, while `bet`
uses the committed production pins.

`plugins:pull` refuses loudly on a dirty or diverged checkout rather than
touching your work; resolve those in the plugin's own repository. `dev/` is
gitignored and never enters a commit here.

A dependency pin still moves only through the documented dependency-refresh
flow. `update` and `sync` do rewrite `lazy-lock.json` through lazy.nvim, as
they always have, but they write the same content on a machine with `dev/`
populated as on one without it: `bin/nvim-config` sets `NVIM_TOOLCHAIN_SYNC`,
and `lua/config/lazy.lua` turns dev matching off when it is set. Without that
guard lazy.nvim would treat each dev plugin as local and drop its pin from the
lockfile entirely.

## Version policy

`lua/config/toolchain.lua` is the source of truth:

- Neovim 0.12.2 is the minimum; 0.12.4 is the tested release.
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

The MCP Buff spec uses only `http://127.0.0.1:8792` and reads the admin
capability from `pass` on the Toughbook. `:McpBuff` owns a temporary,
loopback-only SSH forward through `zemrip-server` for the visible review
session, then terminates that exact child. It cannot reach a bridge address,
container address, or Cloudflare directly.

The `zemrip-server` SSH alias is the WireGuard route and is maintained outside
this repository. WireGuard is expected to remain active; the plugin does not
start, stop, or reconfigure it, and must never fall back to
`zemrip-server-lan`. An already occupied local admin port is refused because
the plugin cannot prove who owns that listener.
