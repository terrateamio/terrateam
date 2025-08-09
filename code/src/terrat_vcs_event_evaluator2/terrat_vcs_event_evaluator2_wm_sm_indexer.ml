module Irm = Abbs_future_combinators.Infix_result_monad
module Msg = Terrat_vcs_provider2.Msg

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module Bs = Builder.Bs
  module Wm_sm = Terrat_vcs_event_evaluator2_wm_sm.Make (S) (Keys)
  module Wm = Terrat_work_manifest3
  module Wmr = Terrat_api_components.Work_manifest_result

  let eq base_ref' branch_ref' { Wm.base_ref; branch_ref; steps; _ } =
    base_ref = S.Api.Ref.to_string base_ref'
    && branch_ref = S.Api.Ref.to_string branch_ref'
    && steps = [ Wm.Step.Index ]

  let create s { Bs.Fetcher.fetch } =
    let open Irm in
    fetch Keys.account
    >>= fun account ->
    fetch Keys.repo
    >>= fun repo ->
    fetch Keys.dest_branch_ref
    >>= fun dest_branch_ref ->
    fetch Keys.working_branch_ref
    >>= fun working_branch_ref ->
    fetch Keys.initiator
    >>= fun initiator ->
    fetch Keys.target
    >>= fun target ->
    let work_manifest =
      {
        Wm.account;
        base_ref = S.Api.Ref.to_string dest_branch_ref;
        branch_ref = S.Api.Ref.to_string working_branch_ref;
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
    fetch Keys.is_interactive
    >>= function
    | true ->
        fetch Keys.branch_ref
        >>= fun branch_ref ->
        let check =
          S.Commit_check.make
            ~config:(Builder.State.config s)
            ~description:"Queued"
            ~title:"terrateam index"
            ~status:Terrat_commit_check.Status.Queued
            ~work_manifest
            ~repo
            account
        in
        fetch Keys.client
        >>= fun client ->
        S.Api.create_commit_checks ~request_id:(Builder.log_id s) client repo branch_ref [ check ]
        >>= fun () -> Abb.Future.return (Ok [ work_manifest ])
    | false -> Abb.Future.return (Ok [ work_manifest ])

  let initiate ({ Wm.id; _ } as work_manifest) s { Bs.Fetcher.fetch } =
    let open Irm in
    fetch Keys.is_interactive
    >>= (function
    | true ->
        fetch Keys.account
        >>= fun account ->
        fetch Keys.repo
        >>= fun repo ->
        fetch Keys.client
        >>= fun client ->
        fetch Keys.branch_ref
        >>= fun branch_ref ->
        let check =
          S.Commit_check.make
            ~config:(Builder.State.config s)
            ~description:"Running"
            ~title:"terrateam index"
            ~status:Terrat_commit_check.Status.Running
            ~work_manifest
            ~repo
            account
        in
        S.Api.create_commit_checks ~request_id:(Builder.log_id s) client repo branch_ref [ check ]
    | false -> Abb.Future.return (Ok ()))
    >>= fun () ->
    fetch Keys.encryption_key
    >>= fun encryption_key ->
    fetch Keys.dest_branch_name
    >>= fun dest_branch_name ->
    fetch Keys.repo_config_raw
    >>= fun (_, repo_config_raw) ->
    fetch Keys.repo_tree_branch
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
        {
          I.dirs;
          base_ref = S.Api.Ref.to_string dest_branch_name;
          token = Wm_sm.token encryption_key id;
          type_ = "index";
          config;
        }
    in
    Abb.Future.return (Ok response)

  let fail work_manifest s { Bs.Fetcher.fetch } =
    let open Irm in
    fetch Keys.is_interactive
    >>= function
    | true ->
        fetch Keys.account
        >>= fun account ->
        fetch Keys.repo
        >>= fun repo ->
        fetch Keys.client
        >>= fun client ->
        fetch Keys.branch_ref
        >>= fun branch_ref ->
        fetch Keys.user
        >>= fun user ->
        fetch Keys.pull_request
        >>= fun pull_request ->
        let check =
          S.Commit_check.make
            ~config:(Builder.State.config s)
            ~description:"Failed"
            ~title:"terrateam index"
            ~status:Terrat_commit_check.Status.Failed
            ~work_manifest
            ~repo
            account
        in
        S.Api.create_commit_checks ~request_id:(Builder.log_id s) client repo branch_ref [ check ]
        >>= fun () ->
        S.Comment.publish_comment
          ~request_id:(Builder.log_id s)
          client
          (CCOption.map_or ~default:"" S.Api.User.to_string user)
          pull_request
          Msg.Unexpected_temporary_err
    | false -> Abb.Future.return (Ok ())

  let result work_manifest result s { Bs.Fetcher.fetch } =
    let open Irm in
    match result with
    | Wmr.Work_manifest_index_result index -> (
        Builder.run_db s ~f:(fun db ->
            S.Db.store_index_result ~request_id:(Builder.log_id s) db work_manifest.Wm.id index
            >>= fun () ->
            S.Db.store_index ~request_id:(Builder.log_id s) db work_manifest.Wm.id index)
        >>= fun _ ->
        fetch Keys.is_interactive
        >>= function
        | true ->
            fetch Keys.account
            >>= fun account ->
            fetch Keys.repo
            >>= fun repo ->
            fetch Keys.branch_ref
            >>= fun branch_ref ->
            fetch Keys.client
            >>= fun client ->
            let check =
              S.Commit_check.make
                ~config:(Builder.State.config s)
                ~description:"Completed"
                ~title:"terrateam index"
                ~status:Terrat_commit_check.Status.Completed
                ~work_manifest
                ~repo
                account
            in
            S.Api.create_commit_checks
              ~request_id:(Builder.log_id s)
              client
              repo
              branch_ref
              [ check ]
        | false -> Abb.Future.return (Ok ()))
    | Wmr.Work_manifest_tf_operation_result _ -> assert false
    | Wmr.Work_manifest_tf_operation_result2 _ -> assert false
    | Wmr.Work_manifest_build_config_result _ -> assert false
    | Wmr.Work_manifest_build_tree_result _ -> assert false
    | Wmr.Work_manifest_build_result_failure _ -> assert false

  let run ~dest_branch_ref ~branch_ref ~name =
    Wm_sm.run ~name ~eq:(eq dest_branch_ref branch_ref) ~create ~initiate ~fail ~result
end
