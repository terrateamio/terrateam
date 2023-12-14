module At = Brtl_js2.Brr.At

let render_status status =
  let open Brtl_js2.Brr.El in
  div
    ~at:At.[ class' (Jstr.v "status") ]
    [
      div
        ~at:
          At.
            [
              class' (Jstr.v "material-icons");
              class'
                (Jstr.v
                   (match status with
                   | "aborted" -> "work-manifest-status-aborted"
                   | "completed" -> "work-manifest-status-completed"
                   | "queued" -> "work-manifest-status-queued"
                   | "running" -> "work-manifest-status-running"
                   | _ -> assert false));
            ]
        [
          span
            [
              txt'
                (match status with
                | "aborted" -> "cancel"
                | "completed" -> "done"
                | "queued" -> "pending"
                | "running" -> "autorenew"
                | _ -> assert false);
            ];
        ];
      div
        ~at:At.[ class' (Jstr.v "status-text") ]
        [
          txt'
            (match status with
            | "aborted" -> "Aborted"
            | "completed" -> "Done"
            | "queued" -> "Queued"
            | "running" -> "Running"
            | _ -> assert false);
        ];
    ]

let render_work_manifest_drift wm =
  let module Wm = Terrat_api_components.Installation_work_manifest_drift in
  let open Brtl_js2.Brr.El in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       [
         render_status wm.Wm.state;
         div ~at:At.[ class' (Jstr.v "h-pair") ] [ div [ txt' "Type" ]; div [ txt' "Drift" ] ];
       ])

let render_work_manifest_pull_request wm =
  let module Wm = Terrat_api_components.Installation_work_manifest_pull_request in
  let module Dirspace = Terrat_api_components.Work_manifest_dirspace in
  let open Brtl_js2.Brr.El in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       [
         render_status wm.Wm.state;
         div
           ~at:At.[ class' (Jstr.v "details") ]
           [
             div
               ~at:At.[ class' (Jstr.v "h-pair") ]
               [
                 div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Operation" ];
                 div [ txt' wm.Wm.run_type ];
               ];
             div
               ~at:At.[ class' (Jstr.v "h-pair") ]
               [
                 div ~at:At.[ class' (Jstr.v "name") ] [ txt' "User" ];
                 div [ txt' (CCOption.get_or ~default:"" wm.Wm.user) ];
               ];
             div
               ~at:At.[ class' (Jstr.v "h-pair") ]
               [
                 div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Commit" ];
                 div ~at:At.[ class' (Jstr.v "commit-sha") ] [ txt' wm.Wm.ref_ ];
               ];
             div
               ~at:At.[ class' (Jstr.v "h-pair") ]
               [
                 div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Created At" ];
                 div [ txt' Brtl_js2_datetime.(to_yyyy_mm_dd_hh_mm (of_string wm.Wm.created_at)) ];
               ];
             div
               ~at:At.[ class' (Jstr.v "h-pair") ]
               [
                 div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Completed At" ];
                 div
                   [
                     txt'
                       (CCOption.map_or
                          ~default:"--"
                          CCFun.(Brtl_js2_datetime.(of_string %> to_yyyy_mm_dd_hh_mm))
                          wm.Wm.completed_at);
                   ];
               ];
             div
               ~at:At.[ class' (Jstr.v "h-pair") ]
               [
                 div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Action Logs" ];
                 div
                   [
                     CCOption.map_or
                       ~default:(txt' "--")
                       (fun run_id ->
                         a
                           ~at:
                             At.
                               [
                                 v (Jstr.v "target") (Jstr.v "_blank");
                                 href
                                   (Jstr.v
                                      (Printf.sprintf
                                         "https://github.com/%s/%s/actions/runs/%s"
                                         wm.Wm.owner
                                         wm.Wm.repo
                                         run_id));
                               ]
                           [ txt' run_id ])
                       wm.Wm.run_id;
                   ];
               ];
             div
               ~at:At.[ class' (Jstr.v "dirspace-table") ]
               ([
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "Dir" ];
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "Workspace" ];
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "Success" ];
                ]
               @ CCList.flat_map
                   (fun Dirspace.{ dir; workspace; success } ->
                     [
                       div [ txt' dir ];
                       div [ txt' workspace ];
                       div
                         [
                           span
                             ~at:
                               At.
                                 [
                                   class' (Jstr.v "material-icons");
                                   class'
                                     (Jstr.v
                                        (match success with
                                        | Some true -> "work-manifest-status-completed"
                                        | Some false -> "work-manifest-status-aborted"
                                        | None -> "work-manifest-status-running"));
                                 ]
                             [
                               txt'
                                 (match success with
                                 | Some true -> "check_circle"
                                 | Some false -> "cancel"
                                 | None -> "autorenew");
                             ];
                         ];
                     ])
                   wm.Wm.dirspaces);
           ];
       ])

let render_work_manifest wm state =
  let module Wm = Terrat_api_components.Installation_work_manifest in
  match wm with
  | Wm.Installation_work_manifest_drift wm -> render_work_manifest_drift wm
  | Wm.Installation_work_manifest_pull_request wm -> render_work_manifest_pull_request wm

let run dir pull_number state =
  let app_state = Brtl_js2.State.app_state state in
  let client = Terrat_ui_js_state.client app_state in
  let installation = Terrat_ui_js_state.selected_installation app_state in
  let module I = Terrat_api_components.Installation in
  let module Wm = Terrat_api_components.Installation_work_manifest in
  let module Page = Terrat_ui_js_comp_page.Make (struct
    type elt = Wm.t
    type state = Terrat_ui_js_state.t

    let class' = "work-manifests"
    let page_param = "page"

    let fetch ?page () =
      Terrat_ui_js_client.work_manifests
        ?page
        ?pull_number
        ?dir
        ~installation_id:installation.I.id
        client

    let render_elt state elt =
      Brtl_js2.Router_output.const
        state
        Brtl_js2.Brr.El.(div ~at:At.[ class' (Jstr.v "item") ] [])
        (render_work_manifest elt)

    let equal = Wm.equal
  end) in
  Page.run state
