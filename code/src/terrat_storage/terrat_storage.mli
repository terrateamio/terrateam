type t = Pgsql_pool.t

val create : Terrat_config.t -> t Abb.Future.t
val create_read_only : Terrat_config.t -> t Abb.Future.t
