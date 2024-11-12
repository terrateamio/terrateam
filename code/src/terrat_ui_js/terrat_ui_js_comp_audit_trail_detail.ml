module At = Brtl_js2.Brr.At

module Output = struct
  module O = Terrat_api_components.Installation_workflow_step_output

  module Scope = struct
    type hook =
      | Pre
      | Post
    [@@deriving eq]

    type t =
      | Dirspace of Terrat_dirspace.t
      | Hook of hook
    [@@deriving eq]
  end

  type t =
    | Scope of Scope.t
    | Output of O.t
    | Payload of (string * Yojson.Safe.t)
  [@@deriving eq]
end

module Ots = struct
  (* Output treeview state *)
  type t = {
    installation_id : string;
    work_manifest_id : string;
    client : Terrat_ui_js_client.t;
  }
end

module Payload = struct
  module Plan = struct
    type t = {
      cmd : string list option; [@default None]
      exit_code : int option; [@default None]
      has_changes : bool option; [@default None]
      plan : string option; [@default None]
      text : string;
    }
    [@@deriving of_yojson { strict = false }]
  end

  module Apply = struct
    type t = {
      cmd : string list option;
      exit_code : int option; [@default None]
      outputs : Yojson.Safe.t option; [@default None]
      text : string;
    }
    [@@deriving of_yojson { strict = false }]
  end

  module Run = struct
    type t = {
      exit_code : int option; [@default None]
      cmd : string list;
      text : string option; [@default None]
    }
    [@@deriving of_yojson { strict = false }]
  end

  module Text = struct
    type t = { text : string } [@@deriving of_yojson { strict = false }]
  end

  module Cost_estimation = struct
    module Summary = struct
      type t = {
        diff_monthly_cost : float;
        prev_monthly_cost : float;
        total_monthly_cost : float;
      }
      [@@deriving of_yojson { strict = false }]
    end

    module Dirspace = struct
      type t = {
        diff_monthly_cost : float;
        prev_monthly_cost : float;
        total_monthly_cost : float;
        dir : string;
        workspace : string;
      }
      [@@deriving of_yojson { strict = false }]
    end

    type t = {
      summary : Summary.t;
      dirspaces : Dirspace.t list;
      currency : string;
    }
    [@@deriving of_yojson { strict = false }]
  end
end

