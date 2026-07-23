(** Regression test for the capture-eagerly invariant on [Socket.Tcp.send] (RFD 675).

    An unpinned task that issues a socket send before its first async suspension must still have the
    send's poll callback serialized onto the task's worker domain. If [send] reads
    [current_unpinned ()] lazily (inside its [with_state] closure, after the chain-data scope is
    gone) the poll runs pinned-style on the loop domain and drives the task's [Abb_fut] State
    cross-domain — the debug build aborts. This module reproduces that deterministically. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
