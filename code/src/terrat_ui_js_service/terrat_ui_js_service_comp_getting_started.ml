module At = Brtl_js2.Brr.At

module Make (Vcs : Terrat_ui_js_service_vcs.S) = struct
  module State = Terrat_ui_js_service_state.Make (Vcs)

  let run state =
    let app_state = Brtl_js2.State.app_state state in
    let vcs = app_state.State.vcs in
    Abb_js.Future.return
    @@ Brtl_js2.Output.const
    @@ Brtl_js2.Brr.El.
         [
           Brtl_js2.Router_output.const
             (Brtl_js2.State.with_app_state vcs state)
             (div ~at:At.[ class' @@ Jstr.v "getting-started" ] [])
             Vcs.Comp.Getting_started.run;
         ]
end
