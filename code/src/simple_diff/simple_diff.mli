(** A simple diffing algorithm *)

module type Comparable =
  sig
    type t
      (** The type of the items being compared *)

    val compare: t -> t -> int
      (** A way to distinguish if items are equal or unequal. It follows
          the OCaml convention of returning an integer between -1 to 1. *)
  end

module type S =
  sig
    type item
    (** The type of the item that will be compared. *)

    type diff =
      | Deleted of item array
      | Added of item array
      | Equal of item array
    (** Represents the change or lack of change in a line or character
        between the old and new version. *)

    type t = diff list
    (** List of diffs which is the return value of the main function. *)

    val get_diff : item array -> item array -> t
    (** Returns a list of diffs between two arrays *)
  end

module Make (Item: Comparable) : S with type item = Item.t
