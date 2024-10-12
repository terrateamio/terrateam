module Page : sig
  type 'a t [@@deriving eq, show]

  val make : ?next:string list -> ?prev:string list -> 'a list -> 'a t
  val page : 'a t -> 'a list
  val next : 'a t -> string list option
  val prev : 'a t -> string list option
end

module type S = sig
  type fetch_err
  type elt [@@deriving eq, show]
  type state
  type query

  val class' : string
  val query : query Brtl_js2_rtng.Route.t
  val make_uri : query -> Uri.t -> Uri.t
  val set_page : string list option -> query -> query
  val fetch : query -> (elt Page.t, fetch_err) result Abb_js.Future.t
  val wrap_page : Brtl_js2.Brr.El.t list -> Brtl_js2.Brr.El.t list
  val render_elt : state Brtl_js2.State.t -> elt -> Brtl_js2.Brr.El.t list

  val query_comp :
    (query Brtl_js2.Note.S.set -> fetch_err option Brtl_js2.Note.E.t -> state Brtl_js2.Comp.t)
    option

  val equal_elt : elt -> elt -> bool
  val equal_query : query -> query -> bool
  val pp_fetch_err : Ppx_deriving_runtime.Format.formatter -> fetch_err -> Ppx_deriving_runtime.unit
  val show_fetch_err : fetch_err -> Ppx_deriving_runtime.string
end

module Make (S : S) : sig
  val run : S.state Brtl_js2.Comp.t
end
