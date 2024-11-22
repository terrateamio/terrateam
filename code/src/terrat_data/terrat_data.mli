module String_map : sig
  include module type of CCMap.Make (CCString)

  val to_yojson : ('a -> 'b) -> 'a t -> [> `Assoc of (string * 'b) list ]

  val of_yojson :
    ('a -> ('b, string) result) -> [> `Assoc of (string * 'a) list ] -> ('b t, string) result

  val pp : (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a t -> unit
  val show : (Format.formatter -> 'a -> unit) -> 'a t -> string
end

module String_set : module type of CCSet.Make (CCString)

module Dirspace_map : sig
  include module type of CCMap.Make (Terrat_dirspace)

  val to_yojson : ('a -> 'b) -> 'a t -> [> `Assoc of (string * 'b) list ]

  val of_yojson :
    ('a -> ('b, string) result) -> [> `Assoc of (string * 'a) list ] -> ('b t, string) result

  val pp : (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a t -> unit
  val show : (Format.formatter -> 'a -> unit) -> 'a t -> string
end

module Dirspace_set : module type of CCSet.Make (Terrat_dirspace)

module type GROUP_BY = sig
  type t
  type key

  val compare : key -> key -> int
  val key : t -> key
end

module Group_by (G : GROUP_BY) : sig
  (** Given a list, group each element in the list by an associated key and
     return a list mapping keys to the values.  This guarantees that the list in
     each group is in the same order as they were in the original list, however
     there are no guarantees around the groups. *)
  val group : G.t list -> (G.key * G.t list) list
end
