module Make (Vcs : Terrat_ui_js_service_vcs.S) : sig
  val run :
    Terrat_ui_js_service_state.Make(Vcs).v Terrat_ui_js_service_state.Make(Vcs).t Brtl_js2.Comp.t
end
