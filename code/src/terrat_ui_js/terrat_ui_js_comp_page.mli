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

  (* After rendering each element, optionally wrap the page.  For example, a
     header or footer. *)
  val wrap_page : Brtl_js2.Brr.El.t list -> Brtl_js2.Brr.El.t list
  val render_elt : state Brtl_js2.State.t -> elt -> Brtl_js2.Brr.El.t list
  val equal : elt -> elt -> bool
end

module Make (S : S) : sig
  val run : S.state Brtl_js2.Comp.t
end
