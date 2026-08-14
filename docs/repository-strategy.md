# Repository strategy

## Current state

At the time of the modularization audit, GitHub's default branch is `debian`,
`MacOS` is an older ancestor, no `main` branch exists, and the repository has
no version tags. The branch difference mostly represents feature age rather
than necessary operating-system divergence.

The active environment is now Debian-only: an XFCE Debian client and a headless
Debian server. The config still uses portable Neovim APIs and automatic
clipboard selection, but macOS is historical rather than an actively tested
target. Maintaining permanent OS branches would duplicate fixes and make the
README, releases, and default installation ambiguous.

## Recommended branch model

Use one protected default branch named `main`:

```text
main
├── feature/theme-workshop
├── feature/json-support
└── fix/git-panel-rename
```

Feature and fix branches should be short-lived and merged through pull requests.
Test local XFCE use and headless Debian/SSH use from the same commit. Keep
environment differences in `lua/config/environment.lua` or `bootstrap.sh`
instead of creating permanent platform branches.

The installer now follows GitHub's default branch, so changing the default later
will not break fresh machines.

## Safe consolidation sequence

Do this only after the current modular work is committed and pushed:

1. Preserve the old Mac state with an annotated archive tag.
2. Create `main` at the tested `debian` tip and push it.
3. In GitHub Settings, change the default branch to `main`.
4. Update any rules, badges, Actions, and open pull requests that name
   `debian`.
5. Test a fresh clone locally and on a clean headless Debian environment.
6. Leave `debian` available for a short transition, then delete the stale
   `debian` and `MacOS` branches only after confirming no unique commits are
   being lost.

Example local commands for the non-destructive part:

```sh
git fetch origin
git tag -a archive/macos-before-unification origin/MacOS \
  -m "Preserve the former macOS configuration branch"
git push origin archive/macos-before-unification

git branch main origin/debian
git push -u origin main
```

Changing the GitHub default branch requires repository administration in the
web settings. GitHub documents the process in
[Changing the default branch](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/changing-the-default-branch).

Do not delete either old branch as part of the same blind operation. The archive
tag and fresh-clone tests make the cleanup recoverable and reviewable.

## Tags and releases

Use annotated tags as immutable milestones and GitHub Releases as the
human-facing page for each milestone.

A sensible first sequence is:

- `v0.1.0`: modular configuration, extracted GitPanel, JSON support, expanded
  diagnostics, and broad Prettier coverage;
- `v0.2.0`: live theme workshop or another substantial user-facing feature;
- patch releases for fixes that do not materially change configuration usage.

For a personal config, these versions are snapshots rather than a compatibility
promise. If GitPanel moves to its own repository, version that plugin
independently with semantic versions and document its minimum Neovim version.

Release checklist:

1. update `CHANGELOG.md`;
2. run the headless checks on Debian and test the XFCE-specific client path;
3. update `lazy-lock.json` intentionally;
4. create an annotated `vX.Y.Z` tag;
5. draft a GitHub Release from the tag with upgrade notes and screenshots;
6. test the release archive on a clean config directory.

GitHub Releases can attach notes and files to a tag; see
[Managing releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).

## GitHub presentation

Before the first release:

- choose and commit a license; MIT is common for a reusable config/plugin, but
  this is an owner decision;
- add a clear repository description, topics such as `neovim`, `lua`,
  `dotfiles`, `lsp`, and `treesitter`, and a social-preview image;
- add one screenshot or short recording of GitPanel and the normal editor UI;
- keep installation, requirements, language coverage, structure, and keymaps in
  the main README;
- keep architecture and maintainer workflow in `docs/`;
- use the changelog for user-visible changes;
- add issue forms for bug reports and feature requests once outside users are
  expected.

## CI and branch protection

Add a Linux GitHub Actions workflow, optionally running the configuration in a
Debian stable container, that:

1. installs the supported Neovim release;
2. checks Bash syntax for `bootstrap.sh`;
3. parses every Lua file;
4. restores locked plugins;
5. launches the config headlessly with parser/tool installation disabled;
6. optionally runs focused GitPanel tests in a temporary Git repository.

Once that workflow is stable, protect `main` with a GitHub ruleset that blocks
force pushes/deletion and requires the CI status check for pull requests.
Requiring a review is useful when there are multiple maintainers but adds little
to a one-person repository.

GitHub explains the available controls in
[About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
and [available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets).

## Extracting GitPanel

`local-plugins/git-panel.nvim/` now has the standard reusable layout. To
publish it:

1. select a license;
2. split or copy that directory into a new repository named
   `git-panel.nvim`;
3. add a minimal headless test workflow;
4. create `v0.1.0`;
5. replace this config's local `dir` spec with
   `"777lotto/git-panel.nvim"`.

Keeping it local until its public API and license are settled avoids publishing
an accidental compatibility promise.
