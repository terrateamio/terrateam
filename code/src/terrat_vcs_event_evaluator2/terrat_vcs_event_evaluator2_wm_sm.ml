module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  let src = Logs.Src.create ("vcs_event_evaluator2_wm_sm." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Wm = Terrat_work_manifest3
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)

  type existing_wm =
    ( S.Api.Account.t,
      ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
    Terrat_work_manifest3.Existing.t
  [@@deriving show]

  (* Wrapper so that when we call [publish_comment] the error type lines up *)
  let publish_comment' f msg =
    let open Abb.Future.Infix_monad in
    f msg
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error `Error -> Abb.Future.return (Error `Error)

  let create_token installation_id work_manifest_id db =
    let open Abbs_future_combinators.Infix_result_monad in
    Terrat_user.create_system_user
      ~access_token_id:work_manifest_id
      ~capabilities:
        Terrat_user.Capability.
          [
            Installation_id (S.Api.Account.Id.to_string installation_id);
            Kv_store_read;
            Kv_store_write;
          ]
      db
    >>= fun user -> Terrat_user.Token.to_token db user

  let create_token' ~log_id installation_id work_manifest_id db =
    let open Abb.Future.Infix_monad in
    create_token installation_id work_manifest_id db
    >>= function
    | Ok _ as r -> Abb.Future.return r
    | Error (#Terrat_user.Token.to_token_err as err) ->
        Logs.err (fun m -> m "%s : CREATE_TOKEN : %a" log_id Terrat_user.Token.pp_to_token_err err);
        Abb.Future.return (Error `Error)

  let match_tag_queries ~accessor ~changes queries =
    CCList.map
      (fun change ->
        ( change,
          CCList.find_idx
            (fun q -> Terrat_change_match3.match_tag_query ~tag_query:(accessor q) change)
            queries ))
      changes

  let replace_stack_vars vars s =
    Str_template.apply (CCFun.flip Terrat_data.String_map.find_opt vars) s

  let apply_stack_vars_to_workflow stack workflow =
    let module R = Terrat_base_repo_config_v1 in
    let module E = R.Workflows.Entry in
    let module S = R.Stacks.Stack in
    let {
      E.apply = _;
      engine = _;
      environment;
      integrations = _;
      lock_policy = _;
      plan = _;
      runs_on = _;
      tag_query = _;
    } =
      workflow
    in
    let open CCResult.Infix in
    CCResult.opt_map (replace_stack_vars stack.S.variables) environment
    >>= fun environment -> Ok { workflow with E.environment }

  let dirspaceflows_of_changes_with_branch_target repo_config changes =
    let module R = Terrat_base_repo_config_v1 in
    let module S = R.Stacks in
    let workflows = R.workflows repo_config in
    CCResult.map_l
      (fun ( {
               Terrat_change_match3.Dirspace_config.dirspace;
               lock_branch_target;
               stack_config = { S.Stack.variables; _ } as stack_config;
               _;
             },
             workflow )
         ->
        let open CCResult.Infix in
        let module Dsf = Terrat_change.Dirspaceflow in
        CCResult.opt_map
          (fun (idx, workflow) ->
            let open CCResult.Infix in
            apply_stack_vars_to_workflow stack_config workflow
            >>= fun workflow -> Ok { Dsf.Workflow.idx; workflow })
          workflow
        >>= fun workflow ->
        Ok { Dsf.dirspace; workflow = (lock_branch_target, workflow); variables = Some variables })
      (match_tag_queries
         ~accessor:(fun { R.Workflows.Entry.tag_query; _ } -> tag_query)
         ~changes
         workflows)

  let strip_lock_branch_target dsfs =
    let module Dsf = Terrat_change.Dirspaceflow in
    CCList.map (fun ({ Dsf.workflow = _, workflow; _ } as dsf) -> { dsf with Dsf.workflow }) dsfs

  let dirspaceflows_of_changes repo_config changes =
    let open CCResult.Infix in
    dirspaceflows_of_changes_with_branch_target repo_config changes
    >>= fun dirspaceflows -> Ok (strip_lock_branch_target dirspaceflows)

  let update_wm_state ~request_id ~name work_manifest_id state db =
    Logs.info (fun m ->
        m
          "%s : WM : UPDATE_STATE : name=%s : wm=%a : state=%s"
          request_id
          name
          Uuidm.pp
          work_manifest_id
          (Terrat_work_manifest3.State.to_string state));
    S.Work_manifest.update_state ~request_id db work_manifest_id state

  let all_wms_completed =
    CCList.for_all (function
      | { Wm.state = Wm.State.(Completed | Aborted); _ } -> true
      | _ -> false)

  let publish_fail s { Builder.Bs.Fetcher.fetch } = function
    | (`Failed_to_start_with_msg_err _ | `Failed_to_start | `Missing_workflow) as err ->
        let open Irm in
        fetch Keys.publish_comment
        >>= fun publish_comment ->
        publish_comment' publish_comment (Terrat_vcs_provider2.Msg.Run_work_manifest_err err)
    | `Error ->
        let open Irm in
        fetch Keys.publish_comment
        >>= fun publish_comment ->
        publish_comment' publish_comment Terrat_vcs_provider2.Msg.Unexpected_temporary_err

  let run
      ~name
      ~eq
      ~dest_branch_ref
      ~branch_ref
      ~branch
      ~create
      ~initiate
      ~fail
      ~result
      s
      ({ Builder.Bs.Fetcher.fetch } as fetcher) =
    let open Irm in
    let module E = Keys.Work_manifest_event in
    Logs.info (fun m -> m "%s : WM : RUN : name=%s" (Builder.log_id s) name);
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
            Logs.info (fun m ->
                m
                  "%s : WM : UPDATE_RUN_ID : name=%s : wm=%a : run_id=%s"
                  (Builder.log_id s)
                  name
                  Uuidm.pp
                  id
                  run_id);
            S.Work_manifest.update_run_id ~request_id:(Builder.log_id s) db id run_id
            >>= fun () ->
            update_wm_state ~request_id:(Builder.log_id s) ~name id Wm.State.Running db)
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
        >>= fun () -> Abb.Future.return (Error (`Suspend_eval name))
    | Some (E.Fail { work_manifest; error }) when eq work_manifest -> (
        Logs.info (fun m -> m "%s : WM : FAIL : name=%s" (Builder.log_id s) name);
        fail work_manifest s fetcher
        >>= fun () ->
        publish_fail s fetcher error
        >>= fun () ->
        fetch Keys.work_manifests_for_job
        >>= function
        | wms when all_wms_completed @@ CCList.filter eq wms ->
            Abb.Future.return (Ok (CCList.filter eq wms))
        | _ -> Abb.Future.return (Error (`Suspend_eval name)))
    | Some (E.Result { work_manifest; result = wm_result }) when eq work_manifest -> (
        Logs.info (fun m -> m "%s : WM : RESULT : name=%s" (Builder.log_id s) name);
        result work_manifest wm_result s fetcher
        >>= fun () ->
        Builder.run_db
          s
          ~f:
            (update_wm_state
               ~request_id:(Builder.log_id s)
               ~name
               work_manifest.Wm.id
               Wm.State.Completed)
        >>= fun () ->
        fetch Keys.job
        >>= fun job ->
        (* Explicitly query the work manifests for this job because we might
           have already created work manifests in parallel operations so we
           don't need to do it again. *)
        Builder.run_db s ~f:(fun db ->
            S.Job_context.Job.query_work_manifests
              ~request_id:(Builder.log_id s)
              db
              ~job_id:job.Tjc.Job.id
              ())
        >>= function
        | wms when all_wms_completed @@ CCList.filter eq wms ->
            Abb.Future.return (Ok (CCList.filter eq wms))
        | _ -> Abb.Future.return (Error (`Suspend_eval name)))
    | Some _ | None -> (
        fetch Keys.job
        >>= fun job ->
        (* Explicitly query the work manifests for this job because we might
           have already created work manifests in parallel operations so we
           don't need to do it again. *)
        Builder.run_db s ~f:(fun db ->
            S.Job_context.Job.query_work_manifests
              ~request_id:(Builder.log_id s)
              db
              ~job_id:job.Tjc.Job.id
              ())
        >>= fun wms ->
        match CCList.filter eq wms with
        | [] -> (
            Logs.info (fun m -> m "%s : WM : CREATE : name=%s" (Builder.log_id s) name);
            create ~dest_branch_ref ~branch_ref ~branch s fetcher
            >>= function
            | [] ->
                Logs.info (fun m ->
                    m "%s : WM : CREATE : name=%s : NO_WORK_MANIFESTS" (Builder.log_id s) name);
                Abb.Future.return (Ok [])
            | wms ->
                CCList.iter
                  (fun {
                         Terrat_work_manifest3.id;
                         base_ref;
                         branch_ref;
                         environment;
                         runs_on;
                         steps;
                         _;
                       }
                     ->
                    Logs.info (fun m ->
                        m
                          "%s : CREATED_WORK_MANIFEST : id=%a : base_ref=%s : branch_ref=%s : \
                           run_type=%s : env=%s : runs_on=%s"
                          (Builder.log_id s)
                          Uuidm.pp
                          id
                          base_ref
                          branch_ref
                          (CCOption.map_or ~default:"" Wm.Step.to_string @@ CCList.head_opt steps)
                          (CCOption.get_or ~default:"" environment)
                          (CCOption.map_or ~default:"" Yojson.Safe.to_string runs_on)))
                  wms;
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
                >>= fun () -> Abb.Future.return (Error (`Suspend_eval name)))
        | wms when all_wms_completed wms ->
            Logs.info (fun m ->
                m "%s : WM : CREATE : name=%s : all_wms_completed" (Builder.log_id s) name);
            Abb.Future.return (Ok wms)
        | _ ->
            Logs.info (fun m ->
                m "%s : WM : CREATE : name=%s : not_all_wms_completed" (Builder.log_id s) name);
            Abb.Future.return (Error (`Suspend_eval name)))
end
