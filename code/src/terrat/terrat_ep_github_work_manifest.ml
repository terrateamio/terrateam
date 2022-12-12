module String_map = CCMap.Make (CCString)
module Dirspace_map = CCMap.Make (Terrat_change.Dirspace)

module Metrics = struct
  let namespace = "terrat"
  let subsystem = "ep_github_work_manifest"

  module Run_output_histogram = Prmths.Histogram (struct
    let spec =
      Prmths.Histogram_spec.of_list [ 500.0; 1000.0; 2500.0; 10000.0; 20000.0; 35000.0; 65000.0 ]
  end)

  module Plan_histogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_list [ 1000.0; 10000.0; 100000.0; 1000000.0; 1000000.0 ]
  end)

  module Work_manifest_run_time_histogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_exponential 20.0 1.5 10
  end)

  let run_output_chars =
    let help = "Number of chars in run output" in
    let family =
      Run_output_histogram.v_labels
        ~label_names:[ "run_type"; "compact_view" ]
        ~help
        ~namespace
        ~subsystem
        "run_output_chars"
    in
    fun ~r ~c ->
      Run_output_histogram.labels
        family
        [ Terrat_work_manifest.Run_type.to_string r; Bool.to_string c ]

  let pgsql_pool_errors_total =
    Terrat_metrics.errors_total ~m:"ep_github_work_manifest" ~t:"pgsql_pool"

  let pgsql_errors_total = Terrat_metrics.errors_total ~m:"ep_github_work_manifest" ~t:"pgsql"
  let github_errors_total = Terrat_metrics.errors_total ~m:"ep_github_work_manifest" ~t:"github"

  let plan_chars =
    let help = "Size of plans" in
    Plan_histogram.v ~help ~namespace ~subsystem "plan_chars"

  let run_overall_result_count =
    let help = "Count of the results of overall runs" in
    Prmths.Counter.v_label
      ~label_name:"success"
      ~help
      ~namespace
      ~subsystem
      "run_overall_result_count"

  let work_manifest_run_time_duration_seconds =
    let help = "Number of seconds since a work manifest was created vs when it was completed" in
    Work_manifest_run_time_histogram.v_label
      ~label_name:"run_type"
      ~help
      ~namespace
      ~subsystem
      "work_manifest_run_time_duration_seconds"

  let work_manifest_wait_duration_seconds =
    let help = "Number of seconds a work manifest waited between creation and the initiate call" in
    Work_manifest_run_time_histogram.v_label
      ~label_name:"run_type"
      ~help
      ~namespace
      ~subsystem
      "work_manifest_wait_duration_seconds"
end

let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

