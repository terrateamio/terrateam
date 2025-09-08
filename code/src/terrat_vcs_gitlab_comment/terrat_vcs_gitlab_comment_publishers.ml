module Api = Terrat_vcs_api_gitlab
module Scope = Terrat_scope.Scope
module By_scope = Terrat_scope.By_scope
module Tmpl = Terrat_vcs_gitlab_comment_templates.Tmpl
module Ui = Terrat_vcs_gitlab_comment_ui.Ui
module Visible_on = Terrat_base_repo_config_v1.Workflow_step.Visible_on

module Output = struct
  type t = {
    cmd : string option;
    name : string;
    success : bool;
    text : string;
    text_decorator : string option;
    visible_on : Visible_on.t;
  }

  let make ?cmd ?text_decorator ~name ~success ~text ~visible_on () =
    (* If name looks like <namespace>/<action> then remove the namespace *)
    let name = CCOption.map_or ~default:name snd (CCString.Split.right ~by:"/" name) in
    { cmd; name; success; text; text_decorator; visible_on }

  let to_kv { cmd; name; success; text; text_decorator; visible_on } =
    `Assoc
      (CCList.flatten
         [
           [
             ("name", `String name);
             ("text", `String text);
             ("success", `Bool success);
             ("text_decorator", `String (CCOption.get_or ~default:"" text_decorator));
           ];
           CCOption.map_or ~default:[] (fun cmd -> [ ("cmd", `String cmd) ]) cmd;
         ])

  let filter ~overall_success =
    CCList.filter (fun { visible_on; _ } ->
        visible_on = Visible_on.Always
        || (overall_success && visible_on = Visible_on.Success)
        || ((not overall_success) && visible_on = Visible_on.Failure))
end

let steps_has_changes steps =
  let module P = struct
    type t = { has_changes : bool [@default false] } [@@deriving of_yojson { strict = false }]
  end in
  let module O = Terrat_api_components.Workflow_step_output in
  match
    CCList.find_map
      (function
        | { O.step = "tf/plan" | "pulumi/plan" | "custom/plan" | "fly/plan"; payload; success; _ }
          -> (
            match P.of_yojson (O.Payload.to_yojson payload) with
            | Ok { P.has_changes } -> Some has_changes
            | _ -> None)
        | _ -> None)
      steps
  with
  | Some has_changes -> has_changes
  | None -> false

let steps_success steps =
  let module O = Terrat_api_components.Workflow_step_output in
  CCList.for_all (fun { O.success; ignore_errors; _ } -> success || ignore_errors) steps

