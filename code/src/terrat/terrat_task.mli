type 'a t
type fresh
type stored
type store_err = Pgsql_io.err
type abort_err = Pgsql_io.err

type run_err =
  [ Pgsql_pool.err
  | Pgsql_io.err
  ]

val make : name:string -> unit -> fresh t
val id : stored t -> Uuidm.t
val store : Pgsql_io.t -> fresh t -> (stored t, [> store_err ]) result Abb.Future.t
val abort : Pgsql_io.t -> stored t -> (unit, [> abort_err ]) result Abb.Future.t

val run :
  Terrat_storage.t ->
  stored t ->
  (unit -> ('a, ([> run_err ] as 'e)) result Abb.Future.t) ->
  ('a, 'e) result Abb.Future.t
