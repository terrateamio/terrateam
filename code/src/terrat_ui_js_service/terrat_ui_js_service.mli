type create_err = [ `Error ] [@@deriving show]
type is_logged_in_err = [ `Error ] [@@deriving show]

module type S = sig
  type t

  val create : unit -> (t, [> create_err ]) result Abb_js.Future.t

  module Comp : sig
    module Login : sig
      type config

      val is_enabled : Terrat_api_components.Server_config.t -> config option
      val run : config -> t Brtl_js2.Comp.t
    end

    module Main : sig
      val run : t Brtl_js2.Comp.t
    end
  end

  val is_logged_in : t -> (bool, [> is_logged_in_err ]) result Abb_js.Future.t
end

type service = Service : (module S with type t = 'a) * 'a -> service

module Make (Vcs : Terrat_ui_js_service_vcs.S) : S
