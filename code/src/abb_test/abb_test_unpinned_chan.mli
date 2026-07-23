(** Multi-domain channel / op cross-domain routing invariants.

    On schedulers that advertise [`Multi_domain] in {!Abb_intf.S.Scheduler.capabilities}, asserts
    that a parked operation's resume (and an async op's callback) is routed to the task that drives
    the operation -- regardless of where the operation was constructed -- so a future is never
    driven from two domains at once. On single-domain schedulers the test is a no-op so the suite
    stays uniform. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
