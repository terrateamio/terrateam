module Make (Terratc : Terratc_intf.S) : sig
  val post : Terrat_config.t -> Terrat_storage.t -> Brtl_rtng.Handler.t
end
