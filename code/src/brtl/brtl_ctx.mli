type ('a, 'b) t

module Request : Cohttp.S.Request with type t = Cohttp.Request.t

val create : Request.t -> (unit, unit) t

val request : ('a, 'b) t -> Request.t

val md_find : 'k Hmap.key -> ('a, 'b) t -> 'k option
val md_add : 'k Hmap.key -> 'k -> ('a, 'b) t -> ('a, 'b) t

val body : ('a, 'b) t -> 'a
val set_body : 'a -> (unit, 'b) t -> ('a, 'b) t

val response : ('a, 'b) t -> 'b
val set_response : 'b -> ('a, 'c) t -> ('a, 'b) t
