# Troubleshooting

## “Did not detect DSR response from terminal”

This warning comes from Neovim's built-in terminal capability detection, not
from the file being opened and not from JSON support. During startup Neovim asks
the terminal for its background color and sends a Device Status Report query as
a synchronization marker. If the terminal does not return that marker within
100 milliseconds, Neovim continues and reports that startup was slower.

If it appears only when a file is opened from Thunar, compare these two paths:

```sh
nvim path/to/file.json
konsole -e nvim path/to/file.json
```

The second form is the appropriate shape for a Thunar custom action when
Konsole is the terminal. Avoid launchers that pipe Neovim through a non-terminal
process or allocate an incomplete pseudo-terminal. If the warning also appears
from an ordinary terminal, test without tmux/screen and check that `$TERM` was
not overwritten by shell startup files.

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

## Clipboard over SSH

OSC 52 supports copying from the remote Neovim process into the local terminal.
Konsole blocks clipboard reads, so paste with the terminal's normal shortcut
instead of expecting `"+p` to read the local clipboard over SSH.
