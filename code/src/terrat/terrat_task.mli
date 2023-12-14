type 'a t
type fresh
type stored

val make : name:string -> unit -> fresh t
val id : stored t -> Uuidm.t
val store : Pgsql_io.t -> fresh t -> (stored t, [> Pgsql_io.err ]) result Abb.Future.t
val abort : Pgsql_io.t -> stored t -> (unit, [> Pgsql_io.err ]) result Abb.Future.t

val run :
  Terrat_storage.t ->
  stored t ->
  (unit -> ('a, ([> Pgsql_pool.err | Pgsql_io.err ] as 'e)) result Abb.Future.t) ->
  ('a, 'e) result Abb.Future.t
