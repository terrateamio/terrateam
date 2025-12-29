module Fc = Abbs_future_combinators
module Irm = Abbs_future_combinators.Infix_result_monad
module Ira = Abbs_future_combinators.Infix_result_app
module P2 = Terrat_vcs_provider2
module Msg = P2.Msg

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  let src = Logs.Src.create ("vcs_event_evaluator2_wm_sm_tf_op." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module Bs = Builder.Bs
  module Wm_sm = Terrat_vcs_event_evaluator2_wm_sm.Make (S) (Keys)
  module Wm = Terrat_work_manifest3
  module Wmr = Terrat_api_components.Work_manifest_result

  let result_version = 2
  let protocol_version = 1

  (* If the number of dirspaces are over this arbitrary threshold, do not create
   dirspace checks. *)
  let dirspace_check_threshold = 50

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

  (* Partitions a dirspaceflows by a few attributes:

       1. The environment, so all environments get their own work manifest.

       2. runs_on, so any runs that get their own runs_on configuration get
          their own work manifest.

       3. Overlapping workspaces.  This way if a dir has multiple workspace that
          will run in it, it will get its own run.  This ensure isolation between
          those directories. *)
  let partition_by_run_params ~max_workspaces_per_batch dirspaceflows =
    let module M = struct
      type t = string option * Yojson.Safe.t option [@@deriving eq]
    end in
    let module Dsf = Terrat_change.Dirspaceflow in
    let module We = Terrat_base_repo_config_v1.Workflows.Entry in
    let partitioned_by_dir =
      let rec update_first_match ~test ~update = function
        | [] -> None
        | x :: xs when test x -> Some (update x :: xs)
        | x :: xs ->
            let open CCOption.Infix in
            update_first_match ~test ~update xs >>= fun xs -> Some (x :: xs)
      in
      let partitions =
        CCList.fold_left
          (fun groups ({ Dsf.dirspace = { Terrat_dirspace.dir; _ }; _ } as dsf) ->
            match
              update_first_match
                ~test:CCFun.(Terrat_data.String_map.mem dir %> not)
                ~update:(Terrat_data.String_map.add dir dsf)
                groups
            with
            | Some groups -> groups
            | None -> Terrat_data.String_map.singleton dir dsf :: groups)
          []
          dirspaceflows
      in
      CCList.map CCFun.(Terrat_data.String_map.to_list %> CCList.map snd) partitions
    in
    let partitions =
      CCList.flat_map
        (fun dirspaceflows ->
          CCListLabels.fold_left
            ~f:(fun acc dsf ->
              let k =
                match dsf with
                | {
                 Dsf.workflow = Some { Dsf.Workflow.workflow = { We.environment; runs_on; _ }; _ };
                 _;
                } -> (environment, runs_on)
                | _ -> (None, None)
              in
              CCList.Assoc.update
                ~eq:M.equal
                ~f:(fun v -> Some (dsf :: CCOption.get_or ~default:[] v))
                k
                acc)
            ~init:[]
            dirspaceflows)
        partitioned_by_dir
    in
    CCList.flat_map
      (fun (k, dsfs) ->
        dsfs
        |> CCList.sort (fun l r ->
               (*Ensure chunks are sorted by dirspace so chunks are consistent between runs. *)
               Terrat_dirspace.compare (Dsf.to_dirspace l) (Dsf.to_dirspace r))
        |> CCList.chunks max_workspaces_per_batch
        |> CCList.map (fun chunk -> (k, chunk)))
      partitions

  let create_op_commit_checks
      create_commit_checks
      config
      account
      repo
      ref_
      work_manifest
      description
      status =
    let module Wm = Terrat_work_manifest3 in
    let module Status = Terrat_commit_check.Status in
    match work_manifest.Wm.changes with
    | [] -> Abb.Future.return (Ok ())
    | dirspaces ->
        let run_type =
          match CCList.rev work_manifest.Wm.steps with
          | [] -> assert false
          | step :: _ -> Wm.Step.to_string step
        in
        let aggregate =
          [
            S.Commit_check.make_str
              ~config
              ~description
              ~status
              ~work_manifest
              ~repo
              ~account
              (Printf.sprintf "terrateam %s pre-hooks" run_type);
            S.Commit_check.make_str
              ~config
              ~description
              ~status
              ~work_manifest
              ~repo
              ~account
              (Printf.sprintf "terrateam %s post-hooks" run_type);
          ]
        in
        let dirspace_checks =
          let module Ds = Terrat_change.Dirspace in
          let module Dsf = Terrat_change.Dirspaceflow in
          CCList.map
            (fun { Dsf.dirspace; _ } ->
              S.Commit_check.make_dirspace
                ~config
                ~description
                ~run_type
                ~dirspace
                ~status
                ~work_manifest
                ~repo
                ~account
                ())
            dirspaces
        in
        let checks = aggregate @ dirspace_checks in
        create_commit_checks' create_commit_checks ref_ checks

  let create_op_commit_checks_of_result
      create_commit_checks
      config
      account
      repo
      ref_
      work_manifest
      result =
    let module Wm = Terrat_work_manifest3 in
    let module Wmr = Terrat_vcs_provider2.Work_manifest_result in
    let module Status = Terrat_commit_check.Status in
    let status = function
      | true -> Terrat_commit_check.Status.Completed
      | false -> Terrat_commit_check.Status.Failed
    in
    let description = function
      | true -> "Completed"
      | false -> "Failed"
    in
    let run_type =
      match CCList.rev work_manifest.Wm.steps with
      | [] -> assert false
      | step :: _ -> Wm.Step.to_string step
    in
    let aggregate =
      [
        S.Commit_check.make_str
          ~config
          ~description:(description result.Wmr.pre_hooks_success)
          ~status:(status result.Wmr.pre_hooks_success)
          ~work_manifest
          ~repo
          ~account
          (Printf.sprintf "terrateam %s pre-hooks" run_type);
        S.Commit_check.make_str
          ~config
          ~description:(description result.Wmr.post_hooks_success)
          ~status:(status result.Wmr.post_hooks_success)
          ~work_manifest
          ~repo
          ~account
          (Printf.sprintf "terrateam %s post-hooks" run_type);
      ]
    in
    let dirspace_checks =
      if CCList.length result.Wmr.dirspaces_success <= dirspace_check_threshold then
        let module Ds = Terrat_change.Dirspace in
        let module Dsf = Terrat_change.Dirspaceflow in
        CCList.map
          (fun (dirspace, success) ->
            S.Commit_check.make_dirspace
              ~config
              ~description:(description success)
              ~run_type
              ~dirspace
              ~status:(status success)
              ~work_manifest
              ~repo
              ~account
              ())
          result.Wmr.dirspaces_success
      else []
    in
    let checks = aggregate @ dirspace_checks in
    create_commit_checks' create_commit_checks ref_ checks

  let maybe_create_pending_apply_commit_checks
      create_commit_checks
      request_id
      config
      client
      account
      repo
      ref_
      all_matches
      apply_requirements =
    let module Ar = Terrat_base_repo_config_v1.Apply_requirements in
    let module String_set = CCSet.Make (CCString) in
    if apply_requirements.Ar.create_pending_apply_check then
      let open Abbs_future_combinators.Infix_result_monad in
      S.Api.fetch_commit_checks ~request_id client repo ref_
      >>= fun commit_checks ->
      let commit_check_titles =
        commit_checks
        |> CCList.map (fun Terrat_commit_check.{ title; _ } -> title)
        |> String_set.of_list
      in
      let missing_commit_checks =
        all_matches
        |> CCList.filter_map
             (fun
               {
                 Terrat_change_match3.Dirspace_config.dirspace;
                 when_modified = { Terrat_base_repo_config_v1.When_modified.autoapply; _ };
                 _;
               }
             ->
               let name = S.Commit_check.make_dirspace_title ~run_type:"apply" dirspace in
               if (not autoapply) && not (String_set.mem name commit_check_titles) then
                 Some
                   (S.Commit_check.make_dirspace
                      ~config
                      ~description:"Waiting"
                      ~run_type:"apply"
                      ~dirspace
                      ~status:Terrat_commit_check.Status.Queued
                      ~repo
                      ~account
                      ())
               else None)
      in
      let missing_apply_check =
        if not (String_set.mem "terrateam apply" commit_check_titles) then
          [
            S.Commit_check.make_str
              ~config
              ~description:"Waiting"
              ~status:Terrat_commit_check.Status.Queued
              ~repo
              ~account
              "terrateam apply";
          ]
        else []
      in
      create_commit_checks' create_commit_checks ref_ (missing_apply_check @ missing_commit_checks)
    else Abb.Future.return (Ok ())

  let changed_dirspaces config changes =
    let module Tcm = Terrat_change_match3 in
    let module S = Terrat_base_repo_config_v1.Stacks in
    let module Tc = Terrat_change in
    let module Dsf = Tc.Dirspaceflow in
    CCList.map
      (fun Tc.{ Dsf.dirspace = { Dirspace.dir; workspace } as dirspace; workflow; _ } ->
        let { Tcm.Dirspace_config.stack_name; stack_config = { S.Stack.variables; _ }; _ } =
          CCOption.get_exn_or "changed_dirspaces" @@ Tcm.of_dirspace config dirspace
        in
        (* TODO: Remove rank, it is deprecated *)
        Terrat_api_components.Work_manifest_dir.
          {
            path = dir;
            workspace;
            workflow;
            rank = 0;
            variables = Some (Variables.make ~additional:variables Json_schema.Empty_obj.t);
            stack_name;
          })
      changes

  let create ~dest_branch_ref ~branch_ref ~branch op s { Bs.Fetcher.fetch } =
    let open Irm in
    fetch Keys.account
    >>= fun account ->
    fetch Keys.repo
    >>= fun repo ->
    fetch Keys.initiator
    >>= fun initiator ->
    fetch Keys.target
    >>= fun target ->
    fetch Keys.repo_config
    >>= fun repo_config ->
    fetch Keys.matches
    >>= fun matches ->
    fetch
      (match op with
      | `Plan -> Keys.access_control_eval_plan
      | `Apply -> Keys.access_control_eval_apply)
    >>= fun access_control_results ->
    Abb.Future.return
      (let module R = Terrat_access_control2.R in
      (access_control_results
        : (R.t, Terrat_access_control2.err) result
        :> (R.t, [> Terrat_access_control2.err ]) result))
    >>= fun access_control_results ->
    let { Terrat_access_control2.R.pass = passed_dirspaces; deny = denied_dirspaces } =
      access_control_results
    in
    Abb.Future.return
      (dirspaceflows_of_changes_with_branch_target
         repo_config
         (CCList.flatten matches.Keys.Matches.all_matches))
    >>= fun all_dirspaceflows ->
    Builder.run_db s ~f:(fun db ->
        S.Db.store_dirspaceflows
          ~request_id:(Builder.log_id s)
          ~base_ref:dest_branch_ref
          ~branch_ref
          db
          repo
          all_dirspaceflows)
    >>= fun () ->
    Abb.Future.return (dirspaceflows_of_changes repo_config passed_dirspaces)
    >>= fun dirspaceflows ->
    let denied_dirspaces =
      let module Ac = Terrat_access_control2 in
      let module Dc = Terrat_change_match3.Dirspace_config in
      CCList.map
        (fun { Ac.R.Deny.change_match = { Dc.dirspace; _ }; policy } ->
          { Wm.Deny.dirspace; policy })
        denied_dirspaces
    in
    let module V1 = Terrat_base_repo_config_v1 in
    let max_workspaces_per_batch =
      if (V1.batch_runs repo_config).V1.Batch_runs.enabled then
        (V1.batch_runs repo_config).V1.Batch_runs.max_workspaces_per_batch
      else CCInt.max_int
    in
    let dirspaceflows_by_run_params =
      partition_by_run_params ~max_workspaces_per_batch dirspaceflows
    in
    fetch Keys.target
    >>= fun target ->
    fetch Keys.initiator
    >>= fun initiator ->
    fetch Keys.job
    >>= fun job ->
    let tag_query =
      let module Tjc = Terrat_job_context in
      let module T = Tjc.Job.Type_ in
      match job.Tjc.Job.type_ with
      | T.Plan { tag_query; kind = _ } | T.Apply { tag_query; kind = _; force = _ } -> tag_query
      | T.Autoapply | T.Autoplan -> Terrat_tag_query.any
      | T.Gate_approval _ | T.Index | T.Repo_config | T.Unlock _ | T.Push -> assert false
    in
    Abbs_future_combinators.List_result.map
      ~f:(fun ((environment, runs_on), dirspaceflows) ->
        let changes =
          let module Dsf = Terrat_change.Dirspaceflow in
          CCList.map
            (fun ({ Dsf.workflow; _ } as dsf) ->
              { dsf with Dsf.workflow = CCOption.map (fun Dsf.Workflow.{ idx; _ } -> idx) workflow })
            dirspaceflows
        in
        let work_manifest =
          {
            Wm.account;
            base_ref = S.Api.Ref.to_string dest_branch_ref;
            branch = Some (S.Api.Ref.to_string branch);
            branch_ref = S.Api.Ref.to_string branch_ref;
            changes;
            completed_at = None;
            created_at = ();
            denied_dirspaces;
            environment;
            id = ();
            initiator;
            run_id = ();
            runs_on;
            state = ();
            steps =
              [
                (match op with
                | `Plan -> Wm.Step.Plan
                | `Apply -> Wm.Step.Apply);
              ];
            tag_query;
            target;
          }
        in
        Builder.run_db s ~f:(fun db ->
            S.Work_manifest.create ~request_id:(Builder.log_id s) db work_manifest)
        >>= fun work_manifest ->
        fetch Keys.client
        >>= fun client ->
        fetch Keys.branch_ref
        >>= fun branch_ref ->
        fetch Keys.create_commit_checks
        >>= fun create_commit_checks ->
        create_op_commit_checks
          create_commit_checks
          (Builder.State.config s)
          account
          repo
          branch_ref
          work_manifest
          "Queued"
          Terrat_commit_check.Status.Queued
        >>= fun () ->
        maybe_create_pending_apply_commit_checks
          create_commit_checks
          (Builder.log_id s)
          (Builder.State.config s)
          client
          account
          repo
          branch_ref
          (CCList.flatten matches.Keys.Matches.all_matches)
          (Terrat_base_repo_config_v1.apply_requirements repo_config)
        >>= fun () -> Abb.Future.return (Ok work_manifest))
      dirspaceflows_by_run_params

  module Plan = struct
    let eq base_ref' branch_ref' { Wm.base_ref; branch_ref; steps; _ } =
      base_ref = S.Api.Ref.to_string base_ref'
      && branch_ref = S.Api.Ref.to_string branch_ref'
      && steps = [ Wm.Step.Plan ]

    let create ~dest_branch_ref ~branch_ref ~branch s ({ Bs.Fetcher.fetch } as fetcher) =
      let open Irm in
      fetch Keys.can_run_plan
      >>= fun () -> create ~dest_branch_ref ~branch_ref ~branch `Plan s fetcher

    let initiate ({ Wm.id; _ } as work_manifest) s { Bs.Fetcher.fetch } =
      let open Irm in
      fetch Keys.account
      >>= fun account ->
      fetch Keys.repo
      >>= fun repo ->
      fetch Keys.client
      >>= fun client ->
      fetch Keys.branch_ref
      >>= fun branch_ref ->
      fetch Keys.create_commit_checks
      >>= fun create_commit_checks ->
      let module Status = Terrat_commit_check.Status in
      create_op_commit_checks
        create_commit_checks
        (Builder.State.config s)
        account
        repo
        branch_ref
        work_manifest
        "Running"
        Status.Running
      >>= fun () ->
      Abb.Future.return (Ok ())
      >>= fun () ->
      let { Wm.base_ref; branch_ref; changes; target; _ } = work_manifest in
      let run_kind =
        match target with
        | P2.Target.Pr pr -> `Pull_request pr
        | P2.Target.Drift _ -> `Drift
      in
      let run_kind_str =
        match run_kind with
        | `Pull_request _ -> "pr"
        | `Drift -> "drift"
      in
      let run_kind_data =
        let module Rkd = Terrat_api_components.Work_manifest_plan.Run_kind_data in
        let module Rkdpr = Terrat_api_components.Run_kind_data_pull_request in
        match run_kind with
        | `Pull_request pr ->
            Some
              (Rkd.Run_kind_data_pull_request
                 { Rkdpr.id = S.Api.Pull_request.Id.to_string (S.Api.Pull_request.id pr) })
        | `Drift -> None
      in
      fetch Keys.derived_repo_config
      >>= fun (_, repo_config) ->
      fetch Keys.synthesized_config
      >>= fun synthesized_config ->
      fetch Keys.dest_branch_name
      >>= fun dest_branch_name ->
      Ira.(
        (fun branch_dirspaces dest_branch_dirspaces -> (branch_dirspaces, dest_branch_dirspaces))
        <$> fetch Keys.branch_dirspaces
        <*> fetch Keys.dest_branch_dirspaces)
      >>= fun (dirspaces, base_dirspaces) ->
      Builder.run_db s ~f:(fun db ->
          Wm_sm.create_token' ~log_id:(Builder.log_id s) (S.Api.Account.id account) id db)
      >>= fun token ->
      let response =
        Terrat_api_components.(
          Work_manifest.Work_manifest_plan
            {
              Work_manifest_plan.token;
              api_base_url = Terrat_config.api_base @@ S.Api.Config.config @@ Builder.State.config s;
              installation_id = S.Api.Account.Id.to_string @@ S.Api.Account.id account;
              base_dirspaces;
              base_ref = S.Api.Ref.to_string dest_branch_name;
              changed_dirspaces = changed_dirspaces synthesized_config changes;
              dirspaces;
              run_kind = run_kind_str;
              run_kind_data;
              type_ = "plan";
              result_version;
              protocol_version = Some protocol_version;
              config =
                repo_config
                |> Terrat_base_repo_config_v1.to_version_1
                |> Terrat_repo_config.Version_1.to_yojson;
              capabilities = [ "tenv" ];
            })
      in
      Abb.Future.return (Ok response)

    let fail work_manifest s { Bs.Fetcher.fetch } =
      let open Irm in
      fetch Keys.account
      >>= fun account ->
      fetch Keys.repo
      >>= fun repo ->
      fetch Keys.client
      >>= fun client ->
      fetch Keys.branch_ref
      >>= fun branch_ref ->
      fetch Keys.create_commit_checks
      >>= fun create_commit_checks ->
      let module Status = Terrat_commit_check.Status in
      create_op_commit_checks
        create_commit_checks
        (Builder.State.config s)
        account
        repo
        branch_ref
        work_manifest
        "Failed"
        Status.Failed

    let result work_manifest result s { Bs.Fetcher.fetch } =
      let open Irm in
      match result with
      | Wmr.Work_manifest_tf_operation_result2 result ->
          fetch Keys.client
          >>= fun client ->
          fetch Keys.matches
          >>= fun matches ->
          let work_manifest_result = S.Work_manifest.result2 result in
          Builder.run_db s ~f:(fun db ->
              S.Db.store_tf_operation_result2
                ~request_id:(Builder.log_id s)
                db
                work_manifest.Wm.id
                result)
          >>= fun () ->
          if work_manifest.Wm.state <> Wm.State.Aborted then
            (* In the case of an abort, we do not report back to the user, we
                just want to store the results. *)
            fetch Keys.branch_ref
            >>= fun branch_ref ->
            fetch Keys.repo
            >>= fun repo ->
            fetch Keys.create_commit_checks
            >>= fun create_commit_checks ->
            create_op_commit_checks_of_result
              create_commit_checks
              (Builder.State.config s)
              work_manifest.Wm.account
              repo
              branch_ref
              work_manifest
              work_manifest_result
            >>= fun () ->
            fetch Keys.account_status
            >>= fun account_status ->
            (* TODO: HUGE HACK, redo this later *)
            let run =
              let open Irm in
              Fc.Result.all3
                (fetch Keys.client)
                (fetch Keys.repo_config_with_provenance)
                (fetch Keys.repo_tree_branch)
              >>= fun (client, (provenance, repo_config), repo_tree) ->
              fetch Keys.dest_branch_name
              >>= fun dest_branch_name ->
              fetch Keys.branch_name
              >>= fun branch_name ->
              fetch Keys.repo_index_branch
              >>= fun index ->
              Abbs_future_combinators.to_result
              @@ Abb.Thread.run (fun () ->
                     Terrat_base_repo_config_v1.derive
                       ~ctx:
                         (Terrat_base_repo_config_v1.Ctx.make
                            ~dest_branch:(S.Api.Ref.to_string dest_branch_name)
                            ~branch:(S.Api.Ref.to_string branch_name)
                            ())
                       ~index
                       ~file_list:repo_tree
                       repo_config)
              >>= fun repo_config ->
              Abb.Future.return (Terrat_change_match3.synthesize_config ~index repo_config)
              >>= fun synthesized_config -> Abb.Future.return (Ok (repo_config, synthesized_config))
            in
            run
            >>= fun (repo_config, synthesized_config) ->
            (* TODO: HUGE HACK, redo this later *)
            fetch Keys.publish_comment
            >>= fun publish_comment ->
            Builder.run_db s ~f:(fun db ->
                publish_comment'
                  publish_comment
                  (Msg.Tf_op_result2
                     {
                       account_status;
                       config = Builder.State.config s;
                       db;
                       is_layered_run = CCList.length matches.Keys.Matches.all_matches > 1;
                       remaining_layers = matches.Keys.Matches.all_unapplied_matches;
                       result;
                       repo_config;
                       synthesized_config;
                       work_manifest;
                     }))
            >>= fun () -> Abb.Future.return (Ok ())
          else Abb.Future.return (Ok ())
      | Wmr.Work_manifest_tf_operation_result result ->
          let open Irm in
          fetch Keys.matches
          >>= fun matches ->
          let work_manifest_result = S.Work_manifest.result result in
          Builder.run_db s ~f:(fun db ->
              S.Db.store_tf_operation_result
                ~request_id:(Builder.log_id s)
                db
                work_manifest.Wm.id
                result)
          >>= fun () ->
          if work_manifest.Wm.state <> Wm.State.Aborted then
            fetch Keys.repo
            >>= fun repo ->
            fetch Keys.branch_ref
            >>= fun branch_ref ->
            fetch Keys.create_commit_checks
            >>= fun create_commit_checks ->
            create_op_commit_checks_of_result
              create_commit_checks
              (Builder.State.config s)
              work_manifest.Wm.account
              repo
              branch_ref
              work_manifest
              work_manifest_result
            >>= fun () ->
            fetch Keys.publish_comment
            >>= fun publish_comment ->
            publish_comment'
              publish_comment
              (Msg.Tf_op_result
                 {
                   is_layered_run = CCList.length matches.Keys.Matches.all_matches > 1;
                   remaining_layers = matches.Keys.Matches.all_unapplied_matches;
                   result;
                   work_manifest;
                 })
            >>= fun () -> Abb.Future.return (Ok ())
          else Abb.Future.return (Ok ())
      | Wmr.Work_manifest_index_result _ -> assert false
      | Wmr.Work_manifest_build_config_result _ -> assert false
      | Wmr.Work_manifest_build_result_failure _ -> assert false
      | Wmr.Work_manifest_build_tree_result _ -> assert false

    let run ~dest_branch_ref ~branch_ref ~branch ~name =
      Wm_sm.run
        ~name
        ~eq:(eq dest_branch_ref branch_ref)
        ~dest_branch_ref
        ~branch_ref
        ~branch
        ~create
        ~initiate
        ~fail
        ~result
  end

  module Apply = struct
    let eq base_ref' branch_ref' { Wm.base_ref; branch_ref; steps; _ } =
      base_ref = S.Api.Ref.to_string base_ref'
      && branch_ref = S.Api.Ref.to_string branch_ref'
      && steps = [ Wm.Step.Apply ]

    let maybe_comment_autoapply_running s { Bs.Fetcher.fetch } =
      let module Tjc = Terrat_job_context in
      let open Irm in
      fetch Keys.context
      >>= function
      | { Tjc.Context.scope = Tjc.Context.Scope.Pull_request _; _ } -> (
          fetch Keys.job
          >>= function
          | { Tjc.Job.type_ = Tjc.Job.Type_.Autoapply; _ } -> (
              fetch Keys.pull_request
              >>= fun pull_request ->
              match S.Api.Pull_request.state pull_request with
              | Terrat_pull_request.State.Merged _ ->
                  fetch Keys.publish_comment
                  >>= fun publish_comment -> publish_comment' publish_comment Msg.Autoapply_running
              | _ -> Abb.Future.return (Ok ()))
          | _ -> Abb.Future.return (Ok ()))
      | _ -> Abb.Future.return (Ok ())

    let create ~dest_branch_ref ~branch_ref ~branch s ({ Bs.Fetcher.fetch } as fetcher) =
      let open Irm in
      fetch Keys.can_run_apply
      >>= fun () ->
      maybe_comment_autoapply_running s fetcher
      >>= fun () -> create ~dest_branch_ref ~branch_ref ~branch `Apply s fetcher

    let initiate ({ Wm.id; _ } as work_manifest) s { Bs.Fetcher.fetch } =
      let open Irm in
      fetch Keys.account
      >>= fun account ->
      fetch Keys.repo
      >>= fun repo ->
      fetch Keys.client
      >>= fun client ->
      fetch Keys.branch_ref
      >>= fun branch_ref ->
      fetch Keys.create_commit_checks
      >>= fun create_commit_checks ->
      let module Status = Terrat_commit_check.Status in
      create_op_commit_checks
        create_commit_checks
        (Builder.State.config s)
        account
        repo
        branch_ref
        work_manifest
        "Running"
        Status.Running
      >>= fun () ->
      let { Wm.base_ref; branch_ref; changes; target; _ } = work_manifest in
      let run_kind =
        match target with
        | P2.Target.Pr pr -> `Pull_request pr
        | P2.Target.Drift _ -> `Drift
      in
      let run_kind_str =
        match run_kind with
        | `Pull_request _ -> "pr"
        | `Drift -> "drift"
      in
      let run_kind_data =
        let module Rkd = Terrat_api_components.Work_manifest_apply.Run_kind_data in
        let module Rkdpr = Terrat_api_components.Run_kind_data_pull_request in
        match run_kind with
        | `Pull_request pr ->
            Some
              (Rkd.Run_kind_data_pull_request
                 { Rkdpr.id = S.Api.Pull_request.Id.to_string (S.Api.Pull_request.id pr) })
        | `Drift -> None
      in
      fetch Keys.derived_repo_config
      >>= fun (_, repo_config) ->
      fetch Keys.synthesized_config
      >>= fun synthesized_config ->
      fetch Keys.dest_branch_name
      >>= fun dest_branch_name ->
      Builder.run_db s ~f:(fun db ->
          Wm_sm.create_token' ~log_id:(Builder.log_id s) (S.Api.Account.id account) id db)
      >>= fun token ->
      let response =
        Terrat_api_components.(
          Work_manifest.Work_manifest_apply
            {
              Work_manifest_apply.token;
              api_base_url = Terrat_config.api_base @@ S.Api.Config.config @@ Builder.State.config s;
              installation_id = S.Api.Account.Id.to_string @@ S.Api.Account.id account;
              base_ref = S.Api.Ref.to_string dest_branch_name;
              changed_dirspaces = changed_dirspaces synthesized_config changes;
              run_kind = run_kind_str;
              run_kind_data;
              type_ = "apply";
              result_version;
              protocol_version = Some protocol_version;
              config =
                repo_config
                |> Terrat_base_repo_config_v1.to_version_1
                |> Terrat_repo_config.Version_1.to_yojson;
              capabilities = [ "tenv" ];
            })
      in
      Abb.Future.return (Ok response)

    let fail work_manifest s { Bs.Fetcher.fetch } =
      let open Irm in
      fetch Keys.account
      >>= fun account ->
      fetch Keys.repo
      >>= fun repo ->
      fetch Keys.branch_ref
      >>= fun branch_ref ->
      fetch Keys.create_commit_checks
      >>= fun create_commit_checks ->
      let module Status = Terrat_commit_check.Status in
      create_op_commit_checks
        create_commit_checks
        (Builder.State.config s)
        account
        repo
        branch_ref
        work_manifest
        "Failed"
        Status.Failed
      >>= fun () ->
      fetch Keys.publish_comment
      >>= fun publish_comment -> publish_comment' publish_comment Msg.Unexpected_temporary_err

    let result = Plan.result

    let run ~dest_branch_ref ~branch_ref ~branch ~name =
      Wm_sm.run
        ~name
        ~eq:(eq dest_branch_ref branch_ref)
        ~dest_branch_ref
        ~branch_ref
        ~branch
        ~create
        ~initiate
        ~fail
        ~result
  end
end
