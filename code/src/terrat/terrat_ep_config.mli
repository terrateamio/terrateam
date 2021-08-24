val get : Terrat_config.t -> Terrat_storage.t -> Githubc_v3.Schema.t -> int64 -> Brtl_rtng.Handler.t

val put :
  Terrat_config.t ->
  Terrat_storage.t ->
  Githubc_v3.Schema.t ->
  int64 ->
  Terrat_data.Request.Config.t ->
  Brtl_rtng.Handler.t
