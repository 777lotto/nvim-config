# Repository strategy

## Branch model

All repositories owned by `777lotto` use `bluff` as their GitHub default and
only long-lived branch:

```text
bluff                      default, integration, and release source
├── feature/...
├── fix/...
└── agent/...
```

Short-lived branches start from `bluff` and return through pull requests. A
tested release is a signed tag from `bluff`; there is no promotion branch or
promotion-only CI gate.

Operating systems are not represented by branches. Keep environment-dependent
behavior in `lua/config/environment.lua` or `bootstrap.sh`, classify work with
`platform:*` labels, and test supported combinations in GitHub Actions.

## Historical branch migration

The former `MacOS` branch is an ancestor of the old `debian` branch and has no
unique commits. Its state is preserved by the signed annotated tag
`archive/macos-before-unification`. The later two-branch production/integration
model was retired in September 2026 when `bluff` became the account-wide
default. Those names may remain in historical changelog entries, tags, or Git
history, but current tooling and guidance use only `bluff`.

## Pull-request flow

1. update local `bluff`;
2. create a focused branch;
3. retain explicit commit provenance (signed human commits or the expected
   unsigned brokered-agent identity);
4. open a pull request into `bluff`;
5. require CI before merge.

## Tags and releases

Use signed annotated tags as immutable milestones and GitHub Releases as their
human-facing descriptions.

- `nvim-config` v0.1.0 records the GitHub foundation and published GitPanel
  integration.
- `git-panel.nvim` is versioned independently and began at `v0.1.0`.
- Patch releases contain compatible fixes; minor releases represent meaningful
  user-facing additions.

Release checklist:

1. update `CHANGELOG.md`;
2. run CI and test the XFCE path on the actual client;
3. review `lazy-lock.json` intentionally;
4. have the operator create and push a signed `vX.Y.Z` tag from `bluff`;
5. have the operator publish GitHub release notes, then test a clean
   archive/bootstrap.

## GitHub presentation

The repository landing page should contain:

- a precise description and relevant discovery topics;
- CI, Neovim-version, release, and license badges;
- a support matrix that distinguishes Debian desktop, Debian SSH, and
  experimental macOS behavior;
- structured issue forms and a pull-request checklist;
- an MIT license, contribution guide, security policy, and code of conduct;
- a screenshot or social-preview card showing the editor and GitPanel.

Keep user installation and feature documentation in `README.md`, architecture
and maintainer policy in `docs/`, and user-visible changes in `CHANGELOG.md`.

## CI and repository rules

The baseline workflow has these stable checks:

- `quality`: Bash syntax, ShellCheck, and whitespace validation;
- `debian-smoke`: pinned Neovim, Lua compilation, local clipboard policy, and
  simulated SSH/OSC 52 policy inside Debian 13;
- `toolchain`: latest Node-backed tools on Node 22 (floor), Node 24
  (recommended), and Node 26 (canary), plus centralized-manifest validation;
- `bootstrap`: the real installer in isolated XDG directories on Node 24.

The `bluff` ruleset should block deletion and force pushes and require CI for
pull requests. Human commits and tags retain verified signatures; brokered
agent commits are intentionally unsigned and identified as `zemrip-ai`.
GitHub Environments are reserved for actual deployment or release secrets; they
are not used to classify operating systems.

### ZemRip broker boundary

The credential-free agent plane is narrower than the public repository model:

- Git pushes may update only `agent/**`; `bluff` and tag writes are refused.
- A push containing `.github/workflows/**` needs one operator-approved ticket
  for the exact repository and ref set. The approval unlocks one later push;
  it does not execute the push.
- Pull requests target `bluff`. Merge behavior comes from the broker's current
  exact-head automerge/approval configuration, not from an assumed production
  branch or from GitHub's repository rules alone.
- The API route cannot create Releases, dispatch workflows, or administer
  settings and Actions secrets. Those are explicit operator actions.
- `gh-agent` addresses the repository selected with `-R`, its reviewed
  environment setting, or the current checkout's broker remote. It must never
  silently fall back to `zemRip` merely because no repository was named.

## GitHub Project

The public account-level **Neovim Workspace** Project is the cross-repository
planning surface for `nvim-config` and its plugins. Repositories and labels
remain the source of truth for ownership, platform, type, and area. Project
fields add only planning state such as Status, Priority, Size, and Target date.

Recommended views are an all-work status board, repository-filtered boards,
Debian/macOS label views, and a release roadmap.

## Dev plane

Plugins stay independent repositories with their own history, CI, releases,
and exact commits in this repository's `lazy-lock.json`. Every account-owned
plugin spec explicitly targets `bluff`, so an ordinary install receives the
same default branch as the account repositories.

`dev/` is gitignored on-disk organization for a maintainer who wants to run the
config and its plugins from working checkouts at the same time. lazy.nvim looks
there for plugins owned by `777lotto` during normal editing sessions:

```lua
dev = {
  path = vim.env.NVIM_DEV_DIR
    or (vim.env.NVIM_CONFIG_ROOT or vim.fn.stdpath("config")) .. "/dev",
  patterns = use_dev and { "777lotto" } or {},
  fallback = true,
}
```

`fallback = true` is the public-install guarantee: a machine with no `dev/`
directory, or one missing a particular plugin checkout, resolves that plugin
from its tested `bluff` pin. No channel setting or persisted branch-state file
is involved.

Each entry may be a real clone or a symlink to a canonical checkout:

```text
dev/
├── agent-manager.nvimz -> ../../agent-manager
├── git-panel.nvim      -> ../../git-panel
├── mcp-buff            -> ../../mcp-buff
├── UX-foundation.nvim  -> ../../ux-foundation
├── UX-styling.nvim     -> ../../ux-styling
└── UX-chrome.nvim      -> ../../ux-chrome
```

Directory names are lazy.nvim plugin names and are case-sensitive. Only
repositories consumed by nvim-config belong to this fleet.
`scripts/dev-plugins.sh` clones from `$NVIM_DEV_GIT_BASE`, defaulting to
`https://github.com/777lotto`, and always uses `bluff`. It refuses dirty,
detached, divergent, or differently branched checkouts instead of switching or
rewriting them.

Dev matching is deliberately off during maintenance. lazy.nvim treats a
plugin resolved outside its own root as local and omits local plugins from the
lockfile it writes, so a `nvim-config sync` on a machine with `dev/` populated
would otherwise delete those plugins' committed pins. Every
`bin/nvim-config` run and the dependency-refresh workflow set
`NVIM_TOOLCHAIN_SYNC`; `lua/config/lazy.lua` then resolves the GitHub pins and
rewrites `lazy-lock.json` faithfully.

An editing session keeps dev matching and is denied the committed lockfile
instead—see "Which lockfile a session writes" in
[maintenance](maintenance.md). That is also why `:Lazy update` cannot move this
fleet: lazy skips every Git task for a plugin outside its root. `:DevPlugins`
and `mise run plugins:pull` are the commands that fast-forward it on `bluff`.

## Published plugins

[GitPanel](https://github.com/777lotto/git-panel.nvim),
[MCP Buff](https://github.com/777lotto/mcp-buff),
[Agent Manager](https://github.com/777lotto/agent-manager.nvimz), and the UX
repositories are independent public projects whose default branch is `bluff`.
This repository owns their lazy.nvim specs, tested lock pins, key mappings, and
complete-editor compatibility checks; each plugin repository owns its own
implementation, issues, tests, documentation, and releases.

MCP Buff's endpoint remains loopback only. Agent Manager remains responsible
for its Rust broker, Python worker, Lua workspace, provider safety boundary,
and build artifacts.
