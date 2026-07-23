val resolve_local_file : docroot:string -> uri:Uri.t -> string
(** Resolve the given URI to a local file in the given docroot.

    This decodes and normalises the Uri. It strips out .. characters so that the
    request will not escape the docroot. The returned filepath is fully
    qualified iff the given docroot is fully qualified. *)
