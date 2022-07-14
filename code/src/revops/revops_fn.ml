(* Implementation for reversible operations. *)

module Make =
functor
  (Monad : Revops_intf.MONAD)
  ->
  struct
    module M = Monad

    module Oprev = struct
      type 'a t = (unit -> 'a M.t) * ('a -> unit M.t)

      let make do_fun undo_fun = (do_fun, undo_fun)
    end

    module Revop = struct
      type 'a t = 'a * ('a -> unit M.t)
    end

    open M

    let doop (do_fun, undo_fun) = do_fun () >>= fun undo_state -> return (undo_state, undo_fun)
    let undo (undo_state, undo_fun) = undo_fun undo_state
    let peek (undo_state, undo_fun) = undo_state

    let compose ~introduce ~eliminate_first ~eliminate_second ~first ~second =
      let _, undo_first = first in
      let _, undo_second = second in
      let do_fun () =
        doop first
        >>= fun first_revop ->
        doop second >>= fun second_revop -> introduce (peek first_revop) (peek second_revop)
      in
      let undo_fun undo_state =
        eliminate_second undo_state
        >>= fun second_state ->
        undo_second second_state
        >>= fun () -> eliminate_first undo_state >>= fun first_state -> undo_first first_state
      in
      Oprev.make do_fun undo_fun

    let compose_tuple first second =
      compose
        ~introduce:(fun l r -> return (l, r))
        ~eliminate_first:(CCFun.compose fst return)
        ~eliminate_second:(CCFun.compose snd return)
        ~first
        ~second

    let ( +* ) = compose_tuple

    let run_in_context oprev action =
      doop oprev
      >>= fun revop ->
      let unit_action () = action (peek revop) in
      M.protect ~f:unit_action ~finally:(fun () -> undo revop)
  end
