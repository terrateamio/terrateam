; This file is intentionally a NO-OP in the public repo.
;
; code/dune ends with `(include dune.stategraph.inc)`. In the stategraph monorepo
; this file carries the stategraph-only build extension.
;
; Why an empty stub here rather than stripping the `(include ...)` line on export?
; Keeping the line valid in BOTH repos lets code/dune be shared verbatim by
; copybara: byte-identical across the two repos, with no per-repo transform to
; strip the include.
