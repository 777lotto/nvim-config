# Contributing

Thanks for helping improve this Neovim configuration. Issues and pull requests
should describe the user-facing problem first, then the proposed change.

## Branch model

- `bet` is the production/default branch.
- `bluff` is the persistent integration branch.
- Short-lived work branches start from `bluff` and merge back into `bluff`.
- A promotion pull request moves tested changes from `bluff` into `bet`.

Do not target `bet` directly for ordinary changes.

## Development workflow

1. Fetch the latest branches and create a focused branch from `bluff`.
2. Keep platform-specific policy in `lua/config/environment.lua` or
   `bootstrap.sh`, not in permanent operating-system branches.
3. Update documentation and `CHANGELOG.md` when behavior changes.
4. Treat `lazy-lock.json` changes as intentional dependency updates.
5. Run the local checks:

   ```sh
   bash -n bootstrap.sh bin/nvim-config
   nvim --headless --clean -l scripts/ci/check-lua.lua .
   nvim --headless --clean -l scripts/toolchain.lua . validate
   nvim --headless --clean -l scripts/ci/smoke-core.lua . native
   SSH_TTY=/dev/pts/0 nvim --headless --clean \
     -l scripts/ci/smoke-core.lua . osc52
   # Run on the recommended Node release from a committed checkout:
   bash scripts/ci/test-update.sh
   ```

6. Sign human commits using a GitHub-verified GPG, SSH, or S/MIME signature.
   Approved dependency-refresh automation may use its GitHub bot identity.
7. Open a pull request into `bluff` and complete the pull-request checklist.

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
