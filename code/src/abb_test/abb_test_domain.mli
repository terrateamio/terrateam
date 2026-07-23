(** Multi-domain placement tests for pinned vs unpinned tasks.

    On schedulers that advertise [`Multi_domain] in {!Abb_intf.S.Scheduler.capabilities}, asserts
    that pinned tasks run on the scheduler's loop domain and unpinned tasks run on a worker domain.
    On single-domain schedulers the test is a no-op so the suite stays uniform. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