let maybe_credential_error_strings =
  [
    "no valid credential"; "Required token could not be found"; "could not find default credentials";
  ]

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map
         (fun s ->
           s
           |> CCString.split_on_char '\n'
           |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
           |> CCString.concat "\n")
         (Terrat_files_sql.read fname))

  let base64 = function
    | Some s :: rest -> (
        match Base64.decode (CCString.replace ~sub:"\n" ~by:"" s) with
        | Ok s -> Some (s, rest)
        | _ -> None)
    | _ -> None

  let run_type = function
    | Some s :: rest ->
        let open CCOption in
        Terrat_work_manifest.Run_type.of_string s >>= fun run_type -> Some (run_type, rest)
    | _ -> None

  let tag_query = function
    | Some s :: rest -> Some (Terrat_tag_set.of_string s, rest)
    | _ -> None

  let policy =
    let module P = struct
      type t = string list [@@deriving yojson]
    end in
    CCFun.(
      CCOption.wrap Yojson.Safe.from_string
      %> CCOption.map P.of_yojson
      %> CCOption.flat_map CCResult.to_opt)

  let initiate_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      // (* bash_hash *) Ret.text
      // (* completed_at *) Ret.(option text)
      // (* created_at *) Ret.text
      // (* hash *) Ret.text
      // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
      // (* state *) Ret.ud' Terrat_work_manifest.State.of_string
      // (* tag_query *) Ret.ud tag_query
      // (* repository *) Ret.bigint
      // (* pull_number *) Ret.bigint
      // (* base_branch *) Ret.text
      // (* installation_id *) Ret.bigint
      // (* owner *) Ret.text
      // (* repo *) Ret.text
      /^ read "github_initiate_work_manifest.sql"
      /% Var.uuid "id"
      /% Var.text "run_id"
      /% Var.text "sha")

  let select_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      // (* bash_hash *) Ret.text
      // (* completed_at *) Ret.(option text)
      // (* created_at *) Ret.text
      // (* hash *) Ret.text
      // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
      // (* state *) Ret.ud' Terrat_work_manifest.State.of_string
      // (* tag_query *) Ret.ud tag_query
      // (* repository *) Ret.bigint
      // (* pull_number *) Ret.bigint
      // (* base_branch *) Ret.text
      // (* installation_id *) Ret.bigint
      // (* owner *) Ret.text
      // (* repo *) Ret.text
      /^ read "select_github_work_manifest.sql"
      /% Var.uuid "id"
      /% Var.text "run_id"
      /% Var.text "sha")

  let abort_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_work_manifests set state = 'aborted', completed_at = now() where id = $id \
          and state in ('queued', 'running')"
      /% Var.uuid "id")

  let select_work_manifest_dirspaces =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      // (* workflow_idx *) Ret.(option integer)
      /^ "select path, workspace, workflow_idx from github_work_manifest_dirspaceflows where \
          work_manifest = $id"
      /% Var.uuid "id")

  let upsert_terraform_plan =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "upsert_terraform_plan.sql"
      /% Var.uuid "work_manifest"
      /% Var.text "path"
      /% Var.text "workspace"
      /% Var.(ud (text "data") Base64.encode_string))

  let insert_github_work_manifest_result =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_work_manifest_result.sql"
      /% Var.uuid "work_manifest"
      /% Var.text "path"
      /% Var.text "workspace"
      /% Var.boolean "success")

  let complete_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_work_manifests set state = 'completed', completed_at = now() where id = $id"
      /% Var.uuid "id")

  let select_dirspaces_without_valid_plans =
    Pgsql_io.Typed_sql.(
      sql
      // (* dir *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_dirspaces_without_valid_plans.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.(str_array (text "dirs"))
      /% Var.(str_array (text "workspaces")))

  let select_dirspaces_owned_by_other_pull_requests =
    Pgsql_io.Typed_sql.(
      sql
      // (* dir *) Ret.text
      // (* workspace *) Ret.text
      // (* base_branch *) Ret.text
      // (* branch *) Ret.text
      // (* base_hash *) Ret.text
      // (* hash *) Ret.text
      // (* merged_hash *) Ret.(option text)
      // (* merged_at *) Ret.(option text)
      // (* pull_number *) Ret.bigint
      // (* state *) Ret.text
      /^ read "select_github_dirspaces_owned_by_other_pull_requests.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.(str_array (text "dirs"))
      /% Var.(str_array (text "workspaces")))

  let select_recent_plan =
    Pgsql_io.Typed_sql.(
      sql
      // (* data *) Ret.ud base64
      /^ read "select_github_recent_plan.sql"
      /% Var.uuid "id"
      /% Var.text "dir"
      /% Var.text "workspace")

  let select_github_parameters_from_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      // (* installation_id *) Ret.bigint
      // (* owner *) Ret.text
      // (* name *) Ret.text
      // (* branch *) Ret.text
      // (* sha *) Ret.text
      // (* base_sha *) Ret.text
      // (* pull_number *) Ret.bigint
      // (* run_type *) Ret.ud run_type
      // (* run_id *) Ret.(option text)
      // (* run time *) Ret.double
      /^ read "select_github_parameters_from_work_manifest.sql"
      /% Var.uuid "id")

  let select_missing_dirspace_applies_for_pull_request =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_missing_dirspace_applies_for_pull_request.sql"
      /% Var.text "owner"
      /% Var.text "name"
      /% Var.bigint "pull_number")

  let select_work_manifest_access_control_denied_dirspaces =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      // (* policy *) Ret.(option (ud' policy))
      /^ read "select_github_work_manifest_access_control_denied_dirspaces.sql"
      /% Var.uuid "work_manifest")
end

module Tmpl = struct
  module Transformers = struct
    let money =
      ( "money",
        Snabela.Kv.(
          function
          | F num -> S (Printf.sprintf "%01.02f" num)
          | any -> any) )

    let plan_diff =
      ( "plan_diff",
        Snabela.Kv.(
          function
          | S plan -> S (Terrat_plan_diff.transform plan)
          | any -> any) )

    let compact_plan =
      ( "compact_plan",
        Snabela.Kv.(
          function
          | S plan ->
              S
                (plan
                |> CCString.split_on_char '\n'
                |> CCList.filter (fun s -> CCString.find ~sub:"= (known after apply)" s = -1)
                |> CCString.concat "\n")
          | any -> any) )
  end

  let read fname =
    fname
    |> Terrat_files_tmpl.read
    |> CCOption.get_exn_or fname
    |> Snabela.Template.of_utf8_string
    |> function
    | Ok tmpl -> Snabela.of_template tmpl Transformers.[ money; compact_plan; plan_diff ]
    | Error (#Snabela.Template.err as err) -> failwith (Snabela.Template.show_err err)

  let plan_complete = read "github_plan_complete.tmpl"
  let apply_complete = read "github_apply_complete.tmpl"

  let work_manifest_already_run =
    "github_work_manifest_already_run.tmpl"
    |> Terrat_files_tmpl.read
    |> CCOption.get_exn_or "github_work_manifest_already_run.tmpl"

  let comment_too_large =
    "github_comment_too_large.tmpl"
    |> Terrat_files_tmpl.read
    |> CCOption.get_exn_or "github_comment_too_large.tmpl"
end

module Workflow_step_output = struct
  type t = {
    success : bool;
    key : string option;
    text : string;
    step_type : string;
  }
end

let pre_hook_output_texts outputs =
  let module Output = Terrat_api_components_hook_outputs.Pre.Items in
  let module Text = Terrat_api_components_output_text in
  let module Run = Terrat_api_components_workflow_output_run in
  let module Checkout = Terrat_api_components_workflow_output_checkout in
  let module Ce = Terrat_api_components_workflow_output_cost_estimation in
  outputs
  |> CCList.filter_map (function
         | Output.Workflow_output_run
             Run.
               {
                 workflow_step = Workflow_step.{ type_; _ };
                 outputs = Some Text.{ text; output_key };
                 success;
                 _;
               }
         | Output.Workflow_output_checkout
             Checkout.
               {
                 workflow_step = Workflow_step.{ type_; _ };
                 outputs = Text.{ text; output_key };
                 success;
               }
         | Output.Workflow_output_cost_estimation
             Ce.
               {
                 workflow_step = Workflow_step.{ type_; _ };
                 outputs = Outputs.Output_text Text.{ text; output_key };
                 success;
                 _;
               } -> Some Workflow_step_output.{ key = output_key; text; success; step_type = type_ }
         | Output.Workflow_output_run
             Run.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ } ->
             Some Workflow_step_output.{ key = None; text = ""; success; step_type = type_ }
         | Output.Workflow_output_env _
         | Output.Workflow_output_cost_estimation
             Ce.{ outputs = Outputs.Output_cost_estimation _; _ } -> None)

