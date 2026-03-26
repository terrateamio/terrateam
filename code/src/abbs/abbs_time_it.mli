val run : (float -> unit) -> (unit -> 'a Abb.Future.t) -> 'a Abb.Future.t
val run' : ('a -> float -> unit) -> (unit -> 'a Abb.Future.t) -> 'a Abb.Future.t
