(** Tests for the scheduler's op queue. Driven through the public [Abb.Sys.sleep] / [Abb.Socket.*]
    APIs since [Op.t] itself is private to the scheduler.

    The interesting cases are abort-timing races: before the dispatcher has run the op, after the
    handle is live but before it fires, and during the fire callback. Each must leave the loop in a
    closeable state with no leaked handles. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
