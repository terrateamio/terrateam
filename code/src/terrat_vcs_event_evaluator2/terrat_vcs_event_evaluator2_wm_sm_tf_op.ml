module Irm = Abbs_future_combinators.Infix_result_monad
module P2 = Terrat_vcs_provider2
module Msg = P2.Msg

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module Bs = Builder.Bs
  module Wm_sm = Terrat_vcs_event_evaluator2_wm_sm.Make (S) (Keys)
  module Wm = Terrat_work_manifest3
  module Wmr = Terrat_api_components.Work_manifest_result

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
      request_id
      config
      client
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
            S.Commit_check.make
              ~config
              ~description
              ~title:(Printf.sprintf "terrateam %s pre-hooks" run_type)
              ~status
              ~work_manifest
              ~repo
              account;
            S.Commit_check.make
              ~config
              ~description
              ~title:(Printf.sprintf "terrateam %s post-hooks" run_type)
              ~status
              ~work_manifest
              ~repo
              account;
          ]
        in
        let dirspace_checks =
          let module Ds = Terrat_change.Dirspace in
          let module Dsf = Terrat_change.Dirspaceflow in
          CCList.map
            (fun { Dsf.dirspace = { Ds.dir; workspace; _ }; _ } ->
              S.Commit_check.make
                ~config
                ~description
                ~title:(Printf.sprintf "terrateam %s: %s %s" run_type dir workspace)
                ~status
                ~work_manifest
                ~repo
                account)
            dirspaces
        in
        let checks = aggregate @ dirspace_checks in
        S.Api.create_commit_checks ~request_id client repo ref_ checks

  let maybe_create_pending_apply_commit_checks
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
                 Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; workspace };
                 when_modified = { Terrat_base_repo_config_v1.When_modified.autoapply; _ };
                 _;
               }
             ->
               let name = Printf.sprintf "terrateam apply: %s %s" dir workspace in
               if (not autoapply) && not (String_set.mem name commit_check_titles) then
                 Some
                   (S.Commit_check.make
                      ~config
                      ~description:"Waiting"
                      ~title:(Printf.sprintf "terrateam apply: %s %s" dir workspace)
                      ~status:Terrat_commit_check.Status.Queued
                      ~repo
                      account)
               else None)
      in
      let missing_apply_check =
        if not (String_set.mem "terrateam apply" commit_check_titles) then
          [
            S.Commit_check.make
              ~config
              ~description:"Waiting"
              ~title:"terrateam apply"
              ~status:Terrat_commit_check.Status.Queued
              ~repo
              account;
          ]
        else []
      in
      S.Api.create_commit_checks
        ~request_id
        client
        repo
        ref_
        (missing_apply_check @ missing_commit_checks)
    else Abb.Future.return (Ok ())

  module Plan = struct
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
      fetch Keys.branch_ref
      >>= fun branch_ref ->
      fetch Keys.working_branch_ref
      >>= fun working_branch_ref ->
      fetch Keys.initiator
      >>= fun initiator ->
      fetch Keys.target
      >>= fun target ->
      fetch Keys.repo_config
      >>= fun repo_config ->
      fetch Keys.matches
      >>= fun matches ->
      fetch Keys.access_control_eval_plan
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
      let all_dirspaceflows = strip_lock_branch_target all_dirspaceflows in
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
        | T.Plan { tag_query } | T.Apply { tag_query } -> tag_query
        | T.Autoapply | T.Autoplan -> Terrat_tag_query.any
        | T.Repo_config | T.Unlock -> assert false
      in
      Abbs_future_combinators.List_result.map
        ~f:(fun ((environment, runs_on), dirspaceflows) ->
          let changes =
            let module Dsf = Terrat_change.Dirspaceflow in
            CCList.map
              (fun ({ Dsf.workflow; _ } as dsf) ->
                {
                  dsf with
                  Dsf.workflow = CCOption.map (fun Dsf.Workflow.{ idx; _ } -> idx) workflow;
                })
              dirspaceflows
          in
          let work_manifest =
            {
              Wm.account;
              base_ref = S.Api.Ref.to_string dest_branch_ref;
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
              steps = [ Wm.Step.Plan ];
              tag_query;
              target;
            }
          in
          Builder.run_db s ~f:(fun db ->
              S.Work_manifest.create ~request_id:(Builder.log_id s) db work_manifest)
          >>= fun work_manifest ->
          Logs.info (fun m ->
              m
                "%s : CREATED_WORK_MANIFEST : id=%a : base_ref=%s : branch_ref=%s : env=%s : \
                 runs_on=%s"
                (Builder.log_id s)
                Uuidm.pp
                work_manifest.Wm.id
                (S.Api.Ref.to_string dest_branch_ref)
                (S.Api.Ref.to_string branch_ref)
                (CCOption.get_or ~default:"" work_manifest.Wm.environment)
                (CCOption.map_or ~default:"" Yojson.Safe.to_string work_manifest.Wm.runs_on));
          fetch Keys.is_interactive
          >>= function
          | true ->
              fetch Keys.client
              >>= fun client ->
              create_op_commit_checks
                (Builder.log_id s)
                (Builder.State.config s)
                client
                account
                repo
                branch_ref
                work_manifest
                "Queued"
                Terrat_commit_check.Status.Queued
              >>= fun () ->
              maybe_create_pending_apply_commit_checks
                (Builder.log_id s)
                (Builder.State.config s)
                client
                account
                repo
                branch_ref
                (CCList.flatten matches.Keys.Matches.all_matches)
                (Terrat_base_repo_config_v1.apply_requirements repo_config)
              >>= fun () -> Abb.Future.return (Ok work_manifest)
          | false -> Abb.Future.return (Ok work_manifest))
        dirspaceflows_by_run_params

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
          fetch Keys.pull_request
          >>= fun pull_request ->
          let module Status = Terrat_commit_check.Status in
          create_op_commit_checks
            (Builder.log_id s)
            (Builder.State.config s)
            client
            account
            repo
            branch_ref
            work_manifest
            "Running"
            Status.Running
          >>= fun () -> Abb.Future.return (Ok ())
      | false -> Abb.Future.return (Ok ()))
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
      >>= fun repo_config ->
      fetch Keys.synthesized_config >>= fun synthesized_config -> raise (Failure "nyi")

    let fail work_manifest s { Bs.Fetcher.fetch } = raise (Failure "nyi")
    let result work_manifest result s { Bs.Fetcher.fetch } = raise (Failure "nyi")

    let run ~dest_branch_ref ~branch_ref ~name =
      Wm_sm.run ~name ~eq:(eq dest_branch_ref branch_ref) ~create ~initiate ~fail ~result
  end

  module Apply = struct
    let eq base_ref' branch_ref' { Wm.base_ref; branch_ref; steps; _ } =
      base_ref = S.Api.Ref.to_string base_ref'
      && branch_ref = S.Api.Ref.to_string branch_ref'
      && steps = [ Wm.Step.Index ]

    let create s { Bs.Fetcher.fetch } = raise (Failure "nyi")
    let initiate ({ Wm.id; _ } as work_manifest) s { Bs.Fetcher.fetch } = raise (Failure "nyi")
    let fail work_manifest s { Bs.Fetcher.fetch } = raise (Failure "nyi")
    let result work_manifest result s { Bs.Fetcher.fetch } = raise (Failure "nyi")

    let run ~dest_branch_ref ~branch_ref ~name =
      Wm_sm.run ~name ~eq:(eq dest_branch_ref branch_ref) ~create ~initiate ~fail ~result
  end
end
