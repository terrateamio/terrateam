(** A simple diffing algorithm *)

(** Represents the change or lack of change in a line or character
    between the old and new version. *)
type diff

(** List of diffs which is the return value of the main function. *)
type t

(** Returns a list of diffs between two arrays *)
val get_diff : string array -> string array -> t
