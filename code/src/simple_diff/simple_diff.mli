(** A simple diffing algorithm *)

module type Comparable = sig
  (** The type of the items being compared *)
  type t

  (** A way to distinguish if items are equal or unequal. It follows
          the OCaml convention of returning an integer between -1 to 1. *)
  val compare : t -> t -> int
end

module type S = sig
  (** The type of the item that will be compared. *)
  type item

  type diff =
    | Deleted of item array
    | Added   of item array
    | Equal   of item array
        (** Represents the change or lack of change in a line or character
        between the old and new version. *)

  (** List of diffs which is the return value of the main function. *)
  type t = diff list

  (** Returns a list of diffs between two arrays *)
  val get_diff : item array -> item array -> t
end

module Make (Item : Comparable) : S with type item = Item.t
