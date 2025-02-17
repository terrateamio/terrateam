module Make (P : Terrat_vcs_provider2_github.S) : sig
  val post : Terrat_config.t -> Terrat_storage.t -> Brtl_rtng.Handler.t
end
