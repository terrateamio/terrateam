module Fc = Abbs_future_combinators
module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context
module Msg = Terrat_vcs_provider2.Msg
module P2 = Terrat_vcs_provider2

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  let src = Logs.Src.create ("vcs_event_evaluator2_tasks_adhoc." ^ S.name)

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

  let time_it s l f =
    Abbs_time_it.run (fun time -> Logs.info (fun m -> l m (Builder.log_id s) time)) f

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
          fetch Keys.branch_name
          >>= fun branch_name ->
          fetch Keys.client
          >>= fun client ->
          fetch Keys.repo
          >>= fun repo ->
          time_it
            s
            (fun m log_id time ->
              m
                "%s : FETCH_BRANCH_SHA : repo = %s : branch = %s : time=%f"
                log_id
                (S.Api.Repo.to_string repo)
                (S.Api.Ref.to_string branch_name)
                time)
            (fun () ->
              S.Api.fetch_branch_sha ~request_id:(Builder.log_id s) client repo branch_name)
          >>= function
          | Some ref_ -> Abb.Future.return (Ok ref_)
          | None -> Abb.Future.return (Error `Error))

    let dest_branch_name =
      run ~name:"dest_branch_name" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.context
          >>= function
          | { Tjc.Context.scope = Tjc.Context.Scope.Branch (_, Some dest_branch_name); _ } ->
              Abb.Future.return (Ok dest_branch_name)
          | { Tjc.Context.scope = Tjc.Context.Scope.Branch (branch_name, None); _ } ->
              Abb.Future.return (Ok branch_name)
          | _ -> assert false)

    let dest_branch_ref =
      run ~name:"dest_branch_ref" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.dest_branch_name
          >>= fun dest_branch_name ->
          fetch Keys.client
          >>= fun client ->
          fetch Keys.repo
          >>= fun repo ->
          time_it
            s
            (fun m log_id time ->
              m
                "%s : FETCH_BRANCH_SHA : repo = %s : branch = %s : time=%f"
                log_id
                (S.Api.Repo.to_string repo)
                (S.Api.Ref.to_string dest_branch_name)
                time)
            (fun () ->
              S.Api.fetch_branch_sha ~request_id:(Builder.log_id s) client repo dest_branch_name)
          >>= function
          | Some ref_ -> Abb.Future.return (Ok ref_)
          | None -> Abb.Future.return (Error `Error))

    let working_dest_branch_ref =
      run ~name:"working_dest_branch_ref" (fun _ { Bs.Fetcher.fetch } -> fetch Keys.dest_branch_ref)

    let working_branch_ref =
      run ~name:"working_branch_ref" (fun _s { Bs.Fetcher.fetch } -> fetch Keys.branch_ref)

    let working_branch_name =
      run ~name:"working_branch_name" (fun _s { Bs.Fetcher.fetch } -> fetch Keys.branch_name)

    let out_of_change_applies =
      run ~name:"out_of_change_applies" (fun _ _ -> Abb.Future.return (Ok []))

    let changes =
      run ~name:"changes" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.dest_branch_name) (fetch Keys.branch_name)
          >>= function
          | dest_branch_name, branch_name when S.Api.Ref.equal dest_branch_name branch_name ->
              fetch Keys.repo_tree_branch
              >>= fun tree ->
              Abb.Future.return
                (Ok (CCList.map (fun filename -> Terrat_change.Diff.Change { filename }) tree))
          | dest_branch_name, branch_name ->
              fetch Keys.client
              >>= fun client ->
              fetch Keys.repo
              >>= fun repo ->
              time_it
                s
                (fun m log_id time ->
                  m
                    "%s : FETCH_DIFF_FILES : repo = %s : base_branch = %s : branch = %s : time=%f"
                    log_id
                    (S.Api.Repo.to_string repo)
                    (S.Api.Ref.to_string dest_branch_name)
                    (S.Api.Ref.to_string branch_name)
                    time)
                (fun () ->
                  S.Api.fetch_diff_files
                    ~request_id:(Builder.log_id s)
                    ~base_ref:dest_branch_name
                    ~branch_ref:branch_name
                    repo
                    client))

    let missing_autoplan_matches =
      run ~name:"missing_autoplan_matches" (fun _ _ ->
          Abb.Future.return (Ok (fun matches -> Abb.Future.return (Ok matches))))

    let is_draft_pr =
      run ~name:"is_draft_pr" (fun s { Bs.Fetcher.fetch } -> Abb.Future.return (Ok false))

    let check_conflicting_apply_work_manifests =
      run ~name:"check_conflicting_apply_work_manifests" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.working_set_matches
          >>= fun working_set_matches ->
          fetch Keys.context
          >>= fun context ->
          let dirspaces =
            CCList.map
              (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } -> dirspace)
              working_set_matches
          in
          Builder.run_db s ~f:(fun db ->
              time_it
                s
                (fun m log_id time ->
                  m
                    "%s : QUERY_CONFLICTING_WORK_MANIFESTS : context_id = %a : time=%f"
                    log_id
                    Uuidm.pp
                    context.Tjc.Context.id
                    time)
                (fun () ->
                  S.Db.query_conflicting_work_manifests_in_repo_for_context
                    ~request_id:(Builder.log_id s)
                    db
                    context
                    dirspaces
                    `Apply))
          >>= function
          | None -> Abb.Future.return (Ok ())
          | Some (P2.Conflicting_work_manifests.Conflicting _) -> Abb.Future.return (Error `Noop)
          | Some (P2.Conflicting_work_manifests.Maybe_stale _) -> Abb.Future.return (Error `Noop))

    let can_run_plan =
      run ~name:"can_run_plan" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.branch_dirspaces) (fetch Keys.dest_branch_dirspaces)
          >>= fun (_, _) -> Abb.Future.return (Ok ()))

    let check_dirspaces_missing_plans =
      run ~name:"check_dirspaces_missing_plans" (fun s { Bs.Fetcher.fetch } ->
          let module R = Terrat_access_control2.R in
          let open Irm in
          fetch Keys.dest_branch_ref
          >>= fun base_ref ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          fetch Keys.repo
          >>= fun repo ->
          fetch Keys.access_control_eval_apply
          >>= fun access_control_result ->
          Abb.Future.return
            (access_control_result
              : (R.t, Terrat_access_control2.err) result
              :> (R.t, [> Terrat_access_control2.err ]) result)
          >>= fun { Terrat_access_control2.R.pass = working_set_matches; _ } ->
          let dirspaces =
            CCList.map
              (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } -> dirspace)
              working_set_matches
          in
          Builder.run_db s ~f:(fun db ->
              time_it
                s
                (fun m log_id time ->
                  m
                    "%s : QUERY_DIRSPACES_WITHOUT_VALID_PLANS_FOR_BRANCH : repo=%s : time=%f"
                    log_id
                    (S.Api.Repo.to_string repo)
                    time)
                (fun () ->
                  S.Db.query_dirspaces_without_valid_plans_for_branch
                    ~request_id:(Builder.log_id s)
                    ~base_ref
                    ~branch_ref
                    db
                    repo
                    dirspaces))
          >>= function
          | [] -> Abb.Future.return (Ok ())
          | _dirspaces -> Abb.Future.return (Error `Noop))

    let can_run_apply =
      run ~name:"can_run_apply" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.ignore
          @@ Fc.Result.all4
               (fetch Keys.check_conflicting_apply_work_manifests)
               (fetch Keys.check_dirspaces_missing_plans)
               (fetch Keys.branch_dirspaces)
               (fetch Keys.dest_branch_dirspaces)
          >>= fun () -> Abb.Future.return (Ok ()))

    let publish_comment =
      run ~name:"publish_comment" (fun _ _ ->
          Abb.Future.return (Ok (fun _ -> Abb.Future.return (Ok ()))))

    let create_commit_checks =
      run ~name:"create_commit_checks" (fun _ _ ->
          Abb.Future.return (Ok (fun _ _ -> Abb.Future.return (Ok ()))))

    (* For ad-hoc runs, always treat all dirspaces as unapplied.
       This ensures every adhoc plan plans everything, regardless of
       whether a previous adhoc plan+apply cycle was completed. *)
    let applied_dirspaces =
      run ~name:"applied_dirspaces" (fun _s _fetcher -> Abb.Future.return (Ok []))

    (* Real access control evaluation for plan - fetches the access control
       engine and evaluates policies, unlike Tasks_branch which auto-passes. *)
    let access_control_eval_plan =
      run ~name:"access_control_eval_plan" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.access_control
          >>= fun access_control ->
          fetch Keys.working_set_matches
          >>= fun working_set_matches ->
          let open Abb.Future.Infix_monad in
          Access_control.eval_tf_operation access_control working_set_matches `Plan
          >>= fun ret -> Abb.Future.return (Ok ret))

    (* For ad-hoc apply, pass all dirspaces through access control.
       The API endpoint enforces installation-level access. Per-directory
       apply policies reference PR reviewers which don't exist in ad-hoc
       context, so we auto-pass here. *)
    let access_control_eval_apply =
      run ~name:"access_control_eval_apply" (fun _s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.working_set_matches
          >>= fun working_set_matches ->
          let r = Terrat_access_control2.{ R.deny = []; pass = working_set_matches } in
          Abb.Future.return (Ok (Ok r)))

    let maybe_automerge = run ~name:"maybe_automerge" (fun _s _fetcher -> Abb.Future.return (Ok ()))
  end

  let tasks tasks =
    let coerce = Builder.coerce_to_task in
    tasks
    |> Hmap.add (coerce Keys.access_control_eval_apply) Tasks.access_control_eval_apply
    |> Hmap.add (coerce Keys.access_control_eval_plan) Tasks.access_control_eval_plan
    |> Hmap.add (coerce Keys.applied_dirspaces) Tasks.applied_dirspaces
    |> Hmap.add (coerce Keys.branch_name) Tasks.branch_name
    |> Hmap.add (coerce Keys.branch_ref) Tasks.branch_ref
    |> Hmap.add (coerce Keys.can_run_apply) Tasks.can_run_apply
    |> Hmap.add (coerce Keys.can_run_plan) Tasks.can_run_plan
    |> Hmap.add (coerce Keys.changes) Tasks.changes
    |> Hmap.add
         (coerce Keys.check_conflicting_apply_work_manifests)
         Tasks.check_conflicting_apply_work_manifests
    |> Hmap.add (coerce Keys.check_dirspaces_missing_plans) Tasks.check_dirspaces_missing_plans
    |> Hmap.add (coerce Keys.create_commit_checks) Tasks.create_commit_checks
    |> Hmap.add (coerce Keys.dest_branch_name) Tasks.dest_branch_name
    |> Hmap.add (coerce Keys.dest_branch_ref) Tasks.dest_branch_ref
    |> Hmap.add (coerce Keys.is_draft_pr) Tasks.is_draft_pr
    |> Hmap.add (coerce Keys.maybe_automerge) Tasks.maybe_automerge
    |> Hmap.add (coerce Keys.missing_autoplan_matches) Tasks.missing_autoplan_matches
    |> Hmap.add (coerce Keys.out_of_change_applies) Tasks.out_of_change_applies
    |> Hmap.add (coerce Keys.publish_comment) Tasks.publish_comment
    |> Hmap.add (coerce Keys.working_branch_name) Tasks.working_branch_name
    |> Hmap.add (coerce Keys.working_branch_ref) Tasks.working_branch_ref
    |> Hmap.add (coerce Keys.working_dest_branch_ref) Tasks.working_dest_branch_ref
end
