(** Byte-level preprocessing that brings Menhir's UTF-8 verdict in line with HCP's, without
    corrupting string contents.

    HCP's Ragel scanner matches comment bodies byte-by-byte (so invalid UTF-8 is silently consumed
    inside [#], [//], and [/* ... */]) but emits [TokenBadUTF8] — and therefore rejects the input —
    for broken UTF-8 in strings, heredocs, and identifiers. Sedlex is codepoint-based and would
    raise [Sedlexing.MalFormed] on the first invalid byte regardless of context. *)

(** [sanitize s] returns a copy of [s] in which each invalid UTF-8 byte appearing inside a line or
    block comment is replaced with ['?'], and every other byte is preserved verbatim. Byte offsets
    are preserved 1:1 so error positions remain accurate.

    Leaving bytes untouched outside comments means sedlex still fails on invalid UTF-8 in string
    literals, heredocs, and code. We want that, because we cannot be lenient and transform data in
    these positions (as opposed to within comments, where we can rewrite invalid UTF8 to accept it,
    and be lenient, like HCP's parser is). *)
val sanitize : string -> string
