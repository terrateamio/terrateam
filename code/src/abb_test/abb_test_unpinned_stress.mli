(** Randomized stress tests for unpinned Tasks.

    These run with a fixed seed so failures are reproducible, but exercise enough interleavings
    (many concurrent tasks, random mixes of sleep / Thread.run / abort / exception / nested Tasks /
    Chan ops) to surface cross-domain races, missed wakeups, and handle leaks that the deterministic
    suites in [abb_test_unpinned] / [abb_test_chan] would miss.

    Each scenario runs a few hundred milliseconds of work and asserts a global invariant (e.g. "all
    expected values arrived", or "every aborted task transitioned to [`Aborted]"). A scenario that
    hangs is automatically caught by the test runner's wall-clock timeout. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
