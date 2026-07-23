(** Tests for [Abb_intf.Chan]: bounded MPSC channel.

    This module exists primarily to surface domain-safety bugs in the [Abb_scheduler_luv]
    implementation. [Chan] is the project's primary cross-domain communication primitive — every bug
    here is a potential lost message, double-fire, or deadlock in code that uses it. The cases below
    cover:

    - same-domain enqueue/dequeue (basic ordering)
    - blocked dequeue woken by a producer
    - blocked enqueue woken by a consumer (capacity backpressure)
    - close while waiters are parked (both directions)
    - many cross-domain producers via [Thread.run] hammering a scheduler-domain consumer
    - randomized producer/consumer interleavings to exercise the lost-wakeup race window

    All tests run with a finite timeout in CI; if any of them hangs that is a domain-safety bug. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
