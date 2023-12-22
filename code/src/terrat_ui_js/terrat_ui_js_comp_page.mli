module type S = sig
  type elt
  type state
  type query

  val class' : string
  val query : query Brtl_js2_rtng.Route.t
  val make_uri : query -> Uri.t -> Uri.t
  val set_page : string list option -> query -> query

  val fetch :
    query -> (elt Terrat_ui_js_client.Page.t, [> Terrat_ui_js_client.err ]) result Abb_js.Future.t

  val wrap_page : Brtl_js2.Brr.El.t list -> Brtl_js2.Brr.El.t list
  val render_elt : state Brtl_js2.State.t -> elt -> Brtl_js2.Brr.El.t list
  val query_comp : (query Brtl_js2.Note.S.set -> state Brtl_js2.Comp.t) option
  val equal_elt : elt -> elt -> bool
  val equal_query : query -> query -> bool
end

module Make (S : S) : sig
  val run : S.state Brtl_js2.Comp.t
end
