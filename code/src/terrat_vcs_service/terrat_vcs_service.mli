module type S = sig
  module Routes : sig
    val get :
      Terrat_config.t ->
      Terrat_storage.t ->
      (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
  end
end
