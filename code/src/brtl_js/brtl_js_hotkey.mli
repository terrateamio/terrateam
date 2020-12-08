(** Key combination that has been pressed.  They keys are sorted to make
   matching possible.  The values are exactly as they appear in a key event,
   including case except if they are a letters.  For example, ArrowUp,
   ArrowDown, Control, k, q.  But letters are always lowercase, for example "K"
   would be ["Shift"; "k"].  On some browsers, the arrow keys have synonyms and
   these are converted to the standard Arrow(Up|Down|Left|Right). *)
module Key_combo : sig
  type t

  val of_list : string list -> t

  val compare : t -> t -> int
end

module Key_map : sig
  type 'a t

  val of_list : (Key_combo.t * 'a) list -> 'a t

  val get : Key_combo.t -> 'a t -> 'a option
end

val create : (Key_combo.t -> unit Abb_fut_js.t) -> unit
