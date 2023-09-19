module Work_manifests : sig
  val get :
    Terrat_config.t ->
    Terrat_storage.t ->
    int ->
    int option ->
    [ `Asc | `Desc ] option ->
    (string * Uuidm.t) Brtl_ep_paginate.Param.t option ->
    int ->
    Brtl_rtng.Handler.t
end

module Pull_requests : sig
  val get :
    Terrat_config.t ->
    Terrat_storage.t ->
    int ->
    int option ->
    int64 Brtl_ep_paginate.Param.t option ->
    int ->
    Brtl_rtng.Handler.t
end
