module At = Brtl_js2.Brr.At

let run (pr_send : Terrat_api_components.Installation_pull_request.t Brtl_js2.Note.E.send) state =
  let app_state = Brtl_js2.State.app_state state in
  let consumed_path = Brtl_js2.State.consumed_path state in
  let client = Terrat_ui_js_state.client app_state in
  let installation = Terrat_ui_js_state.selected_installation app_state in
  let module I = Terrat_api_components.Installation in
  let module Pr = Terrat_api_components.Installation_pull_request in
  let module Page = Terrat_ui_js_comp_page.Make (struct
    type elt = Pr.t [@@deriving eq]
    type state = Terrat_ui_js_state.t
    type query = { page : string list option } [@@deriving eq]

    let class' = "pull-requests"

    let query =
      let rt = Brtl_js2_rtng.(root consumed_path /? Query.(option (array (string "page")))) in
      Brtl_js2_rtng.(rt --> fun page -> { page })

    let make_uri { page } uri =
      match page with
      | Some page -> Uri.add_query_param (Uri.remove_query_param uri "page") ("page", page)
      | None -> Uri.remove_query_param uri "page"

    let set_page page _ = { page }

    let fetch { page } =
      Terrat_ui_js_client.pull_requests ?page ~installation_id:installation.I.id client

    let wrap_page = CCFun.id

    let render_elt state pr =
      [
        Brtl_js2.Router_output.const
          state
          Brtl_js2.Brr.El.(div ~at:At.[ class' (Jstr.v "item") ] [])
          (Terrat_ui_js_comp_pull_request.run (Some pr_send) pr);
      ]

    let query_comp = None
  end) in
  Page.run state
