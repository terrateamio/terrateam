module Make (Abb : Abb_intf.S ) : sig
  (** A test. Like moose, a plural of tests is called a test.  A single test can
      wrap multiple tests inside of it. *)
  module Test : sig
    type t
  end

  (** Takes a list of tests and make them runnable in parallel. *)
  val parallel : Test.t list -> Test.t

  (** Run multiple tests in serial *)
  val serial : Test.t list -> Test.t

  (** Run a test and timeout if it does not finish in a given amount of time *)
  val timeout : Duration.t -> Test.t -> Test.t

  (** Turn a function into a test *)
  val test : ?desc:string -> name:string -> (unit -> unit Abb.Future.t) -> Test.t

  (** Turn a test that returns a result into one that returns a unit.  This
      asserts that the result is on the 'Ok' path.  *)
  val result_test :
    (Oth.State.t -> (unit, 'err) result Abb.Future.t) ->
    Oth.State.t ->
    unit Abb.Future.t

  (** Convert an asynchronous test into a synchronous test.  This requires
      running the ever loop. *)
  val to_sync_test : Test.t -> Oth.Test.t
end
