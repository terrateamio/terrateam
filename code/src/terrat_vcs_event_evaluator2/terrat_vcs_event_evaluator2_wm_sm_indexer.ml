module Irm = Abbs_future_combinators.Infix_result_monad
module Msg = Terrat_vcs_provider2.Msg

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  let src = Logs.Src.create ("vcs_event_evaluator2_wm_sm_indexer." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module Bs = Builder.Bs
  module Wm_sm = Terrat_vcs_event_evaluator2_wm_sm.Make (S) (Keys)
  module Wm = Terrat_work_manifest3
  module Wmr = Terrat_api_components.Work_manifest_result

  (* Wrapper so that when we call [publish_comment] the error type lines up *)
  let publish_comment' f msg =
    let open Abb.Future.Infix_monad in
    f msg
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error `Error -> Abb.Future.return (Error `Error)

  let create_commit_checks' f branch_ref checks =
    let open Abb.Future.Infix_monad in
    f branch_ref checks
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error `Error -> Abb.Future.return (Error `Error)

  let eq base_ref' branch_ref' { Wm.base_ref; branch_ref; steps; _ } =
    base_ref = S.Api.Ref.to_string base_ref'
    && branch_ref = S.Api.Ref.to_string branch_ref'
    && steps = [ Wm.Step.Index ]

  let status_name ~branch ~branch_name =
    let branch = S.Api.Ref.to_string branch in
    let branch_name = S.Api.Ref.to_string branch_name in
    if branch = branch_name then "terrateam index" else "terrateam index " ^ branch

  let create ~dest_branch_ref ~branch_ref ~branch s { Bs.Fetcher.fetch } =
    let open Irm in
    fetch Keys.account
    >>= fun account ->
    Builder.run_db s ~f:(fun db ->
        S.Db.query_index ~request_id:(Builder.log_id s) db account branch_ref)
    >>= function
    | None ->
        fetch Keys.repo
        >>= fun repo ->
        fetch Keys.initiator
        >>= fun initiator ->
        fetch Keys.target
        >>= fun target ->
        let work_manifest =
          {
            Wm.account;
            base_ref = S.Api.Ref.to_string dest_branch_ref;
            branch = Some (S.Api.Ref.to_string branch);
            branch_ref = S.Api.Ref.to_string branch_ref;
            changes = [];
            completed_at = None;
            created_at = ();
            denied_dirspaces = [];
            environment = None;
            id = ();
            initiator;
            run_id = ();
            runs_on = None;
            state = ();
            steps = [ Wm.Step.Index ];
            tag_query = Terrat_tag_query.any;
            target;
          }
        in
        Builder.run_db s ~f:(fun db ->
            S.Work_manifest.create ~request_id:(Builder.log_id s) db work_manifest)
        >>= fun work_manifest ->
        fetch Keys.branch_ref
        >>= fun branch_ref ->
        fetch Keys.branch_name
        >>= fun branch_name ->
        let module Status = Terrat_commit_check.Status in
        let check =
          S.Commit_check.make_str
            ~config:(Builder.State.config s)
            ~description:"Queued"
            ~status:Status.Queued
            ~work_manifest
            ~repo
            ~account
            (status_name ~branch ~branch_name)
        in
        fetch Keys.create_commit_checks
        >>= fun create_commit_checks ->
        create_commit_checks' create_commit_checks branch_ref [ check ]
        >>= fun () -> Abb.Future.return (Ok [ work_manifest ])
    | Some _ -> Abb.Future.return (Ok [])

  let initiate ~branch ({ Wm.id; _ } as work_manifest) s { Bs.Fetcher.fetch } =
    let open Irm in
    fetch Keys.account
    >>= fun account ->
    fetch Keys.repo
    >>= fun repo ->
    fetch Keys.branch_ref
    >>= fun branch_ref ->
    fetch Keys.branch_name
    >>= fun branch_name ->
    let module Status = Terrat_commit_check.Status in
    let check =
      S.Commit_check.make_str
        ~config:(Builder.State.config s)
        ~description:"Running"
        ~status:Status.Running
        ~work_manifest
        ~repo
        ~account
        (status_name ~branch ~branch_name)
    in
    fetch Keys.create_commit_checks
    >>= fun create_commit_checks ->
    create_commit_checks' create_commit_checks branch_ref [ check ]
    >>= fun () ->
    fetch Keys.branch_name
    >>= fun branch_name ->
    fetch Keys.dest_branch_name
    >>= fun dest_branch_name ->
    (* Pull the right config and tree down based on the branch we're operating on. *)
    let repo_config_raw, repo_tree =
      if branch = branch_name then (Keys.repo_config_raw, Keys.repo_tree_branch)
      else if branch = dest_branch_name then
        (Keys.repo_config_dest_branch_raw, Keys.repo_tree_dest_branch)
      else assert false
    in
    fetch repo_config_raw
    >>= fun (_, repo_config_raw) ->
    fetch repo_tree
    >>= fun repo_tree ->
    fetch Keys.synthesized_config_empty_index
    >>= fun config ->
    Abbs_time_it.run
      (fun t -> Logs.info (fun m -> m "%s : MATCH_DIFF_LIST : time=%f" (Builder.log_id s) t))
      (fun () ->
        Abbs_future_combinators.to_result
        @@ Abb.Thread.run (fun () ->
               CCList.filter
                 (Terrat_change_match3.match_tag_query ~tag_query:Terrat_tag_query.any)
                 (CCList.flatten
                    (Terrat_change_match3.match_diff_list
                       config
                       (CCList.map
                          (fun filename -> Terrat_change.Diff.(Change { filename }))
                          repo_tree)))))
    >>= fun matches ->
    Abb.Future.return (Wm_sm.dirspaceflows_of_changes repo_config_raw matches)
    >>= fun dirspaceflows ->
    Builder.run_db s ~f:(fun db ->
        Wm_sm.create_token' ~log_id:(Builder.log_id s) (S.Api.Account.id account) id db)
    >>= fun token ->
    let module Dsf = Terrat_change.Dirspaceflow in
    let dirs =
      CCList.map (fun Terrat_change.Dirspace.{ dir; _ } -> dir)
      @@ CCList.map Terrat_change.Dirspaceflow.to_dirspace
      @@ CCList.map
           (fun ({ Dsf.workflow; _ } as dsf) ->
             { dsf with Dsf.workflow = CCOption.map (fun { Dsf.Workflow.idx; _ } -> idx) workflow })
           dirspaceflows
    in
    let module I = Terrat_api_components.Work_manifest_index in
    let config =
      repo_config_raw
      |> Terrat_base_repo_config_v1.to_version_1
      |> Terrat_repo_config.Version_1.to_yojson
    in
    let response =
      Terrat_api_components.Work_manifest.Work_manifest_index
        { I.dirs; base_ref = S.Api.Ref.to_string dest_branch_name; token; type_ = "index"; config }
    in
    Abb.Future.return (Ok response)

  let fail ~branch work_manifest s { Bs.Fetcher.fetch } =
    let open Irm in
    fetch Keys.account
    >>= fun account ->
    fetch Keys.repo
    >>= fun repo ->
    fetch Keys.branch_ref
    >>= fun branch_ref ->
    fetch Keys.branch_name
    >>= fun branch_name ->
    let module Status = Terrat_commit_check.Status in
    let check =
      S.Commit_check.make_str
        ~config:(Builder.State.config s)
        ~description:"Failed"
        ~status:Status.Failed
        ~work_manifest
        ~repo
        ~account
        (status_name ~branch ~branch_name)
    in
    fetch Keys.create_commit_checks
    >>= fun create_commit_checks ->
    create_commit_checks' create_commit_checks branch_ref [ check ]
    >>= fun () ->
    fetch Keys.publish_comment
    >>= fun publish_comment -> publish_comment' publish_comment Msg.Unexpected_temporary_err

  let result ~branch work_manifest result s { Bs.Fetcher.fetch } =
    let open Irm in
    match result with
    | Wmr.Work_manifest_index_result index ->
        Builder.run_db s ~f:(fun db ->
            S.Db.store_index_result ~request_id:(Builder.log_id s) db work_manifest.Wm.id index
            >>= fun () ->
            S.Db.store_index ~request_id:(Builder.log_id s) db work_manifest.Wm.id index)
        >>= fun _ ->
        fetch Keys.account
        >>= fun account ->
        fetch Keys.repo
        >>= fun repo ->
        fetch Keys.branch_ref
        >>= fun branch_ref ->
        fetch Keys.branch_name
        >>= fun branch_name ->
        let module Status = Terrat_commit_check.Status in
        let check =
          S.Commit_check.make_str
            ~config:(Builder.State.config s)
            ~description:"Completed"
            ~status:Status.Completed
            ~work_manifest
            ~repo
            ~account
            (status_name ~branch ~branch_name)
        in
        fetch Keys.create_commit_checks
        >>= fun create_commit_checks ->
        create_commit_checks' create_commit_checks branch_ref [ check ]
    | Wmr.Work_manifest_tf_operation_result _ -> assert false
    | Wmr.Work_manifest_tf_operation_result2 _ -> assert false
    | Wmr.Work_manifest_build_config_result _ -> assert false
    | Wmr.Work_manifest_build_tree_result _ -> assert false
    | Wmr.Work_manifest_build_result_failure _ -> assert false

  let run ~dest_branch_ref ~branch_ref ~branch ~name =
    Wm_sm.run
      ~name
      ~eq:(eq dest_branch_ref branch_ref)
      ~dest_branch_ref
      ~branch_ref
      ~branch
      ~create
      ~initiate:(initiate ~branch)
      ~fail:(fail ~branch)
      ~result:(result ~branch)
end
