type create_err = [ `Error ] [@@deriving show]

module Make (Vcs : Terrat_ui_js_service_vcs.S) : sig
  val create :
    Vcs.t -> (unit Terrat_ui_js_service_state.Make(Vcs).t, [> create_err ]) result Abb_js.Future.t

  val run : unit Terrat_ui_js_service_state.Make(Vcs).t Brtl_js2.Comp.t
end
