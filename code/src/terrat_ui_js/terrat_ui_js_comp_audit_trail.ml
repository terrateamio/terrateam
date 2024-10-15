module At = Brtl_js2.Brr.At

let render_work_manifest_drift github_web_base_url wm =
  let module Wm = Terrat_api_components.Installation_work_manifest_drift in
  let module Dirspace = Terrat_api_components.Work_manifest_dirspace in
  let open Brtl_js2.Brr.El in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       [
         div
           ~at:At.[ class' (Jstr.v "details") ]
           [
             h1 [ txt' "Drift" ];
             div
               ~at:At.[ class' (Jstr.v "attrs") ]
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
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "State" ];
                     div [ txt' wm.Wm.state ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Created At" ];
                     div
                       [ txt' Brtl_js2_datetime.(to_yyyy_mm_dd_hh_mm (of_string wm.Wm.created_at)) ];
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
                                             "%s/%s/%s/actions/runs/%s"
                                             github_web_base_url
                                             wm.Wm.owner
                                             wm.Wm.repo
                                             run_id));
                                   ]
                               [ txt' run_id ])
                           wm.Wm.run_id;
                       ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Environment" ];
                     div [ txt' (CCOption.get_or ~default:"" wm.Wm.environment) ];
                   ];
               ];
             div
               ~at:At.[ class' (Jstr.v "dirspace-table") ]
               ([
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "Dir" ];
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "Workspace" ];
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "State" ];
                ]
               @ CCList.flat_map
                   (fun Dirspace.{ dir; workspace; success } ->
                     [
                       div [ txt' dir ];
                       div [ txt' workspace ];
                       div
                         [
                           txt'
                             (match (wm.Wm.state, success) with
                             | _, Some true -> "Success"
                             | _, Some false -> "Fail"
                             | ("queued" | "running"), None -> "Running"
                             | _, _ -> "--");
                         ];
                     ])
                   wm.Wm.dirspaces);
           ];
       ])

