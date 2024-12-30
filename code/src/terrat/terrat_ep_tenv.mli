module Releases : sig
  val get :
    Terrat_config.t -> Terrat_storage.t -> string -> string -> int option -> Brtl_rtng.Handler.t
end

module Download : sig
  val get : Terrat_config.t -> Terrat_storage.t -> string -> string -> string -> Brtl_rtng.Handler.t
end
