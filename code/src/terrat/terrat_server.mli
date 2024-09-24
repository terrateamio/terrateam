module Make (Terratc : Terratc_intf.S) : sig
  val run : Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
end
