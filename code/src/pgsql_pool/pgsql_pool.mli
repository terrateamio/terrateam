exception Pgsql_pool_closed

type err = [ `Pgsql_pool_error ]

type t

(** Create a pool which will create [Pgsql] connections with the given
   configuration.  No connections are made on creation. *)
val create :
  ?tls_config:[ `Require of Otls.Tls_config.t | `Prefer  of Otls.Tls_config.t ] ->
  ?passwd:string ->
  ?port:int ->
  connect_timeout:float ->
  host:string ->
  user:string ->
  max_conns:int ->
  string ->
  t Abb.Future.t

(** Destroy the pool.  All idle connections are closed and connections in use
   are closed once they are no longer used. *)
val destroy : t -> unit Abb.Future.t

(** Perform an operation with a connection.  If there is no available idle
   connection and there are fewer than [max_conns] created, then create a new
   one and use it, otherwise wait until a connection is idle.

   This function expects that the pool will always be available and it throws an
   exception if it is not.  This error means retrying the operion will
   consistently fail.

   However if the pool is available but there are issues with creating new
   connections to the database, it will return a [`Pgsql_pool_error] error.
   This error is temporarily and retrying the operation may succeed. *)
val with_conn :
  t -> f:(Pgsql_io.t -> ('a, ([> err ] as 'e)) result Abb.Future.t) -> ('a, 'e) result Abb.Future.t

val pp_err : Format.formatter -> err -> unit

val show_err : err -> string
