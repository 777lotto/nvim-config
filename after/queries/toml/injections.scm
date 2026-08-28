; extends

; Mise task scripts with an env shebang use the named interpreter.
(pair
  (bare_key) @key
  (string) @injection.content @injection.language
  (#eq? @key "run")
  (#is-mise?)
  (#match? @injection.language "^['\"]{3}\n*#!(/\\w+)+/env\\s+\\w+")
  (#gsub! @injection.language "^.*#!/.*/env%s+([^%s]+).*" "%1")
  (#offset! @injection.content 0 3 0 -3))

; Mise task scripts with a direct shebang use the interpreter basename.
(pair
  (bare_key) @key
  (string) @injection.content @injection.language
  (#eq? @key "run")
  (#is-mise?)
  (#match? @injection.language "^['\"]{3}\n*#!(/\\w+)+\\s*\n")
  (#gsub! @injection.language "^.*#!/.*/([^/%s]+).*" "%1")
  (#offset! @injection.content 0 3 0 -3))

; Multiline scripts without a shebang default to Bash.
(pair
  (bare_key) @key
  (string) @injection.content
  (#eq? @key "run")
  (#is-mise?)
  (#match? @injection.content "^['\"]{3}\n*.*")
  (#not-match? @injection.content "^['\"]{3}\n*#!")
  (#offset! @injection.content 0 3 0 -3)
  (#set! injection.language "bash"))

; Single-line scripts default to Bash.
(pair
  (bare_key) @key
  (string) @injection.content
  (#eq? @key "run")
  (#is-mise?)
  (#not-match? @injection.content "^['\"]{3}")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "bash"))
