(** A simple diffing algorithm *)

(** Represents the change or lack of change in a line or character
    between the old and new version. *)
type diff =
  | Deleted of string array
  | Added of string array
  | Equal of string array

(** List of diffs which is the return value of the main function. *)
type t = diff list

(** Returns a list of diffs between two arrays *)
val get_diff : string array -> string array -> t
