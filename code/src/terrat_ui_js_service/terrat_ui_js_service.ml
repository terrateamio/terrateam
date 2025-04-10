type create_err = [ `Error ] [@@deriving show]

module type S = sig
  type t

  val create : unit -> (t, [> create_err ]) result Abb_js.Future.t

  module Comp : sig
    module Login : sig
      type config

      val is_enabled : Terrat_api_components.Server_config.t -> config option
      val run : config -> t Brtl_js2.Comp.t
    end
  end
end

type service = Service : (module S with type t = 'a) * 'a -> service
