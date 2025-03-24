module type S = sig
  module Service : sig
    type t
    type vcs_config

    val start : Terrat_config.t -> vcs_config -> Terrat_storage.t -> t Abb.Future.t
    val stop : t -> unit Abb.Future.t
    val routes : t -> (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
  end
end
