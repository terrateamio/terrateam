module String_map : sig
  include module type of CCMap.Make (CCString)

  val to_yojson : ('a -> 'b) -> 'a t -> [> `Assoc of (string * 'b) list ]

  val of_yojson :
    ('a -> ('b, string) result) -> [> `Assoc of (string * 'a) list ] -> ('b t, string) result

  val pp : (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a t -> unit
  val show : (Format.formatter -> 'a -> unit) -> 'a t -> string
end

module Dirspace_map : sig
  include module type of CCMap.Make (Terrat_dirspace)

  val to_yojson : ('a -> 'b) -> 'a t -> [> `Assoc of (string * 'b) list ]

  val of_yojson :
    ('a -> ('b, string) result) -> [> `Assoc of (string * 'a) list ] -> ('b t, string) result

  val pp : (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a t -> unit
  val show : (Format.formatter -> 'a -> unit) -> 'a t -> string
end
