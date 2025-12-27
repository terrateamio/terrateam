module Fc = Abbs_future_combinators
module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context
module Msg = Terrat_vcs_provider2.Msg
module P2 = Terrat_vcs_provider2

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  let src = Logs.Src.create ("vcs_event_evaluator2_tasks_branch." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Wm_sm = Terrat_vcs_event_evaluator2_wm_sm.Make (S) (Keys)
  module Repo_tree_wm = Terrat_vcs_event_evaluator2_wm_sm_repo_tree.Make (S) (Keys)
  module Build_config_wm = Terrat_vcs_event_evaluator2_wm_sm_build_config.Make (S) (Keys)
  module Indexer_wm = Terrat_vcs_event_evaluator2_wm_sm_indexer.Make (S) (Keys)
  module Tf_op_wm = Terrat_vcs_event_evaluator2_wm_sm_tf_op.Make (S) (Keys)
  module Access_control = Terrat_vcs_event_evaluator2_access_control.Make (S) (Keys)
  module Hmap = Keys.Hmap
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module B = Builder.B
  module Bs = Builder.Bs
  module Tasks_base = Terrat_vcs_event_evaluator2_tasks_base.Make (S) (Keys)

  module Tasks = struct
    let run = Tasks_base.run

    let branch_name =
      run ~name:"branch_name" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.context
          >>= function
          | { Tjc.Context.scope = Tjc.Context.Scope.Branch (branch_name, _); _ } ->
              Abb.Future.return (Ok branch_name)
          | _ -> assert false)

    let branch_ref =
      run ~name:"branch_ref" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.context
          >>= function
          | { Tjc.Context.scope = Tjc.Context.Scope.Branch (branch_name, _); _ } -> (
              fetch Keys.client
              >>= fun client ->
              fetch Keys.repo
              >>= fun repo ->
              S.Api.fetch_branch_sha ~request_id:(Builder.log_id s) client repo branch_name
              >>= function
              | Some ref_ -> Abb.Future.return (Ok ref_)
              | None -> Abb.Future.return (Error `Error))
          | _ -> assert false)

    let dest_branch_name =
      run ~name:"dest_branch_name" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.context
          >>= function
          | { Tjc.Context.scope = Tjc.Context.Scope.Branch (_, Some dest_branch_name); _ } ->
              Abb.Future.return (Ok dest_branch_name)
          | { Tjc.Context.scope = Tjc.Context.Scope.Branch (_, None); _ } -> assert false
          | _ -> assert false)

    let dest_branch_ref =
      run ~name:"dest_branch_ref" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.context
          >>= function
          | { Tjc.Context.scope = Tjc.Context.Scope.Branch (_, Some dest_branch_name); _ } -> (
              fetch Keys.client
              >>= fun client ->
              fetch Keys.repo
              >>= fun repo ->
              S.Api.fetch_branch_sha ~request_id:(Builder.log_id s) client repo dest_branch_name
              >>= function
              | Some ref_ -> Abb.Future.return (Ok ref_)
              | None -> Abb.Future.return (Error `Error))
          | { Tjc.Context.scope = Tjc.Context.Scope.Branch (_, None); _ } -> assert false
          | _ -> assert false)

    let working_branch_ref =
      run ~name:"working_branch_ref" (fun _s { Bs.Fetcher.fetch } -> fetch Keys.branch_ref)

    let working_branch_name =
      run ~name:"working_branch_name" (fun _s { Bs.Fetcher.fetch } -> fetch Keys.branch_name)

    let out_of_change_applies =
      run ~name:"out_of_change_applies" (fun _ _ -> Abb.Future.return (Ok []))

    let applied_dirspaces = run ~name:"applied_dirspaces" (fun _ _ -> Abb.Future.return (Ok []))

    let changes =
      run ~name:"changes" (fun _s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.repo_tree_branch
          >>= fun tree ->
          Abb.Future.return
            (Ok (CCList.map (fun filename -> Terrat_change.Diff.Change { filename }) tree)))

    let missing_autoplan_matches =
      run ~name:"missing_autoplan_matches" (fun _ _ ->
          Abb.Future.return (Ok (fun matches -> Abb.Future.return (Ok matches))))

    let is_draft_pr =
      run ~name:"is_draft_pr" (fun s { Bs.Fetcher.fetch } -> Abb.Future.return (Ok false))

    let can_run_plan =
      run ~name:"can_run_plan" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.branch_dirspaces) (fetch Keys.dest_branch_dirspaces)
          >>= fun (_, _) -> Abb.Future.return (Ok ()))

    let can_run_apply =
      run ~name:"can_run_apply" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.branch_dirspaces) (fetch Keys.dest_branch_dirspaces)
          >>= fun (_, _) -> Abb.Future.return (Ok ()))

    let publish_comment =
      run ~name:"publish_comment" (fun _ _ ->
          Abb.Future.return (Ok (fun _ -> Abb.Future.return (Ok ()))))

    let create_commit_checks =
      run ~name:"create_commit_checks" (fun _ _ ->
          Abb.Future.return (Ok (fun _ _ -> Abb.Future.return (Ok ()))))
  end

  let tasks tasks =
    let coerce = Builder.coerce_to_task in
    tasks
    (* |> Hmap.add (coerce Keys.access_control_eval_apply) Tasks.access_control_eval_apply *)
    |> Hmap.add (coerce Keys.applied_dirspaces) Tasks.applied_dirspaces
    |> Hmap.add (coerce Keys.branch_name) Tasks.branch_name
    |> Hmap.add (coerce Keys.branch_ref) Tasks.branch_ref
    |> Hmap.add (coerce Keys.can_run_apply) Tasks.can_run_apply
    |> Hmap.add (coerce Keys.can_run_plan) Tasks.can_run_plan
    |> Hmap.add (coerce Keys.changes) Tasks.changes
    (* |> Hmap.add (coerce Keys.check_access_control_apply) Tasks.check_access_control_apply *)
    (* |> Hmap.add (coerce Keys.check_access_control_ci_change) Tasks.check_access_control_ci_change *)
    (* |> Hmap.add (coerce Keys.check_access_control_files) Tasks.check_access_control_files *)
    (* |> Hmap.add (coerce Keys.check_access_control_plan) Tasks.check_access_control_plan *)
    (* |> Hmap.add *)
    (*      (coerce Keys.check_access_control_repo_config) *)
    (*      Tasks.check_access_control_repo_config *)
    (* |> Hmap.add *)
    (*      (coerce Keys.check_conflicting_apply_work_manifests) *)
    (*      Tasks.check_conflicting_apply_work_manifests *)
    (* |> Hmap.add *)
    (*      (coerce Keys.check_conflicting_plan_work_manifests) *)
    (*      Tasks.check_conflicting_plan_work_manifests *)
    (* |> Hmap.add (coerce Keys.check_dirspaces_missing_plans) Tasks.check_dirspaces_missing_plans *)
    (* |> Hmap.add *)
    (*      (coerce Keys.check_dirspaces_owned_by_other_pull_requests) *)
    (* (\*      Tasks.check_dirspaces_owned_by_other_pull_requests *\) *)
    (* |> Hmap.add (coerce Keys.check_dirspaces_to_apply) Tasks.check_dirspaces_to_apply *)
    (* |> Hmap.add (coerce Keys.check_dirspaces_to_plan) Tasks.check_dirspaces_to_plan *)
    (* |> Hmap.add (coerce Keys.check_merge_conflict) Tasks.check_merge_conflict *)
    |> Hmap.add (coerce Keys.create_commit_checks) Tasks.create_commit_checks
    |> Hmap.add (coerce Keys.dest_branch_name) Tasks.dest_branch_name
    |> Hmap.add (coerce Keys.dest_branch_ref) Tasks.dest_branch_ref
    |> Hmap.add (coerce Keys.is_draft_pr) Tasks.is_draft_pr
    |> Hmap.add (coerce Keys.missing_autoplan_matches) Tasks.missing_autoplan_matches
    |> Hmap.add (coerce Keys.out_of_change_applies) Tasks.out_of_change_applies
    |> Hmap.add (coerce Keys.working_branch_name) Tasks.working_branch_name
    |> Hmap.add (coerce Keys.working_branch_ref) Tasks.working_branch_ref
end
