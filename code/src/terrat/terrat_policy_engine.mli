type ('a, 'b) t

module Syntax : sig
  val ( let+ ) :
    (('a, 'b) result, 'c) t -> ('a -> (('d, 'b) result, 'c) t) -> (('d, 'b) result, 'c) t

  val ( let* ) : ('a, 'b) t -> ('a -> ('c, 'b) t) -> ('c, 'b) t
end

val run :
  (unit -> (('a, 'b) result, 'c) t) ->
  ('a * 'c list, [> `Error of 'b * 'c list ]) result Abb.Future.t

val append : 'b -> (unit, 'b) t
val return : 'a -> ('a, 'b) t
val exec : 'a Abb.Future.t -> ('a, 'b) t
val bind : ('a, 'b) t -> ('a -> ('c, 'b) t) -> ('c, 'b) t
