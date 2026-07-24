(** Raised by {!split} at the byte offset where decoding failed. *)
exception Malformed_utf8 of int

(** [split ~max_bytes s] cuts [s] into consecutive fragments of at most [max_bytes] bytes each,
    never cutting in the middle of a UTF-8 codepoint.

    Concatenating the result in order reproduces [s] exactly. Fragments are therefore *uneven*: a
    fragment is short whenever the next codepoint would not fit under the bound, since the cut is
    made before that codepoint rather than through it. Callers must reassemble by concatenation in
    order and must never compute a byte offset from a fragment index.

    An empty [s] yields a single empty fragment rather than the empty list, so a value stored one
    fragment per row always has at least one row to find.

    [max_bytes] below {b 4} (the widest UTF-8 codepoint) is raised to 4. Any smaller bound could
    leave a codepoint with nowhere to land.

    {b [s] must be valid UTF-8.} It is decoded, not merely scanned, and invalid input raises
    {!Malformed_utf8} carrying the byte offset at which decoding failed. Raising rather than
    returning a result keeps the common case -- a caller that already holds text -- free of error
    plumbing; handing this function arbitrary binary is a mistake at the call site, not a runtime
    condition to recover from. A caller holding bytes not known to be text is responsible for
    getting them to text first, for instance by base64-encoding them ({!Sln_base64}) before they
    ever reach here. This matters most for a caller storing fragments into a PostgreSQL [jsonb]
    column, which rejects invalid UTF-8 outright rather than storing it: the exception names the
    offending offset, where the store error further downstream would not.

    Examples:
    - [split ~max_bytes:4 "abcdefgh"] = [["abcd"; "efgh"]]
    - [split ~max_bytes:8 "abc"] = [["abc"]]
    - [split ~max_bytes:4 ""] = [[""]]
    - [split ~max_bytes:4 "aé"] = [["aé"]] (3 bytes, so it fits in a single fragment)
    - [split ~max_bytes:4 "ééé"] = [["éé"; "é"]] (6 bytes; the cut falls before the third ["é"]
      rather than through it, so the first fragment is 4 bytes and not 5) *)
val split : max_bytes:int -> string -> string list
