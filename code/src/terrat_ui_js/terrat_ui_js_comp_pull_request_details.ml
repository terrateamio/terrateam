module At = Brtl_js2.Brr.At

let run pull_number state =
  let module I = Terrat_api_components.Installation in
  let open Abb_js.Future.Infix_monad in
  let app_state = Brtl_js2.State.app_state state in
  let client = Terrat_ui_js_state.client app_state in
  let installation = Terrat_ui_js_state.selected_installation app_state in
  Terrat_ui_js_client.pull_requests ~pull_number ~installation_id:installation.I.id client
  >>= function
  | Ok page -> (
      match Terrat_ui_js_client.Page.page page with
      | pr :: _ ->
          Abb_js.Future.return
            (Brtl_js2.Output.const
               Brtl_js2.Brr.El.
                 [
                   div ~at:At.[ class' (Jstr.v "details-header") ] [ txt' "Pull Request Details" ];
                   div
                     ~at:At.[ class' (Jstr.v "pull-requests") ]
                     [
                       div
                         ~at:At.[ class' (Jstr.v "page") ]
                         [
                           Brtl_js2.Router_output.const
                             state
                             (div ~at:At.[ class' (Jstr.v "item") ] [])
                             (Terrat_ui_js_comp_pull_request.run None pr);
                         ];
                     ];
                   div ~at:At.[ class' (Jstr.v "details-header") ] [ txt' "Operations" ];
                   Brtl_js2.Router_output.const
                     state
                     (div [])
                     (Terrat_ui_js_comp_work_manifests.run (Some `Asc) (Some pull_number));
                 ])
      | [] ->
          Brtl_js2.Brr.Console.(log [ Jstr.v "No matching pull request found" ]);
          Abb_js.Future.return
            (Brtl_js2.Output.const Brtl_js2.Brr.El.[ txt' "No matching pull request found" ]))
  | Error err ->
      Brtl_js2.Brr.Console.(
        log [ Jstr.v "Failed to load pull requests"; Jstr.v (Terrat_ui_js_client.show_err err) ]);
      Abb_js.Future.return
        (Brtl_js2.Output.const Brtl_js2.Brr.El.[ txt' "Error loading pull requests" ])
