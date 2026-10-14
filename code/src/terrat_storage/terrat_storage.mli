type t = Pgsql_pool.t

(** The pool of the orchestration database. [create] raises [Failure] where [try_create] returns the
    error. *)
val try_create : Terrat_config.t -> (t, [> Pgsql_io.err | Pgsql_pool.err ]) result Abb.Future.t

val create : Terrat_config.t -> t Abb.Future.t

(** Pool for the database that holds the Infracost price book. It uses the pool settings of
    {!create} and connects with the settings of the given record. *)
val create_pricing : Terrat_config.t -> Terrat_config.Infracost.price_book -> t Abb.Future.t
