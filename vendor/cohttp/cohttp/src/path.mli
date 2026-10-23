val resolve_local_file : docroot:string -> uri:Uri.t -> string
(** Resolve the given URI to a local file in the given docroot.

    This is [Filename.concat docroot (normalise uri)]. It decodes
    percent-encoding once and removes [..] segments so that the request cannot
    escape the docroot. The returned filepath is fully qualified iff the given
    docroot is fully qualified. *)

val normalise : Uri.t -> string
(** [normalise uri] returns the path of [uri] with percent-encoding decoded
    exactly once and [.]/[..] segments resolved, as a relative path that can
    never ascend above its root.

    Use this to derive a lookup key from a request URI, for example a filesystem
    path or a key-value store key. *)
