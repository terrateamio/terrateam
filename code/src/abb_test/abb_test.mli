(** Aggregate test harness for an [Abb_intf.S] scheduler. Each sub-module [Abb_test_*] is a functor
    that builds one [Oth.Test.t]; this functor composes them all into a single sync test and
    provides a [run_tests] entry point. *)
module Make (_ : Abb_intf.S) : sig
  (** The composed sync test that runs every sub-suite (Concurrency, Thread, Sleep, Simple,
      Getaddrinfo, Socket, Process, Task) in serial. *)
  val test : Oth.Test.t

  (** Seed [Random] and dispatch the test runner against this file. Used by the per-scheduler
      [test.ml] entry points under [code/tests/abb_*]. *)
  val run_tests : unit -> unit
end
