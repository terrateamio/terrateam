module Installations : sig
  val get : Terrat_config.t -> Terrat_storage.t -> Brtl_rtng.Handler.t
end
