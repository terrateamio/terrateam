(** Flatten a multi-file JSON schema document into a single self-contained one.

    Foreign references of the form ["<path>#/definitions/<Name>"] are resolved against [search_path]
    (and the referencing file's directory). By default the referenced definition is inlined into the
    document's ["definitions"] and the ref rewritten to an internal ["#/definitions/<canonical>"]
    (the canonical name is namespaced by the foreign file's stem). Files named in [file_link]
    (matched by basename) are instead referenced via ["#/file-link/<MODULE_BASE>/<Name>"] and are
    neither loaded nor inlined. Internal ["#/..."] refs are left untouched.

    Transitive foreign refs are flattened recursively; cycles are broken by reusing the canonical
    name of an already-visited definition.

    Raises [Failure] if a foreign file cannot be located, a referenced definition is missing, or a
    foreign ref uses an unsupported pointer (only ["#/definitions/<Name>"] is supported). *)
val flatten_document :
  search_path:string list ->
  file_link:(string * string) list ->
  root_file:string ->
  Yojson.Safe.t ->
  Yojson.Safe.t