module Output_treeview = Brtl_js2_treeview.Make (struct
  type state = Ots.t
  type node = Output.t [@@deriving eq]
  type fetch_nodes_err = Terrat_ui_js_client.work_manifest_outputs_err

  let class' = "treeview"

  let fetch_outputs ?filter client installation_id work_manifest_id query =
    let open Abb_js_future_combinators.Infix_result_monad in
    Terrat_ui_js_client.work_manifest_outputs
      ~limit:100
      ~q:query
      ~installation_id
      ~work_manifest_id
      client
    >>= fun page ->
    let nodes =
      CCList.filter_map
        (fun output ->
          match filter with
          | Some filter when filter output ->
              Some (Brtl_js2_treeview.Node.Branch (Output.Output output))
          | None -> Some (Brtl_js2_treeview.Node.Branch (Output.Output output))
          | Some _ -> None)
        (Brtl_js2_page.Page.page page)
    in
    Abb_js.Future.return (Ok nodes)

  let fetch_nodes state =
    let app_state = Brtl_js2.State.app_state state in
    let { Ots.installation_id; work_manifest_id; client } = app_state in
    function
    | Output.(Scope Scope.(Dirspace { Terrat_dirspace.dir; workspace })) ->
        fetch_outputs
          client
          installation_id
          work_manifest_id
          ("scope:dirspace and dir:" ^ dir ^ " and workspace:" ^ workspace)
    | Output.(Scope Scope.(Hook Pre)) ->
        let module O = Terrat_api_components.Installation_workflow_step_output in
        fetch_outputs
          ~filter:(fun { O.step; _ } -> step <> "cost_estimation")
          client
          installation_id
          work_manifest_id
          "scope:run and flow:hooks and subflow:pre"
    | Output.(Scope Scope.(Hook Post)) ->
        fetch_outputs
          client
          installation_id
          work_manifest_id
          "scope:run and flow:hooks and subflow:post"
    | Output.Output step ->
        let module O = Terrat_api_components.Installation_workflow_step_output in
        Abb_js.Future.return
          (Ok
             [
               Brtl_js2_treeview.Node.Leaf
                 (Output.Payload (step.O.step, O.Payload.to_yojson step.O.payload));
             ])
    | Output.Payload _ -> assert false

  let render_payload_cost_estimation payload =
    let open CCResult.Infix in
    let module P = Payload.Cost_estimation in
    P.of_yojson payload
    >>= fun { P.currency; dirspaces; summary = ce_summary } ->
    Ok
      Brtl_js2.Brr.El.
        [
          div
            ~at:At.[ class' (Jstr.v "cost-estimation"); class' (Jstr.v "summary") ]
            [
              div
                [
                  div
                    ~at:At.[ class' (Jstr.v "heading") ]
                    [ txt' (Printf.sprintf "Previous Total Monthly Cost (%s)" currency) ];
                  div
                    ~at:At.[ class' (Jstr.v "heading") ]
                    [ txt' (Printf.sprintf "Difference (%s)" currency) ];
                  div
                    ~at:At.[ class' (Jstr.v "heading") ]
                    [ txt' (Printf.sprintf "Total Monthly Cost (%s)" currency) ];
                  div [ txt' (Printf.sprintf "%0.02f" ce_summary.P.Summary.prev_monthly_cost) ];
                  div [ txt' (Printf.sprintf "%0.02f" ce_summary.P.Summary.diff_monthly_cost) ];
                  div [ txt' (Printf.sprintf "%0.02f" ce_summary.P.Summary.total_monthly_cost) ];
                ];
            ];
        ]

  let render_payload_plan payload =
    let open CCResult.Infix in
    let module P = Payload.Plan in
    P.of_yojson payload
    >>= function
    | { P.cmd; exit_code; has_changes; text = _; plan = Some text }
    | { P.cmd; exit_code; has_changes; text; plan = None } ->
        let text = CCString.trim text in
        let is_plan = exit_code = Some 0 || exit_code = Some 2 in
        let text_el =
          if is_plan then (
            let code_el = Brtl_js2.Brr.El.code [] in
            let code_el_js = Brtl_js2.Brr.El.to_jv code_el in
            let code =
              Hljs.highlight (Hljs.Opts.make ~language:"diff" ()) (Terrat_plan_diff.transform text)
            in
            Jv.set code_el_js "innerHTML" (Jv.of_string code);
            Brtl_js2.Brr.El.(pre [ code_el ]))
          else Brtl_js2.Brr.El.(pre [ txt' text ])
        in
        Ok
          Brtl_js2.Brr.El.(
            CCList.flatten
              [
                CCOption.map_or
                  ~default:[]
                  (fun cmd ->
                    [
                      div
                        ~at:At.[ class' (Jstr.v "cmd") ]
                        [ div [ txt' "Command" ]; div [ div [ txt' (CCString.concat " " cmd) ] ] ];
                    ])
                  cmd;
                CCOption.map_or
                  ~default:[]
                  (fun has_changes ->
                    [
                      div
                        ~at:At.[ class' (Jstr.v "exit-code") ]
                        [
                          div [ txt' "Has changes" ];
                          div [ div [ txt' (if has_changes then "Yes" else "No") ] ];
                        ];
                    ])
                  has_changes;
                CCOption.map_or
                  ~default:[]
                  (fun exit_code ->
                    [
                      div
                        ~at:At.[ class' (Jstr.v "exit-code") ]
                        [
                          div [ txt' "Exit code" ]; div [ div [ txt' (CCInt.to_string exit_code) ] ];
                        ];
                    ])
                  exit_code;
                [ div ~at:At.[ class' (Jstr.v "text") ] [ text_el ] ];
              ])

  let render_payload_apply payload =
    let open CCResult.Infix in
    let module P = Payload.Apply in
    P.of_yojson payload
    >>= function
    | { P.cmd; exit_code; outputs; text } ->
        Ok
          Brtl_js2.Brr.El.(
            CCList.flatten
              [
                CCOption.map_or
                  ~default:[]
                  (fun cmd ->
                    [
                      div
                        ~at:At.[ class' (Jstr.v "cmd") ]
                        [ div [ txt' "Command" ]; div [ div [ txt' (CCString.concat " " cmd) ] ] ];
                    ])
                  cmd;
                CCOption.map_or
                  ~default:[]
                  (fun exit_code ->
                    [
                      div
                        ~at:At.[ class' (Jstr.v "exit-code") ]
                        [
                          div [ txt' "Exit code" ]; div [ div [ txt' (CCInt.to_string exit_code) ] ];
                        ];
                    ])
                  exit_code;
                [ div ~at:At.[ class' (Jstr.v "text") ] [ txt' text ] ];
                CCOption.map_or
                  ~default:[]
                  (fun outputs ->
                    let outputs_el =
                      let code_el = Brtl_js2.Brr.El.code [] in
                      let code_el_js = Brtl_js2.Brr.El.to_jv code_el in
                      let code =
                        Hljs.highlight
                          (Hljs.Opts.make ~language:"json" ())
                          (Yojson.Safe.pretty_to_string outputs)
                      in
                      Jv.set code_el_js "innerHTML" (Jv.of_string code);
                      Brtl_js2.Brr.El.(pre [ code_el ])
                    in
                    [ div ~at:At.[ class' (Jstr.v "text") ] [ outputs_el ] ])
                  outputs;
              ])

  let render_payload_run payload =
    let open CCResult.Infix in
    let module P = Payload.Run in
    P.of_yojson payload
    >>= fun { P.exit_code; cmd; text } ->
    Ok
      Brtl_js2.Brr.El.(
        CCList.flatten
          [
            [
              div
                ~at:At.[ class' (Jstr.v "cmd") ]
                [ div [ txt' "Command" ]; div [ div [ txt' (CCString.concat " " cmd) ] ] ];
            ];
            CCOption.map_or
              ~default:[]
              (fun exit_code ->
                [
                  div
                    ~at:At.[ class' (Jstr.v "exit-code") ]
                    [ div [ txt' "Exit code" ]; div [ div [ txt' (CCInt.to_string exit_code) ] ] ];
                ])
              exit_code;
            CCOption.map_or
              ~default:[]
              (fun text ->
                let text = CCString.trim text in
                [ div ~at:At.[ class' (Jstr.v "text") ] [ pre [ txt' text ] ] ])
              text;
          ])

  let render_payload_text payload =
    let open CCResult.Infix in
    let module P = Payload.Text in
    P.of_yojson payload
    >>= fun { P.text } ->
    let text = CCString.trim text in
    Ok Brtl_js2.Brr.El.[ div ~at:At.[ class' (Jstr.v "text") ] [ pre [ txt' text ] ] ]

  let render_payload_any payload =
    let code_el = Brtl_js2.Brr.El.code [] in
    let code_el_js = Brtl_js2.Brr.El.to_jv code_el in
    let code =
      Hljs.highlight (Hljs.Opts.make ~language:"json" ()) (Yojson.Safe.pretty_to_string payload)
    in
    Jv.set code_el_js "innerHTML" (Jv.of_string code);
    Brtl_js2.Brr.El.[ pre [ code_el ] ]

  let render_payload step payload =
    let run =
      match step with
      | "plan" -> render_payload_plan payload
      | "apply" -> render_payload_apply payload
      | "cost_estimation" -> render_payload_cost_estimation payload
      | step -> render_payload_run payload
    in
    match run with
    | Ok r -> r
    | Error _ -> (
        match render_payload_text payload with
        | Ok r -> r
        | Error _ -> render_payload_any payload)

  let render_output_cost_estimation output =
    let module O = Terrat_api_components.Installation_workflow_step_output in
    let module S = Terrat_api_components_workflow_step_output_scope in
    let { O.created_at = _; idx = _; ignore_errors = _; payload; scope = _; state = _; step = _ } =
      output
    in
    let module P = Payload.Cost_estimation in
    match P.of_yojson (O.Payload.to_yojson payload) with
    | Ok { P.summary = { P.Summary.total_monthly_cost; _ }; currency; _ } ->
        Brtl_js2.Brr.El.
          [
            div
              ~at:At.[ class' (Jstr.v "title"); class' (Jstr.v "cost-estimation") ]
              [
                div [ txt' "Cost Estimation" ];
                div [ txt' "Total Monthly Cost" ];
                div [ txt' (Printf.sprintf "%0.02f" total_monthly_cost) ];
                div [ txt' currency ];
              ];
          ]
    | Error _ ->
        Brtl_js2.Brr.El.[ div ~at:At.[ class' (Jstr.v "title") ] [ txt' "Cost Estimation" ] ]

  let render_output_any output =
    let module O = Terrat_api_components.Installation_workflow_step_output in
    let module S = Terrat_api_components_workflow_step_output_scope in
    let { O.created_at = _; idx = _; ignore_errors; payload = _; scope = _; state; step } =
      output
    in
    Brtl_js2.Brr.El.
      [
        div
          ~at:At.[ class' (Jstr.v "step") ]
          [
            div [ txt' "Step" ];
            div [ txt' step ];
            div [ txt' "State" ];
            div ~at:At.[ class' (Jstr.v "state"); class' (Jstr.v state) ] [ txt' state ];
          ];
      ]

  let render_output output =
    let module O = Terrat_api_components.Installation_workflow_step_output in
    match output.O.step with
    | "cost_estimation" -> render_output_cost_estimation output
    | _ -> render_output_any output

  let render_node' = function
    | Output.(Scope (Scope.Dirspace { Terrat_dirspace.dir; workspace })) ->
        Brtl_js2.Brr.El.
          [
            div
              ~at:At.[ class' (Jstr.v "title"); class' (Jstr.v "dirspace") ]
              [
                div [ txt' "Directory" ];
                div [ txt' dir ];
                div [ txt' "Workspace" ];
                div [ txt' workspace ];
              ];
          ]
    | Output.(Scope Scope.(Hook Pre)) ->
        Brtl_js2.Brr.El.[ div ~at:At.[ class' (Jstr.v "title") ] [ txt' "Pre Hooks" ] ]
    | Output.(Scope Scope.(Hook Post)) ->
        Brtl_js2.Brr.El.[ div ~at:At.[ class' (Jstr.v "title") ] [ txt' "Post Hooks" ] ]
    | Output.(Output output) -> render_output output
    | Output.(Payload (step, payload)) -> render_payload step payload

  let render_expander expanded =
    let icon = Tabler_icons_outline.plus () in
    Brtl_js2.R.Elr.def_class
      (Jstr.v "expanded")
      (Brtl_js2.Note.S.map ~eq:Bool.equal (( = ) `Expanded) expanded)
      icon;
    Brtl_js2.Note.S.const ~eq:( == ) [ icon ]

  let render_node node state =
    match node with
    | Brtl_js2_treeview.Node.Branch (expander, node) ->
        Abb_js.Future.return
          (Brtl_js2.Output.const
             Brtl_js2.Brr.El.
               [
                 div
                   ~at:At.[ class' (Jstr.v "expander") ]
                   [
                     Brtl_js2.Kit.Ui.(
                       Button.el
                         (Button.v'
                            ~action:(fun () ->
                              Brtl_js2_treeview.Expander.toggle expander;
                              Abb_js.Future.return ())
                            (render_expander (Brtl_js2_treeview.Expander.state_signal expander))
                            ()));
                   ];
                 div
                   [
                     div ~at:At.[ class' (Jstr.v "node") ] (render_node' node);
                     Brtl_js2.Router_output.const
                       state
                       Brtl_js2.Brr.El.(div ~at:At.[ class' (Jstr.v "child-node") ] [])
                       (Brtl_js2_treeview.Expander.comp expander);
                   ];
               ])
    | Brtl_js2_treeview.Node.Leaf node ->
        Abb_js.Future.return (Brtl_js2.Output.const (render_node' node))

  let render_fetch_nodes_err node err state =
    Abb_js.Future.return (Brtl_js2.Output.const Brtl_js2.Brr.El.[ div [ txt' "Error" ] ])
end)

let string_of_kind =
  let module Wm = Terrat_api_components.Installation_work_manifest in
  function
  | Wm.Kind.Kind_pull_request _ -> "pull-request"
  | Wm.Kind.Kind_drift _ -> "drift"
  | Wm.Kind.Kind_index _ -> "index"

let render_title github_web_base_url wm run_type =
  let module Wm = Terrat_api_components.Installation_work_manifest in
  let module P = Terrat_api_components_kind_pull_request in
  function
  | Wm.Kind.Kind_pull_request { P.pull_number; pull_request_title } ->
      Brtl_js2.Brr.El.
        [
          h2
            [
              div [ Tabler_icons_outline.git_pull_request () ];
              div [ txt' "Pull Request" ];
              div [ txt' (CCInt.to_string pull_number) ];
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
                              pull_number));
                    ]
                [ Tabler_icons_outline.external_link () ];
            ];
          h1 [ txt' (CCOption.get_or ~default:"" pull_request_title) ];
        ]
  | Wm.Kind.Kind_drift _ ->
      Brtl_js2.Brr.El.
        [ h2 [ div [ Tabler_icons_outline.arrow_ramp_right () ]; div [ txt' "Drift" ] ] ]
  | Wm.Kind.Kind_index _ ->
      Brtl_js2.Brr.El.[ h2 [ div [ Tabler_icons_outline.chart_dots_3 () ]; div [ txt' "Index" ] ] ]

let render_work_manifest state =
  let module Wm = Terrat_api_components.Installation_work_manifest in
  function
  | {
      Wm.base_branch;
      base_ref;
      branch;
      branch_ref;
      completed_at;
      created_at;
      dirspaces;
      environment;
      id = work_manifest_id;
      kind;
      owner;
      repo;
      run_id;
      run_type;
      state = work_manifest_state;
      tag_query;
      user;
    } as wm -> (
      let run =
        let open Abb_js_future_combinators.Infix_result_monad in
        let module Sc = Terrat_api_components.Server_config in
        let module I = Terrat_api_components.Installation in
        let module Ds = Terrat_api_components.Work_manifest_dirspace in
        let app_state = Brtl_js2.State.app_state state in
        let installation = Terrat_ui_js_state.selected_installation app_state in
        let installation_id = installation.I.id in
        let client = Terrat_ui_js_state.client app_state in
        let server_config = Terrat_ui_js_state.server_config app_state in
        let github_web_base_url = server_config.Sc.github_web_base_url in
        Abb_js_future_combinators.Infix_result_app.(
          (fun failed_runs header_steps -> (failed_runs, header_steps))
          <$> Terrat_ui_js_client.work_manifest_outputs
                ~q:"state:failure"
                ~limit:1
                ~installation_id
                ~work_manifest_id
                client
          <*> Terrat_ui_js_client.work_manifest_outputs
                ~q:"step:cost_estimation"
                ~installation_id
                ~work_manifest_id
                client)
        >>= fun (failed_runs, header_steps) ->
        let work_manifest_state =
          match work_manifest_state with
          | "completed" when CCList.is_empty (Brtl_js2_page.Page.page failed_runs) -> "success"
          | "completed" -> "failure"
          | any -> any
        in
        let outputs =
          CCList.map
            (fun step -> Brtl_js2_treeview.Node.Branch Output.(Output step))
            (Brtl_js2_page.Page.page header_steps)
          @ [ Brtl_js2_treeview.Node.Branch Output.(Scope Scope.(Hook Pre)) ]
          @ CCList.map
              (fun { Ds.dir; workspace; _ } ->
                Brtl_js2_treeview.Node.Branch
                  Output.(Scope (Scope.Dirspace { Terrat_dirspace.dir; workspace })))
              (CCList.sort
                 (fun { Ds.dir = d1; workspace = w1; _ } { Ds.dir = d2; workspace = w2; _ } ->
                   let module Cmp = struct
                     type t = string * string [@@deriving ord]
                   end in
                   Cmp.compare (d1, w1) (d2, w2))
                 dirspaces)
          @ [ Brtl_js2_treeview.Node.Branch Output.(Scope Scope.(Hook Post)) ]
        in
        Abb_js.Future.return
          (Ok
             (Brtl_js2.Output.const
                Brtl_js2.Brr.El.
                  [
                    div
                      ~at:At.[ class' (Jstr.v "details") ]
                      [
                        div
                          ~at:At.[ class' (Jstr.v "title"); class' (Jstr.v (string_of_kind kind)) ]
                          (render_title github_web_base_url wm run_type kind);
                        div [ div [ txt' "ID" ]; div [ txt' work_manifest_id ] ];
                        div
                          [
                            div [ txt' "State" ];
                            div
                              [
                                div
                                  ~at:
                                    At.
                                      [
                                        class' (Jstr.v "state"); class' (Jstr.v work_manifest_state);
                                      ]
                                  [ txt' work_manifest_state ];
                              ];
                          ];
                        div [ div [ txt' "Base Branch" ]; div [ txt' base_branch ] ];
                        div [ div [ txt' "Base Ref" ]; div [ txt' base_ref ] ];
                        div [ div [ txt' "Branch" ]; div [ txt' branch ] ];
                        div [ div [ txt' "Branch Ref" ]; div [ txt' branch_ref ] ];
                        div
                          [
                            div [ txt' "Created" ];
                            div
                              [
                                txt' Brtl_js2_datetime.(to_yyyy_mm_dd_hh_mm (of_string created_at));
                              ];
                          ];
                        div [ div [ txt' "Repo" ]; div [ txt' repo ] ];
                        div
                          [
                            div [ txt' "Completed" ];
                            div
                              [
                                txt'
                                  (CCOption.map_or
                                     ~default:""
                                     CCFun.(Brtl_js2_datetime.(of_string %> to_yyyy_mm_dd_hh_mm))
                                     completed_at);
                              ];
                          ];
                        div
                          [
                            div [ txt' "Environment" ];
                            div [ txt' (CCOption.get_or ~default:"" environment) ];
                          ];
                        div
                          [
                            div [ txt' "Run ID" ];
                            div
                              ~at:At.[ class' (Jstr.v "run-id") ]
                              (CCOption.map_or
                                 ~default:[]
                                 (fun run_id ->
                                   [
                                     div [ txt' run_id ];
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
                                                     owner
                                                     repo
                                                     run_id));
                                           ]
                                       [ Tabler_icons_outline.external_link () ];
                                   ])
                                 run_id);
                          ];
                        div [ div [ txt' "User" ]; div [ txt' (CCOption.get_or ~default:"" user) ] ];
                        div
                          [
                            div [ txt' "Tag Query" ];
                            div ~at:At.[ class' (Jstr.v "tag-query") ] [ txt' tag_query ];
                          ];
                      ];
                    div ~at:At.[ class' (Jstr.v "outputs-title") ] [ txt' "Outputs" ];
                    Brtl_js2.Router_output.const
                      (Brtl_js2.State.with_app_state
                         { Ots.client; installation_id; work_manifest_id }
                         state)
                      (div ~at:At.[ class' (Jstr.v "outputs") ] [])
                      (Output_treeview.run outputs);
                  ]))
      in
      let open Abb_js.Future.Infix_monad in
      run
      >>= function
      | Ok r -> Abb_js.Future.return r
      | Error _ -> raise (Failure "nyi"))

let work_manifest_comp installation_id work_manifest_id state =
  let app_state = Brtl_js2.State.app_state state in
  let client = Terrat_ui_js_state.client app_state in
  let open Abb_js.Future.Infix_monad in
  Terrat_ui_js_client.work_manifests ~q:("id:" ^ work_manifest_id) ~installation_id client
  >>= function
  | Ok page -> (
      match Brtl_js2_page.Page.page page with
      | wm :: _ -> render_work_manifest state wm
      | [] -> raise (Failure "nyi"))
  | Error _ -> raise (Failure "nyi")

let comp work_manifest_id state =
  let module I = Terrat_api_components.Installation in
  let app_state = Brtl_js2.State.app_state state in
  let installation = Terrat_ui_js_state.selected_installation app_state in
  let installation_id = installation.I.id in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       [
         Brtl_js2.Router_output.const
           state
           (Brtl_js2.Brr.El.div ~at:At.[ class' (Jstr.v "work-manifest-details") ] [])
           (work_manifest_comp installation_id work_manifest_id);
       ])

let ph_loading =
  Brtl_js2.Brr.El.
    [
      div
        ~at:At.[ class' (Jstr.v "loading") ]
        [ span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "autorenew" ] ];
    ]

let run work_manifest_id = Brtl_js2.Ph.create ph_loading (comp work_manifest_id)
