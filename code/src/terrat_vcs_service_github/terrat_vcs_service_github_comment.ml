module Api = Terrat_vcs_api_github

module Scope = struct
  type t =
    | Dirspace of Terrat_dirspace.t
    | Run of {
        flow : string;
        subflow : string;
      }
  [@@deriving eq, ord]

  let of_terrat_api_scope =
    let module S = Terrat_api_components.Workflow_step_output_scope in
    let module Ds = Terrat_api_components.Workflow_step_output_scope_dirspace in
    let module R = Terrat_api_components.Workflow_step_output_scope_run in
    function
    | S.Workflow_step_output_scope_dirspace { Ds.dir; workspace; _ } ->
        Dirspace { Terrat_dirspace.dir; workspace }
    | S.Workflow_step_output_scope_run { R.flow; subflow; _ } -> Run { flow; subflow }
end

module Ui = struct
  let work_manifest_url config account work_manifest =
    let module Wm = Terrat_work_manifest3 in
    Some
      (Uri.of_string
         (Printf.sprintf
            "%s/i/%d/runs/%s"
            (Uri.to_string (Terrat_config.terrateam_web_base_url @@ Api.Config.config config))
            (Api.Account.id account)
            (Uuidm.to_string work_manifest.Wm.id)))
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

    let minus_one =
      ( "minus_one",
        Snabela.Kv.(
          function
          | I v -> I (v - 1)
          | F v -> F (v -. 1.0)
          | any -> any) )
  end

  let read fname =
    fname
    |> Terrat_files_github_tmpl.read
    |> CCOption.get_exn_or fname
    |> Snabela.Template.of_utf8_string
    |> (function
    | Ok tmpl -> tmpl
    | Error (#Snabela.Template.err as err) -> failwith (Snabela.Template.show_err err))
    |> fun tmpl ->
    Snabela.of_template tmpl Transformers.[ money; compact_plan; plan_diff; minus_one ]

  let terrateam_comment_help = read "terrateam_comment_help.tmpl"
  let apply_requirements_config_err_tag_query = read "apply_requirements_config_err_tag_query.tmpl"

  let apply_requirements_config_err_invalid_query =
    read "apply_requirements_config_err_invalid_query.tmpl"

  let apply_requirements_validation_err = read "apply_requirements_validation_err.tmpl"
  let mismatched_refs = read "mismatched_refs.tmpl"
  let missing_plans = read "missing_plans.tmpl"
  let dirspaces_owned_by_other_pull_requests = read "dirspaces_owned_by_other_pull_requests.tmpl"
  let conflicting_work_manifests = read "conflicting_work_manifests.tmpl"
  let depends_on_cycle = read "depends_on_cycle.tmpl"
  let maybe_stale_work_manifests = read "maybe_stale_work_manifests.tmpl"
  let repo_config_parse_failure = read "repo_config_parse_failure.tmpl"
  let repo_config_schema_err = read "repo_config_schema_err.tmpl"
  let repo_config_generic_failure = read "repo_config_generic_failure.tmpl"
  let pull_request_not_appliable = read "pull_request_not_appliable.tmpl"
  let pull_request_not_mergeable = read "pull_request_not_mergeable.tmpl"
  let apply_no_matching_dirspaces = read "apply_no_matching_dirspaces.tmpl"
  let plan_no_matching_dirspaces = read "plan_no_matching_dirspaces.tmpl"
  let base_branch_not_default_branch = read "dest_branch_no_match.tmpl"
  let auto_apply_running = read "auto_apply_running.tmpl"
  let bad_custom_branch_tag_pattern = read "bad_custom_branch_tag_pattern.tmpl"
  let bad_glob = read "bad_glob.tmpl"
  let unlock_success = read "unlock_success.tmpl"
  let access_control_all_dirspaces_denied = read "access_control_all_dirspaces_denied.tmpl"
  let access_control_dirspaces_denied = read "access_control_dirspaces_denied.tmpl"
  let access_control_files_denied = read "access_control_files_denied.tmpl"
  let access_control_unlock_denied = read "access_control_unlock_denied.tmpl"
  let access_control_ci_config_update_denied = read "access_control_ci_config_update_denied.tmpl"

  let access_control_terrateam_config_update_denied =
    read "access_control_terrateam_config_update_denied.tmpl"

  let access_control_lookup_err = read "access_control_lookup_err.tmpl"
  let tag_query_error = read "tag_query_error.tmpl"
  let account_expired_err = read "account_expired_err.tmpl"
  let repo_config = read "repo_config.tmpl"
  let unexpected_temporary_err = read "unexpected_temporary_err.tmpl"
  let failed_to_start_workflow = read "failed_to_start_workflow.tmpl"
  let failed_to_find_workflow = read "failed_to_find_workflow.tmpl"
  let comment_too_large = read "comment_too_large.tmpl"
  let index_complete = read "index_complete.tmpl"
  let invalid_lock_id = read "unlock_failed_bad_id.tmpl"

  (* Repo config errors *)
  let repo_config_err_access_control_policy_apply_autoapprove_match_parse_err =
    read "repo_config_err_access_control_policy_apply_autoapprove_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_apply_force_match_parse_err =
    read "repo_config_err_access_control_policy_apply_force_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_apply_match_parse_err =
    read "repo_config_err_access_control_policy_apply_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_apply_with_superapproval_match_parse_err =
    read "repo_config_err_access_control_policy_apply_with_supperapproval_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_plan_match_parse_err =
    read "repo_config_err_access_control_policy_plan_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_superapproval_match_parse_err =
    read "repo_config_err_access_control_policy_superapproval_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_tag_query_err =
    read "repo_config_err_access_control_policy_tag_query_err.tmpl"

  let repo_config_err_access_control_terrateam_config_update_match_parse_err =
    read "repo_config_err_access_control_terrateam_config_update_match_parse_err.tmpl"

  let repo_config_err_access_control_ci_config_update_match_parse_err =
    read "repo_config_err_access_control_ci_config_update_match_parse_err.tmpl"

  let repo_config_err_access_control_file_match_parse_err =
    read "repo_config_err_access_control_file_match_parse_err.tmpl"

  let repo_config_err_access_control_unlock_match_parse_err =
    read "repo_config_err_access_control_unlock_match_parse_err.tmpl"

  let repo_config_err_apply_requirements_approved_all_of_match_parse_err =
    read "repo_config_err_apply_requirements_approved_all_of_match_parse_err.tmpl"

  let repo_config_err_apply_requirements_approved_any_of_match_parse_err =
    read "repo_config_err_apply_requirements_approved_any_of_match_parse_err.tmpl"

  let repo_config_err_apply_requirements_check_tag_query_err =
    read "repo_config_err_apply_requirements_check_tag_query_err.tmpl"

  let repo_config_err_depends_on_err = read "repo_config_err_depends_on_err.tmpl"
  let repo_config_err_drift_schedule_err = read "repo_config_err_drift_schedule_err.tmpl"
  let repo_config_err_drift_tag_query_err = read "repo_config_err_drift_tag_query_err.tmpl"
  let repo_config_err_glob_parse_err = read "repo_config_err_glob_parse_err.tmpl"

  let repo_config_err_hooks_unknown_run_on_err =
    read "repo_config_err_hooks_unknown_run_on_err.tmpl"

  let repo_config_err_hooks_unknown_visible_on_err =
    read "repo_config_err_hooks_unknown_visible_on_err.tmpl"

  let repo_config_err_pattern_parse_err = read "repo_config_err_pattern_parse_err.tmpl"
  let repo_config_err_unknown_lock_policy_err = read "repo_config_err_unknown_lock_policy_err.tmpl"

  let repo_config_err_window_parse_timezone_err =
    read "repo_config_err_window_parse_timezone_err.tmpl"

  let repo_config_err_workflows_apply_unknown_run_on_err =
    read "repo_config_err_workflows_apply_unknown_run_on_err.tmpl"

  let repo_config_err_workflows_apply_unknown_visible_on_err =
    read "repo_config_err_workflows_apply_unknown_visible_on_err.tmpl"

  let repo_config_err_workflows_plan_unknown_run_on_err =
    read "repo_config_err_workflows_plan_unknown_run_on_err.tmpl"

  let repo_config_err_workflows_plan_unknown_visible_on_err =
    read "repo_config_err_workflows_plan_unknown_visible_on_err.tmpl"

  let repo_config_err_workflows_tag_query_parse_err =
    read "repo_config_err_workflows_tag_query_parse_err.tmpl"

  let plan_complete = read "plan_complete.tmpl"
  let apply_complete = read "apply_complete.tmpl"
  let plan_complete2 = read "plan_complete2.tmpl"
  let apply_complete2 = read "apply_complete2.tmpl"
  let automerge_failure = read "automerge_error.tmpl"
  let premium_feature_err_access_control = read "premium_feature_err_access_control.tmpl"

  let premium_feature_err_multiple_drift_schedules =
    read "premium_feature_err_multiple_drift_schedules.tmpl"

  let premium_feature_err_gatekeeping = read "premium_feature_err_gatekeeping.tmpl"
  let repo_config_merge_err = read "repo_config_merge_err.tmpl"
  let gate_check_failure = read "gate_check_failure.tmpl"
  let tier_check = read "tier_check.tmpl"
  let build_tree_failure = read "build_tree_failure.tmpl"
end

module Result = struct
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

  module Publisher2 = struct
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
        Snabela.Kv.(
          Map.of_list
            (CCList.flatten
               [
                 [
                   ("name", string name);
                   ("text", string text);
                   ("success", bool success);
                   ("text_decorator", string (CCOption.get_or ~default:"" text_decorator));
                 ];
                 CCOption.map_or ~default:[] (fun cmd -> [ ("cmd", string cmd) ]) cmd;
               ]))

      let filter ~overall_success =
        CCList.filter (fun { visible_on; _ } ->
            visible_on = Visible_on.Always
            || (overall_success && visible_on = Visible_on.Success)
            || ((not overall_success) && visible_on = Visible_on.Failure))
    end

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
          Snabela.Kv.(
            Map.of_list
              [
                ("name", string "cost_estimation");
                ("success", bool output.O.success);
                ("prev_monthly_cost", float summary.P.S.prev_monthly_cost);
                ("total_monthly_cost", float summary.P.S.total_monthly_cost);
                ("diff_monthly_cost", float summary.P.S.diff_monthly_cost);
                ("currency", string payload.P.currency);
                ( "dirspaces",
                  list
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
                             (Map.of_list
                                [
                                  ("dir", string dir);
                                  ("workspace", string workspace);
                                  ("prev_monthly_cost", float prev_monthly_cost);
                                  ("total_monthly_cost", float total_monthly_cost);
                                  ("diff_monthly_cost", float diff_monthly_cost);
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
        Ok Snabela.Kv.(Map.of_list [ ("success", bool output.O.success); ("text", string text) ])

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

    let create_run_output
        ~view
        dirspace_compare
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
        | [] -> []
        | dirspaces ->
            Snabela.Kv.
              [
                ( "denied_dirspaces",
                  list
                    (CCList.map
                       (fun { Wm.Deny.dirspace = { Terrat_dirspace.dir; workspace }; policy } ->
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
                                             (fun p ->
                                               Map.of_list
                                                 [
                                                   ( "item",
                                                     string
                                                       (Terrat_base_repo_config_v1.Access_control
                                                        .Match
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
            | Ok kv -> [ ("cost_estimation", Snabela.Kv.list [ kv ]) ]
            | Error _ -> [ ("cost_estimation", Snabela.Kv.list [ Output.to_kv (output_of_raw o) ]) ]
            )
      in
      let kv =
        Snabela.Kv.(
          Map.of_list
            (CCList.flatten
               [
                 CCOption.map_or
                   ~default:[]
                   (fun work_manifest_url ->
                     [ ("work_manifest_url", string (Uri.to_string work_manifest_url)) ])
                   (Ui.work_manifest_url config work_manifest.Wm.account work_manifest);
                 CCOption.map_or
                   ~default:[]
                   (fun env -> [ ("environment", string env) ])
                   work_manifest.Wm.environment;
                 [
                   ( "account_status",
                     string
                       (match account_status with
                       | `Trial_ending duration when Duration.to_day duration < 15 ->
                           (* Only mark as trial ending if less than two weeks from now *)
                           "trial_ending"
                       | `Trial_ending _ | `Active -> "active"
                       | `Expired -> "expired"
                       | `Disabled -> "disabled") );
                   ( "trial_end_days",
                     match account_status with
                     | `Trial_ending duration -> int (Duration.to_day duration)
                     | _ -> int 0 );
                   ("is_layered_run", bool is_layered_run);
                   ("num_more_layers", int num_remaining_layers);
                   ("overall_success", bool overall_success);
                   ( "pre_hooks",
                     hooks_pre
                     |> CCOption.get_or ~default:[]
                     |> output_of_steps
                     |> Output.filter ~overall_success
                     |> kv_of_outputs
                     |> list );
                   ( "post_hooks",
                     hooks_post
                     |> CCOption.get_or ~default:[]
                     |> output_of_steps
                     |> Output.filter ~overall_success
                     |> kv_of_outputs
                     |> list );
                   ("compact_view", bool (view = `Compact));
                   ("compact_dirspaces", bool (CCList.length dirspaces > 5));
                   ( "dirspaces",
                     list
                       (CCList.map
                          (fun ({ Terrat_dirspace.dir; workspace }, steps) ->
                            let has_changes = steps_has_changes steps in
                            let success = steps_success steps in
                            Map.of_list
                              (CCList.flatten
                                 [
                                   [
                                     ("dir", string dir);
                                     ("workspace", string workspace);
                                     ("success", bool success);
                                     ( "steps",
                                       list
                                         (kv_of_outputs
                                            (Output.filter ~overall_success (output_of_steps steps)))
                                     );
                                     ("has_changes", bool has_changes);
                                   ];
                                 ]))
                          dirspaces) );
                   ( "gates",
                     let module G = Terrat_api_components.Gate in
                     list
                     @@ CCList.map (fun { G.all_of; any_of; any_of_count; dir; token; workspace } ->
                            let all_of = CCOption.get_or ~default:[] all_of in
                            let any_of = CCOption.get_or ~default:[] any_of in
                            let any_of_count = CCOption.get_or ~default:0 any_of_count in
                            let dir = CCOption.get_or ~default:"" dir in
                            let workspace = CCOption.get_or ~default:"" workspace in
                            Map.of_list
                              [
                                ("token", string token);
                                ("dir", string dir);
                                ("workspace", string workspace);
                                ( "all_of",
                                  list
                                  @@ CCList.map (fun q -> Map.of_list [ ("q", string q) ]) all_of );
                                ( "any_of",
                                  list
                                  @@ CCList.map
                                       (fun q -> Map.of_list [ ("q", string q) ])
                                       (if any_of_count = 0 then [] else any_of) );
                                ("any_of_count", int any_of_count);
                              ])
                     @@ CCList.sort (fun { G.token = t1; _ } { G.token = t2; _ } ->
                            CCString.compare t1 t2)
                     @@ CCOption.get_or ~default:[] gates );
                 ];
                 denied_dirspaces;
                 cost_estimation;
               ]))
      in
      let tmpl =
        match CCList.rev work_manifest.Wm.steps with
        | [] | Wm.Step.Index :: _ | Wm.Step.Build_config :: _ | Wm.Step.Build_tree :: _ ->
            assert false
        | Wm.Step.Plan :: _ -> Tmpl.plan_complete2
        | Wm.Step.(Apply | Unsafe_apply) :: _ -> Tmpl.apply_complete2
      in
      match Snabela.apply tmpl kv with
      | Ok body -> body
      | Error (#Snabela.err as err) ->
          Logs.err (fun m -> m "%s : ERROR : %a" request_id Snabela.pp_err err);
          assert false
  end
end

module S = struct
  type t = { client : Terrat_vcs_api_github.Client.t }

  type el = {
    rendered_length : int;
    dirspace : Terrat_dirspace.t;
    is_success : bool;
    strategy : Terrat_vcs_comment.Strategy.t;
    step_outputs : Terrat_api_components_workflow_step_output.t list;
  }

  type comment_id = int

  module Cmp = struct
    type t = bool * bool * Terrat_dirspace.t [@@deriving ord]
  end

  let query_comment_id t el = 1000
  let query_els_for_comment_id t cid = []
  let upsert_comment_id t els cid = Abb.Future.return (Ok ())
  let delete_comment t comment_id = Abb.Future.return (Ok ())
  let minimize_comment t comment_id = Abb.Future.return (Ok ())

  let post_comment t els =
    let module Gh = Terrat_vcs_api_github in
    let _request_id = "test" in
    Abb.Future.return (Ok 1)

  let rendered_length els = CCList.fold_left (fun acc el -> acc + el.rendered_length) 0 els
  let dirspace el = el.dirspace
  let is_success el = el.is_success
  let strategy el = el.strategy

  (* TODO: For testing purposes only, will change this later *)
  (* TODO: Wirte with proper templates on Tmpl later *)
  let compact el = { el with rendered_length = 2048 }

  let compare_el el1 el2 =
    let dirspace1 = dirspace el1 in
    let steps1 = el1.step_outputs in
    let dirspace2 = dirspace el2 in
    let steps2 = el2.step_outputs in
    let has_changes1 = Result.steps_has_changes steps1 in
    let success1 = Result.steps_success steps2 in
    let has_changes2 = Result.steps_has_changes steps2 in
    let success2 = Result.steps_success steps2 in
    (* Negate has_changes because the order of [bool] is [false]
            before [true]. *)
    Cmp.compare (not has_changes1, success1, dirspace1) (not has_changes2, success2, dirspace2)

  (* Github Limits it to 2^16 = 65536
     https://github.com/mshick/add-pr-comment/issues/93#issuecomment-1531415467
     I set it to a smaller value *)
  let max_comment_length = 65536 / 2
end
