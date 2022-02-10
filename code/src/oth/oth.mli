(** Internal state of the test, explicitly passed around with some
    combinators. *)
module State : sig
  type t
end

(** A test. Like moose, a plural of tests is called a test.  A single test can
    wrap multiple tests inside of it. *)
module Test : sig
  type t
end

(** The result of a single test. *)
module Test_result : sig
  type t = {
    name : string;
    desc : string option;
    duration : Duration.t;
    res : [ `Ok | `Exn of exn * Printexc.raw_backtrace option | `Timedout ];
  }
end

(** The result of a run, which is a list of tests.  The order of the tests is
    undefined. *)
module Run_result : sig
  type t

  val of_test_results : Test_result.t list -> t
  val test_results : t -> Test_result.t list
end

module Outputter : sig
  type t = Run_result.t -> unit

  (** An outputter that writes a basic format to stdout. *)
  val basic_stdout : t

  (** An outputter that writes to a file. The [out_channel] specifies where to
      write the results to. *)
  val basic_tap : [ `Filename of string | `Out_channel of out_channel ] -> t

  (** Takes an environment variable name and a list of tuples mapping a string
      name to an Outputter.  The environment variable will be compared to the
      list of tuples and outputters listed in the environment variable will be
      used.  The names in the environment variable are separated by spaces and
      checked against the tuples.  Multiple outputters may be specified in the
      environment variable.  Default outputters can also be specified which will
      be used if the environment variable is not present. By default, nothing is
      specified. *)
  val of_env : ?default:string list -> string -> (string * t) list -> t
end

(** Evaluate a test and return the result. *)
val eval : Test.t -> Run_result.t

(** Execute a test and output its results with the outputter and terminates the
    process when complete.  If any tests have failed it will call [exit 1],
    otherwise [exit 0]. *)
val main : Outputter.t -> Test.t -> unit

(** This is a wrapper for a call to {!main} with an Outputter which can output
    TAP and stdout (and does both by default).  The output channel is a file, by
    default, in the current working directory named the same as the executable
    with a [".tap"] added to the end.  The output directory can be modified with
    the [OTH_TAP_DIR] environment variable.  The environment variable used to
    modify this behaviour is [OTH_OUTPUTTER]. *)
val run : Test.t -> unit

(** Takes a list of tests and make them runnable in parallel.

    Currently this is a synonym for {!serial}. *)
val parallel : Test.t list -> Test.t

(** Run multiple tests in serial *)
val serial : Test.t list -> Test.t

(** Execute a test multiple times *)
val loop : int -> Test.t -> Test.t

(** Run a test and timeout if it does not finish in a given amount of time *)
val timeout : Duration.t -> Test.t -> Test.t

(** Turn a function into a test *)
val test : ?desc:string -> name:string -> (State.t -> unit) -> Test.t

val raw_test : (State.t -> Run_result.t) -> Test.t

(** Name a test. This is useful for naming loops or grouped tests in order to
    see the time and a named output but not for each individual run.

    @deprecated This no longer does anything. *)
val name : name:string -> Test.t -> Test.t

(** Turn a test that returns a result into one that returns a unit.  This
    asserts that the result is on the 'Ok' path.  *)
val result_test : (State.t -> (unit, 'err) result) -> State.t -> unit

(** Turn a function into a test with a setup and teardown phase *)
val test_with_revops :
  ?desc:string -> name:string -> revops:'a Revops.Oprev.t -> ('a -> State.t -> unit) -> Test.t

(** Turn verbose logging on.  This is the default but can be turned off with
    {!silent}, this will turn it back on.

    @deprecated This no longer does anything. *)
val verbose : Test.t -> Test.t

(** Turn logging off in the test, this is useful in combination with {!loop}.

    @deprecated This no longer does anything. *)
val silent : Test.t -> Test.t
