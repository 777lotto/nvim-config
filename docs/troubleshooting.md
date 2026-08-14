# Troubleshooting

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
For Java Card SSH authentication, its `SSH_AUTH_SOCK` must match:

```sh
gpgconf --list-dirs agent-ssh-socket
```

The expected socket resolves below `$XDG_RUNTIME_DIR/gnupg`, not `/tmp/ssh-*`.
The session-wide setting lives in
`~/.config/environment.d/99-ssh-agent.conf`:

```ini
SSH_AUTH_SOCK=${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh
```

After changing that file, log out of XFCE completely and log back in. Existing
Thunar, terminal, and Neovim processes retain their old environment until they
are restarted. Do not solve this only in the Neovim launcher: Git in every
graphical application should use the same Java Card agent.

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

## Clipboard on the XFCE client and over SSH

The default `NVIM_CLIPBOARD=auto` policy has two paths:

- Locally on the Debian XFCE/X11 client, Neovim selects its native clipboard
  provider. This machine has `xclip` installed.
- On the future headless Debian server, `SSH_TTY` or `SSH_CONNECTION` selects
  copy-only OSC 52 so yanks can reach the clipboard owned by Xfce Terminal on
  the client.

The remote path is configured but has not yet been validated end-to-end because
Neovim is not installed on the server. After deployment, test without tmux
first:

1. Run `:EnvironmentInfo` remotely and confirm `Clipboard policy: osc52`.
2. Yank a short line in Neovim; `unnamedplus` should send it through OSC 52.
3. Paste into a local XFCE application and confirm the exact text arrived.
4. Test again through tmux only after the direct SSH path works, because a
   multiplexer may require OSC 52 passthrough configuration.

OSC 52 clipboard reads are intentionally disabled because terminal support
varies and remote clipboard reads have security implications. Paste into remote
Neovim using Xfce Terminal's normal paste action; `"+p` is intentionally not a
remote clipboard-read mechanism. This follows Neovim's
[OSC 52 provider guidance](https://neovim.io/doc/user/provider.html#clipboard-osc52).

For an unusual machine or forwarded clipboard setup, override detection for one
launch with `NVIM_CLIPBOARD=native nvim` or `NVIM_CLIPBOARD=osc52 nvim`.