let post_hook_output_texts (outputs : Terrat_api_components_hook_outputs.Post.t) =
  let module Output = Terrat_api_components_hook_outputs.Post.Items in
  let module Text = Terrat_api_components_output_text in
  let module Run = Terrat_api_components_workflow_output_run in
  outputs
  |> CCList.filter_map (function
         | Output.Workflow_output_run
             Run.
               {
                 workflow_step = Workflow_step.{ type_; _ };
                 outputs = Some Text.{ text; output_key };
                 success;
                 _;
               } -> Some Workflow_step_output.{ key = output_key; text; success; step_type = type_ }
         | Output.Workflow_output_run
             Run.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ } ->
             Some Workflow_step_output.{ key = None; text = ""; success; step_type = type_ }
         | Output.Workflow_output_env _ -> None)

let workflow_output_texts outputs =
  let module Output = Terrat_api_components_workflow_outputs.Items in
  let module Run = Terrat_api_components_workflow_output_run in
  let module Init = Terrat_api_components_workflow_output_init in
  let module Plan = Terrat_api_components_workflow_output_plan in
  let module Apply = Terrat_api_components_workflow_output_apply in
  let module Text = Terrat_api_components_output_text in
  let module Output_plan = Terrat_api_components_output_plan in
  outputs
  |> CCList.flat_map (function
         | Output.Workflow_output_run
             Run.
               {
                 workflow_step = Workflow_step.{ type_; _ };
                 outputs = Some Text.{ text; output_key };
                 success;
                 _;
               }
         | Output.Workflow_output_init
             Init.
               {
                 workflow_step = Workflow_step.{ type_; _ };
                 outputs = Some Text.{ text; output_key };
                 success;
                 _;
               }
         | Output.Workflow_output_plan
             Plan.
               {
                 workflow_step = Workflow_step.{ type_; _ };
                 outputs = Some (Plan.Outputs.Output_text Text.{ text; output_key });
                 success;
                 _;
               }
         | Output.Workflow_output_apply
             Apply.
               {
                 workflow_step = Workflow_step.{ type_; _ };
                 outputs = Some Text.{ text; output_key };
                 success;
                 _;
               } -> [ Workflow_step_output.{ step_type = type_; text; key = output_key; success } ]
         | Output.Workflow_output_plan
             Plan.
               {
                 workflow_step = Workflow_step.{ type_; _ };
                 outputs = Some (Plan.Outputs.Output_plan Output_plan.{ plan; plan_text });
                 success;
                 _;
               } ->
             [
               Workflow_step_output.
                 { step_type = type_; text = plan_text; key = Some "plan_text"; success };
               Workflow_step_output.{ step_type = type_; text = plan; key = Some "plan"; success };
             ]
         | Output.Workflow_output_run _
         | Output.Workflow_output_plan _
         | Output.Workflow_output_env _
         | Output.Workflow_output_init Init.{ outputs = None; _ }
         | Output.Workflow_output_apply Apply.{ outputs = None; _ } -> [])

module T = struct
  type t = {
    config : Terrat_config.t;
    access_token : string;
    owner : string;
    name : string;
    pull_number : int;
    hash : string;
    base_hash : string;
    request_id : string;
    run_id : string;
    work_manifest : Uuidm.t;
  }
end

module Pull_request = struct
  module Lite = struct
    type t = (int64, unit, unit) Terrat_pull_request.t [@@deriving show]
  end

  type t = {
    repo_id : int64;
    pull_number : int64;
    base_branch : string;
  }
  [@@deriving show]
end

