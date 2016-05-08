open Core.Std

(** Internal state of the test, explicitly passed around with some
    combinators. *)
module State : sig
  type t
end

(** A test. *)
module Test : sig
  type t
end

(** Run a test and terminate the process when complete.  The exit code will be 0
    on success and non zero on failure. Information will only be printed in the
    case of a test failure *)
val run : Test.t -> unit

(** Takes a list of tests and make them runnable in parallel.

    Currently this is a synonym for {!serial}. *)
val parallel : Test.t list -> Test.t

(** Run multiple tests in serial *)
val serial : Test.t list -> Test.t

(** Execute a test multiple times *)
val loop : int -> Test.t -> Test.t

(** Run a test and timeout if it does not finish in a given amount of time *)
val timeout : Core.Span.t -> Test.t -> Test.t

(** Turn a function into a test *)
val test : ?desc:string -> name:string -> (State.t -> unit) -> Test.t

(** Name a test. This is useful for naming loops or grouped tests in order to
    see the time and a named output but not for each individual run *)
val name : name:string -> Test.t -> Test.t

(** Turn a test that returns a result into one that returns a unit.  This
    asserts that the result is on the 'Ok' path.  *)
val result_test :
  (State.t -> (unit, 'err) Result.t) ->
  State.t ->
  unit

(** Turn a function into a test with a setup and teardown phase *)
val test_with_revops :
  ?desc:string ->
  name:string ->
  revops:'a Revops.Oprev.t ->
  ('a -> State.t -> unit) ->
  Test.t

(** Turn verbose logging on.  This is the default but can be turned off with
    {!silent}, this will turn it back on. *)
val verbose : Test.t -> Test.t

(** Turn logging off in the test, this is useful in combination with {!loop}. *)
val silent  : Test.t -> Test.t
