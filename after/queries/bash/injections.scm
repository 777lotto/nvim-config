; extends

; Mise file-task metadata is TOML. Include the newline so adjacent directives
; remain valid source ranges when Neovim builds the injected language tree.
((comment) @injection.content
  (#lua-match? @injection.content "^#MISE ")
  (#offset! @injection.content 0 6 0 1)
  (#set! injection.language "toml"))

((comment) @injection.content
  (#lua-match? @injection.content "^#%[MISE%] ")
  (#offset! @injection.content 0 8 0 1)
  (#set! injection.language "toml"))

((comment) @injection.content
  (#lua-match? @injection.content "^# %[MISE%] ")
  (#offset! @injection.content 0 9 0 1)
  (#set! injection.language "toml"))

; Neovim 0.12 can parse consecutive USAGE directives as one KDL region by
; capturing multiple comment nodes in a single match. This avoids the older
; injection.combined workaround and its cross-block limitations.
((comment)+ @injection.content
  (#lua-match? @injection.content "^#USAGE ")
  (#offset! @injection.content 0 7 0 1)
  (#set! injection.language "kdl"))

((comment)+ @injection.content
  (#lua-match? @injection.content "^#%[USAGE%] ")
  (#offset! @injection.content 0 9 0 1)
  (#set! injection.language "kdl"))

((comment)+ @injection.content
  (#lua-match? @injection.content "^# %[USAGE%] ")
  (#offset! @injection.content 0 10 0 1)
  (#set! injection.language "kdl"))
