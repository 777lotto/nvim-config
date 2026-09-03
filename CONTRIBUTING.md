# Contributing

Thanks for helping improve this Neovim configuration. Issues and pull requests
should describe the user-facing problem first, then the proposed change.

## Branch model

- `bluff` is the default and only long-lived branch.
- Short-lived work branches start from `bluff` and merge back into `bluff`.
- Releases are signed tags from a tested `bluff` commit.

## Development workflow

1. Fetch the latest `bluff` and create a focused branch from it.
2. Keep platform-specific policy in `lua/config/environment.lua` or
   `bootstrap.sh`, not in permanent operating-system branches.
3. Update documentation and `CHANGELOG.md` when behavior changes.
4. Treat `lazy-lock.json` changes as intentional dependency updates.
5. Run the local checks:

   ```sh
   bash -n bootstrap.sh bin/nvim-config bin/nvim-update scripts/ci/*.sh
   shellcheck bootstrap.sh bin/nvim-config bin/nvim-update scripts/ci/*.sh
   nvim --headless --clean -l scripts/ci/check-lua.lua .
   nvim --headless --clean -l scripts/toolchain.lua . validate
   nvim --headless --clean -l scripts/ci/smoke-core.lua . native
   SSH_TTY=/dev/pts/0 nvim --headless --clean \
     -l scripts/ci/smoke-core.lua . osc52
   # Run on the recommended Node release from a committed checkout:
   bash scripts/ci/test-update.sh
   git diff --check
   ```

   The updater integration command also runs the focused Mise query/range tests
   with isolated Bash, TOML, and KDL parsers and a Mise-free startup smoke test.

6. Sign human commits using a GitHub-verified GPG, SSH, or S/MIME signature.
   Approved dependency-refresh automation may use its GitHub bot identity;
   brokered `zemrip-ai` commits use the expected unsigned agent identity.
7. Open a pull request into `bluff` and complete the pull-request checklist.

On the ZemRip agent plane, use an `agent/**` branch. The broker refuses direct
pushes to `bluff` and tags; a workflow-file push additionally requires an
operator-approved one-use ticket. It cannot publish Releases or administer
repository settings or secrets, which remain operator actions.

## Pull requests

Keep changes reviewable and avoid combining unrelated configuration, plugin,
and dependency updates. UI changes benefit from a screenshot or short capture.
Bug fixes should include a reproducible failure mode or a regression check when
practical.

Runtime/tool changes must preserve the Node 22 compatibility floor and pass
the recommended Node 24 and canary Node 26 lanes. Do not hand-edit plugin
commits merely to float them: use the dependency-refresh workflow or
`:Lazy update`, review the resulting `lazy-lock.json`, and let CI establish the
new latest-tested baseline.

Use [Discussions](https://github.com/777lotto/nvim-config/discussions) for
questions, setup showcases, and exploratory ideas. Open an Issue when the work
is reproducible and actionable. Cross-repository work is planned in the public
[Neovim Workspace](https://github.com/users/777lotto/projects/5).

The project currently supports Debian desktop and headless SSH use. macOS work
is welcome, but should be labelled experimental until it has a green CI job and
documented installation path.
