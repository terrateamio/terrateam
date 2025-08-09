module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  module Wm = Terrat_work_manifest3
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)

  type existing_wm =
    ( S.Api.Account.t,
      ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
    Terrat_work_manifest3.Existing.t

  let token encryption_key id =
    Base64.encode_exn
    @@ Cstruct.to_string
    @@ Mirage_crypto.Hash.SHA256.hmac ~key:encryption_key
    @@ Cstruct.of_string
    @@ Ouuid.to_string id

  let match_tag_queries ~accessor ~changes queries =
    CCList.map
      (fun change ->
        ( change,
          CCList.find_idx
            (fun q -> Terrat_change_match3.match_tag_query ~tag_query:(accessor q) change)
            queries ))
      changes

  let dirspaceflows_of_changes_with_branch_target repo_config changes =
    let module R = Terrat_base_repo_config_v1 in
    let workflows = R.workflows repo_config in
    Ok
      (CCList.map
         (fun ({ Terrat_change_match3.Dirspace_config.dirspace; lock_branch_target; _ }, workflow)
            ->
           let module Dsf = Terrat_change.Dirspaceflow in
           {
             Dsf.dirspace;
             workflow =
               ( lock_branch_target,
                 CCOption.map (fun (idx, workflow) -> { Dsf.Workflow.idx; workflow }) workflow );
           })
         (match_tag_queries
            ~accessor:(fun { R.Workflows.Entry.tag_query; _ } -> tag_query)
            ~changes
            workflows))

  let strip_lock_branch_target dsfs =
    let module Dsf = Terrat_change.Dirspaceflow in
    CCList.map (fun ({ Dsf.workflow = _, workflow; _ } as dsf) -> { dsf with Dsf.workflow }) dsfs

  let dirspaceflows_of_changes repo_config changes =
    let open CCResult.Infix in
    dirspaceflows_of_changes_with_branch_target repo_config changes
    >>= fun dirspaceflows -> Ok (strip_lock_branch_target dirspaceflows)

  let all_wms_completed =
    CCList.for_all (function
      | { Wm.state = Wm.State.(Completed | Aborted); _ } -> true
      | _ -> false)

  let run ~name ~eq ~create ~initiate ~fail ~result s ({ Builder.Bs.Fetcher.fetch } as fetcher) =
    let open Irm in
    let module E = Keys.Work_manifest_event in
    fetch Keys.work_manifest_event
    >>= function
    | Some
        (E.Initiate
           {
             work_manifest = { Wm.id; state = Wm.State.(Queued | Running); _ } as work_manifest;
             run_id;
           })
      when eq work_manifest ->
        Logs.info (fun m -> m "%s : WM : INITIATE : name=%s" (Builder.log_id s) name);
        Builder.run_db s ~f:(fun db ->
            S.Work_manifest.update_run_id ~request_id:(Builder.log_id s) db id run_id
            >>= fun () ->
            S.Work_manifest.update_state ~request_id:(Builder.log_id s) db id Wm.State.Running)
        >>= fun () ->
        initiate work_manifest s fetcher
        >>= fun response ->
        fetch Keys.compute_node_id
        >>= fun compute_node_id ->
        Builder.run_db s ~f:(fun db ->
            S.Job_context.Compute_node.set_work
              ~request_id:(Builder.log_id s)
              ~compute_node_id
              ~work_manifest:id
              db
              response)
        >>= fun () -> Abb.Future.return (Error (`Suspend_eval_err name))
    | Some (E.Fail { work_manifest }) when eq work_manifest -> (
        Logs.info (fun m -> m "%s : WM : FAIL : name=%s" (Builder.log_id s) name);
        fail work_manifest s fetcher
        >>= fun () ->
        fetch Keys.work_manifests_for_job
        >>= function
        | wms when all_wms_completed @@ CCList.filter eq wms ->
            Abb.Future.return (Ok (CCList.filter eq wms))
        | _ -> Abb.Future.return (Error (`Suspend_eval_err name)))
    | Some (E.Result { work_manifest; result = wm_result }) when eq work_manifest -> (
        Logs.info (fun m -> m "%s : WM : RESULT : name=%s" (Builder.log_id s) name);
        result work_manifest wm_result s fetcher
        >>= fun () ->
        Builder.run_db s ~f:(fun db ->
            S.Work_manifest.update_state
              ~request_id:(Builder.log_id s)
              db
              work_manifest.Wm.id
              Wm.State.Completed)
        >>= fun () ->
        fetch Keys.work_manifests_for_job
        >>= function
        | wms when all_wms_completed @@ CCList.filter eq wms ->
            Abb.Future.return (Ok (CCList.filter eq wms))
        | _ -> Abb.Future.return (Error (`Suspend_eval_err name)))
    | Some _ | None -> (
        fetch Keys.work_manifests_for_job
        >>= fun wms ->
        match CCList.filter eq wms with
        | [] ->
            Logs.info (fun m -> m "%s : WM : CREATE : name=%s" (Builder.log_id s) name);
            create s fetcher
            >>= fun wms ->
            fetch Keys.job
            >>= fun job ->
            Builder.run_db s ~f:(fun db ->
                Abbs_future_combinators.List_result.iter
                  ~f:(fun { Wm.id = work_manifest_id; _ } ->
                    S.Job_context.Job.add_work_manifest
                      ~request_id:(Builder.log_id s)
                      db
                      ~job_id:job.Tjc.Job.id
                      ~work_manifest_id
                      ())
                  wms)
            >>= fun () -> Abb.Future.return (Error (`Suspend_eval_err name))
        | wms when all_wms_completed wms ->
            Logs.info (fun m ->
                m "%s : WM : CREATE : name=%s : all_wms_completed" (Builder.log_id s) name);
            Abb.Future.return (Ok wms)
        | _ ->
            Logs.info (fun m ->
                m "%s : WM : CREATE : name=%s : not_all_wms_completed" (Builder.log_id s) name);
            Abb.Future.return (Error (`Suspend_eval_err name)))
end
