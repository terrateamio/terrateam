type t

val millisecond_day : float
val of_string : string -> t
val to_iso_string : t -> string
val to_hh_mm : t -> string
val to_yyyy_mm_dd_hh_mm : t -> string
val to_yyyy_mm_dd : t -> string
val to_yyyy_mm : t -> string
val range : t -> t -> t list
val add_milliseconds : t -> float -> t
val now : unit -> t
val get_time : t -> float
val set_hours : t -> int -> unit
val set_minutes : t -> int -> unit
