(** A test runner that gives every async test its OWN scheduler run.

    Deliberately NOT {!Oth_abb}. This is a scheduler *conformance* suite: several tests here pick
    their own [thread_pool_size] and drive [Abb.Scheduler.run_with_state] themselves in order to
    exercise the scheduler under a specific pool configuration (see {!Abb_test_pool_pressure} and
    the [Thread.run] tests in {!Abb_test_thread}). [Oth_abb] runs one scheduler for the whole suite,
    so those tests would be nesting a scheduler inside a running one. Fresh-scheduler-per-test is
    the property under test, not an accident of the old harness.

    This is [Oth_abb.Make]'s body retargeted at {!Oth}, so the composed test is a plain synchronous
    {!Oth.Test.t}. *)
module Make (Abb : Abb_intf.S) : sig
  module Test : sig
    type t = Oth.Test.t
  end

  val parallel : Test.t list -> Test.t
  val serial : Test.t list -> Test.t

  (** Turn an async function into a test. A scheduler is spun up for the duration of [f] and any
      exception in the future tree propagates out synchronously. *)
  val test :
    ?tags:string list -> ?desc:string -> name:string -> (unit -> unit Abb.Future.t) -> Test.t
end
