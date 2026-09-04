# Configuration maintenance

The repository separates installation, routine updates, and dependency
upgrades so each operation has one predictable responsibility.

## Commands

| Command                     | Purpose                                                                        |
| --------------------------- | ------------------------------------------------------------------------------ |
| `bootstrap.sh`              | Clone the GitHub default branch when needed and provision the checkout on disk |
| `nvim-update`               | Fast-forward the config and an existing local plugin fleet                     |
| `nvim-config doctor`        | Validate Git, Neovim, Node/npm, supporting tools, upstream, and worktree state |
| `nvim-config update`        | Backward-compatible implementation behind `nvim-update`                        |
| `nvim-config sync`          | Restore locked plugins/runtime and install missing managed tools/parsers       |
| `nvim-config sync --latest` | Update unpinned Mason tools and Treesitter parsers                             |
| `:NvimUpdate`               | Run the same guarded update asynchronously from Neovim                         |
| `:DevPlugins`               | Fetch and fast-forward an existing `dev/` plugin fleet on `bluff`              |
| `:NvimConfigUpdate`         | Backward-compatible alias for `:NvimUpdate`                                    |
| `:NvimConfigDoctor`         | Run the doctor asynchronously from Neovim                                      |

The updater requires a clean, attached checkout with a configured upstream. It
fetches that remote, accepts only a fast-forward, and never changes branches.
If `dev/` exists, it then preflights the complete account-owned plugin fleet,
fast-forwards each clean `bluff` checkout, and compile-checks every Lua plugin.
An ordinary install has no `dev/` directory and continues using only exact
GitHub pins.

After restoring plugins, `nvim-config sync` asks Lazy to rebuild only Agent
Manager. For the reviewed remote pin, that build is an idempotent packaged
runtime verification/install: it downloads only when the exact release is
missing and never invokes Cargo, uv, or pip. For a local `dev/` override it is a
no-op because the fleet's source-build path owns that runtime. `:DevPlugins`
therefore never performs the packaged install and never rebuilds unrelated
plugins.

The updater does not stash, reset, rewrite remote URLs, switch branches, or
modify SSH/network configuration. Dirty, detached, differently branched, or
divergent checkouts are reported for manual resolution before any plugin is
updated. These properties make interrupted runs safe to retry.

The former persistent channel file at
`${XDG_STATE_HOME:-$HOME/.local/state}/nvim-config/channel` is no longer read.
It may remain harmlessly on machines that used the retired two-branch model.
An old config checkout still attached to the retired branch needs one explicit
Git switch to `bluff`; subsequent `nvim-update` runs follow its normal
`origin/bluff` upstream.

## Optional Mise task façade

`mise.toml` at the repository root is a thin façade over `bin/nvim-config`
plus fleet operations on `dev/`. It declares no `[tools]`:
`lua/config/toolchain.lua`, Mason, and the machine's own Mise configuration
already own tool provisioning. Mise stays optional—nothing in the editor,
`bootstrap.sh`, or `bin/nvim-config` invokes or requires it.

| Task                      | Runs                                                       |
| ------------------------- | ---------------------------------------------------------- |
| `mise run update`         | `bin/nvim-update`                                          |
| `mise run doctor`         | `bin/nvim-config doctor`                                   |
| `mise run sync`           | `bin/nvim-config sync`                                     |
| `mise run plugins:clone`  | ensure every fleet checkout exists under `dev/` on `bluff` |
| `mise run plugins:pull`   | fast-forward `bluff` in every `dev/` checkout              |
| `mise run plugins:sync`   | explicit alias for the same fleet convergence              |
| `mise run plugins:status` | one line of branch/dirty/ahead-behind per checkout         |
| `mise run plugins:check`  | compile-check every `dev/` plugin that has Lua             |
| `mise run test-sync`      | backward-compatible alias for `bin/nvim-update`            |
| `mise run verify`         | shell, core, updater, fleet, UX, and performance gates     |

Always use the explicit `mise run <task>` form. Mise ships its own top-level
`doctor` and `sync` subcommands, so a bare `mise doctor` or `mise sync` runs
Mise's command instead of this repository's task.

### Manual testing loop

Create the developer fleet once, then use the same routine update command as
an ordinary install:

```sh
mise run plugins:clone
nvim-update
```

Restart Neovim afterwards. lazy.nvim resolves account-owned plugins from the
local `dev/` checkouts when present and falls back to the tested `bluff` pins
for every missing checkout.

`plugins:pull` refuses loudly on a dirty, detached, divergent, or non-`bluff`
checkout rather than touching it. Resolve the state in that plugin's own
repository. `dev/` is gitignored and never enters a commit.

`plugins:pull` and `:DevPlugins` are the only things that move the `dev/`
fleet. lazy.nvim skips Git tasks for plugins resolved outside its own root;
conversely, the fleet commands never touch third-party plugins.

## Which lockfile a session writes

A dependency pin moves only through the documented dependency-refresh flow,
and `lazy-lock.json` stays committed. It is what makes every public install
reproducible.

