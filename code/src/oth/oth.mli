module Assert : sig
  (** Asserts that a result is [Ok v] and returns [v], otherwise prints the given message and fails
      the test. *)
  val ok : ?fail_msg:string -> ('a, 'err) result -> 'a

  (** Asserts that a result is [Ok v] and returns [v], otherwise prints the error and fails the
      test. *)
  val ok_pp : pp:(Format.formatter -> 'err -> unit) -> ('a, 'err) result -> 'a

  (** Asserts that a result is [Error v] and returns [v], otherwise prints the given message and
      fails the test. *)
  val error : ?fail_msg:string -> ('a, 'err) result -> 'err

  (** Asserts that a result is [Error v] and returns [v], otherwise prints the error and fails the
      test. *)
  val error_pp : pp:(Format.formatter -> 'a -> unit) -> ('a, 'err) result -> 'err

  (** Asserts that an option is [Some v] and returns [v], otherwise prints a message and fails the
      test. *)
  val some : ?fail_msg:string -> 'a option -> 'a

  (** Asserts that an option is [None], otherwise prints the message and fails the test. *)
  val none : ?fail_msg:string -> 'a option -> unit

  (** Asserts that an option is [None], otherwise prints the unexpected value with [pp] and fails
      the test. *)
  val none_pp : pp:(Format.formatter -> 'a -> unit) -> 'a option -> unit

  (** Asserts that two values are equal based on a provided equality function [eq], otherwise prints
      both values and fails the test. *)
  val eq : eq:('a -> 'a -> bool) -> pp:(Format.formatter -> 'a -> unit) -> 'a -> 'a -> unit

  (** Asserts that the value is [true], otherwise fails the test displaying [msg]. *)
  val true_ : string -> bool -> unit

  (** Fails the test, displaying [msg] *)
  val false_ : string -> 'a

  (** Asserts that [haystack] contains the substring [needle], otherwise fails the test. *)
  val str_contains : haystack:string -> needle:string -> unit

  (** Asserts that [haystack] contains every substring in [needles], otherwise fails the test on the
      first one that is missing. *)
  val str_contains_all : haystack:string -> needles:string list -> unit

  (** Asserts that [haystack] does not contain the substring [needle], otherwise fails the test. *)
  val str_doesnt_contain : haystack:string -> needle:string -> unit

  module List : sig
    (** Asserts that the list has the [expected] length, otherwise fails the test. *)
    val length : expected:int -> 'a list -> unit

    (** Asserts that the list has exactly one element and returns it, otherwise fails the test. *)
    val length_one : 'a list -> 'a

    (** Asserts that the list is non-empty and return the first element, otherwise fails the test.
    *)
    val non_empty : 'a list -> 'a

    (** Asserts that the list is empty, otherwise fails the test. *)
    val empty : 'a list -> unit
  end

  module Eq : sig
    (** Asserts that two strings are equal. *)
    val string : expected:string -> actual:string -> unit

    (** Asserts that two ints are equal. *)
    val int : expected:int -> actual:int -> unit

    (** Asserts that two bools are equal. *)
    val bool : expected:bool -> actual:bool -> unit

    (** Asserts that two string lists are equal. *)
    val string_list : expected:string list -> actual:string list -> unit

    (** Asserts that two int lists are equal. *)
    val int_list : expected:int list -> actual:int list -> unit

    (** Asserts that two option values are equal, using the given equality and pretty-printer for
        the underlying type. *)
    val option :
      eq:('a -> 'a -> bool) ->
      pp:(Format.formatter -> 'a -> unit) ->
      expected:'a option ->
      actual:'a option ->
      unit

    (** Asserts that two string options are equal. *)
    val string_option : expected:string option -> actual:string option -> unit

    (** Asserts that two bool lists are equal. *)
    val bool_list : expected:bool list -> actual:bool list -> unit

    (** Asserts that two lists are equal, element by element. On failure, reports each differing
        item with its index, and flags extra or missing items, making it easy to spot which element
        is wrong. *)
    val list :
      eq:('a -> 'a -> bool) ->
      pp:(Format.formatter -> 'a -> unit) ->
      expected:'a list ->
      actual:'a list ->
      unit
  end

  module String : sig
    (** Asserts that the string is empty, otherwise fails the test. *)
    val empty : string -> unit

    (** Asserts that [haystack] does not contain any member of [needles], otherwise fails the test.
    *)
    val doesnt_contain_any : haystack:string -> needles:string list -> unit
  end

  module Exit_code : sig
    (** Asserts that the process exited with a zero return code, otherwise fails the test. A
        signaled or stopped process also fails the test. *)
    val zero : Abb_intf.Process.Exit_code.t -> unit

    (** Asserts that the process exited, with a non-zero exit, otherwise fails the test. A signaled
        or stopped process also fails the test. *)
    val non_zero : Abb_intf.Process.Exit_code.t -> unit
  end
end

(** Internal state of the test, explicitly passed around with some combinators. *)
module State : sig
  type t

  (** File-derived tags set via [~file] on {!run}. Empty when no file was provided. *)
  val file_dir_tags : t -> string list

  (** Whether the current run is only printing tags ([OTH_PRINT_TAGS] is set). *)
  val print_tags : t -> bool
end

(** Tag-based test filtering.

    Each test's effective tag set is the union of:
    - [{!Tag.default}] (always present)
    - The test's [~name]
    - Explicit [~tags] passed to {!test}
    - File/directory tags derived from [~file] passed to {!run} (e.g., passing [Stdlib.__FILE__] for
      [tests/sg_tf_eval/test.ml] adds ["sg_tf_eval"] and ["test.ml"])

    Tests can be filtered at runtime via environment variables:

    - [OTH_TAGS]: space-separated list of tags to include (whitelist). When set, only tests with at
      least one matching tag are run.
    - [OTH_EXCLUDE_TAGS]: space-separated list of tags to exclude (blacklist). Tests with any
      matching tag are skipped.

    Exclude takes priority over include. When neither variable is set, all tests run. Filtered tests
    are skipped without executing their body. *)
module Tag : sig
  module Set : CCSet.S with type elt = string

  (** The default tag assigned to all tests. *)
  val default : string

  (** Derive tags from a source file path (typically [Stdlib.__FILE__]). Strips everything up to and
      including [src/] or [tests/], then returns the remaining path components as tags. For example,
      [../../../tests/sg_tf_eval/test.ml] yields [["sg_tf_eval"; "test.ml"]]. *)
  val file_dir_tags : string -> string list

  (** Read a space-separated tag set from an environment variable. Returns [None] if the variable is
      unset or empty. *)
  val of_env_opt : string -> Set.t option
end

(** Build the full tag list for a test: [{!Tag.default}], [~name], explicit [~tags], and file-dir
    tags from [state]. *)
val all_tags : name:string -> tags:string list -> State.t -> string list

(** Check whether a test with the given [~tags] should run. Checks against [OTH_TAGS] /
    [OTH_EXCLUDE_TAGS]. *)
val test_should_run : tags:string list -> bool

(** Print tags on a single sorted line. Used by [OTH_PRINT_TAGS] mode. *)
val print_test_tags : tags:string list -> unit

(** A test. Like moose, a plural of tests is called a test. A single test can wrap multiple tests
    inside of it. *)
module Test : sig
  type t
end

(** The result of a single test. *)
module Test_result : sig
  type t = {
    name : string;
    desc : string option;
    duration : Duration.t;
    res : [ `Ok | `Exn of exn * Printexc.raw_backtrace option | `Timedout | `Skipped ];
  }
end

(** The result of a run, which is a list of tests. The order of the tests is undefined. *)
module Run_result : sig
  type t

  val of_test_results : Test_result.t list -> t
  val test_results : t -> Test_result.t list
end

module Outputter : sig
  type t = Run_result.t -> unit

  (** An outputter that writes a basic format to stdout. *)
  val basic_stdout : t

  (** An outputter that writes to a file. The [out_channel] specifies where to write the results to.
  *)
  val basic_tap : [ `Filename of string | `Out_channel of out_channel ] -> t

  (** Takes an environment variable name and a list of tuples mapping a string name to an Outputter.
      The environment variable will be compared to the list of tuples and outputters listed in the
      environment variable will be used. The names in the environment variable are separated by
      spaces and checked against the tuples. Multiple outputters may be specified in the environment
      variable. Default outputters can also be specified which will be used if the environment
      variable is not present. By default, nothing is specified. *)
  val of_env : ?default:string list -> string -> (string * t) list -> t
end

(** Evaluate a test and return the result. When [~file] is provided, file-derived tags are available
    for filtering. *)
val eval : file:string -> Test.t -> Run_result.t

(** Execute a test and output its results with the outputter and terminates the process when
    complete. If any tests have failed it will call [exit 1], otherwise [exit 0]. The optional
    [~finally] function is called before exiting. *)
val main : file:string -> ?finally:(unit -> unit) -> Outputter.t -> Test.t -> unit

(** This is a wrapper for a call to {!main} with an Outputter which can output TAP and stdout (and
    does both by default). The output channel is a file, by default, in the current working
    directory named the same as the executable with a [".tap"] added to the end. The output
    directory can be modified with the [OTH_TAP_DIR] environment variable. The environment variable
    used to modify this behaviour is [OTH_OUTPUTTER].

    [~file] must be [!Stdlib.__FILE__]). [~file] is used to derive path components which are added
    as tags to every test result, enabling file-based filtering via [OTH_TAGS] and
    [OTH_EXCLUDE_TAGS]. *)
val run : file:string -> ?finally:(unit -> unit) -> Test.t -> unit

(** Return the parallelism level from the [OTH_PARALLEL] environment variable. Defaults to [1] when
    unset or unparseable. *)
val parallelism : unit -> int

(** Takes a list of tests and runs them in parallel using the Domainslib pool. *)
val parallel : Test.t list -> Test.t

(** Run multiple tests in serial *)
val serial : Test.t list -> Test.t

(** Execute a test multiple times *)
val loop : int -> Test.t -> Test.t

(** Run a test and timeout if it does not finish in a given amount of time *)
val timeout : Duration.t -> Test.t -> Test.t

(** Turn a function into a test. The test's [~name] and [{!Tag.default}] are always included as
    tags. Extra tags can be added via [~tags]. File-based tags are injected by {!run} via its
    [~file] parameter. A test whose effective tags don't pass filtering is skipped without executing
    its body. *)
val test : ?tags:string list -> ?desc:string -> name:string -> (State.t -> unit) -> Test.t

val raw_test : (State.t -> Run_result.t) -> Test.t

(** Name a test. This is useful for naming loops or grouped tests in order to see the time and a
    named output but not for each individual run.

    @deprecated This no longer does anything. *)
val name : name:string -> Test.t -> Test.t

(** Turn a test that returns a result into one that returns a unit. This asserts that the result is
    on the 'Ok' path. *)
val result_test : (State.t -> (unit, 'err) result) -> State.t -> unit

(** Turn a function into a test with a setup and teardown phase *)
val test_with_revops :
  ?tags:string list ->
  ?desc:string ->
  name:string ->
  revops:'a Revops.Oprev.t ->
  ('a -> State.t -> unit) ->
  Test.t

(** Turn verbose logging on. This is the default but can be turned off with {!silent}, this will
    turn it back on.

    @deprecated This no longer does anything. *)
val verbose : Test.t -> Test.t

(** Turn logging off in the test, this is useful in combination with {!loop}.

    @deprecated This no longer does anything. *)
val silent : Test.t -> Test.t

module Diff : sig
  (** Function used in regression tests, to check that [actual_content] is equal to the content of
      the file at [expected_file_path]. The intended use is that [expected_file_path] is a versioned
      "expected output" file, and [actual_content] is the output generated by the test. If they
      differ, this means something unexpected changed, and the test fails.

      To make it easy to regenerate expected output files when code changes cause a regresson, set
      the environment variable [OTH_CREATE_EXPECTED_FILES] to "1". In that case, this function
      writes [actual_content] to [expected_file_path], instead of checking anything. *)
  val check : tmp_dir_name:string -> expected_file_path:string -> actual_content:string -> unit
end
