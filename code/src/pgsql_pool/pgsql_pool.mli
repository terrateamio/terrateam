exception Pgsql_pool_closed

module Metrics : sig
  type t = {
    num_conns : int;
    idle_conns : int;
  }
end

type err = [ `Pgsql_pool_error ]
type t

(** Create a pool which will create [Pgsql] connections with the given configuration. No connections
    are made on creation.

    - [idle_check] specifies how long between uses of a connection to check if it is still
      connected. This is tested on the next use of the connection. The check translates to a ping
      being sent to the database to verify the connection is still alive. By default this check is 1
      year. A value of [0] checks it on every use. If the connection has been disconnected, the next
      connection is verified, and so on, until a connection is found.

    - [conn_timeout_check] specifies how long a connection can be idle for before timing out and
      being closed, shrinking the pool when it is not in active use. By default, this is 1 minute.
*)
val create :
  ?metrics:(Metrics.t -> unit Abb.Future.t) ->
  ?idle_check:Duration.t ->
  ?conn_timeout_check:Duration.t ->
  ?tls_config:[ `Require of Otls.Tls_config.t | `Prefer of Otls.Tls_config.t ] ->
  ?passwd:string ->
  ?port:int ->
  ?on_connect:(Pgsql_io.t -> unit Abb.Future.t) ->
  connect_timeout:float ->
  host:string ->
  user:string ->
  max_conns:int ->
  string ->
  t Abb.Future.t

(** Destroy the pool. All idle connections are closed and connections in use are closed once they
    are no longer used. *)
val destroy : t -> unit Abb.Future.t

(** Perform an operation with a connection. If there is no available idle connection and there are
    fewer than [max_conns] created, then create a new one and use it, otherwise wait until a
    connection is idle.

    This function expects that the pool will always be available and it throws an exception if it is
    not. This error means retrying the operion will consistently fail.

    However if the pool is available but there are issues with creating new connections to the
    database, it will return a [`Pgsql_pool_error] error. This error is temporarily and retrying the
    operation may succeed. *)
val with_conn :
  t -> f:(Pgsql_io.t -> ('a, ([> err ] as 'e)) result Abb.Future.t) -> ('a, 'e) result Abb.Future.t

val pp_err : Format.formatter -> err -> unit
val show_err : err -> string
