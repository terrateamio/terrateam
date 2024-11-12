module At = Brtl_js2.Brr.At

module Node = struct
  type ('b, 'l) t =
    | Branch of 'b
    | Leaf of 'l
end

module Expander = struct
  type 'a t = {
    comp : 'a Brtl_js2.Comp.t;
    state : [ `Collapsed | `Expanded ] Brtl_js2.Note.signal;
    set_state : [ `Collapsed | `Expanded ] -> unit;
  }

  let comp t = t.comp
  let state t = Brtl_js2.Note.S.value t.state
  let set_state t = t.set_state
  let state_signal t = t.state

  let toggle t =
    match state t with
    | `Collapsed -> set_state t `Expanded
    | `Expanded -> set_state t `Collapsed
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

module Make (S : S) = struct
  let rec run nodes state =
    Abb_js.Future.return
      (Brtl_js2.Output.const
         Brtl_js2.Brr.El.
           [ div ~at:At.[ class' (Jstr.v S.class') ] (CCList.map (render state) nodes) ])

  and render state = function
    | Node.Branch node ->
        let expanded, set_expanded = Brtl_js2.Note.S.create ~eq:( = ) `Collapsed in
        let comp state =
          Abb_js.Future.return
            (Brtl_js2.Output.render
               (Brtl_js2.Note.S.map
                  ~eq:( = )
                  (function
                    | `Collapsed -> []
                    | `Expanded ->
                        Brtl_js2.Brr.Console.(log [ Jstr.v "THERE" ]);
                        [
                          Brtl_js2.Router_output.const
                            state
                            Brtl_js2.Brr.El.(div [])
                            (render_child_node_comp node);
                        ])
                  expanded))
        in
        let expander = { Expander.state = expanded; set_state = set_expanded; comp } in
        Brtl_js2.Router_output.const
          state
          Brtl_js2.Brr.El.(div ~at:At.[ class' (Jstr.v "branch") ] [])
          (S.render_node (Node.Branch (expander, node)))
    | Node.Leaf _ as n ->
        Brtl_js2.Router_output.const
          state
          Brtl_js2.Brr.El.(div ~at:At.[ class' (Jstr.v "leaf") ] [])
          (S.render_node n)

  and render_child_node_comp node state =
    let open Abb_js.Future.Infix_monad in
    S.fetch_nodes state node
    >>= function
    | Ok nodes -> run nodes state
    | Error err -> S.render_fetch_nodes_err node err state
end