let render_work_manifest_pull_request github_web_base_url wm =
  let module Wm = Terrat_api_components.Installation_work_manifest_pull_request in
  let module Dirspace = Terrat_api_components.Work_manifest_dirspace in
  let open Brtl_js2.Brr.El in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       [
         div
           ~at:At.[ class' (Jstr.v "details") ]
           [
             h1 [ txt' (CCOption.get_or ~default:"" wm.Wm.pull_request_title) ];
             div
               ~at:At.[ class' (Jstr.v "attrs") ]
               [
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Pull Request" ];
                     div
                       [
                         a
                           ~at:
                             At.
                               [
                                 v (Jstr.v "target") (Jstr.v "_blank");
                                 href
                                   (Jstr.v
                                      (Printf.sprintf
                                         "%s/%s/%s/pull/%d"
                                         github_web_base_url
                                         wm.Wm.owner
                                         wm.Wm.repo
                                         wm.Wm.pull_number));
                               ]
                           [ txt' (Jstr.to_string (Jstr.of_int wm.Wm.pull_number)) ];
                       ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Operation" ];
                     div [ txt' wm.Wm.run_type ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Repo" ]; div [ txt' wm.Wm.repo ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "State" ];
                     div [ txt' wm.Wm.state ];
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
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Branch" ];
                     div ~at:At.[ class' (Jstr.v "commit-sha") ] [ txt' wm.Wm.branch ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Created At" ];
                     div
                       [ txt' Brtl_js2_datetime.(to_yyyy_mm_dd_hh_mm (of_string wm.Wm.created_at)) ];
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
                                             "%s/%s/%s/actions/runs/%s"
                                             github_web_base_url
                                             wm.Wm.owner
                                             wm.Wm.repo
                                             run_id));
                                   ]
                               [ txt' run_id ])
                           wm.Wm.run_id;
                       ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Environment" ];
                     div [ txt' (CCOption.get_or ~default:"" wm.Wm.environment) ];
                   ];
               ];
             div
               ~at:At.[ class' (Jstr.v "dirspace-table") ]
               ([
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "Dir" ];
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "Workspace" ];
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "State" ];
                ]
               @ CCList.flat_map
                   (fun Dirspace.{ dir; workspace; success } ->
                     [
                       div [ txt' dir ];
                       div [ txt' workspace ];
                       div
                         [
                           txt'
                             (match (wm.Wm.state, success) with
                             | _, Some true -> "Success"
                             | _, Some false -> "Fail"
                             | ("queued" | "running"), None -> "Running"
                             | _, _ -> "--");
                         ];
                     ])
                   (CCList.sort
                      (fun Dirspace.{ dir = dir1; _ } Dirspace.{ dir = dir2; _ } ->
                        CCString.compare dir1 dir2)
                      wm.Wm.dirspaces));
           ];
       ])

let render_work_manifest_index github_web_base_url wm =
  let module Wm = Terrat_api_components.Installation_work_manifest_index in
  let module Dirspace = Terrat_api_components.Work_manifest_dirspace in
  let open Brtl_js2.Brr.El in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       [
         div
           ~at:At.[ class' (Jstr.v "details") ]
           [
             h1 [ txt' (CCOption.get_or ~default:"" wm.Wm.pull_request_title) ];
             div
               ~at:At.[ class' (Jstr.v "attrs") ]
               [
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Pull Request" ];
                     div
                       [
                         a
                           ~at:
                             At.
                               [
                                 v (Jstr.v "target") (Jstr.v "_blank");
                                 href
                                   (Jstr.v
                                      (Printf.sprintf
                                         "%s/%s/%s/pull/%d"
                                         github_web_base_url
                                         wm.Wm.owner
                                         wm.Wm.repo
                                         wm.Wm.pull_number));
                               ]
                           [ txt' (Jstr.to_string (Jstr.of_int wm.Wm.pull_number)) ];
                       ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Operation" ];
                     div [ txt' "index" ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Repo" ]; div [ txt' wm.Wm.repo ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "State" ];
                     div [ txt' wm.Wm.state ];
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
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Branch" ];
                     div ~at:At.[ class' (Jstr.v "commit-sha") ] [ txt' wm.Wm.branch ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "h-pair") ]
                   [
                     div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Created At" ];
                     div
                       [ txt' Brtl_js2_datetime.(to_yyyy_mm_dd_hh_mm (of_string wm.Wm.created_at)) ];
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
                                             "%s/%s/%s/actions/runs/%s"
                                             github_web_base_url
                                             wm.Wm.owner
                                             wm.Wm.repo
                                             run_id));
                                   ]
                               [ txt' run_id ])
                           wm.Wm.run_id;
                       ];
                   ];
               ];
             div
               ~at:At.[ class' (Jstr.v "dirspace-table") ]
               ([
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "Dir" ];
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "Workspace" ];
                  div ~at:At.[ class' (Jstr.v "table-header") ] [ txt' "State" ];
                ]
               @ CCList.flat_map
                   (fun Dirspace.{ dir; workspace; success } ->
                     [
                       div [ txt' dir ];
                       div [ txt' workspace ];
                       div
                         [
                           txt'
                             (match (wm.Wm.state, success) with
                             | _, Some true -> "Success"
                             | _, Some false -> "Fail"
                             | ("queued" | "running"), None -> "Running"
                             | _, _ -> "--");
                         ];
                     ])
                   (CCList.sort
                      (fun Dirspace.{ dir = dir1; _ } Dirspace.{ dir = dir2; _ } ->
                        CCString.compare dir1 dir2)
                      wm.Wm.dirspaces));
           ];
       ])

let render_work_manifest wm state =
  let module Sc = Terrat_api_components.Server_config in
  let module Wm = Terrat_api_components.Installation_work_manifest in
  let app_state = Brtl_js2.State.app_state state in
  let server_config = Terrat_ui_js_state.server_config app_state in
  let github_web_base_url = server_config.Sc.github_web_base_url in
  match wm with
  | Wm.Installation_work_manifest_drift wm -> render_work_manifest_drift github_web_base_url wm
  | Wm.Installation_work_manifest_pull_request wm ->
      render_work_manifest_pull_request github_web_base_url wm
  | Wm.Installation_work_manifest_index wm -> render_work_manifest_index github_web_base_url wm

let query_help =
  let open Brtl_js2.Brr.El in
  div
    ~at:At.[ class' (Jstr.v "tql-help") ]
    [
      div [ txt' "Searches are written in the Tag Query Language." ];
      div
        [
          ul
            [
              li [ code [ txt' "pr:123" ]; txt' " - Match a pull request number" ];
              li
                [
                  code [ txt' "state:completed" ];
                  txt' " - Match states, valid options ";
                  code [ txt' "running" ];
                  txt' ", ";
                  code [ txt' "completed" ];
                  txt' ", ";
                  code [ txt' "failed" ];
                  txt' ", ";
                  code [ txt' "aborted" ];
                  txt' ".";
                ];
              li [ code [ txt' "repo:foo" ]; txt' " - Match a repository." ];
              li [ code [ txt' "user:joe" ]; txt' " - Match a user." ];
              li
                [
                  code [ txt' "dir:path/to/dir" ];
                  txt' " - Match those operations which processed the directory.";
                ];
              li
                [
                  code [ txt' "type:plan" ];
                  txt' " - Match type of run, valid options are ";
                  code [ txt' "plan" ];
                  txt' " and ";
                  code [ txt' "apply" ];
                  txt' ".";
                ];
              li
                [
                  code [ txt' "kind:pr" ];
                  txt' " - Match kind of run, valid options are ";
                  code [ txt' "pr" ];
                  txt' " and ";
                  code [ txt' "drift" ];
                  txt' ".";
                ];
              li [ code [ txt' "branch:my-branch" ]; txt' " - Match a branch." ];
              li
                [
                  code [ txt' "workspace:default" ];
                  txt' " - Match those operations which processed the specified workspace.";
                ];
              li
                [
                  code [ txt' "created_at:2023-12-21" ];
                  txt' " - Match those operations performed on the specified date.";
                ];
              li
                [
                  code [ txt' "created_at:2023-12-21..2023-12-25" ];
                  txt'
                    " - Match those operations performed between the specified dates.  The query \
                     is inclusive for the first date an exclusive for the second date.  The first \
                     or second date may be omitted.";
                ];
              li
                [
                  code [ txt' "\"created_at:2023-12-21 14:51\"" ];
                  txt' " - Match those operations performed on the specified date and time.  ";
                  span
                    ~at:At.[ class' (Jstr.v "font-semibold") ]
                    [ txt' "Note: the quotes are important" ];
                ];
              li
                [
                  code [ txt' "\"created_at:2023-12-21 12:00..2023-12-25 19:00\"" ];
                  txt'
                    " - Match those operations performed between the specified dates and time.  \
                     The query is inclusive for the first datetime an exclusive for the second \
                     datetime.  The first or second datetime may be omitted.  ";
                  span
                    ~at:At.[ class' (Jstr.v "font-semibold") ]
                    [ txt' "Note: the quotes are important" ];
                ];
              li [ code [ txt' "environment:production" ]; txt' " - Match an environment." ];
              li
                [
                  code [ txt' "environment:" ]; txt' " - Match runs with no environment specified.";
                ];
              li
                [
                  code [ txt' "sort:asc" ];
                  txt' " - Sort the results by ";
                  code [ txt' "created_at" ];
                  txt' " in ascending order.  Valid options ";
                  code [ txt' "asc" ];
                  txt' ", ";
                  code [ txt' "desc" ];
                  txt' ".";
                ];
            ];
        ];
      div [ txt' "Example queries" ];
      div
        [
          ul
            [
              li
                [
                  code
                    [ txt' "state:completed and repo:infrastructure and (user:joe or user:tammy)" ];
                  txt'
                    " - All operations that are completed and in the 'infrastructure' repository \
                     executed by useres 'joe' or 'tammy'";
                ];
              li
                [
                  code [ txt' "created_at:2023-12-01.. and kind:drift" ];
                  txt' " - All drift operations performed between '2023-12-01' and now.";
                ];
              li
                [
                  code [ txt' "dir:infra/s3 and dir:infra/iam and kind:pr and sort:asc" ];
                  txt'
                    " - All pull request operations that were performed on the 'infra/s3' and the \
                     'infra/iam' directories and sort the results by oldest first.";
                ];
            ];
        ];
    ]

let comp state =
  let app_state = Brtl_js2.State.app_state state in
  let consumed_path = Brtl_js2.State.consumed_path state in
  let client = Terrat_ui_js_state.client app_state in
  let installation = Terrat_ui_js_state.selected_installation app_state in
  let module I = Terrat_api_components.Installation in
  let module Wm = Terrat_api_components.Installation_work_manifest in
  let module Page = Brtl_js2_page.Make (struct
    type fetch_err = Terrat_ui_js_client.work_manifests_err [@@deriving show]
    type elt = Wm.t [@@deriving eq, show]
    type state = Terrat_ui_js_state.t

    type query = {
      page : string list option;
      q : string option;
    }
    [@@deriving eq]

    let class' = "work-manifests"

    let query =
      let rt =
        Brtl_js2_rtng.(
          root consumed_path
          /? Query.(option (array (string "page")))
          /? Query.(option (string "q")))
      in
      Brtl_js2_rtng.(rt --> fun page q -> { page; q })

    let make_uri { page; q } uri =
      let uri =
        match page with
        | Some page -> Uri.add_query_param (Uri.remove_query_param uri "page") ("page", page)
        | None -> Uri.remove_query_param uri "page"
      in
      let uri =
        match q with
        | Some query -> Uri.add_query_param' (Uri.remove_query_param uri "q") ("q", query)
        | None -> Uri.remove_query_param uri "q"
      in
      uri

    let set_page page query = { query with page }

    let fetch { page; q } =
      let tz = Brtl_js2_datetime.timezone () in
      Terrat_ui_js_client.work_manifests ?page ?q ~tz ~installation_id:installation.I.id client

    let wrap_page query = CCFun.id

    let render_elt state query elt =
      [
        Brtl_js2.Router_output.const
          state
          Brtl_js2.Brr.El.(div ~at:At.[ class' (Jstr.v "item") ] [])
          (render_work_manifest elt);
      ]

    let search_comp (set_query : query Brtl_js2.Note.S.set) query state =
      let query = CCOption.get_or ~default:"" query in
      let input =
        Brtl_js2.Kit.Ui.Input.v
          ~class':(Jstr.v "input-primary")
          ~placeholder:(Jstr.v "Search...")
          (Brtl_js2.Note.S.const ~eq:( = ) (Jstr.v query))
      in
      let input_el = Brtl_js2.Kit.Ui.Input.el input in
      let search_btn =
        Brtl_js2.Brr.El.button
          ~at:At.[ class' (Jstr.v "btn-search"); type' (Jstr.v "submit") ]
          Brtl_js2.Brr.El.[ txt' "Search" ]
      in
      let clear_btn =
        Brtl_js2.Kit.Ui.Button.v'
          ~class':(Jstr.v "btn-clear")
          ~enabled:(Brtl_js2.Note.S.const ~eq:CCBool.equal (query <> ""))
          ~action:(fun () ->
            set_query { q = None; page = None };
            Abb_js.Future.return ())
          (Brtl_js2.Note.S.const ~eq:( == ) Brtl_js2.Brr.El.[ txt' "Clear" ])
          ()
      in
      let search_form =
        Brtl_js2.Brr.El.form [ input_el; search_btn; Brtl_js2.Kit.Ui.Button.el clear_btn ]
      in
      let logr =
        Brtl_js2.Note.E.log
          (Brtl_js2.R.Evr.on_el
             Brtl_js2.Io.Form.Ev.submit
             (Brtl_js2.R.Evr.instruct ~default:false)
             search_form)
          (fun () ->
            set_query { q = Some (Jstr.to_string (Brtl_js2.Kit.Ui.Input.value input)); page = None })
      in
      Abb_js.Future.return
        (Brtl_js2.Output.const
           ~cleanup:(fun () ->
             Brtl_js2.Note.Logr.destroy' logr;
             Abb_js.Future.return ())
           [ search_form ])

    let format_err =
      let module El = Brtl_js2.Brr.El in
      let module Br = Terrat_api_installations.List_work_manifests.Responses.Bad_request in
      function
      | `Bad_request Br.{ id = "IN_DIR_NOT_SUPPORTED"; _ } ->
          El.[ txt' "The 'in dir' operator is not supported" ]
      | `Bad_request Br.{ id = "BAD_DATE_FORMAT"; data = Some data } ->
          El.[ txt' ("Invalid date format: " ^ data) ]
      | `Bad_request Br.{ id = "UNKNOWN_TAG"; data = Some data } ->
          El.[ txt' ("Unknown tag: " ^ data) ]
      | `Bad_request Br.{ id = "PARSE_ERROR"; data = Some data } ->
          El.[ txt' ("Could not parse query: " ^ data) ]
      | `Bad_request Br.{ id = "STATEMENT_TIMEOUT"; _ } -> El.[ txt' "Query timed out" ]
      | `Io_err err -> El.[ txt' ("Query failed: " ^ Jstr.to_string (Jv.Error.message err)) ]
      | (`Not_found | `Conversion_err _ | `Missing_response _ | `Forbidden | `Bad_request _) as err
        -> El.[ txt' ("Unknown error: " ^ show_fetch_err err) ]

    let error fetch_err =
      let el = Brtl_js2.Brr.El.div ~at:At.[ class' (Jstr.v "error") ] [] in
      Brtl_js2.R.Elr.def_children
        el
        (Brtl_js2.Note.S.hold ~eq:( = ) []
        @@ Brtl_js2.Note.E.map
             (function
               | None -> []
               | Some err -> format_err err)
             fetch_err);
      el

    let query_comp' set_query fetch_err state =
      let query_rt () = Brtl_js2_rtng.(root consumed_path /? Query.(option (string "q"))) in
      Abb_js.Future.return
        (Brtl_js2.Output.const
           Brtl_js2.Brr.El.
             [
               Brtl_js2.Router_output.create
                 state
                 (div [])
                 Brtl_js2_rtng.[ query_rt () --> search_comp set_query ];
               error fetch_err;
               details [ summary [ txt' "Learn how to write queries" ]; query_help ];
             ])

    let query_comp = Some query_comp'
  end) in
  Page.run state

let ph_loading =
  Brtl_js2.Brr.El.
    [
      div
        ~at:At.[ class' (Jstr.v "loading") ]
        [ span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "autorenew" ] ];
    ]

let run = Brtl_js2.Ph.create ph_loading comp
