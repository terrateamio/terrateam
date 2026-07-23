(** URI helpers shared by the framework and its endpoints. *)

(** [merge_base ~base uri] is the absolute URI for [uri]'s path and query, rooted at [base]. The two
    paths are joined with exactly ONE separator, whatever either side supplies: [base] routinely
    carries a bare ["/"] path ({!Brtl_ctx.uri_base} defaults to it) while a request [uri]'s path is
    absolute, so concatenating them raw yields ["//api/v1/…"] — which servers 404. The query is
    taken from [uri]; any query on [base] is dropped. *)
val merge_base : base:Uri.t -> Uri.t -> Uri.t
