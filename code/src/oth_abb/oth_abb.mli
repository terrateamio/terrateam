module Make (Abb : Abb_intf.S) : sig
  (** A test. Like moose, a plural of tests is called a test. A single test can wrap multiple tests
      inside of it. Under the new scheme, an async test is just an {!Oth.Test.t} whose body runs the
      Abb scheduler internally. *)
  module Test : sig
    type t = Oth.Test.t
  end

  (** Takes a list of tests and makes them runnable in parallel. Alias for {!Oth.parallel}. *)
  val parallel : Test.t list -> Test.t

  (** Run multiple tests in serial. Alias for {!Oth.serial}. *)
  val serial : Test.t list -> Test.t

  (** Run a test and timeout if it does not finish in a given amount of time. *)
  val timeout : Duration.t -> Test.t -> Test.t

  (** Turn an async function into a test. The scheduler is run for the duration of [f], and any
      exception raised in the future tree propagates out synchronously. *)
  val test :
    ?tags:string list -> ?desc:string -> name:string -> (unit -> unit Abb.Future.t) -> Test.t

  (** Turn a result-returning test into a unit-returning test. *)
  val result_test :
    (Oth.State.t -> (unit, 'err) result Abb.Future.t) -> Oth.State.t -> unit Abb.Future.t

  (** No-op: async tests are now plain {!Oth.Test.t}, so no conversion is needed. Kept for backwards
      compatibility with existing callers. *)
  val to_sync_test : Test.t -> Oth.Test.t
end
