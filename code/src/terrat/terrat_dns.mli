type t

val create : unit -> t
val srv : t -> int64 -> (string * int, [> `Dns_error ]) result Abb.Future.t
