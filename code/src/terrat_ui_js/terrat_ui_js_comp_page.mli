type page = string list

module type S = sig
  type elt
  type state

  val class' : string
  val page_param : string

  val fetch :
    ?page:page ->
    unit ->
    (elt Terrat_ui_js_client.Page.t, [> Terrat_ui_js_client.err ]) result Abb_js.Future.t

  val render_elt : state Brtl_js2.State.t -> elt -> Brtl_js2.Brr.El.t
  val equal : elt -> elt -> bool
end

module Make (S : S) : sig
  val run : page option -> S.state Brtl_js2.Comp.t
end
