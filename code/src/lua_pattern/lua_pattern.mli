(** Implementation of Lua patterns.  Patterns are a simplified regex meant to
    be easier to implement and use. *)
type t

(** Captures are ranges that have been matched in the search string. *)
module Capture : sig
  type t

  (** The index into the search string the capture starts. *)
  val start : t -> int

  (** The index into the search string one past where the capture stops. *)
  val stop  : t -> int

  (** Extract the string of the capture.*)
  val to_string  : t -> string
end

(** Matches that the pattern has matched into the search strings. *)
module Match : sig
  type t

  (** Indices into the search string that has been matched. *)
  val range     : t -> (int * int)

  (** The string the capture matches. *)
  val to_string : t -> string

  (** List of the captures. *)
  val captures  : t -> Capture.t list
end

(** Compile a pattern.

    @return [None] if the pattern is invalid, [Some t] if the pattern is valid. *)
val of_string : string -> t option

(** Find the first successful pattern hit in the search string.

    @param start optional place in the search string to start searching

    @return [None] if the pattern is not found, [Some (s, e)] if the pattern was
    found, where the range is \[s, e) *)
val find : ?start:int -> string -> t -> (int * int) option


(** Match a pattern in the search string.

    @param start optional place in the search string to start

    @return [None] if the pattern was not found, [Some m] if the pattern was
    found. *)
val mtch : ?start:int -> string -> t -> Match.t option


(** Replace a matches in a string.  Replacing is a function on the {!Match.t}
    returning a new string.

    @param start optional place in the search string to start

    @param s string to search int

    @param r replace function

    @return [None] if the pattern was not found, [Some str] where [str] is the
    string with replacements applied *)
val substitute :
  ?start:int ->
  s:string ->
  r:(Match.t -> string) ->
  t ->
  string option

(** Helper function for the common case where {!substitute} is to replace a
    pattern with a static string.  [rep_str] also supports access captures
    with {v %N v} where {v N v} is a number from 1 to 9.

    Example:

    [let pat = Option.value_exn (of_string "(%d+)(%a+)") in
    substitute ~s:"123foobar" ~r:(rep_str "%2%1") pat]

    yields

    [Some "foobar123"] *)
val rep_str : string -> Match.t -> string