lazy.nvim rewrites its lockfile after every install, update, restore, and clean
from whatever the resolved plugin directories currently hold. An editing
session cannot do that faithfully here for two reasons:

- **dev matching** resolves the account's own plugins from `dev/`, outside
  lazy's root, so lazy treats them as local and omits their committed pins;
- **the plugin root is shared.** Everything under `stdpath("data")/lazy` is one
  directory per machine, so an unrelated session may already have moved it.

An editing session therefore writes a per-machine scratch copy at
`${XDG_STATE_HOME:-$HOME/.local/state}/nvim/nvim-config/lazy-lock.local.json`.
`lua/config/lockfile.lua` gives the committed path only to a maintenance run
that has disabled dev matching. A dev-backed test remains on the scratch path
even when it sets `NVIM_TOOLCHAIN_SYNC` for tool isolation.

The practical consequence is that interactive `:Lazy update` can move
third-party plugins on disk, but it does not propose a lockfile change to
commit. The next `nvim-config sync` restores the reviewed pins. Agent Manager
is additionally release-coupled: generic updates leave its pin unchanged, and
the Lazy spec itself is pinned so an interactive update cannot bypass the
release gate. Its build hook installs only a runtime whose source revision
matches the exact released commit. Automation proposes updates, CI tests them,
and merging advances the lock.

## Version policy

`lua/config/toolchain.lua` is the source of truth:

- Neovim 0.12.2 is the minimum; 0.12.4 is the tested release.
- Node 22 is the compatibility floor.
- Node 24 is the recommended/default CI lane.
- Node 26 is the forward-looking canary lane.
- Treesitter parsers, Mason package names, and LSP server names are centralized
  so bootstrap, startup, CI, and docs cannot silently drift.

The managed parser list includes Bash, TOML, and KDL for the optional Mise
query extensions. `nvim-config sync` installs missing parsers, while
`nvim-config sync --latest` refreshes parsers and their upstream queries.

lazy.nvim dependencies use exact commits in `lazy-lock.json`. Account-owned
plugins are pinned to commits on `bluff`; third-party dependencies retain their
own upstream branch names. Mason entries intentionally have no version suffix,
so Mason resolves the latest registry release when `MasonToolsUpdateSync` runs.

## Automation

`.github/workflows/dependency-update.yml` runs weekly and can receive a
`plugin-release` repository dispatch from any account-owned plugin. The payload
names exactly one of `agent-manager.nvimz`, `git-panel.nvim`, `mcp-buff`,
`UX-chrome.nvim`, `UX-foundation.nvim`, or `UX-styling.nvim` and includes the
full tagged commit. The workflow proves that commit is reachable from the
plugin's `bluff` branch, changes only that lock entry, and records the request
in its pull-request body. Agent Manager advances only through this published
release event; weekly, generic `all`, and manual branch-head refreshes exclude
it so its Lua and packaged runtime cannot drift apart. A manual run can select
the other focused targets or refresh the remaining lazy.nvim dependencies.

The workflow opens a pull request into `bluff`. It accepts an operator-managed,
fine-grained `DEPENDENCY_UPDATE_TOKEN` repository secret with contents and
pull-request write access and otherwise falls back to `GITHUB_TOKEN`; events
created by that fallback follow GitHub's token-trigger policy.

Each plugin repository contains a notification workflow for stable published
Releases. It uses an operator-managed, fine-grained
`NVIM_CONFIG_DISPATCH_TOKEN` scoped only to this repository with Contents write
permission and sends this contract:

```sh
gh api --method POST repos/777lotto/nvim-config/dispatches \
  --raw-field event_type=plugin-release \
  --field 'client_payload[plugin]=git-panel.nvim' \
  --field "client_payload[commit]=$PLUGIN_COMMIT" \
  --field "client_payload[tag]=$PLUGIN_TAG"
```

The plugin name is the publisher's exact lazy.nvim key. The release workflow
reads the secret only at its GitHub Actions process boundary and exits with a
setup notice when it is absent. Provisioning that secret, creating signed tags,
and publishing Releases are operator work. The credential-free ZemRip broker
cannot read or write Actions secrets, create tags or Releases, or submit this
cross-repository dispatch; do not put the token in the agent plane to work
around those policy boundaries.

## MCP Buff boundary

The MCP Buff spec uses only the loopback endpoints `http://127.0.0.1:8792` for
Cloudflare and `http://127.0.0.1:8793` for GitHub. It reads their separate
`zemrip/mcp/admin-capability` and `zemrip/github/admin-capability` entries from
`pass` on the Toughbook. Each tab owns a temporary SSH forward through
`zemrip-server` for its visible review session, then terminates that exact
child. Neither broker inherits the other's endpoint, bearer, or tunnel, and
the plugin cannot reach a bridge or container address directly.

The `zemrip-server` SSH alias is the WireGuard route and is maintained outside
this repository. WireGuard is expected to remain active; the plugin does not
start, stop, or reconfigure it, and must never fall back to
`zemrip-server-lan`.
