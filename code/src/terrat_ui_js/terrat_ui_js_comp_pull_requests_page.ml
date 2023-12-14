module At = Brtl_js2.Brr.At

let run (pr_send : Terrat_api_components.Installation_pull_request.t Brtl_js2.Note.E.send) state =
  let app_state = Brtl_js2.State.app_state state in
  let client = Terrat_ui_js_state.client app_state in
  let installation = Terrat_ui_js_state.selected_installation app_state in
  let module I = Terrat_api_components.Installation in
  let module Pr = Terrat_api_components.Installation_pull_request in
  let module Page = Terrat_ui_js_comp_page.Make (struct
    type elt = Pr.t
    type state = Terrat_ui_js_state.t

    let class' = "pull-requests"
    let page_param = "page"

    let fetch ?page () =
      Terrat_ui_js_client.pull_requests ?page ~installation_id:installation.I.id client

    let render_elt state pr =
      Brtl_js2.Router_output.const
        state
        Brtl_js2.Brr.El.(div ~at:At.[ class' (Jstr.v "item") ] [])
        (Terrat_ui_js_comp_pull_request.run (Some pr_send) pr)

    let equal = Pr.equal
  end) in
  Page.run state