let kv_of_cost_estimation changed_dirspaces output =
  let module P = struct
    module S = struct
      type t = {
        prev_monthly_cost : float;
        total_monthly_cost : float;
        diff_monthly_cost : float;
      }
      [@@deriving of_yojson { strict = false }]
    end

    module Ds = struct
      type t = {
        dir : string;
        workspace : string;
        prev_monthly_cost : float;
        total_monthly_cost : float;
        diff_monthly_cost : float;
      }
      [@@deriving yojson { strict = false }]
    end

    type t = {
      summary : S.t;
      dirspaces : Ds.t list;
      currency : string;
    }
    [@@deriving of_yojson { strict = false }]
  end in
  let module O = Terrat_api_components.Workflow_step_output in
  if output.O.success then
    let open CCResult.Infix in
    P.of_yojson (O.Payload.to_yojson output.O.payload)
    >>= fun payload ->
    let summary = payload.P.summary in
    let changed_dirspaces = Terrat_data.Dirspace_set.of_list changed_dirspaces in
    Ok
      (`Assoc
         [
           ("name", `String "cost_estimation");
           ("success", `Bool output.O.success);
           ("prev_monthly_cost", `Float summary.P.S.prev_monthly_cost);
           ("total_monthly_cost", `Float summary.P.S.total_monthly_cost);
           ("diff_monthly_cost", `Float summary.P.S.diff_monthly_cost);
           ("currency", `String payload.P.currency);
           ( "dirspaces",
             `List
               (CCList.filter_map
                  (fun {
                         P.Ds.dir;
                         workspace;
                         total_monthly_cost;
                         prev_monthly_cost;
                         diff_monthly_cost;
                       }
                     ->
                    if
                      Terrat_data.Dirspace_set.mem
                        { Terrat_dirspace.dir; workspace }
                        changed_dirspaces
                    then
                      Some
                        (`Assoc
                           [
                             ("dir", `String dir);
                             ("workspace", `String workspace);
                             ("prev_monthly_cost", `Float prev_monthly_cost);
                             ("total_monthly_cost", `Float total_monthly_cost);
                             ("diff_monthly_cost", `Float diff_monthly_cost);
                           ])
                    else None)
                  payload.P.dirspaces) );
         ])
  else
    let module P = struct
      type t = { text : string } [@@deriving of_yojson { strict = false }]
    end in
    let open CCResult.Infix in
    P.of_yojson (O.Payload.to_yojson output.O.payload)
    >>= fun { P.text } ->
    Ok (`Assoc [ ("success", `Bool output.O.success); ("text", `String text) ])

let output_of_run ?(default_visible_on = Visible_on.Failure) output =
  let module P = struct
    type t = {
      cmd : string list option; [@default None]
      text : string option; [@default None]
      visible_on : string option;
    }
    [@@deriving of_yojson { strict = false }]
  end in
  let module O = Terrat_api_components.Workflow_step_output in
  let open CCResult.Infix in
  P.of_yojson (O.Payload.to_yojson output.O.payload)
  >>= fun { P.cmd; text; visible_on } ->
  Ok
    (Output.make
       ?cmd:(CCOption.map (CCString.concat " ") cmd)
       ~name:output.O.step
       ~success:output.O.success
       ~text:(CCOption.get_or ~default:"" text)
       ~visible_on:
         (CCOption.map_or
            ~default:default_visible_on
            (function
              | "always" -> Visible_on.Always
              | "failure" -> Visible_on.Failure
              | "success" -> Visible_on.Success
              | _ -> Visible_on.Failure)
            visible_on)
       ())

let output_of_plan output =
  let module P = struct
    type t = {
      cmd : string list option; [@default None]
      text : string;
      plan : string option; [@default None]
      has_changes : bool option; [@default None]
    }
    [@@deriving of_yojson { strict = false }]
  end in
  let module O = Terrat_api_components.Workflow_step_output in
  let open CCResult.Infix in
  P.of_yojson (O.Payload.to_yojson output.O.payload)
  >>= fun { P.cmd; text; has_changes; plan } ->
  if output.O.success then
    Ok
      (Output.make
         ?cmd:(CCOption.map (CCString.concat " ") cmd)
         ~name:output.O.step
         ~success:output.O.success
         ~text:(CCOption.get_or ~default:text plan)
         ~text_decorator:"diff"
         ~visible_on:Visible_on.Always
         ())
  else
    Ok
      (Output.make
         ?cmd:(CCOption.map (CCString.concat " ") cmd)
         ~name:output.O.step
         ~success:output.O.success
         ~text
         ~visible_on:Visible_on.Always
         ())

let output_of_workflow_output output =
  let module O = Terrat_api_components.Workflow_step_output in
  match output.O.step with
  | "run" | "env" -> output_of_run output
  | "tf/init" | "pulumi/init" | "custom/init" | "fly/init" ->
      output_of_run ~default_visible_on:Visible_on.Failure output
  | "tf/apply" | "pulumi/apply" | "custom/apply" | "fly/apply" ->
      output_of_run ~default_visible_on:Visible_on.Always output
  | "tf/plan" | "pulumi/plan" | "custom/plan" | "fly/plan" -> output_of_plan output
  | step -> output_of_run output

let output_of_raw output =
  let module O = Terrat_api_components.Workflow_step_output in
  let { O.step; success; payload; _ } = output in
  Output.make
    ~name:step
    ~success
    ~text:(Yojson.Safe.pretty_to_string (O.Payload.to_yojson payload))
    ~visible_on:Visible_on.Failure
    ()

let output_of_steps steps =
  let module O = Terrat_api_components.Workflow_step_output in
  CCList.filter_map
    (fun output ->
      match output.O.step with
      | "tf/cost-estimation" -> None
      | _ -> (
          match output_of_workflow_output output with
          | Ok output -> Some output
          | Error _ -> Some (output_of_raw output)))
    steps

let kv_of_outputs outputs = CCList.map Output.to_kv outputs

let dirspace_compare (dirspace1, steps1) (dirspace2, steps2) =
  let module Cmp = struct
    type t = bool * bool * Terrat_dirspace.t [@@deriving ord]
  end in
  let has_changes1 = steps_has_changes steps1 in
  let success1 = steps_success steps1 in
  let has_changes2 = steps_has_changes steps2 in
  let success2 = steps_success steps2 in
  (* Negate has_changes because the order of [bool] is [false]
             before [true]. *)
  Cmp.compare (not has_changes1, success1, dirspace1) (not has_changes2, success2, dirspace2)

module Comment_api = struct
  let comment_on_pull_request ~request_id client pull_request msg_type body =
    let open Abbs_future_combinators.Infix_result_monad in
    Api.comment_on_pull_request ~request_id client pull_request body
    >>= fun comment_id -> Abb.Future.return (Ok comment_id)

  let apply_template_and_publish ~request_id client pull_request msg_type template kv =
    match Snabela.apply template kv with
    | Ok body ->
        Abbs_future_combinators.Result.ignore
        @@ comment_on_pull_request ~request_id client pull_request msg_type body
    | Error (#Snabela.err as err) ->
        Logs.err (fun m -> m "%s : TEMPLATE_ERROR : %a" request_id Snabela.pp_err err);
        Abb.Future.return (Error `Error)

  let apply_template_and_publish_jinja ~request_id client pull_request msg_type template kv =
    match Minijinja.render_template template kv with
    | Ok body -> comment_on_pull_request ~request_id client pull_request msg_type body
    | Error err ->
        Logs.err (fun m -> m "%s : TEMPLATE_ERROR : %s" request_id err);
        Abb.Future.return (Error `Error)
end

module Publisher_tools = struct
  let create_run_output
      ~view
      request_id
      account_status
      config
      is_layered_run
      remaining_dirspace_configs
      by_scope
      gates
      work_manifest =
    let module Wm = Terrat_work_manifest3 in
    let module R2 = Terrat_api_components.Work_manifest_tf_operation_result2 in
    let module O = Terrat_api_components.Workflow_step_output in
    let module Sds = Terrat_api_components.Workflow_step_output_scope_dirspace in
    let module Sr = Terrat_api_components.Workflow_step_output_scope_run in
    let hooks_pre =
      CCList.Assoc.get ~eq:Scope.equal (Scope.Run { flow = "hooks"; subflow = "pre" }) by_scope
    in
    let hooks_post =
      CCList.Assoc.get ~eq:Scope.equal (Scope.Run { flow = "hooks"; subflow = "post" }) by_scope
    in
    let dirspaces =
      by_scope
      |> CCList.filter_map (function
           | Scope.Dirspace dirspace, steps -> Some (dirspace, steps)
           | _ -> None)
      |> CCList.sort dirspace_compare
    in
    let overall_success =
      CCList.for_all
        (fun (_, steps) ->
          CCList.for_all (fun { O.success; ignore_errors; _ } -> success || ignore_errors) steps)
        by_scope
    in
    let num_remaining_layers = CCList.length remaining_dirspace_configs in
    let denied_dirspaces =
      match work_manifest.Wm.denied_dirspaces with
      | [] -> [ ("denied_dirspaces", `List []) ]
      | dirspaces ->
          [
            ( "denied_dirspaces",
              `List
                (CCList.map
                   (fun { Wm.Deny.dirspace = { Terrat_dirspace.dir; workspace }; policy } ->
                     `Assoc
                       (CCList.flatten
                          [
                            [ ("dir", `String dir); ("workspace", `String workspace) ];
                            (match policy with
                            | Some policy ->
                                [
                                  ( "policy",
                                    `List
                                      (CCList.map
                                         (fun p ->
                                           `Assoc
                                             [
                                               ( "item",
                                                 `String
                                                   (Terrat_base_repo_config_v1.Access_control.Match
                                                    .to_string
                                                      p) );
                                             ])
                                         policy) );
                                ]
                            | None -> []);
                          ]))
                   dirspaces) );
          ]
    in
    let cost_estimation =
      hooks_pre
      |> CCOption.get_or ~default:[]
      |> CCList.filter (fun { O.step; _ } -> CCString.equal step "tf/cost-estimation")
      |> function
      | [] -> []
      | o :: _ -> (
          let changed_dirspaces =
            CCList.map
              (fun { Terrat_change.Dirspaceflow.dirspace; _ } -> dirspace)
              work_manifest.Wm.changes
          in
          match kv_of_cost_estimation changed_dirspaces o with
          | Ok kv -> [ ("cost_estimation", kv) ]
          | Error _ -> [ ("cost_estimation", Output.to_kv (output_of_raw o)) ])
    in
    let kv =
      `Assoc
        (CCList.flatten
           [
             CCOption.map_or
               ~default:[]
               (fun work_manifest_url ->
                 [ ("work_manifest_url", `String (Uri.to_string work_manifest_url)) ])
               (Ui.work_manifest_url config work_manifest.Wm.account work_manifest);
             CCOption.map_or
               ~default:[]
               (fun env -> [ ("environment", `String env) ])
               work_manifest.Wm.environment;
             [
               ( "account_status",
                 `String
                   (match account_status with
                   | `Trial_ending duration when Duration.to_day duration < 15 ->
                       (* Only mark as trial ending if less than two weeks from now *)
                       "trial_ending"
                   | `Trial_ending _ | `Active -> "active"
                   | `Expired -> "expired"
                   | `Disabled -> "disabled") );
               ( "trial_end_days",
                 match account_status with
                 | `Trial_ending duration -> `Int (Duration.to_day duration)
                 | _ -> `Int 0 );
               ("is_layered_run", `Bool is_layered_run);
               ("num_more_layers", `Int num_remaining_layers);
               ("overall_success", `Bool overall_success);
               ( "pre_hooks",
                 `List
                   (hooks_pre
                   |> CCOption.get_or ~default:[]
                   |> output_of_steps
                   |> Output.filter ~overall_success
                   |> kv_of_outputs) );
               ( "post_hooks",
                 `List
                   (hooks_post
                   |> CCOption.get_or ~default:[]
                   |> output_of_steps
                   |> Output.filter ~overall_success
                   |> kv_of_outputs) );
               ("compact_view", `Bool (view = `Compact));
               ("compact_dirspaces", `Bool (CCList.length dirspaces > 5));
               ( "dirspaces",
                 `List
                   (CCList.map
                      (fun ({ Terrat_dirspace.dir; workspace }, steps) ->
                        let has_changes = steps_has_changes steps in
                        let success = steps_success steps in
                        `Assoc
                          (CCList.flatten
                             [
                               [
                                 ("dir", `String dir);
                                 ("workspace", `String workspace);
                                 ("success", `Bool success);
                                 ( "steps",
                                   `List
                                     (kv_of_outputs
                                        (Output.filter ~overall_success (output_of_steps steps))) );
                                 ("has_changes", `Bool has_changes);
                               ];
                             ]))
                      dirspaces) );
               ( "gates",
                 let module G = Terrat_api_components.Gate in
                 `List
                   (CCList.map
                      (fun { G.all_of; any_of; any_of_count; dir; token; name; workspace } ->
                        let all_of = CCOption.get_or ~default:[] all_of in
                        let any_of = CCOption.get_or ~default:[] any_of in
                        let any_of_count = CCOption.get_or ~default:0 any_of_count in
                        let dir = CCOption.get_or ~default:"" dir in
                        let workspace = CCOption.get_or ~default:"" workspace in
                        `Assoc
                          [
                            ( "token",
                              CCOption.map_or ~default:`Null (fun token -> `String token) token );
                            ("name", CCOption.map_or ~default:`Null (fun name -> `String name) name);
                            ("dir", `String dir);
                            ("workspace", `String workspace);
                            ( "all_of",
                              `List (CCList.map (fun q -> `Assoc [ ("q", `String q) ]) all_of) );
                            ( "any_of",
                              `List
                                (CCList.map
                                   (fun q -> `Assoc [ ("q", `String q) ])
                                   (if any_of_count = 0 then [] else any_of)) );
                            ("any_of_count", `Int any_of_count);
                          ])
                   @@ CCList.sort
                        (fun { G.token = t1; name = n1; _ } { G.token = t2; name = n2; _ } ->
                          let module Cmp = struct
                            type t = string option * string option [@@deriving ord]
                          end in
                          Cmp.compare (t1, n1) (t2, n2))
                   @@ CCOption.get_or ~default:[] gates) );
             ];
             denied_dirspaces;
             cost_estimation;
           ])
    in
    let tmpl =
      match CCList.rev work_manifest.Wm.steps with
      | [] | Wm.Step.Index :: _ | Wm.Step.Build_config :: _ | Wm.Step.Build_tree :: _ ->
          assert false
      | Wm.Step.Plan :: _ -> Tmpl.plan_complete2
      | Wm.Step.(Apply | Unsafe_apply) :: _ -> Tmpl.apply_complete2
    in
    match Minijinja.render_template tmpl kv with
    | Ok body -> body
    | Error err ->
        Logs.err (fun m -> m "%s : ERROR : %s" request_id err);
        assert false
end
