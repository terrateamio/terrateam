module Drift : sig
  module List : sig
    val get : string -> Terrat_config.t -> Terrat_storage.t -> Brtl_rtng.Handler.t
  end
end
