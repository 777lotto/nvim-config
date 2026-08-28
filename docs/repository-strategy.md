# Repository strategy

## Branch model

All repositories owned by `777lotto` use the same persistent branches:

```text
bet                         production and GitHub default
└── bluff                   working integration / staging
    ├── feature/...
    ├── fix/...
    └── agent/...
```

Short-lived branches start from `bluff` and return through pull requests.
Tested batches are promoted through a `bluff` → `bet` pull request. Direct
feature pull requests into `bet` are rejected by the promotion-source CI check.

Operating systems are not represented by branches. Keep environment-dependent
behavior in `lua/config/environment.lua` or `bootstrap.sh`, classify work with
`platform:*` labels, and test supported combinations in GitHub Actions.

## Historical branch migration

The former `MacOS` branch is an ancestor of the old `debian` branch and has no
unique commits. Its state is preserved by the signed annotated tag
`archive/macos-before-unification`. `bet` and `bluff` were created at the tested
`debian` tip; the old branches remain temporarily available for rollback.

Do not delete historical branches until fresh production and integration clones
have been exercised on the real desktop and headless machines.

## Pull-request flow

Ordinary work:

1. update local `bluff`;
2. create a focused branch;
3. commit with verified signatures;
4. open a pull request into `bluff`;
5. require CI before merge.

Production promotion:

1. confirm `bluff` is green;
2. update `CHANGELOG.md` when the batch is release-worthy;
3. open a `bluff` → `bet` pull request;
4. require the promotion-source and CI checks;
5. merge without deleting the persistent `bluff` branch.

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
4. promote `bluff` into `bet`;
5. create and push a signed `vX.Y.Z` tag from `bet`;
6. publish GitHub release notes and test a clean archive/bootstrap.

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

The `bet` ruleset should block deletion and force pushes, require verified
signatures, require pull requests, and require the CI checks plus a successful
promotion-source check. The `bluff` ruleset should block deletion and force
pushes and require verified signatures and CI for pull requests.

No approving review is required while the project has one maintainer. GitHub
Environments are reserved for actual deployment or release secrets; they are
not used to classify operating systems.

## GitHub Project

The public account-level **Neovim Workspace** Project is the cross-repository
planning surface for `nvim-config` and `git-panel.nvim`. Repository and labels
remain the source of truth for ownership, platform, type, and area. Project
fields add only planning state such as Status, Priority, Size, and Target date.

Recommended views are an all-work status board, repository-filtered Config and
GitPanel boards, Debian/macOS label views, and a release roadmap.

## Dev plane

Plugins stay independent repositories: their own history, CI, releases, and a
resolved commit in this repository's `lazy-lock.json`. Nothing below changes
that. `dev/` is on-disk organization for a maintainer who wants to run the
config and its plugins from working checkouts at the same time.

`dev/` is a gitignored directory at the repository root. lazy.nvim's dev mode
is configured in `lua/config/lazy.lua` to look there for any plugin whose spec
matches `777lotto`:

```lua
dev = {
  path = (vim.env.NVIM_CONFIG_ROOT or vim.fn.stdpath("config")) .. "/dev",
  patterns = { "777lotto" },
  fallback = true,
}
```

`fallback = true` is the guarantee that matters for everyone else: a machine
with no `dev/` directory, or one missing a particular plugin, resolves that
plugin from its `lazy-lock.json` pin exactly as before. Dev mode is opt-in by
the presence of a directory, never by configuration a user has to undo.

Each entry may be a real clone or a symlink to a canonical one. A standalone
machine runs `mise run plugins:clone` and gets real clones on `bluff`. A
workstation that already keeps canonical clones elsewhere symlinks them in, so
one checkout serves both the coordination clone and the editor:

```text
dev/
├── git-panel.nvim      -> ../../git-panel.nvim
├── mcp-buff            -> ../../mcp-buff
├── UX-foundation.nvim  -> ../../ux-foundation.nvim
├── UX-styling.nvim     -> ../../ux-styling.nvim
├── UX-chrome.nvim      -> ../../ux-chrome.nvim
└── agent-manager.nvimz -> ../../agent-manager.nvimz
```

Directory names are the lazy.nvim plugin names and are case-sensitive, so they
must match the repository names exactly even when the symlink target is
lowercase. `scripts/dev-plugins.sh` treats an existing directory *or* symlink
as present, which is what lets both layouts coexist.

`scripts/dev-plugins.sh` clones from `$NVIM_DEV_GIT_BASE`, defaulting to
`https://github.com/777lotto`. A machine that reaches GitHub through a broker
or mirror sets that variable instead of editing the script.

Dev mode is deliberately off during maintenance. lazy.nvim treats a plugin
resolved outside its own root as local and omits local plugins from the
lockfile it writes, so a `nvim-config sync` on a machine with `dev/` populated
would delete exactly those plugins' committed pins. Every `bin/nvim-config` run
and the dependency-refresh workflow already set `NVIM_TOOLCHAIN_SYNC`, and
`lua/config/lazy.lua` disables dev matching when it is set: maintenance
resolves those plugins from their pins and rewrites `lazy-lock.json`
faithfully, exactly as it does on a machine with no `dev/` at all.

## Published plugins

[git-panel.nvim](https://github.com/777lotto/git-panel.nvim) is an independent
public repository with preserved subdirectory history, its own `bet` and
`bluff` branches, tests, CI, community files, and signed releases. This config
consumes `"777lotto/git-panel.nvim"` as a normal lazy.nvim dependency and keeps
the resolved commit in `lazy-lock.json`.

Plugin implementation, issues, releases, and user documentation belong in the
plugin repository. This repository owns only the lazy.nvim integration, key
mappings, and compatibility validation for the complete editor configuration.
Both repositories share the Neovim Workspace Project for cross-repository
planning.

[MCP Buff](https://github.com/777lotto/mcp-buff) follows the same production
`bet` and integration `bluff` model. This config consumes its `bet` branch and
keeps its resolved commit in `lazy-lock.json`; its endpoint remains loopback
only. Plugin release workflows may dispatch a focused dependency refresh here,
but the resulting lock change still enters through `bluff` and the normal
production promotion.
