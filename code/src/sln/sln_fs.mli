(** Concatenate a root path with a list of segments. [concat_many path ["dir"; "subdir"]] is
    [path/dir/subdir]. *)
val concat_many : string -> string list -> string

(** Normalize a file path by resolving [.], [..], and redundant separators. *)
val normalize_path : string -> string

(** [has_no_parent_escape path] is [true] iff [path], after {!normalize_path}, is non-absolute and
    does not begin with a [..] segment — i.e., walking the path from its first segment never steps
    upward above its starting point.

    Stronger than {!Stdlib.Filename.is_relative}: that function only rejects absolute paths, while
    this also rejects relative paths like [..] or [../a] that escape their base. Because
    {!normalize_path} is applied first, it correctly classifies paths whose escape status only
    becomes visible after [.]/[..] resolution — e.g. [a/../b] is contained (normalizes to [b]) while
    [a/../../b] escapes (normalizes to [../b]).

    Use this to decide whether a path is safe to treat as a location inside some tree (e.g. the
    reified state root) without the caller needing to know what that tree's root actually is. *)
val has_no_parent_escape : string -> bool

(** [relpath ~from ~to_] computes the relative filesystem walk from directory [from] to [to_]. Both
    arguments are normalized first via {!normalize_path}. The result walks up via [..] for each
    segment of [from] that is not shared with [to_], then down through the remaining segments of
    [to_].

    Examples:
    - [relpath ~from:"a/b" ~to_:"a/b/c/d"] = ["c/d"]
    - [relpath ~from:"a/b" ~to_:"a/c"] = ["../c"]
    - [relpath ~from:"a/b/c" ~to_:"x/y"] = ["../../../x/y"]
    - [relpath ~from:"a" ~to_:"a"] = ["."]

    Assumes both paths normalize to non-absolute, non-escaping forms. Behavior on absolute or
    escaping inputs is unspecified. *)
val relpath : from:string -> to_:string -> string

(** [mkdir_p path] creates [path] and every missing ancestor, stopping at [/], [.] or the empty
    string. An already-existing directory is not an error, so concurrent callers building
    overlapping trees (parallel tests laying down fixture directories, say) do not race each other.
*)
val mkdir_p : string -> unit

(** [write_file ~dir ~filepath content] writes [content] to [dir/filepath], creating any
    intermediate directories via {!mkdir_p}. Truncates an existing file. *)
val write_file : dir:string -> filepath:string -> string -> unit
