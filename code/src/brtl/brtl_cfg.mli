type t

val create : ?read_header_timeout:Duration.t -> ?handler_timeout:Duration.t -> int -> t

val port : t -> int

val read_header_timeout : t -> Duration.t option

val handler_timeout : t -> Duration.t option
