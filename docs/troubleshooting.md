# Troubleshooting

## Configuration update is refused

Run `nvim-config doctor` first. `nvim-update` deliberately stops when the
config or selected plugin fleet has uncommitted/untracked files, is detached,
is missing the selected remote branch, or has diverged from it. It will switch
only to the explicitly persisted channel; it will not stash, reset, rewrite
remote URLs, or modify SSH/network configuration on your behalf.

For ordinary public installs, use `nvim-update channel bet`; this workstation's
nightly soak uses `nvim-update channel bluff`. Preserve any local edits on a
separate branch and retry after every affected worktree is clean.
If the branch has diverged, inspect it with GitPanel or standard Git commands
and reconcile it explicitly rather than forcing the updater through the state.

## Node is below the supported floor

The current floor is Node 22 and the recommended release line is Node 24. The
repository's `.nvmrc` selects the recommended major without freezing an aging
patch release:

```sh
nvm install
nvm use
nvim-config doctor
```

Other version managers can select Node 24 directly. The config does not install
or replace the system Node runtime automatically. Once the runtime passes the
doctor, `nvim-config sync --latest` refreshes the unpinned Mason tools and
Treesitter parsers; plugin commits remain controlled by `lazy-lock.json`.

## XFCE and Thunar launch behavior

The supported desktop is XFCE on Debian. Thunar should launch Neovim in Xfce
Terminal; no KDE or Konsole component is required. A desktop entry can use
`Terminal=true` with `Exec=nvim %F` (or an absolute Neovim path when the
graphical session's `PATH` does not include it), allowing XFCE to select its
preferred terminal.

For a direct comparison, run Neovim in the current terminal and then ask Xfce
Terminal to create a separate process:

```sh
nvim path/to/project
xfce4-terminal --disable-server --execute nvim path/to/project
```

`--execute` passes the remainder of the command line to the terminal. See the
[Xfce Terminal command-line documentation](https://docs.xfce.org/apps/xfce4-terminal/command-line)
for the complete launcher syntax.

Thunar and `.desktop` launchers inherit the graphical login environment; they
do not source interactive `.bashrc` setup before starting Neovim. Run
`:EnvironmentInfo` inside Neovim to inspect what the process actually received.
For Java Card SSH authentication, the desired `SSH_AUTH_SOCK` is reported by:

```sh
gpgconf --list-dirs agent-ssh-socket
```

The expected socket resolves below `$XDG_RUNTIME_DIR/gnupg`, not `/tmp/ssh-*`.
When `gpgconf` is available, this configuration sets Neovim's environment to
that socket before starting child Git, SSH, or terminal processes. The
session-wide setting for every graphical application lives in
`~/.config/environment.d/99-ssh-agent.conf`:

```ini
SSH_AUTH_SOCK=${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh
```

After changing that file, log out of XFCE completely and log back in. Existing
Thunar and terminal processes retain their old environment until they are
restarted. The Neovim safeguard fixes its child processes, but it does not
change sibling graphical applications; Git in those applications should use
the same Java Card agent.

## “Did not detect DSR response from terminal”

This warning comes from Neovim's built-in terminal capability detection, not
from the file being opened and not from JSON support. During startup Neovim asks
the terminal for its background color and sends a Device Status Report query as
a synchronization marker. If the terminal does not return that marker within
100 milliseconds, Neovim continues and reports that startup was slower.

If it appears only when a file is opened from Thunar, compare the direct and
`xfce4-terminal --disable-server --execute` launch paths above. Avoid launchers
that pipe Neovim through a non-terminal process or allocate an incomplete
pseudo-terminal. If the warning also appears from an ordinary terminal, test
without tmux/screen and check that `$TERM` was not overwritten by shell startup
files.

The warning is harmless to the JSON file and editing can continue normally.

## JSON LSP does not attach

Open a JSON or JSONC file and run:

```vim
:set filetype?
:LspInfo
:Mason
```

The filetype should be `json` or `jsonc`, `jsonls` should be attached, and
Mason's `json-lsp` package should be installed. Run `:MasonInstall json-lsp` if
the bootstrap process was interrupted.

## Formatting does not run

Run `:ConformInfo`. For a Prettier-supported file, it should show either the
project-local Prettier binary or Mason's fallback. Plain text, Lua, Python, C,
and XML are intentionally not assigned to Prettier.

## Mise embedded highlighting does not appear

Run `:set filetype?` and `:Inspect`. Mise TOML should use the `toml` filetype,
and Bash file tasks should use `sh`. If Neovim reports a missing Bash, TOML, or
KDL parser, run `nvim-config sync`; use `nvim-config sync --latest` when the
installed parser or its upstream queries are stale.

The `run` injection is intentionally restricted to Mise's default config names,
environment/local variants, grouped `mise` / `.mise` config paths, and their
non-hidden `conf.d` TOML fragments. A generic `config.toml` or `settings.toml`
with a `run` key is not a Mise config and stays plain TOML. The `mise`
executable is optional and is not a `nvim-config doctor` check.

## Clipboard on the XFCE client and over SSH

The default `NVIM_CLIPBOARD=auto` policy has two paths:

- Locally on the Debian XFCE/X11 client, Neovim selects its native clipboard
  provider. This machine has `xclip` installed.
- Over `ssh ai` or `ssh zem`, `SSH_TTY` or `SSH_CONNECTION` selects the
  copy-only Toughbook bridge when `~/.local/bin/toughbook-copy` is installed.
  The SSH reverse forward carries yanks to the Xfce clipboard without exposing
  clipboard reads to the remote host. OSC 52 remains the portable fallback.

Test the remote path without tmux first:

1. Run `:EnvironmentInfo` remotely and confirm `Clipboard policy: bridge`.
2. Yank a short line in Neovim; `unnamedplus` should invoke
   `~/.local/bin/toughbook-copy`.
3. Paste into a local XFCE application and confirm the exact text arrived.
4. Test again through tmux; tmux copy mode and Neovim use the same bridge.

Remote clipboard reads are intentionally disabled because they expose local
clipboard contents to remote programs. Paste into remote Neovim using Xfce
Terminal's normal paste action; `"+p` is intentionally not a remote
clipboard-read mechanism. The OSC 52 fallback follows Neovim's
[OSC 52 provider guidance](https://neovim.io/doc/user/provider.html#clipboard-osc52).

For an unusual machine or forwarded clipboard setup, override detection for one
launch with `NVIM_CLIPBOARD=native nvim`, `NVIM_CLIPBOARD=bridge nvim`, or
`NVIM_CLIPBOARD=osc52 nvim`.
