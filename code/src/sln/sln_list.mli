module String : sig
  (** [CCList.mem ~eq:CCString.equal] *)
  val mem : string -> string list -> bool

  (** [CCList.sort CCString.compare] *)
  val sort : string list -> string list

  (** [CCList.sort_uniq ~cmp:CCString.compare] *)
  val sort_uniq : string list -> string list

  (** [CCList.equal CCString.equal] *)
  val equal : string list -> string list -> bool

  (** [CCList.uniq ~eq:CCString.equal] *)
  val uniq : string list -> string list

  (** [CCList.remove ~eq:CCString.equal ~key]: drops {i every} occurrence of the value, not just the
      first. *)
  val remove : string -> string list -> string list

  (** [CCList.assoc_opt ~eq:CCString.equal] *)
  val assoc_opt : string -> (string * 'a) list -> 'a option

  (** [CCList.mem_assoc ~eq:CCString.equal] *)
  val mem_assoc : string -> (string * _) list -> bool

  (** [CCList.sort (fun (a, _) (b, _) -> CCString.compare a b)] *)
  val sort_assoc : (string * 'a) list -> (string * 'a) list
end

module Uuidm : sig
  (** [CCList.mem ~eq:Uuidm.equal] *)
  val mem : Uuidm.t -> Uuidm.t list -> bool
end
