module Make (P : Terrat_vcs_provider2_github.S) : sig
  val post : P.Api.Config.t -> Terrat_storage.t -> Brtl_rtng.Handler.t
end
