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

    module Main : sig
      val run : t Brtl_js2.Comp.t
    end
  end
end

type service = Service : (module S with type t = 'a) * 'a -> service

module Make (Vcs : Terrat_ui_js_service_vcs.S) : S = struct
  module Main = Terrat_ui_js_service_comp_main.Make (Vcs)

  type t = unit Main.t

  let create () =
    let open Abb_js_future_combinators.Infix_result_monad in
    Vcs.create () >>= fun vcs -> Main.create vcs

  module Comp = struct
    module Login = struct
      type config = Vcs.Login.config

      let is_enabled = Vcs.Login.is_enabled

      let run config state =
        let t = Brtl_js2.State.app_state state in
        Vcs.Login.run config (Brtl_js2.State.with_app_state (Main.vcs t) state)
    end

    module Main = Main
  end
end
