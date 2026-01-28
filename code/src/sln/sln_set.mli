module String : sig
  include CCSet.S with type elt = string

  val to_yojson : t -> Yojson.Safe.t
  val of_yojson : Yojson.Safe.t -> (t, string) result
  val dedup_list : string list -> string list
end
