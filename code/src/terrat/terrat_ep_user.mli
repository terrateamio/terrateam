module Prefs : sig
  val get : Terrat_storage.t -> Brtl_rtng.Handler.t
  val put : Terrat_storage.t -> Terrat_data.Request.User_prefs.t -> Brtl_rtng.Handler.t
end