module Initiate = struct
  let post config storage work_manifest_id work_manifest_initiate ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    Terrat_github_evaluator.Work_manifest.initiate
      ~request_id
      config
      storage
      work_manifest_id
      work_manifest_initiate
    >>= function
    | Some response ->
        let body =
          response
          |> Terrat_api_work_manifest.Initiate.Responses.OK.to_yojson
          |> Yojson.Safe.to_string
        in
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~headers:response_headers ~status:`OK body) ctx)
    | None ->
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
end

module Plans = struct
  module Pc = Terrat_api_components.Plan_create

  let post config storage work_manifest_id { Pc.path; workspace; plan_data } ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    let plan = Base64.decode_exn plan_data in
    Metrics.Plan_histogram.observe Metrics.plan_chars (CCFloat.of_int (CCString.length plan));
    Terrat_github_evaluator.Work_manifest.plan_store
      ~request_id
      ~path
      ~workspace
      storage
      work_manifest_id
      plan
    >>= function
    | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
    | Error `Error ->
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)

  let get config storage work_manifest_id path workspace ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    Terrat_github_evaluator.Work_manifest.plan_fetch
      ~request_id
      ~path
      ~workspace
      storage
      work_manifest_id
    >>= function
    | Ok (Some data) ->
        let response =
          Terrat_api_work_manifest.Plan_get.Responses.OK.(
            { data = Base64.encode_exn data } |> to_yojson)
          |> Yojson.Safe.to_string
        in
        Abb.Future.return
          (Brtl_ctx.set_response
             (Brtl_rspnc.create ~headers:response_headers ~status:`OK response)
             ctx)
    | Ok None ->
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
    | Error `Error ->
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
end

module Results = struct
  let complete_check ~access_token ~owner ~repo ~branch ~run_id ~run_type ~sha ~results () =
    let module Wmr = Terrat_api_components.Work_manifest_result in
    let module R = Terrat_api_work_manifest.Results.Request_body in
    let module Hooks_output = Terrat_api_components.Hook_outputs in
    let unified_run_type =
      Terrat_work_manifest.(run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
    in
    let success = results.R.overall.R.Overall.success in
    let description = if success then "Completed" else "Failed" in
    let target_url = Printf.sprintf "https://github.com/%s/%s/actions/runs/%s" owner repo run_id in
    let pre_hooks_status =
      let module Run = Terrat_api_components.Workflow_output_run in
      let module Env = Terrat_api_components.Workflow_output_env in
      let module Checkout = Terrat_api_components.Workflow_output_checkout in
      let module Ce = Terrat_api_components.Workflow_output_cost_estimation in
      results.R.overall.R.Overall.outputs.Hooks_output.pre
      |> CCList.exists
           Hooks_output.Pre.Items.(
             function
             | Workflow_output_run Run.{ success; _ }
             | Workflow_output_env Env.{ success; _ }
             | Workflow_output_checkout Checkout.{ success; _ }
             | Workflow_output_cost_estimation Ce.{ success; _ } -> not success)
      |> function
      | true -> Terrat_commit_check.Status.Failed
      | false -> Terrat_commit_check.Status.Completed
    in
    let post_hooks_status =
      let module Run = Terrat_api_components.Workflow_output_run in
      let module Env = Terrat_api_components.Workflow_output_env in
      results.R.overall.R.Overall.outputs.Hooks_output.post
      |> CCList.exists
           Hooks_output.Post.Items.(
             function
             | Workflow_output_run Run.{ success; _ } | Workflow_output_env Env.{ success; _ } ->
                 not success)
      |> function
      | true -> Terrat_commit_check.Status.Failed
      | false -> Terrat_commit_check.Status.Completed
    in
    let commit_statuses =
      let aggregate =
        Terrat_commit_check.
          [
            make
              ~details_url:target_url
              ~description
              ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
              ~status:pre_hooks_status;
            make
              ~details_url:target_url
              ~description
              ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
              ~status:post_hooks_status;
          ]
      in
      let dirspaces =
        CCList.map
          (fun Wmr.{ path; workspace; success; _ } ->
            let status = Terrat_commit_check.Status.(if success then Completed else Failed) in
            let description = if success then "Completed" else "Failed" in
            Terrat_commit_check.make
              ~details_url:target_url
              ~description
              ~title:(Printf.sprintf "terrateam %s: %s %s" unified_run_type path workspace)
              ~status)
          results.R.dirspaces
      in
      aggregate @ dirspaces
    in
    Terrat_github_commit_check.create ~access_token ~owner ~repo ~ref_:sha commit_statuses

  let create_run_output ~compact_view run_type results denied_dirspaces =
    let module Wmr = Terrat_api_components.Work_manifest_result in
    let module R = Terrat_api_work_manifest.Results.Request_body in
    let module Dirspace_result_compare = struct
      type t = bool * string * string [@@deriving ord]
    end in
    let dirspaces =
      results.R.dirspaces
      |> CCList.sort
           (fun
             Wmr.{ path = p1; workspace = w1; success = s1; _ }
             Wmr.{ path = p2; workspace = w2; success = s2; _ }
           -> Dirspace_result_compare.compare (s1, p1, w1) (s2, p2, w2))
    in
    let maybe_credentials_error =
      dirspaces
      |> CCList.exists (fun Wmr.{ outputs; _ } ->
             let module Text = Terrat_api_components_output_text in
             let texts = workflow_output_texts outputs in
             CCList.exists
               (fun Workflow_step_output.{ text; _ } ->
                 CCList.exists
                   (fun sub -> CCString.find ~sub text <> -1)
                   maybe_credential_error_strings)
               texts)
    in
    let module Hook_outputs = Terrat_api_components.Hook_outputs in
    let pre = results.R.overall.R.Overall.outputs.Hook_outputs.pre in
    let post = results.R.overall.R.Overall.outputs.Hook_outputs.post in
    let cost_estimation =
      let module Wce = Terrat_api_components_workflow_output_cost_estimation in
      let module Ce = Terrat_api_components_output_cost_estimation in
      pre
      |> CCList.filter_map (function
             | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_cost_estimation
                 {
                   Wce.outputs = Wce.Outputs.Output_cost_estimation Ce.{ cost_estimation; _ };
                   success = true;
                   _;
                 } -> Some cost_estimation
             | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_run _
             | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_env _
             | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_checkout _
             | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_cost_estimation _ ->
                 None)
      |> CCOption.of_list
      |> CCOption.map (function
             | Ce.Cost_estimation.
                 { currency; total_monthly_cost; prev_monthly_cost; diff_monthly_cost; dirspaces }
             ->
             Snabela.Kv.(
               Map.of_list
                 [
                   ("prev_monthly_cost", float prev_monthly_cost);
                   ("total_monthly_cost", float total_monthly_cost);
                   ("diff_monthly_cost", float diff_monthly_cost);
                   ("currency", string currency);
                   ( "dirspaces",
                     list
                       (CCList.map
                          (fun Ce.Cost_estimation.Dirspaces.Items.
                                 {
                                   path;
                                   workspace;
                                   total_monthly_cost;
                                   prev_monthly_cost;
                                   diff_monthly_cost;
                                 } ->
                            Map.of_list
                              [
                                ("dir", string path);
                                ("workspace", string workspace);
                                ("prev_monthly_cost", float prev_monthly_cost);
                                ("total_monthly_cost", float total_monthly_cost);
                                ("diff_monthly_cost", float diff_monthly_cost);
                              ])
                          dirspaces) );
                 ]))
    in
    let kv_of_workflow_step steps =
      Snabela.Kv.(
        list
          (CCList.map
             (function
               | Workflow_step_output.{ key = Some key; text; success; step_type } ->
                   Map.of_list
                     [
                       (key, bool true);
                       ("text", string text);
                       ("success", bool success);
                       ("step_type", string step_type);
                     ]
               | Workflow_step_output.{ success; text; step_type; _ } ->
                   Map.of_list
                     [
                       ("success", bool success);
                       ("text", string text);
                       ("step_type", string step_type);
                     ])
             steps))
    in
    let kv =
      Snabela.Kv.(
        Map.of_list
          (CCList.flatten
             [
               CCOption.map_or
                 ~default:[]
                 (fun cost_estimation -> [ ("cost_estimation", list [ cost_estimation ]) ])
                 cost_estimation;
               [
                 ("maybe_credentials_error", bool maybe_credentials_error);
                 ("overall_success", bool results.R.overall.R.Overall.success);
                 ("pre_hooks", kv_of_workflow_step (pre_hook_output_texts pre));
                 ("post_hooks", kv_of_workflow_step (post_hook_output_texts post));
                 ("compact_view", bool compact_view);
                 ( "results",
                   list
                     (CCList.map
                        (fun Wmr.{ path; workspace; success; outputs; _ } ->
                          let module Text = Terrat_api_components_output_text in
                          Map.of_list
                            [
                              ("dir", string path);
                              ("workspace", string workspace);
                              ("success", bool success);
                              ("outputs", kv_of_workflow_step (workflow_output_texts outputs));
                            ])
                        dirspaces) );
               ];
               (match denied_dirspaces with
               | [] -> []
               | dirspaces ->
                   [
                     ( "denied_dirspaces",
                       list
                         (CCList.map
                            (fun (Terrat_change.Dirspace.{ dir; workspace }, policy) ->
                              Map.of_list
                                (CCList.flatten
                                   [
                                     [ ("dir", string dir); ("workspace", string workspace) ];
                                     (match policy with
                                     | Some policy ->
                                         [
                                           ( "policy",
                                             list
                                               (CCList.map
                                                  (fun p -> Map.of_list [ ("item", string p) ])
                                                  policy) );
                                         ]
                                     | None -> []);
                                   ]))
                            denied_dirspaces) );
                   ]);
             ]))
    in
    let tmpl =
      match Terrat_work_manifest.Unified_run_type.of_run_type run_type with
      | Terrat_work_manifest.Unified_run_type.Plan -> Tmpl.plan_complete
      | Terrat_work_manifest.Unified_run_type.Apply -> Tmpl.apply_complete
    in
    match Snabela.apply tmpl kv with
    | Ok body -> body
    | Error (#Snabela.err as err) ->
        Logs.err (fun m -> m "WORK_MANIFEST : ERROR : %s" (Snabela.show_err err));
        assert false

  let rec iterate_comment_posts
      ?(compact_view = false)
      ~request_id
      ~access_token
      ~owner
      ~repo
      ~pull_number
      ~run_id
      ~sha
      ~run_type
      ~results
      ~denied_dirspaces
      () =
    let open Abb.Future.Infix_monad in
    let output = create_run_output ~compact_view run_type results denied_dirspaces in
    Metrics.Run_output_histogram.observe
      (Metrics.run_output_chars ~r:run_type ~c:compact_view)
      (CCFloat.of_int (CCString.length output));
    Terrat_github.publish_comment ~access_token ~owner ~repo ~pull_number output
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Terrat_github.publish_comment_err as err) when not compact_view ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : ITERATE_COMMENT_POST : %s"
              request_id
              (Terrat_github.show_publish_comment_err err));
        iterate_comment_posts
          ~compact_view:true
          ~request_id
          ~access_token
          ~owner
          ~repo
          ~pull_number
          ~run_id
          ~sha
          ~run_type
          ~results
          ~denied_dirspaces
          ()
    | Error (#Terrat_github.publish_comment_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : ITERATE_COMMENT_POST : %s"
              request_id
              (Terrat_github.show_publish_comment_err err));
        Terrat_github.publish_comment ~access_token ~owner ~repo ~pull_number Tmpl.comment_too_large

  let publish_results
      ~request_id
      ~config
      ~access_token
      ~owner
      ~repo
      ~branch
      ~pull_number
      ~run_type
      ~results
      ~denied_dirspaces
      ~run_id
      ~sha
      () =
    let run =
      Abbs_future_combinators.Infix_result_app.(
        (fun _ _ -> ())
        <$> Abbs_time_it.run
              (fun t -> Logs.info (fun m -> m "WORK_MANIFEST : %s : COMMENT : %f" request_id t))
              (fun () ->
                iterate_comment_posts
                  ~request_id
                  ~access_token
                  ~owner
                  ~repo
                  ~pull_number
                  ~run_id
                  ~sha
                  ~run_type
                  ~results
                  ~denied_dirspaces
                  ())
        <*> Abbs_time_it.run
              (fun t ->
                Logs.info (fun m ->
                    m "WORK_MANIFEST : %s : COMPLETE_COMMIT_STATUSES : %f" request_id t))
              (fun () ->
                complete_check ~access_token ~owner ~repo ~branch ~run_id ~run_type ~sha ~results ()))
    in
    let open Abb.Future.Infix_monad in
    Abbs_time_it.run
      (fun t -> Logs.info (fun m -> m "WORK_MANIFEST : %s : PUBLISH_RESULTS : %f" request_id t))
      (fun () -> run)
    >>= function
    | Ok () -> Abb.Future.return ()
    | Error (#Githubc2_abb.call_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m "WORK_MANIFEST : %s : ERROR : %s" request_id (Githubc2_abb.show_call_err err));
        Abb.Future.return ()
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : ERROR : %s"
              request_id
              (Terrat_github.show_get_installation_access_token_err err));
        Abb.Future.return ()
    | Error (#Terrat_github.publish_comment_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : ERROR : %s"
              request_id
              (Terrat_github.show_publish_comment_err err));
        Abb.Future.return ()

  let automerge_config = function
    | Terrat_repo_config.(Version_1.{ automerge = Some _ as automerge; _ }) -> automerge
    | _ -> None

  let merge_pull_request request_id access_token owner repo pull_number =
    let open Abbs_future_combinators.Infix_result_monad in
    let client = Terrat_github.create (`Token access_token) in
    Logs.info (fun m ->
        m
          "WORK_MANIFEST : %s : MERGE_PULL_REQUEST : %s : %s : %Ld"
          request_id
          owner
          repo
          pull_number);
    Githubc2_abb.call
      client
      Githubc2_pulls.Merge.(
        make
          ~body:
            Request_body.(
              make
                Primary.(
                  make
                    ~commit_title:(Some (Printf.sprintf "Terrateam Automerge #%Ld" pull_number))
                    ()))
          Parameters.(make ~owner ~repo ~pull_number:(CCInt64.to_int pull_number)))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK _ -> Abb.Future.return (Ok ())
    | `Method_not_allowed _ -> (
        Logs.info (fun m ->
            m
              "WORK_MANIFEST : %s : MERGE_METHOD_NOT_ALLOWED : %s : %s : %Ld"
              request_id
              owner
              repo
              pull_number);
        Githubc2_abb.call
          client
          Githubc2_pulls.Merge.(
            make
              ~body:Request_body.(make Primary.(make ~merge_method:(Some "squash") ()))
              Parameters.(make ~owner ~repo ~pull_number:(CCInt64.to_int pull_number)))
        >>= fun resp ->
        match Openapi.Response.value resp with
        | `OK _ -> Abb.Future.return (Ok ())
        | ( `Method_not_allowed _
          | `Conflict _
          | `Forbidden _
          | `Not_found _
          | `Unprocessable_entity _ ) as err -> Abb.Future.return (Error err))
    | (`Conflict _ | `Forbidden _ | `Not_found _ | `Unprocessable_entity _) as err ->
        Abb.Future.return (Error err)

  let delete_pull_request_branch request_id access_token owner repo pull_number =
    let open Abbs_future_combinators.Infix_result_monad in
    Logs.info (fun m ->
        m
          "WORK_MANIFEST : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %Ld"
          request_id
          owner
          repo
          pull_number);
    Terrat_github.fetch_pull_request ~access_token ~owner ~repo (CCInt64.to_int pull_number)
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK
        Githubc2_components.Pull_request.
          { primary = Primary.{ head = Head.{ primary = Primary.{ ref_ = branch; _ }; _ }; _ }; _ }
      -> (
        Logs.info (fun m ->
            m
              "WORK_MANIFEST : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %Ld : %s"
              request_id
              owner
              repo
              pull_number
              branch);
        let client = Terrat_github.create (`Token access_token) in
        Githubc2_abb.call
          client
          Githubc2_git.Delete_ref.(make Parameters.(make ~owner ~repo ~ref_:("heads/" ^ branch)))
        >>= fun resp ->
        match Openapi.Response.value resp with
        | `No_content -> Abb.Future.return (Ok ())
        | `Unprocessable_entity err ->
            Logs.err (fun m ->
                m
                  "WORK_MANIFEST : %s : DELETE_PULL_REQUEST_BRANCH : ERROR : %s : %s : %Ld : %s"
                  request_id
                  owner
                  repo
                  pull_number
                  (Githubc2_git.Delete_ref.Responses.Unprocessable_entity.show err));
            Abb.Future.return (Ok ()))
    | `Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _ ->
        failwith "nyi"

  let perform_post_apply
      ~request_id
      ~config
      ~storage
      ~access_token
      ~owner
      ~repo
      ~sha
      ~pull_number
      () =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Logs.info (fun m ->
          m
            "WORK_MANIFEST : %s : AUTOMERGE : SELECT_MISSING_DIRSPACE_APPLIES : %s : %s : %Ld : %s"
            request_id
            owner
            repo
            pull_number
            sha);
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_missing_dirspace_applies_for_pull_request
            ~f:(fun path workspace -> (path, workspace))
            owner
            repo
            pull_number)
      >>= function
      | [] -> (
          Logs.info (fun m ->
              m
                "WORK_MANIFEST : %s : ALL_DIRSPACES_APPLIED : %s : %s : %Ld : %s"
                request_id
                owner
                repo
                pull_number
                sha);
          Terrat_github.fetch_repo_config
            ~python:(Terrat_config.python_exec config)
            ~access_token
            ~owner
            ~repo
            sha
          >>= fun repo_config ->
          match automerge_config repo_config with
          | Some Terrat_repo_config.Automerge.{ enabled = true; delete_branch } -> (
              merge_pull_request request_id access_token owner repo pull_number
              >>= function
              | () when delete_branch ->
                  delete_pull_request_branch request_id access_token owner repo pull_number
              | () -> Abb.Future.return (Ok ()))
          | _ -> Abb.Future.return (Ok ()))
      | _ :: _ ->
          (* Not everything is applied, so skip *)
          Abb.Future.return (Ok ())
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok () -> Abb.Future.return ()
    | Error (#Pgsql_pool.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
              request_id
              owner
              repo
              pull_number
              sha
              (Pgsql_pool.show_err err));
        Abb.Future.return ()
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
              request_id
              owner
              repo
              pull_number
              sha
              (Pgsql_io.show_err err));
        Abb.Future.return ()
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
              request_id
              owner
              repo
              pull_number
              sha
              (Terrat_github.show_get_installation_access_token_err err));
        Abb.Future.return ()
    | Error (#Terrat_github.fetch_repo_config_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
              request_id
              owner
              repo
              pull_number
              sha
              (Terrat_github.show_fetch_repo_config_err err));
        Abb.Future.return ()
    | Error (`Conflict err) ->
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
              request_id
              owner
              repo
              pull_number
              sha
              (Githubc2_pulls.Merge.Responses.Conflict.show err));
        Abb.Future.return ()
    | Error (`Method_not_allowed err) ->
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
              request_id
              owner
              repo
              pull_number
              sha
              (Githubc2_pulls.Merge.Responses.Method_not_allowed.show err));
        Abb.Future.return ()

  let complete_work_manifest
      ~config
      ~storage
      ~request_id
      ~installation_id
      ~owner
      ~repo
      ~branch
      ~sha
      ~pull_number
      ~run_type
      ~run_id
      ~results
      ~denied_dirspaces
      () =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.get_installation_access_token config (CCInt64.to_int installation_id)
      >>= fun access_token ->
      Abb.Future.Infix_app.(
        (fun () () -> Ok ())
        <$> publish_results
              ~request_id
              ~config
              ~access_token
              ~owner
              ~repo
              ~branch
              ~pull_number:(CCInt64.to_int pull_number)
              ~run_type
              ~results
              ~denied_dirspaces
              ~run_id:(CCOption.get_exn_or "run_id is None" run_id)
              ~sha
              ()
        <*>
        match Terrat_work_manifest.Unified_run_type.of_run_type run_type with
        | Terrat_work_manifest.Unified_run_type.Apply ->
            perform_post_apply
              ~request_id
              ~config
              ~storage
              ~access_token
              ~owner
              ~repo
              ~sha
              ~pull_number
              ()
        | Terrat_work_manifest.Unified_run_type.Plan -> Abb.Future.return ())
    in
    let open Abb.Future.Infix_monad in
    run
    >>= fun ret ->
    Abb.Future.fork (Terrat_github_evaluator.Runner.run ~request_id config storage)
    >>= fun _ ->
    match ret with
    | Ok () -> Abb.Future.return ()
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : ERROR : %s"
              request_id
              (Terrat_github.show_get_installation_access_token_err err));
        Abb.Future.return ()

  let put config storage work_manifest_id results ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    let id = Uuidm.to_string work_manifest_id in
    Logs.info (fun m ->
        m
          "WORK_MANIFEST : %s : RESULT : %s : %s"
          request_id
          id
          (if Terrat_api_work_manifest.Results.Request_body.(results.overall.Overall.success) then
           "SUCCESS"
          else "FAILURE"));
    Prmths.Counter.inc_one
      (Metrics.run_overall_result_count
         (Bool.to_string
            Terrat_api_work_manifest.Results.Request_body.(results.overall.Overall.success)));
    Pgsql_pool.with_conn storage ~f:(fun db ->
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_io.tx db ~f:(fun () ->
            Abbs_time_it.run
              (fun t ->
                Logs.info (fun m ->
                    m "WORK_MANIFEST : %s : DIRSPACE_RESULT_STORE : %f" request_id t))
              (fun () ->
                Abbs_future_combinators.List_result.iter
                  ~f:(fun result ->
                    let module Wmr = Terrat_api_components.Work_manifest_result in
                    Logs.info (fun m ->
                        m
                          "WORK_MANIFEST : %s : RESULT_STORE : %s : %s : %s : %s"
                          request_id
                          id
                          result.Wmr.path
                          result.Wmr.workspace
                          (if result.Wmr.success then "SUCCESS" else "FAILURE"));
                    Pgsql_io.Prepared_stmt.execute
                      db
                      Sql.insert_github_work_manifest_result
                      work_manifest_id
                      result.Wmr.path
                      result.Wmr.workspace
                      result.Wmr.success)
                  results.Terrat_api_work_manifest.Results.Request_body.dirspaces)
            >>= fun () ->
            Abbs_time_it.run
              (fun t ->
                Logs.info (fun m ->
                    m "WORK_MANIFEST : %s : COMPLETE_WORK_MANIFEST : %f" request_id t))
              (fun () ->
                Pgsql_io.Prepared_stmt.execute db Sql.complete_work_manifest work_manifest_id)
            >>= fun () ->
            Abbs_time_it.run
              (fun t ->
                Logs.info (fun m ->
                    m "WORK_MANIFEST : %s : FETCH_ACCESS_CONTROL_DENIED_DIRSPACES : %f" request_id t))
              (fun () ->
                Pgsql_io.Prepared_stmt.fetch
                  db
                  Sql.select_work_manifest_access_control_denied_dirspaces
                  ~f:(fun dir workspace policy ->
                    (Terrat_change.Dirspace.{ dir; workspace }, policy))
                  work_manifest_id)
            >>= fun denied_dirspaces ->
            Abbs_time_it.run
              (fun t ->
                Logs.info (fun m ->
                    m "WORK_MANIFEST : %s : SELECT_GITHUB_PARAMETERS : %f" request_id t))
              (fun () ->
                Pgsql_io.Prepared_stmt.fetch
                  db
                  (Sql.select_github_parameters_from_work_manifest ())
                  ~f:
                    (fun installation_id
                         owner
                         name
                         branch
                         sha
                         _base_sha
                         pull_number
                         run_type
                         run_id
                         run_time ->
                    ( installation_id,
                      owner,
                      name,
                      branch,
                      sha,
                      pull_number,
                      run_type,
                      run_id,
                      denied_dirspaces,
                      run_time ))
                  work_manifest_id)
            >>= function
            | values :: _ -> Abb.Future.return (Ok values)
            | [] -> assert false))
    >>= function
    | Ok
        ( installation_id,
          owner,
          repo,
          branch,
          sha,
          pull_number,
          run_type,
          run_id,
          denied_dirspaces,
          run_time ) ->
        Metrics.Work_manifest_run_time_histogram.observe
          (Metrics.work_manifest_run_time_duration_seconds
             (Terrat_work_manifest.Run_type.to_string run_type))
          run_time;
        complete_work_manifest
          ~config
          ~storage
          ~request_id
          ~installation_id
          ~owner
          ~repo
          ~branch
          ~sha
          ~pull_number
          ~run_type
          ~run_id
          ~results
          ~denied_dirspaces
          ()
        >>= fun () ->
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
    | Error (#Pgsql_pool.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
        Logs.err (fun m -> m "WORK_MANIFEST : PLAN : %s : ERROR : %s" id (Pgsql_pool.show_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "WORK_MANIFEST : PLAN : %s : ERROR : %s" id (Pgsql_io.show_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
end
