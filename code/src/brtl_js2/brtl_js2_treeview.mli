module Node : sig
  type ('b, 'l) t =
    | Branch of 'b
    | Leaf of 'l
end

module Expander : sig
  type 'a t

  val comp : 'a t -> 'a Brtl_js2.Comp.t
  val state : 'a t -> [ `Collapsed | `Expanded ]
  val set_state : 'a t -> [ `Collapsed | `Expanded ] -> unit
  val state_signal : 'a t -> [ `Collapsed | `Expanded ] Brtl_js2.Note.signal
  val toggle : 'a t -> unit
end

module type S = sig
  type state
  type node [@@deriving eq]
  type fetch_nodes_err

  val class' : string

  val fetch_nodes :
    state Brtl_js2.State.t ->
    node ->
    ((node, node) Node.t list, fetch_nodes_err) result Abb_js.Future.t

  val render_node : (state Expander.t * node, node) Node.t -> state Brtl_js2.Comp.t
  val render_fetch_nodes_err : node -> fetch_nodes_err -> state Brtl_js2.Comp.t
end

module Make (S : S) : sig
  val run : (S.node, S.node) Node.t list -> S.state Brtl_js2.Comp.t
end
