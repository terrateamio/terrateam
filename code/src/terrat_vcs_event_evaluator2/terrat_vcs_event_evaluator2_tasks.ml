module Fc = Abbs_future_combinators
module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context
module Msg = Terrat_vcs_provider2.Msg
module P2 = Terrat_vcs_provider2

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  let src = Logs.Src.create ("vcs_event_evaluator2_tasks." ^ S.name)

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

  let make_tasks tasks_map =
    {
      Bs.Tasks.get =
        (fun s k -> Abb.Future.return (Ok (Hmap.find (Builder.coerce_to_task k) tasks_map)));
    }

  let of_work_manifest_tasks work_manifest =
    let module Wm = Terrat_work_manifest3 in
    let coerce = Builder.coerce_to_task in
    let { Wm.id; account; initiator; target; _ } = work_manifest in
    match target with
    | Terrat_vcs_provider2.Target.Pr pr ->
        Hmap.empty
        |> Hmap.add (coerce Keys.account) (fun _ _ -> Abb.Future.return (Ok account))
        |> Hmap.add (coerce Keys.pull_request_id) (fun _ _ ->
               Abb.Future.return (Ok (S.Api.Pull_request.id pr)))
        |> Hmap.add (coerce Keys.repo) (fun _ _ ->
               Abb.Future.return (Ok (S.Api.Pull_request.repo pr)))
        |> Hmap.add (coerce Keys.user) (fun _ _ -> Abb.Future.return (Ok None))
    | Terrat_vcs_provider2.Target.Drift _ -> raise (Failure "nyi")

  module H = struct
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
  end

  module Tasks = struct
    let run ~name f s fetcher =
      Abbs_time_it.run
        (fun t ->
          Logs.info (fun m -> m "%s : TASK : END : name=%s : time=%f" (Builder.log_id s) name t))
        (fun () ->
          let open Abb.Future.Infix_monad in
          Logs.info (fun m -> m "%s : TASK : START : name=%s" (Builder.log_id s) name);
          f s fetcher
          >>= function
          | Ok _ as r -> Abb.Future.return r
          | Error (`Suspend_eval _) as err ->
              Logs.info (fun m -> m "%s : TASK : SUSPEND : name=%s" (Builder.log_id s) name);
              Abb.Future.return err
          | Error (#Builder.err as err) ->
              Logs.info (fun m -> m "%s : TASK : FAIL : name=%s" (Builder.log_id s) name);
              Abb.Future.return (Error err))

    let account_status =
      run ~name:"account_status" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_account_status ~request_id:(Builder.log_id s) db account))

    let is_interactive =
      run ~name:"is_interactive" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.context
          >>= function
          | { Tjc.Context.scope = Tjc.Context.Scope.Pull_request _; _ } ->
              Abb.Future.return (Ok true)
          | _ -> Abb.Future.return (Ok false))

    let branch_name =
      run ~name:"branch_name" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Abb.Future.return (Ok (S.Api.Pull_request.branch_name pull_request)))

    let branch_ref =
      run ~name:"branch_ref" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Abb.Future.return (Ok (S.Api.Pull_request.branch_ref pull_request)))

    let dest_branch_name =
      run ~name:"dest_branch_name" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Abb.Future.return (Ok (S.Api.Pull_request.base_branch_name pull_request)))

    let dest_branch_ref =
      run ~name:"dest_branch_ref" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request -> Abb.Future.return (Ok (S.Api.Pull_request.base_ref pull_request)))

    let target =
      run ~name:"target" (fun s { Bs.Fetcher.fetch } ->
          let module C = Terrat_job_context.Context in
          let open Irm in
          fetch Keys.context
          >>= function
          | { C.scope = C.Scope.Pull_request _; _ } ->
              fetch Keys.pull_request
              >>= fun pull_request ->
              Abb.Future.return
                (Ok
                   (Terrat_vcs_provider2.Target.Pr
                      (Terrat_pull_request.set_diff ()
                      @@ Terrat_pull_request.set_checks ()
                      @@ pull_request)))
          | { C.scope = C.Scope.Branch branch; _ } ->
              fetch Keys.repo
              >>= fun repo ->
              Abb.Future.return
                (Ok
                   (Terrat_vcs_provider2.Target.Drift { repo; branch = S.Api.Ref.to_string branch }))
          | { C.scope = C.Scope.Setup; _ } -> assert false)

    let initiator =
      run ~name:"initiator" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.job
          >>= function
          | { Tjc.Job.initiator = Some user; _ } ->
              Abb.Future.return
                (Ok (Terrat_work_manifest3.Initiator.User (S.Api.User.to_string user)))
          | { Tjc.Job.initiator = None; _ } ->
              Abb.Future.return (Ok Terrat_work_manifest3.Initiator.System))

    let client =
      run ~name:"client" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          Builder.run_db s ~f:(fun db ->
              S.Api.create_client ~request_id:(Builder.log_id s) (Builder.State.config s) account db))

    let context =
      run ~name:"context" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.context_id
          >>= fun context_id ->
          Builder.run_db s ~f:(fun db ->
              S.Job_context.query ~request_id:(Builder.log_id s) db context_id)
          >>= function
          | Some context -> Abb.Future.return (Ok context)
          | None -> assert false)

    let work_manifests_for_job =
      run ~name:"work_manifests_for_job" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.job
          >>= fun job ->
          Builder.run_db s ~f:(fun db ->
              S.Job_context.Job.query_work_manifests
                ~request_id:(Builder.log_id s)
                db
                ~job_id:job.Tjc.Job.id
                ()))

    let default_branch_sha =
      run ~name:"default_branch_sha" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.client
          >>= fun client ->
          fetch Keys.repo
          >>= fun repo ->
          S.Api.fetch_remote_repo ~request_id:(Builder.log_id s) client repo
          >>= fun remote_repo ->
          let default_branch = S.Api.Remote_repo.default_branch remote_repo in
          S.Api.fetch_branch_sha ~request_id:(Builder.log_id s) client repo default_branch
          >>= function
          | Some branch_sha -> Abb.Future.return (Ok branch_sha)
          | None -> assert false)

    let working_branch_ref =
      run ~name:"working_branch_ref" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          match S.Api.Pull_request.state pull_request with
          | Terrat_pull_request.State.Open _ | Terrat_pull_request.State.Closed ->
              Abb.Future.return (Ok (S.Api.Pull_request.branch_ref pull_request))
          | Terrat_pull_request.State.Merged _ -> fetch Keys.default_branch_sha)

    let matches =
      run ~name:"matches" (fun s { Bs.Fetcher.fetch } ->
          let compute_matches
              ~repo_config
              ~tag_query
              ~out_of_change_applies
              ~applied_dirspaces
              ~diff
              ~repo_tree
              ~index
              () =
            let module Dc = Terrat_change_match3.Dirspace_config in
            let module Dir_set = CCSet.Make (CCString) in
            let open Irm in
            fetch Keys.synthesized_config
            >>= fun config ->
            let out_of_change_dirspace_configs =
              CCList.flat_map
                CCFun.(Terrat_change_match3.of_dirspace config %> CCOption.to_list)
                out_of_change_applies
            in
            let applied_dirspaces = Terrat_data.Dirspace_set.of_list applied_dirspaces in
            let all_matches =
              Terrat_change_match3.match_diff_list
                ~force_matches:out_of_change_dirspace_configs
                config
                diff
            in
            let dirs =
              all_matches
              |> CCList.flatten
              |> CCList.map
                   (fun
                     {
                       Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
                       _;
                     }
                   -> dir)
              |> Dir_set.of_list
            in
            let existing_dirs =
              Dir_set.filter
                (function
                  | "." ->
                      (* The root directory is always there, because...it
                     has to be. *)
                      true
                  | d ->
                      let d = d ^ "/" in
                      CCList.exists (CCString.prefix ~pre:d) repo_tree)
                dirs
            in
            (* Filter out any dirspaces that have been applied or refer to a directory
           that no longer exists. This could happen because of
           [out_of_change_applies], these may refer to directories that no longer
           exist, and thus we can't do much about them other than ignore them. *)
            let all_unapplied_matches =
              CCList.filter_map
                (fun layer ->
                  match
                    CCList.filter
                      (fun { Dc.dirspace = { Terrat_dirspace.dir; _ } as dirspace; _ } ->
                        (not (Terrat_data.Dirspace_set.mem dirspace applied_dirspaces))
                        && Dir_set.mem dir existing_dirs)
                      layer
                  with
                  | [] -> None
                  | layer -> Some layer)
                all_matches
            in
            let working_set_matches =
              match all_unapplied_matches with
              | layer :: _ -> CCList.filter (Terrat_change_match3.match_tag_query ~tag_query) layer
              | [] -> []
            in
            let all_tag_query_matches =
              CCList.map
                (CCList.filter (Terrat_change_match3.match_tag_query ~tag_query))
                all_matches
            in
            let unapplied_dirspaces =
              all_unapplied_matches
              |> CCList.flat_map (fun layer ->
                     CCList.map (fun { Dc.dirspace; _ } -> dirspace) layer)
              |> Terrat_data.Dirspace_set.of_list
            in
            let working_layer =
              all_matches
              |> CCList.filter (fun layer ->
                     CCList.exists
                       (fun { Dc.dirspace; _ } ->
                         Terrat_data.Dirspace_set.mem dirspace unapplied_dirspaces)
                       layer)
              |> CCList.head_opt
              |> CCOption.get_or ~default:[]
            in
            Abb.Future.return
              (Ok
                 ( working_set_matches,
                   all_matches,
                   all_tag_query_matches,
                   all_unapplied_matches,
                   working_layer ))
          in
          let missing_autoplan_matches db pull_request matches =
            let module Dc = Terrat_change_match3.Dirspace_config in
            let open Irm in
            S.Db.query_dirspaces_without_valid_plans
              ~request_id:(Builder.log_id s)
              db
              pull_request
              (CCList.map (fun { Dc.dirspace; _ } -> dirspace) matches)
            >>= fun dirspaces ->
            let dirspaces = Terrat_data.Dirspace_set.of_list dirspaces in
            Abb.Future.return
              (Ok
                 (CCList.filter
                    (fun { Dc.dirspace; _ } -> Terrat_data.Dirspace_set.mem dirspace dirspaces)
                    matches))
          in
          let out_of_change_applies db =
            let open Abb.Future.Infix_monad in
            fetch Keys.pull_request
            >>= function
            | Ok pull_request ->
                S.Db.query_pull_request_out_of_change_applies
                  ~request_id:(Builder.log_id s)
                  db
                  pull_request
            | Error (`Missing_dep_err "pull_request") -> Abb.Future.return (Ok [])
            | Error #Builder.err as err -> Abb.Future.return err
          in
          let applied_dirspaces db =
            let open Abb.Future.Infix_monad in
            fetch Keys.pull_request
            >>= function
            | Ok pull_request ->
                S.Db.query_applied_dirspaces ~request_id:(Builder.log_id s) db pull_request
            | Error (`Missing_dep_err "pull_request") -> Abb.Future.return (Ok [])
            | Error #Builder.err as err -> Abb.Future.return err
          in
          let diff () =
            let open Abb.Future.Infix_monad in
            fetch Keys.pull_request
            >>= function
            | Ok _ -> fetch Keys.pull_request_diff
            | Error (`Missing_dep_err "pull_request") ->
                let open Irm in
                fetch Keys.repo_tree_branch
                >>= fun tree ->
                Abb.Future.return
                  (Ok (CCList.map (fun filename -> Terrat_change.Diff.Change { filename }) tree))
            | Error #Builder.err as err -> Abb.Future.return err
          in
          let module Tjc = Terrat_job_context in
          let open Irm in
          Fc.Result.all3
            (fetch Keys.repo_config)
            (fetch Keys.repo_tree_branch)
            (fetch Keys.repo_index_branch)
          >>= fun (repo_config, repo_tree, repo_index) ->
          Builder.run_db s ~f:out_of_change_applies
          >>= fun out_of_change_applies ->
          Builder.run_db s ~f:applied_dirspaces
          >>= fun applied_dirspaces ->
          fetch Keys.dest_branch_name
          >>= fun dest_branch_name ->
          fetch Keys.branch_name
          >>= fun branch_name ->
          fetch Keys.job
          >>= fun job ->
          let tag_query =
            let module T = Tjc.Job.Type_ in
            match job.Tjc.Job.type_ with
            | T.Apply { tag_query } | T.Plan { tag_query } -> tag_query
            | T.Autoapply | T.Autoplan | T.Repo_config | T.Unlock _ -> Terrat_tag_query.any
          in
          fetch Keys.repo_index_branch
          >>= fun index ->
          fetch Keys.derived_repo_config
          >>= fun (_, repo_config) ->
          diff ()
          >>= fun diff ->
          Abbs_time_it.run
            (fun t -> Logs.info (fun m -> m "%s : COMPUTE_APPROVED : time=%f" (Builder.log_id s) t))
            (fun () ->
              compute_matches
                ~repo_config
                ~tag_query
                ~out_of_change_applies
                ~applied_dirspaces
                ~diff
                ~repo_tree
                ~index
                ())
          >>= fun ( working_set_matches,
                    all_matches,
                    all_tag_query_matches,
                    all_unapplied_matches,
                    working_layer )
                ->
          let open Abb.Future.Infix_monad in
          fetch Keys.pull_request
          >>= function
          | Ok pull_request -> (
              let module T = Tjc.Job.Type_ in
              match job.Tjc.Job.type_ with
              | T.Autoplan ->
                  let working_set_matches =
                    CCList.filter
                      (fun {
                             Terrat_change_match3.Dirspace_config.when_modified =
                               {
                                 Terrat_base_repo_config_v1.When_modified.autoplan;
                                 autoplan_draft_pr;
                                 _;
                               };
                             _;
                           }
                         ->
                        autoplan
                        && ((not (S.Api.Pull_request.is_draft_pr pull_request)) || autoplan_draft_pr))
                      working_set_matches
                  in
                  let open Irm in
                  Builder.run_db s ~f:(fun db ->
                      missing_autoplan_matches db pull_request working_set_matches)
                  >>= fun working_set_matches ->
                  Abb.Future.return
                    (Ok
                       {
                         Keys.Matches.working_set_matches;
                         all_matches;
                         all_tag_query_matches;
                         all_unapplied_matches;
                         working_layer;
                       })
              | T.Autoapply ->
                  let working_set_matches =
                    CCList.filter
                      (fun {
                             Terrat_change_match3.Dirspace_config.when_modified =
                               { Terrat_base_repo_config_v1.When_modified.autoapply; _ };
                             _;
                           }
                         -> autoapply)
                      working_set_matches
                  in
                  Abb.Future.return
                    (Ok
                       {
                         Keys.Matches.working_set_matches;
                         all_matches;
                         all_tag_query_matches;
                         all_unapplied_matches;
                         working_layer;
                       })
              | T.Apply _ | T.Plan _ ->
                  Abb.Future.return
                    (Ok
                       {
                         Keys.Matches.working_set_matches;
                         all_matches;
                         all_tag_query_matches;
                         all_unapplied_matches;
                         working_layer;
                       })
              | T.Repo_config | T.Unlock _ -> assert false)
          | Error (`Missing_dep_err "pull_request") ->
              Abb.Future.return
                (Ok
                   {
                     Keys.Matches.working_set_matches;
                     all_matches;
                     all_tag_query_matches;
                     all_unapplied_matches;
                     working_layer;
                   })
          | Error #Builder.err as err -> Abb.Future.return err)

    let working_set_matches =
      run ~name:"working_set_matches" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.matches
          >>= fun { Keys.Matches.working_set_matches; _ } ->
          Abb.Future.return (Ok working_set_matches))

    let all_matches =
      run ~name:"all_matches" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.matches
          >>= fun { Keys.Matches.all_matches; _ } -> Abb.Future.return (Ok all_matches))

    let all_unapplied_matches =
      run ~name:"all_unapplied_matches" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.matches
          >>= fun { Keys.Matches.all_unapplied_matches; _ } ->
          Abb.Future.return (Ok all_unapplied_matches))

    let all_tag_query_matches =
      run ~name:"all_tag_query_matches" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.matches
          >>= fun { Keys.Matches.all_tag_query_matches; _ } ->
          Abb.Future.return (Ok all_tag_query_matches))

    let working_layer =
      run ~name:"working_layer" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.matches
          >>= fun { Keys.Matches.working_layer; _ } -> Abb.Future.return (Ok working_layer))

    let repo_tree_branch_wm_completed =
      run ~name:"repo_tree_branch_wm_completed" (fun s ({ Bs.Fetcher.fetch } as fetcher) ->
          let module Wm = Terrat_work_manifest3 in
          let open Irm in
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          Repo_tree_wm.run ~dest_branch_ref ~branch_ref ~name:"repo_tree_branch_wm" s fetcher
          >>= function
          | [] -> assert false
          | wm :: _ ->
              (* TODO: Handle failure *)
              Abb.Future.return (Ok wm))

    let built_repo_tree_branch =
      run ~name:"built_repo_tree_branch" (fun s { Bs.Fetcher.fetch } ->
          let module I = Terrat_api_components.Work_manifest_build_tree_result.Files.Items in
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_repo_tree
                ~request_id:(Builder.log_id s)
                ~base_ref:dest_branch_ref
                db
                account
                branch_ref)
          >>= function
          | Some tree -> Abb.Future.return (Ok (CCList.map (fun { I.path; _ } -> path) tree))
          | None -> (
              fetch Keys.repo_tree_branch_wm_completed
              >>= fun _ ->
              Builder.run_db s ~f:(fun db ->
                  S.Db.query_repo_tree
                    ~request_id:(Builder.log_id s)
                    ~base_ref:dest_branch_ref
                    db
                    account
                    branch_ref)
              >>= function
              | Some tree -> Abb.Future.return (Ok (CCList.map (fun { I.path; _ } -> path) tree))
              | None -> assert false))

    let built_repo_config_branch_wm_completed =
      run ~name:"built_repo_config_branch_wm_completed" (fun s ({ Bs.Fetcher.fetch } as fetcher) ->
          let module Wm = Terrat_work_manifest3 in
          let open Irm in
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          Build_config_wm.run
            ~dest_branch_ref
            ~branch_ref
            ~name:"repo_build_config_branch_wm"
            s
            fetcher
          >>= function
          | [] -> assert false
          | wm :: _ ->
              (* TODO: Handle failure *)
              Abb.Future.return (Ok wm))

    let repo_tree_branch =
      run ~name:"repo_tree_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          let module V1 = Terrat_base_repo_config_v1 in
          fetch Keys.repo_config_raw'
          >>= fun (_, repo_config_raw) ->
          let tree_builder = V1.tree_builder repo_config_raw in
          if tree_builder.V1.Tree_builder.enabled then fetch Keys.built_repo_tree_branch
          else
            Fc.Result.all3 (fetch Keys.client) (fetch Keys.repo) (fetch Keys.branch_ref)
            >>= fun (client, repo, branch_ref) ->
            S.Api.fetch_tree ~request_id:(Builder.log_id s) client repo branch_ref)

    let repo_tree_dest_branch_wm_completed =
      run ~name:"repo_tree_dest_branch_wm_completed" (fun s ({ Bs.Fetcher.fetch } as fetcher) ->
          let module Wm = Terrat_work_manifest3 in
          let open Irm in
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          Repo_tree_wm.run
            ~dest_branch_ref
            ~branch_ref:dest_branch_ref
            ~name:"repo_tree_dest_branch_wm"
            s
            fetcher
          >>= function
          | [] -> assert false
          | wm :: _ ->
              (* TODO: Handle failure *)
              Abb.Future.return (Ok wm))

    let built_repo_tree_dest_branch =
      run ~name:"built_repo_tree_dest_branch" (fun s { Bs.Fetcher.fetch } ->
          let module I = Terrat_api_components.Work_manifest_build_tree_result.Files.Items in
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_repo_tree ~request_id:(Builder.log_id s) db account dest_branch_ref)
          >>= function
          | Some tree -> Abb.Future.return (Ok (CCList.map (fun { I.path; _ } -> path) tree))
          | None -> (
              fetch Keys.repo_tree_dest_branch_wm_completed
              >>= fun _ ->
              Builder.run_db s ~f:(fun db ->
                  S.Db.query_repo_tree ~request_id:(Builder.log_id s) db account dest_branch_ref)
              >>= function
              | Some tree -> Abb.Future.return (Ok (CCList.map (fun { I.path; _ } -> path) tree))
              | None -> assert false))

    let built_repo_config_dest_branch_wm_completed =
      run
        ~name:"built_repo_config_dest_branch_wm_completed"
        (fun s ({ Bs.Fetcher.fetch } as fetcher) ->
          let module Wm = Terrat_work_manifest3 in
          let open Irm in
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          Build_config_wm.run
            ~dest_branch_ref
            ~branch_ref:dest_branch_ref
            ~name:"repo_build_config_dest_branch_wm"
            s
            fetcher
          >>= function
          | [] -> assert false
          | wm :: _ ->
              (* TODO: Handle failure *)
              Abb.Future.return (Ok wm))

    let built_repo_config_dest_branch =
      run ~name:"built_repo_config_dest_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          let module V1 = Terrat_base_repo_config_v1 in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          fetch Keys.repo_config_dest_branch_raw'
          >>= fun (_, repo_config_raw) ->
          let config_builder = V1.config_builder repo_config_raw in
          if config_builder.V1.Config_builder.enabled then
            Builder.run_db s ~f:(fun db ->
                S.Db.query_repo_config_json
                  ~request_id:(Builder.log_id s)
                  db
                  account
                  dest_branch_ref)
            >>= function
            | None ->
                fetch Keys.built_repo_config_dest_branch_wm_completed
                >>= fun _ ->
                Builder.run_db s ~f:(fun db ->
                    S.Db.query_repo_config_json
                      ~request_id:(Builder.log_id s)
                      db
                      account
                      dest_branch_ref)
            | Some _ as ret -> Abb.Future.return (Ok ret)
          else Abb.Future.return (Ok None))

    let repo_tree_dest_branch =
      run ~name:"repo_tree_dest_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          let module V1 = Terrat_base_repo_config_v1 in
          fetch Keys.repo_config_raw'
          >>= fun (_, repo_config_raw) ->
          let tree_builder = V1.tree_builder repo_config_raw in
          if tree_builder.V1.Tree_builder.enabled then fetch Keys.built_repo_tree_dest_branch
          else
            Fc.Result.all3 (fetch Keys.client) (fetch Keys.repo) (fetch Keys.dest_branch_ref)
            >>= fun (client, repo, dest_branch_ref) ->
            S.Api.fetch_tree ~request_id:(Builder.log_id s) client repo dest_branch_ref)

    let built_repo_config_branch =
      run ~name:"built_repo_config_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          let module V1 = Terrat_base_repo_config_v1 in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          fetch Keys.repo_config_raw'
          >>= fun (_, repo_config_raw) ->
          let config_builder = V1.config_builder repo_config_raw in
          if config_builder.V1.Config_builder.enabled then
            Builder.run_db s ~f:(fun db ->
                S.Db.query_repo_config_json ~request_id:(Builder.log_id s) db account branch_ref)
            >>= function
            | None ->
                fetch Keys.built_repo_config_branch_wm_completed
                >>= fun _ ->
                Builder.run_db s ~f:(fun db ->
                    S.Db.query_repo_config_json ~request_id:(Builder.log_id s) db account branch_ref)
            | Some _ as ret -> Abb.Future.return (Ok ret)
          else Abb.Future.return (Ok None))

    let repo_config_system_defaults =
      run ~name:"repo_config_system_defaults" (fun s _ ->
          let module V1 = Terrat_base_repo_config_v1 in
          match Terrat_config.infracost @@ S.Api.Config.config @@ Builder.State.config s with
          | Some _ -> Abb.Future.return (Ok V1.default)
          | None ->
              let system_defaults =
                {
                  (V1.to_view V1.default) with
                  V1.View.cost_estimation = V1.Cost_estimation.make ~enabled:false ();
                }
              in
              Abb.Future.return (Ok (V1.of_view system_defaults)))

    let repo_config_raw' =
      run ~name:"repo_config_raw'" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all4
            (fetch Keys.client)
            (fetch Keys.branch_ref)
            (fetch Keys.repo_config_system_defaults)
            (fetch Keys.repo)
          >>= fun (client, branch_ref, system_defaults, repo) ->
          S.Repo_config.fetch_with_provenance
            ~system_defaults
            (Builder.log_id s)
            client
            repo
            branch_ref)

    let repo_config_raw =
      run ~name:"repo_config_raw" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all5
            (fetch Keys.client)
            (fetch Keys.branch_ref)
            (fetch Keys.repo_config_system_defaults)
            (fetch Keys.repo)
            (fetch Keys.built_repo_config_branch)
          >>= fun (client, branch_ref, system_defaults, repo, built_config) ->
          S.Repo_config.fetch_with_provenance
            ?built_config
            ~system_defaults
            (Builder.log_id s)
            client
            repo
            branch_ref)

    let derived_repo_config_empty_index =
      run ~name:"derived_repo_config_empty_index" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all3
            (fetch Keys.repo_config_raw)
            (fetch Keys.pull_request)
            (fetch Keys.repo_tree_branch)
          >>= fun ((provenance, repo_config_raw), pull_request, repo_tree) ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m "%s : derived_repo_config_empty_index : derive : time=%f" (Builder.log_id s) t))
            (fun () ->
              Abbs_future_combinators.to_result
              @@ Abb.Thread.run (fun () ->
                     Terrat_base_repo_config_v1.derive
                       ~ctx:
                         (Terrat_base_repo_config_v1.Ctx.make
                            ~dest_branch:
                              (S.Api.Ref.to_string
                              @@ S.Api.Pull_request.base_branch_name pull_request)
                            ~branch:
                              (S.Api.Ref.to_string @@ S.Api.Pull_request.branch_name pull_request)
                            ())
                       ~index:Terrat_base_repo_config_v1.Index.empty
                       ~file_list:repo_tree
                       repo_config_raw))
          >>= fun repo_config -> Abb.Future.return (Ok (provenance, repo_config)))

    let derived_repo_config =
      run ~name:"derived_repo_config" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all3
            (fetch Keys.repo_config_raw)
            (fetch Keys.pull_request)
            (fetch Keys.repo_tree_branch)
          >>= fun ((provenance, repo_config_raw), pull_request, repo_tree) ->
          fetch Keys.repo_index_branch
          >>= fun index ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m "%s : derived_repo_config : derive : time=%f" (Builder.log_id s) t))
            (fun () ->
              Abbs_future_combinators.to_result
              @@ Abb.Thread.run (fun () ->
                     Terrat_base_repo_config_v1.derive
                       ~ctx:
                         (Terrat_base_repo_config_v1.Ctx.make
                            ~dest_branch:
                              (S.Api.Ref.to_string
                              @@ S.Api.Pull_request.base_branch_name pull_request)
                            ~branch:
                              (S.Api.Ref.to_string @@ S.Api.Pull_request.branch_name pull_request)
                            ())
                       ~index
                       ~file_list:repo_tree
                       repo_config_raw))
          >>= fun repo_config -> Abb.Future.return (Ok (provenance, repo_config)))

    let repo_config_with_provenance =
      run ~name:"repo_config_with_provenance" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.derived_repo_config
          >>= fun repo_config ->
          fetch Keys.synthesized_config >>= fun _ -> Abb.Future.return (Ok repo_config))

    let synthesized_config_empty_index =
      run ~name:"synthesized_config_empty_index" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.repo_tree_branch
          >>= fun repo_tree ->
          fetch Keys.derived_repo_config_empty_index
          >>= fun (_provenance, repo_config) ->
          match
            Terrat_change_match3.synthesize_config
              ~index:Terrat_base_repo_config_v1.Index.empty
              repo_config
          with
          | Ok synthesized_config -> Abb.Future.return (Ok synthesized_config)
          | Error (#Terrat_change_match3.synthesize_config_err as err) ->
              Abb.Future.return (Error err))

    let synthesized_config =
      run ~name:"synthesized_config" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.repo_tree_branch
          >>= fun repo_tree ->
          fetch Keys.repo_index_branch
          >>= fun index ->
          fetch Keys.derived_repo_config
          >>= fun (_provenance, repo_config) ->
          match Terrat_change_match3.synthesize_config ~index repo_config with
          | Ok synthesized_config -> Abb.Future.return (Ok synthesized_config)
          | Error (#Terrat_change_match3.synthesize_config_err as err) ->
              Abb.Future.return (Error err))

    let repo_config =
      run ~name:"repo_config" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.repo_config_with_provenance
          >>= fun (_, repo_config) -> Abb.Future.return (Ok repo_config))

    (* Repo config dest branch *)
    let repo_config_dest_branch_raw' =
      run ~name:"repo_config_dest_branch_raw'" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all4
            (fetch Keys.client)
            (fetch Keys.dest_branch_ref)
            (fetch Keys.repo_config_system_defaults)
            (fetch Keys.repo)
          >>= fun (client, dest_branch_ref, system_defaults, repo) ->
          S.Repo_config.fetch_with_provenance
            ~system_defaults
            (Builder.log_id s)
            client
            repo
            dest_branch_ref)

    let repo_config_dest_branch_raw =
      run ~name:"repo_config_dest_branch_raw" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all5
            (fetch Keys.client)
            (fetch Keys.dest_branch_ref)
            (fetch Keys.repo_config_system_defaults)
            (fetch Keys.repo)
            (fetch Keys.built_repo_config_dest_branch)
          >>= fun (client, dest_branch_ref, system_defaults, repo, built_config) ->
          S.Repo_config.fetch_with_provenance
            ?built_config
            ~system_defaults
            (Builder.log_id s)
            client
            repo
            dest_branch_ref)

    let derived_repo_config_dest_branch_empty_index =
      run ~name:"derived_repo_config_dest_branch_empty_index" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all3
            (fetch Keys.repo_config_dest_branch_raw)
            (fetch Keys.pull_request)
            (fetch Keys.repo_tree_dest_branch)
          >>= fun ((provenance, repo_config_raw), pull_request, repo_tree) ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m "%s : derived_repo_config_empty_index : derive : time=%f" (Builder.log_id s) t))
            (fun () ->
              Abbs_future_combinators.to_result
              @@ Abb.Thread.run (fun () ->
                     Terrat_base_repo_config_v1.derive
                       ~ctx:
                         (Terrat_base_repo_config_v1.Ctx.make
                            ~dest_branch:
                              (S.Api.Ref.to_string
                              @@ S.Api.Pull_request.base_branch_name pull_request)
                            ~branch:
                              (S.Api.Ref.to_string @@ S.Api.Pull_request.branch_name pull_request)
                            ())
                       ~index:Terrat_base_repo_config_v1.Index.empty
                       ~file_list:repo_tree
                       repo_config_raw))
          >>= fun repo_config -> Abb.Future.return (Ok (provenance, repo_config)))

    let derived_repo_config_dest_branch =
      run ~name:"derived_repo_config_dest_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all3
            (fetch Keys.repo_config_dest_branch_raw)
            (fetch Keys.pull_request)
            (fetch Keys.repo_tree_dest_branch)
          >>= fun ((provenance, repo_config_raw), pull_request, repo_tree) ->
          fetch Keys.repo_index_dest_branch
          >>= fun index ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m "%s : derived_repo_config : derive : time=%f" (Builder.log_id s) t))
            (fun () ->
              Abbs_future_combinators.to_result
              @@ Abb.Thread.run (fun () ->
                     Terrat_base_repo_config_v1.derive
                       ~ctx:
                         (Terrat_base_repo_config_v1.Ctx.make
                            ~dest_branch:
                              (S.Api.Ref.to_string
                              @@ S.Api.Pull_request.base_branch_name pull_request)
                            ~branch:
                              (S.Api.Ref.to_string @@ S.Api.Pull_request.branch_name pull_request)
                            ())
                       ~index
                       ~file_list:repo_tree
                       repo_config_raw))
          >>= fun repo_config -> Abb.Future.return (Ok (provenance, repo_config)))

    let repo_config_dest_branch_with_provenance =
      run ~name:"repo_config_dest_branch_with_provenance" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.derived_repo_config_dest_branch
          >>= fun repo_config ->
          fetch Keys.synthesized_config_dest_branch >>= fun _ -> Abb.Future.return (Ok repo_config))

    let synthesized_config_dest_branch_empty_index =
      run ~name:"synthesized_config_dest_branch_empty_index" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.repo_tree_dest_branch
          >>= fun repo_tree ->
          fetch Keys.derived_repo_config_dest_branch_empty_index
          >>= fun (_provenance, repo_config) ->
          match
            Terrat_change_match3.synthesize_config
              ~index:Terrat_base_repo_config_v1.Index.empty
              repo_config
          with
          | Ok synthesized_config -> Abb.Future.return (Ok synthesized_config)
          | Error (#Terrat_change_match3.synthesize_config_err as err) ->
              Abb.Future.return (Error err))

    let synthesized_config_dest_branch =
      run ~name:"synthesized_config_dest_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.repo_tree_dest_branch
          >>= fun repo_tree ->
          fetch Keys.repo_index_dest_branch
          >>= fun index ->
          fetch Keys.derived_repo_config_dest_branch
          >>= fun (_provenance, repo_config) ->
          match Terrat_change_match3.synthesize_config ~index repo_config with
          | Ok synthesized_config -> Abb.Future.return (Ok synthesized_config)
          | Error (#Terrat_change_match3.synthesize_config_err as err) ->
              Abb.Future.return (Error err))

    let repo_config_dest_branch =
      run ~name:"repo_config_dest_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.repo_config_dest_branch_with_provenance
          >>= fun (_, repo_config) -> Abb.Future.return (Ok repo_config))

    let repo_index_branch_wm_completed =
      run ~name:"repo_index_branch_wm_completed" (fun s ({ Bs.Fetcher.fetch } as fetcher) ->
          let open Irm in
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          Indexer_wm.run ~dest_branch_ref ~branch_ref ~name:"repo_index_branch_wm" s fetcher
          >>= function
          | [] -> assert false
          | wm :: _ ->
              (* TODO: Handle failure *)
              Abb.Future.return (Ok wm))

    let built_repo_index_branch =
      run ~name:"built_repo_index_branch" (fun s { Bs.Fetcher.fetch } ->
          (* TODO: Handle failed index *)
          let module I = Terrat_vcs_provider2.Index in
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.working_branch_ref
          >>= fun working_branch_ref ->
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_index ~request_id:(Builder.log_id s) db account working_branch_ref)
          >>= function
          | Some { I.index; _ } -> Abb.Future.return (Ok index)
          | None -> (
              fetch Keys.repo_index_branch_wm_completed
              >>= fun _ ->
              Builder.run_db s ~f:(fun db ->
                  S.Db.query_index ~request_id:(Builder.log_id s) db account working_branch_ref)
              >>= function
              | Some { I.index; _ } -> Abb.Future.return (Ok index)
              | None -> assert false))

    let repo_index_branch =
      run ~name:"repo_index_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          let module V1 = Terrat_base_repo_config_v1 in
          fetch Keys.repo_config_raw
          >>= fun (_, repo_config_raw) ->
          let indexer = V1.indexer repo_config_raw in
          if indexer.V1.Indexer.enabled then fetch Keys.built_repo_index_branch
          else Abb.Future.return (Ok V1.Index.empty))

    let repo_index_dest_branch_wm_completed =
      run ~name:"repo_index_dest_branch_wm_completed" (fun s ({ Bs.Fetcher.fetch } as fetcher) ->
          let open Irm in
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          Indexer_wm.run
            ~dest_branch_ref
            ~branch_ref:dest_branch_ref
            ~name:"repo_index_dest_branch_wm"
            s
            fetcher
          >>= function
          | [] -> assert false
          | wm :: _ ->
              (* TODO: Handle failure *)
              Abb.Future.return (Ok wm))

    let built_repo_index_dest_branch =
      run ~name:"built_repo_index_dest_branch" (fun s { Bs.Fetcher.fetch } ->
          (* TODO: Handle failed index *)
          let module I = Terrat_vcs_provider2.Index in
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_index ~request_id:(Builder.log_id s) db account dest_branch_ref)
          >>= function
          | Some { I.index; _ } -> Abb.Future.return (Ok index)
          | None -> (
              fetch Keys.repo_index_dest_branch_wm_completed
              >>= fun _ ->
              Builder.run_db s ~f:(fun db ->
                  S.Db.query_index ~request_id:(Builder.log_id s) db account dest_branch_ref)
              >>= function
              | Some { I.index; _ } -> Abb.Future.return (Ok index)
              | None -> assert false))

    let repo_index_dest_branch =
      run ~name:"repo_index_dest_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          let module V1 = Terrat_base_repo_config_v1 in
          fetch Keys.repo_config_raw
          >>= fun (_, repo_config_raw) ->
          let indexer = V1.indexer repo_config_raw in
          if indexer.V1.Indexer.enabled then fetch Keys.built_repo_index_dest_branch
          else Abb.Future.return (Ok V1.Index.empty))

    (* Dirspaces *)
    let dest_branch_dirspaces =
      run ~name:"dest_branch_dirspaces" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all3
            (fetch Keys.repo_config_dest_branch)
            (fetch Keys.synthesized_config_dest_branch)
            (fetch Keys.repo_tree_dest_branch)
          >>= fun (repo_config, config, repo_tree) ->
          Abbs_time_it.run
            (fun t -> Logs.info (fun m -> m "%s : MATCH_DIFF_LIST : time=%f" (Builder.log_id s) t))
            (fun () ->
              Abbs_future_combinators.to_result
              @@ Abb.Thread.run (fun () ->
                     CCList.flatten
                       (Terrat_change_match3.match_diff_list
                          config
                          (CCList.map
                             (fun filename -> Terrat_change.Diff.(Change { filename }))
                             repo_tree))))
          >>= fun matches ->
          let workflows = Terrat_base_repo_config_v1.workflows repo_config in
          let dirspaceflows =
            let module S = Terrat_base_repo_config_v1.Stacks in
            CCList.map
              (fun ({
                      Terrat_change_match3.Dirspace_config.dirspace;
                      stack_config = { S.Stack.variables; _ };
                      _;
                    } as change)
                 ->
                Terrat_change.Dirspaceflow.
                  {
                    dirspace;
                    workflow =
                      CCOption.map
                        (fun (idx, workflow) -> Workflow.{ idx; workflow })
                        (CCList.find_idx
                           (fun { Terrat_base_repo_config_v1.Workflows.Entry.tag_query; _ } ->
                             Terrat_change_match3.match_tag_query ~tag_query change)
                           workflows);
                    variables = Some variables;
                  })
              matches
          in
          Abb.Future.return
            (Ok
               (CCList.map
                  (fun Terrat_change.
                         {
                           Dirspaceflow.dirspace = { Dirspace.dir; workspace } as dirspace;
                           workflow;
                           variables;
                           _;
                         }
                     ->
                    let module Tcm = Terrat_change_match3 in
                    let module Wmd = Terrat_api_components.Work_manifest_dir in
                    let { Tcm.Dirspace_config.stack_name; _ } =
                      CCOption.get_exn_or "dirspaces" @@ Tcm.of_dirspace config dirspace
                    in
                    {
                      Wmd.path = dir;
                      workspace;
                      workflow =
                        CCOption.map
                          (fun Terrat_change.Dirspaceflow.Workflow.{ idx; _ } -> idx)
                          workflow;
                      rank = 0;
                      variables =
                        CCOption.map
                          (fun additional -> Wmd.Variables.make ~additional Json_schema.Empty_obj.t)
                          variables;
                      stack_name;
                    })
                  dirspaceflows)))

    let branch_dirspaces =
      run ~name:"branch_dirspaces" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all3
            (fetch Keys.repo_config)
            (fetch Keys.synthesized_config)
            (fetch Keys.repo_tree_branch)
          >>= fun (repo_config, config, repo_tree) ->
          Abbs_time_it.run
            (fun t -> Logs.info (fun m -> m "%s : MATCH_DIFF_LIST : time=%f" (Builder.log_id s) t))
            (fun () ->
              Abbs_future_combinators.to_result
              @@ Abb.Thread.run (fun () ->
                     CCList.flatten
                       (Terrat_change_match3.match_diff_list
                          config
                          (CCList.map
                             (fun filename -> Terrat_change.Diff.(Change { filename }))
                             repo_tree))))
          >>= fun matches ->
          let workflows = Terrat_base_repo_config_v1.workflows repo_config in
          let dirspaceflows =
            let module S = Terrat_base_repo_config_v1.Stacks in
            CCList.map
              (fun ({
                      Terrat_change_match3.Dirspace_config.dirspace;
                      stack_config = { S.Stack.variables; _ };
                      _;
                    } as change)
                 ->
                Terrat_change.Dirspaceflow.
                  {
                    dirspace;
                    workflow =
                      CCOption.map
                        (fun (idx, workflow) -> Workflow.{ idx; workflow })
                        (CCList.find_idx
                           (fun { Terrat_base_repo_config_v1.Workflows.Entry.tag_query; _ } ->
                             Terrat_change_match3.match_tag_query ~tag_query change)
                           workflows);
                    variables = Some variables;
                  })
              matches
          in
          Abb.Future.return
            (Ok
               (CCList.map
                  (fun Terrat_change.
                         {
                           Dirspaceflow.dirspace = { Dirspace.dir; workspace } as dirspace;
                           workflow;
                           variables;
                           _;
                         }
                     ->
                    let module Tcm = Terrat_change_match3 in
                    let module Wmd = Terrat_api_components.Work_manifest_dir in
                    let { Tcm.Dirspace_config.stack_name; _ } =
                      CCOption.get_exn_or "dirspaces" @@ Tcm.of_dirspace config dirspace
                    in
                    {
                      Wmd.path = dir;
                      workspace;
                      workflow =
                        CCOption.map
                          (fun Terrat_change.Dirspaceflow.Workflow.{ idx; _ } -> idx)
                          workflow;
                      rank = 0;
                      variables =
                        CCOption.map
                          (fun additional -> Wmd.Variables.make ~additional Json_schema.Empty_obj.t)
                          variables;
                      stack_name;
                    })
                  dirspaceflows)))

    let publish_unlock =
      run ~name:"publish_unlock" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          let eval_access_control () =
            fetch Keys.repo_config
            >>= fun repo_config ->
            fetch Keys.access_control
            >>= fun access_control ->
            let module Ac = Terrat_base_repo_config_v1.Access_control in
            let ac_conf = Terrat_base_repo_config_v1.access_control repo_config in
            if ac_conf.Ac.enabled then
              let match_list = ac_conf.Ac.unlock in
              Access_control.eval_match_list access_control match_list
              >>= function
              | true -> Abb.Future.return (Ok None)
              | false -> Abb.Future.return (Ok (Some match_list))
            else Abb.Future.return (Ok None)
          in
          let parse_unlock_ids pull_request_id = function
            | [] -> Ok [ S.Unlock_id.of_pull_request pull_request_id ]
            | unlock_ids ->
                CCResult.map_l
                  (function
                    | "drift" -> Ok (S.Unlock_id.drift ())
                    | s -> (
                        match S.Api.Pull_request.Id.of_string s with
                        | Some id -> Ok (S.Unlock_id.of_pull_request id)
                        | None -> Error (`Invalid_unlock_id s)))
                  unlock_ids
          in
          let run client pull_request unlock_ids =
            let open Irm in
            fetch Keys.repo
            >>= fun repo ->
            fetch Keys.access_control
            >>= fun access_control ->
            fetch Keys.user
            >>= fun user ->
            eval_access_control ()
            >>= function
            | None ->
                let open Irm in
                Builder.run_db s ~f:(fun db ->
                    Abbs_future_combinators.List_result.iter
                      ~f:(S.Db.unlock ~request_id:(Builder.log_id s) db repo)
                      unlock_ids)
                >>= fun () ->
                S.Comment.publish_comment
                  ~request_id:(Builder.log_id s)
                  client
                  (CCOption.map_or ~default:"" S.Api.User.to_string user)
                  pull_request
                  Msg.Unlock_success
                >>= fun () -> Abb.Future.return (Ok ())
            | Some match_list ->
                let open Irm in
                S.Comment.publish_comment
                  ~request_id:(Builder.log_id s)
                  client
                  (CCOption.map_or ~default:"" S.Api.User.to_string user)
                  pull_request
                  (Msg.Access_control_denied
                     ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                       `Unlock match_list ))
                >>= fun () -> Abb.Future.return (Ok ())
          in
          let open Irm in
          fetch Keys.client
          >>= fun client ->
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.user
          >>= fun user ->
          fetch Keys.job
          >>= fun job ->
          match job.Tjc.Job.type_ with
          | Tjc.Job.Type_.Unlock unlock_ids -> (
              let open Abb.Future.Infix_monad in
              Abb.Future.return @@ parse_unlock_ids (S.Api.Pull_request.id pull_request) unlock_ids
              >>= function
              | Ok unlock_ids -> run client pull_request unlock_ids
              | Error (`Invalid_unlock_id id) ->
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Invalid_unlock_id id))
          | _ -> assert false)

    let publish_repo_config =
      run ~name:"publish_repo_config" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all5
            (fetch Keys.client)
            (fetch Keys.pull_request)
            (fetch Keys.repo_config_with_provenance)
            (fetch Keys.user)
            (fetch Keys.react_to_comment)
          >>= fun (client, pull_request, repo_config_with_provenance, user, ()) ->
          S.Comment.publish_comment
            ~request_id:(Builder.log_id s)
            client
            (CCOption.map_or ~default:"" S.Api.User.to_string user)
            pull_request
            (Msg.Repo_config repo_config_with_provenance))

    let react_to_comment =
      run ~name:"react_to_comment" (fun s { Bs.Fetcher.fetch } ->
          let open Abb.Future.Infix_monad in
          fetch Keys.comment_id
          >>= function
          | Ok comment_id ->
              let open Irm in
              Fc.Result.all3 (fetch Keys.comment_id) (fetch Keys.pull_request) (fetch Keys.client)
              >>= fun (comment_id, pull_request, client) ->
              S.Api.react_to_comment ~request_id:(Builder.log_id s) client pull_request comment_id
          | Error (`Missing_dep_err "comment_id") ->
              (* It's OK if no comment_id exists, this is an error we'll just ignore. *)
              Abb.Future.return (Ok ())
          | Error #Builder.err as err -> Abb.Future.return err)

    let pull_request =
      run ~name:"pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all4
            (fetch Keys.account)
            (fetch Keys.repo)
            (fetch Keys.client)
            (fetch Keys.pull_request_id)
          >>= fun (account, repo, client, pull_request_id) ->
          S.Api.fetch_pull_request
            ~request_id:(Builder.log_id s)
            account
            client
            repo
            pull_request_id)

    let pull_request_diff =
      run ~name:"pull_request_diff" (fun s { Bs.Fetcher.fetch } ->
          let module V1 = Terrat_base_repo_config_v1 in
          let module I = Terrat_api_components.Work_manifest_build_tree_result.Files.Items in
          let open Irm in
          fetch Keys.repo_config
          >>= fun repo_config ->
          fetch Keys.pull_request
          >>= fun pull_request ->
          let diff = S.Api.Pull_request.diff pull_request in
          let tree_builder = V1.tree_builder repo_config in
          if tree_builder.V1.Tree_builder.enabled then
            let changed_files =
              Terrat_data.String_set.of_list
              @@ CCList.flat_map
                   (function
                     | Terrat_change.Diff.Add { filename }
                     | Terrat_change.Diff.Change { filename }
                     | Terrat_change.Diff.Remove { filename } -> [ filename ]
                     | Terrat_change.Diff.Move { filename; previous_filename } ->
                         [ filename; previous_filename ])
                   diff
            in
            fetch Keys.repo_tree_branch
            >>= fun _ ->
            fetch Keys.account
            >>= fun account ->
            fetch Keys.working_branch_ref
            >>= fun working_branch_ref ->
            fetch Keys.dest_branch_ref
            >>= fun dest_branch_ref ->
            Builder.run_db s ~f:(fun db ->
                S.Db.query_repo_tree
                  ~request_id:(Builder.log_id s)
                  ~base_ref:dest_branch_ref
                  db
                  account
                  working_branch_ref)
            >>= function
            | Some repo_tree ->
                Abb.Future.return
                  (Ok
                     (CCList.filter_map
                        (function
                          | { I.path = filename; changed = Some true; _ } ->
                              Some (Terrat_change.Diff.Change { filename })
                          | { I.path = filename; changed = None; _ }
                            when Terrat_data.String_set.mem filename changed_files ->
                              Some (Terrat_change.Diff.Change { filename })
                          | _ -> None)
                        repo_tree))
            | None -> assert false
          else Abb.Future.return (Ok diff))

    let store_repository =
      run ~name:"store_repository" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.repo
          >>= fun repo ->
          Builder.run_db s ~f:(fun db ->
              S.Db.store_account_repository ~request_id:(Builder.log_id s) db account repo))

    let store_pull_request =
      run ~name:"store_pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Builder.run_db s ~f:(fun db ->
              S.Db.store_pull_request ~request_id:(Builder.log_id s) db pull_request))

    let compute_node =
      run ~name:"compute_node" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.compute_node_id
          >>= fun compute_node_id ->
          Builder.run_db s ~f:(fun db ->
              S.Job_context.Compute_node.query ~request_id:(Builder.log_id s) ~compute_node_id db)
          >>= function
          | Some compute_node -> Abb.Future.return (Ok compute_node)
          | None -> Abb.Future.return (Error (`Missing_dep_err "compute_node")))

    let check_pull_request_state =
      run ~name:"check_pull_request_state" (fun s { Bs.Fetcher.fetch } ->
          let module Pr = Terrat_pull_request in
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          match S.Api.Pull_request.state pull_request with
          | Pr.State.Closed ->
              Logs.info (fun m -> m "%s : NOOP : PR_CLOSED" (Builder.log_id s));
              fetch Keys.client
              >>= fun client ->
              fetch Keys.repo
              >>= fun repo ->
              fetch Keys.branch_ref
              >>= fun branch_ref ->
              S.Api.fetch_commit_checks ~request_id:(Builder.log_id s) client repo branch_ref
              >>= fun commit_checks ->
              let module Ch = Terrat_commit_check in
              let unfinished_checks =
                CCList.filter_map
                  (function
                    | { Ch.status = Ch.Status.(Completed | Failed | Canceled); _ } -> None
                    | { Ch.status = Ch.Status.(Queued | Running); _ } as c ->
                        Some { c with Ch.status = Ch.Status.Canceled })
                  commit_checks
              in
              S.Api.create_commit_checks
                ~request_id:(Builder.log_id s)
                client
                repo
                branch_ref
                unfinished_checks
              >>= fun () -> Abb.Future.return (Error `Noop)
          | Pr.State.(Open _ | Merged _) -> Abb.Future.return (Ok ()))

    let access_control =
      run ~name:"access_control" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.user
          >>= function
          | Some user ->
              fetch Keys.repo_config
              >>= fun repo_config ->
              fetch Keys.client
              >>= fun client ->
              fetch Keys.repo
              >>= fun repo ->
              S.Api.fetch_remote_repo ~request_id:(Builder.log_id s) client repo
              >>= fun remote_repo ->
              let access_control = Terrat_base_repo_config_v1.access_control repo_config in
              Abb.Future.return
                (Ok
                   {
                     Keys.Access_control_engine.config = access_control;
                     ctx =
                       Keys.Access_control_engine.Access_control.Ctx.make
                         ~request_id:(Builder.log_id s)
                         ~client
                         ~config:(S.Api.Config.config (Builder.State.config s))
                         ~repo
                         ~user:(S.Api.User.to_string user)
                         ();
                     request_id = Builder.log_id s;
                     user = S.Api.User.to_string user;
                     policy_branch = S.Api.Remote_repo.default_branch remote_repo;
                   })
          | None -> assert false)

    let check_conflicting_plan_work_manifests =
      run ~name:"check_conflicting_plan_work_manifests" (fun s { Bs.Fetcher.fetch } ->
          let module R = Terrat_access_control2.R in
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.access_control_eval_plan
          >>= fun access_control_eval ->
          Abb.Future.return
            (access_control_eval
              : (R.t, Terrat_access_control2.err) result
              :> (R.t, [> Terrat_access_control2.err ]) result)
          >>= fun { R.pass = passed_dirspaces; _ } ->
          let dirspaces =
            CCList.map
              (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } -> dirspace)
              passed_dirspaces
          in
          Builder.run_db s ~f:(fun db ->
              S.Db.query_conflicting_work_manifests_in_repo
                ~request_id:(Builder.log_id s)
                db
                pull_request
                dirspaces
                `Plan)
          >>= function
          | None -> Abb.Future.return (Ok ())
          | Some (P2.Conflicting_work_manifests.Conflicting wms) ->
              fetch Keys.client
              >>= fun client ->
              fetch Keys.user
              >>= fun user ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                (Msg.Conflicting_work_manifests wms)
              >>= fun () -> Abb.Future.return (Error `Noop)
          | Some (P2.Conflicting_work_manifests.Maybe_stale wms) ->
              fetch Keys.client
              >>= fun client ->
              fetch Keys.user
              >>= fun user ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                (Msg.Maybe_stale_work_manifests wms)
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_merge_conflict =
      run ~name:"check_merge_conflict" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          match S.Api.Pull_request.state pull_request with
          | Terrat_pull_request.State.(Open Open_status.Merge_conflict) ->
              Logs.info (fun m -> m "%s : MERGE_CONFLICT" (Builder.log_id s));
              fetch Keys.client
              >>= fun client ->
              fetch Keys.user
              >>= fun user ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                Msg.Pull_request_not_mergeable
              >>= fun () -> Abb.Future.return (Error `Noop)
          | Terrat_pull_request.State.Open _
          | Terrat_pull_request.State.Closed
          | Terrat_pull_request.State.Merged _ -> Abb.Future.return (Ok ()))

    let check_account_tier =
      run ~name:"check_account_tier" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.is_interactive
          >>= function
          | true -> (
              fetch Keys.user
              >>= function
              | Some user -> (
                  fetch Keys.account
                  >>= fun account ->
                  Abbs_time_it.run
                    (fun time ->
                      Logs.info (fun m ->
                          m
                            "%s : TIER_CHECK : account=%s : user=%s : time=%f"
                            (Builder.log_id s)
                            (S.Api.Account.Id.to_string @@ S.Api.Account.id account)
                            (S.Api.User.to_string user)
                            time))
                    (fun () ->
                      Builder.run_db s ~f:(S.Tier.check ~request_id:(Builder.log_id s) user account))
                  >>= function
                  | None -> Abb.Future.return (Ok ())
                  | Some checks ->
                      fetch Keys.client
                      >>= fun client ->
                      fetch Keys.pull_request
                      >>= fun pull_request ->
                      S.Comment.publish_comment
                        ~request_id:(Builder.log_id s)
                        client
                        (S.Api.User.to_string user)
                        pull_request
                        (Msg.Tier_check checks)
                      >>= fun () -> Abb.Future.return (Error `Noop))
              | None -> Abb.Future.return (Ok ()))
          | false -> Abb.Future.return (Ok ()))

    let check_account_status_expired =
      run ~name:"check_account_status_expired" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_account_status ~request_id:(Builder.log_id s) db account)
          >>= function
          | `Active -> Abb.Future.return (Ok ())
          | `Trial_ending duration ->
              Logs.info (fun m ->
                  m
                    "EVALUATOR ; %s : TRIAL_ENDING : days=%d"
                    (Builder.log_id s)
                    (Duration.to_day duration));
              Abb.Future.return (Ok ())
          | `Expired | `Disabled ->
              Logs.info (fun m -> m "%s : ACCOUNT_EXPIRED" (Builder.log_id s));
              fetch Keys.client
              >>= fun client ->
              fetch Keys.pull_request
              >>= fun pull_request ->
              fetch Keys.user
              >>= fun user ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                Msg.Account_expired)

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

    let access_control_eval_apply =
      run ~name:"access_control_eval_apply" (fun s { Bs.Fetcher.fetch } ->
          let module Rr = Terrat_pull_request_review in
          let open Irm in
          fetch Keys.access_control
          >>= fun access_control ->
          fetch Keys.working_set_matches
          >>= fun working_set_matches ->
          fetch Keys.client
          >>= fun client ->
          fetch Keys.repo
          >>= fun repo ->
          fetch Keys.is_interactive
          >>= function
          | true ->
              fetch Keys.pull_request
              >>= fun pull_request ->
              S.Api.fetch_pull_request_reviews
                ~request_id:(Builder.log_id s)
                repo
                (S.Api.Pull_request.id pull_request)
                client
              >>= fun reviews ->
              let reviews =
                CCList.filter_map
                  (function
                    | { Rr.user; status = Rr.Status.Approved; _ } -> user
                    | _ -> None)
                  reviews
              in
              let open Abb.Future.Infix_monad in
              Access_control.eval_tf_operation access_control working_set_matches (`Apply reviews)
              >>= fun ret -> Abb.Future.return (Ok ret)
          | false -> Abb.Future.return (Error `Error))

    let check_access_control_plan =
      run ~name:"check_access_control_plan" (fun s { Bs.Fetcher.fetch } ->
          let module R = Terrat_access_control2.R in
          let open Irm in
          fetch Keys.access_control
          >>= fun access_control ->
          fetch Keys.access_control_eval_plan
          >>= function
          | Ok { R.pass = []; deny = _ :: _ as deny }
            when not (Access_control.plan_require_all_dirspace_access access_control) -> (
              let open Irm in
              fetch Keys.is_interactive
              >>= function
              | true ->
                  fetch Keys.client
                  >>= fun client ->
                  fetch Keys.pull_request
                  >>= fun pull_request ->
                  fetch Keys.user
                  >>= fun user ->
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Access_control_denied
                       ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                         `All_dirspaces deny ))
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | false -> Abb.Future.return (Error `Noop))
          | Ok { R.pass; deny }
            when CCList.is_empty deny
                 || not (Access_control.plan_require_all_dirspace_access access_control) ->
              Abb.Future.return (Ok ())
          | Ok { R.deny; _ } -> (
              let open Irm in
              fetch Keys.is_interactive
              >>= function
              | true ->
                  fetch Keys.client
                  >>= fun client ->
                  fetch Keys.pull_request
                  >>= fun pull_request ->
                  fetch Keys.user
                  >>= fun user ->
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Access_control_denied
                       ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                         `Dirspaces deny ))
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | false -> Abb.Future.return (Error `Noop))
          | Error `Error -> (
              let open Irm in
              fetch Keys.is_interactive
              >>= function
              | true ->
                  fetch Keys.client
                  >>= fun client ->
                  fetch Keys.pull_request
                  >>= fun pull_request ->
                  fetch Keys.user
                  >>= fun user ->
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Access_control_denied
                       ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                         `Lookup_err ))
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | false -> Abb.Future.return (Error `Noop)))

    let check_access_control_apply =
      run ~name:"check_access_control_apply" (fun s { Bs.Fetcher.fetch } ->
          let module R = Terrat_access_control2.R in
          let open Irm in
          let apply_requirements () =
            Fc.Result.all5
              (fetch Keys.client)
              (fetch Keys.repo_config)
              (fetch Keys.pull_request)
              (fetch Keys.working_set_matches)
              (fetch Keys.user)
            >>= fun (client, repo_config, pull_request, working_set_matches, user) ->
            match user with
            | Some user ->
                S.Apply_requirements.eval
                  ~request_id:(Builder.log_id s)
                  (Builder.State.config s)
                  user
                  client
                  repo_config
                  pull_request
                  working_set_matches
            | None -> raise (Failure "nyi")
          in
          apply_requirements ()
          >>= fun apply_requirements ->
          let op =
            `Apply
              (CCList.filter_map
                 (fun { Terrat_pull_request_review.user; _ } -> user)
                 (S.Apply_requirements.Result.approved_reviews apply_requirements))
          in
          Fc.Result.all6
            (fetch Keys.access_control)
            (fetch Keys.matches)
            (fetch Keys.client)
            (fetch Keys.pull_request)
            (fetch Keys.access_control_eval_apply)
            (fetch Keys.user)
          >>= fun (access_control, matches, client, pull_request, access_control_result, user) ->
          Abb.Future.return
            (access_control_result
              : (R.t, Terrat_access_control2.err) result
              :> (R.t, [> Terrat_access_control2.err ]) result)
          >>= fun access_control_result ->
          let passed_apply_requirements = S.Apply_requirements.Result.passed apply_requirements in
          match access_control_result with
          | _ when (not passed_apply_requirements) && not (op = `Apply_force) ->
              (* Regardless of access control, if apply requirements were NOT
                 passed, then we cannot apply this change UNLESS we are in an
                 "apply-force" because then access control result is important
                 because we are bypassing the apply requirements. *)
              Logs.info (fun m -> m "%s : PR_NOT_APPLIABLE" (Builder.log_id s));
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                (Msg.Pull_request_not_appliable (pull_request, apply_requirements))
              >>= fun () -> Abb.Future.return (Error `Noop)
          | { Terrat_access_control2.R.pass = []; deny = _ :: _ as deny }
            when not (Access_control.apply_require_all_dirspace_access access_control) ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `All_dirspaces deny ))
              >>= fun () -> Abb.Future.return (Error `Noop)
          | { Terrat_access_control2.R.pass; deny }
            when CCList.is_empty deny
                 || not (Access_control.apply_require_all_dirspace_access access_control) ->
              (* This is the success path *)
              Abb.Future.return (Ok ())
          | { Terrat_access_control2.R.deny; _ } ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                (Msg.Access_control_denied
                   ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                     `Dirspaces deny ))
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_conflicting_apply_work_manifests =
      run ~name:"check_conflicting_apply_work_manifests" (fun s { Bs.Fetcher.fetch } ->
          let module R = Terrat_access_control2.R in
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.access_control_eval_apply
          >>= fun access_control_eval ->
          Abb.Future.return
            (access_control_eval
              : (R.t, Terrat_access_control2.err) result
              :> (R.t, [> Terrat_access_control2.err ]) result)
          >>= fun { R.pass = passed_dirspaces; _ } ->
          let dirspaces =
            CCList.map
              (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } -> dirspace)
              passed_dirspaces
          in
          Builder.run_db s ~f:(fun db ->
              S.Db.query_conflicting_work_manifests_in_repo
                ~request_id:(Builder.log_id s)
                db
                pull_request
                dirspaces
                `Apply)
          >>= function
          | None -> Abb.Future.return (Ok ())
          | Some (P2.Conflicting_work_manifests.Conflicting wms) ->
              fetch Keys.client
              >>= fun client ->
              fetch Keys.user
              >>= fun user ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                (Msg.Conflicting_work_manifests wms)
              >>= fun () -> Abb.Future.return (Error `Noop)
          | Some (P2.Conflicting_work_manifests.Maybe_stale wms) ->
              fetch Keys.client
              >>= fun client ->
              fetch Keys.user
              >>= fun user ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                (Msg.Maybe_stale_work_manifests wms)
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_dirspaces_missing_plans =
      run ~name:"check_dirspaces_missing_plans" (fun s { Bs.Fetcher.fetch } ->
          let module R = Terrat_access_control2.R in
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.access_control_eval_apply
          >>= fun access_control_result ->
          Abb.Future.return
            (access_control_result
              : (R.t, Terrat_access_control2.err) result
              :> (R.t, [> Terrat_access_control2.err ]) result)
          >>= fun { Terrat_access_control2.R.pass = working_set_matches; _ } ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_dirspaces_without_valid_plans
                ~request_id:(Builder.log_id s)
                db
                pull_request
                (CCList.map
                   (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } -> dirspace)
                   working_set_matches))
          >>= function
          | [] -> Abb.Future.return (Ok ())
          | dirspaces ->
              fetch Keys.client
              >>= fun client ->
              fetch Keys.user
              >>= fun user ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                (Msg.Missing_plans dirspaces)
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_gates =
      run ~name:"check_gates" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all3
            (fetch Keys.client)
            (fetch Keys.pull_request)
            (fetch Keys.working_set_matches)
          >>= fun (client, pull_request, working_set_matches) ->
          let module Dc = Terrat_change_match3.Dirspace_config in
          let dirspaces = CCList.map (fun { Dc.dirspace; _ } -> dirspace) working_set_matches in
          Builder.run_db s ~f:(fun db ->
              S.Gate.eval ~request_id:(Builder.log_id s) client dirspaces pull_request db)
          >>= function
          | [] -> Abb.Future.return (Ok ())
          | denied ->
              fetch Keys.user
              >>= fun user ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                (Msg.Gate_check_failure denied)
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_dirspaces_owned_by_other_pull_requests =
      run ~name:"check_dirspaces_owned_by_other_pull_requests" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all3 (fetch Keys.repo_config) (fetch Keys.pull_request) (fetch Keys.all_matches)
          >>= fun (repo_config, pull_request, all_matches) ->
          Abb.Future.return (H.dirspaceflows_of_changes repo_config (CCList.flatten all_matches))
          >>= fun all_match_dirspaceflows ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_dirspaces_owned_by_other_pull_requests
                ~request_id:(Builder.log_id s)
                db
                pull_request
                (CCList.map Terrat_change.Dirspaceflow.to_dirspace all_match_dirspaceflows))
          >>= function
          | [] -> Abb.Future.return (Ok ())
          | owned_dirspaces ->
              fetch Keys.client
              >>= fun client ->
              fetch Keys.user
              >>= fun user ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                (Msg.Dirspaces_owned_by_other_pull_request owned_dirspaces)
              >>= fun () -> Abb.Future.return (Error `Noop))

    let check_valid_destination_branch =
      run ~name:"check_valid_destination_branch" (fun s { Bs.Fetcher.fetch } ->
          (* Turn a glob into lua pattern for checking.  We escape all lua pattern
             special characters "().%+-?[^$", turn * into ".*", and wrap the whole thing
             in ^ and $ to make it a complete string match. *)
          let pattern_of_glob s =
            let len = CCString.length s in
            let b = Buffer.create len in
            Buffer.add_char b '^';
            for i = 0 to len - 1 do
              match CCString.get s i with
              | '*' -> Buffer.add_string b ".*"
              | ('(' | ')' | '.' | '%' | '+' | '-' | '?' | '[' | '^' | '$') as c ->
                  Buffer.add_char b '%';
                  Buffer.add_char b c
              | c -> Buffer.add_char b c
            done;
            Buffer.add_char b '$';
            let pattern = Buffer.contents b in
            CCOption.get_exn_or
              ("pattern_glob " ^ s ^ " " ^ pattern)
              (Lua_pattern.of_string pattern)
          in
          let rec eval_destination_branch_match dest_branch source_branch =
            let module Ds = Terrat_base_repo_config_v1.Destination_branches.Destination_branch in
            function
            | [] -> Error `No_matching_dest_branch
            | { Ds.branch; source_branches } :: valid_branches -> (
                let branch_glob = pattern_of_glob (CCString.lowercase_ascii branch) in
                match Lua_pattern.find dest_branch branch_glob with
                | Some _ ->
                    (* Partition the source branches into the not patterns and the
                   positive patterns. *)
                    let not_branches, branches =
                      CCList.partition (CCString.prefix ~pre:"!") source_branches
                    in
                    (* Remove the exclamation point from the beginning as it's not
                   actually part of the pattern. *)
                    let not_branch_globs =
                      CCList.map
                        CCFun.(CCString.drop 1 %> CCString.lowercase_ascii %> pattern_of_glob)
                        not_branches
                    in
                    let branch_globs =
                      let branches =
                        (* If there are not-branch globs, but branch globs is empty,
                       that implicitly means match anything on the positive branch.
                       If not-branches are empty then take what is in branches,
                       which could be nothing. *)
                        match (not_branch_globs, branches) with
                        | _ :: _, [] -> [ "*" ]
                        | _, branches -> branches
                      in
                      CCList.map CCFun.(CCString.lowercase_ascii %> pattern_of_glob) branches
                    in
                    (* The not patterns are an "and", as in success for the not patterns
                   is that all of them do not match.

                   The positive matches, however, are if any of them match. *)
                    if
                      CCList.for_all
                        CCFun.(Lua_pattern.find source_branch %> CCOption.is_none)
                        not_branch_globs
                      && CCList.exists
                           CCFun.(Lua_pattern.find source_branch %> CCOption.is_some)
                           branch_globs
                    then Ok ()
                    else Error `No_matching_source_branch
                | None ->
                    (* If the dest branch doesn't match this branch, then try the next *)
                    eval_destination_branch_match dest_branch source_branch valid_branches)
          in
          let module Rc = Terrat_base_repo_config_v1 in
          let module Ds = Rc.Destination_branches.Destination_branch in
          let open Irm in
          Fc.Result.all3 (fetch Keys.client) (fetch Keys.pull_request) (fetch Keys.repo_config)
          >>= fun (client, pull_request, repo_config) ->
          S.Api.fetch_remote_repo
            ~request_id:(Builder.log_id s)
            client
            (S.Api.Pull_request.repo pull_request)
          >>= fun remote_repo ->
          let default_branch = S.Api.Remote_repo.default_branch remote_repo in
          let base_branch_name = S.Api.Pull_request.base_branch_name pull_request in
          let branch_name = S.Api.Pull_request.branch_name pull_request in
          let valid_branches =
            match Rc.destination_branches repo_config with
            | [] -> [ Ds.make ~branch:(S.Api.Ref.to_string default_branch) () ]
            | ds -> ds
          in
          let dest_branch = CCString.lowercase_ascii (S.Api.Ref.to_string base_branch_name) in
          let source_branch = CCString.lowercase_ascii (S.Api.Ref.to_string branch_name) in
          match eval_destination_branch_match dest_branch source_branch valid_branches with
          | Ok () -> Abb.Future.return (Ok ())
          | Error `No_matching_dest_branch -> (
              fetch Keys.job
              >>= fun job ->
              let module T = Terrat_job_context.Job.Type_ in
              match job.Terrat_job_context.Job.type_ with
              | T.Autoplan | T.Autoapply ->
                  Logs.info (fun m ->
                      m
                        "%s : DEST_BRANCH_NOT_VALID : branch=%s"
                        (Builder.log_id s)
                        (S.Api.Ref.to_string base_branch_name));
                  Abb.Future.return (Error `Noop)
              | T.Plan _ | T.Apply _ ->
                  let open Irm in
                  fetch Keys.user
                  >>= fun user ->
                  Logs.info (fun m ->
                      m
                        "%s : DEST_BRANCH_NOT_VALID_BRANCH_EXPLICIT : branch=%s"
                        (Builder.log_id s)
                        (S.Api.Ref.to_string base_branch_name));
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Dest_branch_no_match pull_request)
                  >>= fun () -> Abb.Future.return (Error `Error)
              | T.Repo_config | T.Unlock _ -> assert false)
          | Error `No_matching_source_branch -> (
              fetch Keys.job
              >>= fun job ->
              let module T = Terrat_job_context.Job.Type_ in
              match job.Terrat_job_context.Job.type_ with
              | T.Autoplan | T.Autoapply ->
                  Logs.info (fun m ->
                      m
                        "%s : SOURCE_BRANCH_NOT_VALID : branch=%s"
                        (Builder.log_id s)
                        (S.Api.Ref.to_string branch_name));
                  Abb.Future.return (Error `Noop)
              | T.Plan _ | T.Apply _ ->
                  let open Irm in
                  fetch Keys.user
                  >>= fun user ->
                  Logs.info (fun m ->
                      m
                        "%s : SOURCE_BRANCH_NOT_VALID_BRANCH_EXPLICIT : branch=%s"
                        (Builder.log_id s)
                        (S.Api.Ref.to_string branch_name));
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Dest_branch_no_match pull_request)
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | T.Repo_config | T.Unlock _ -> assert false))

    let check_access_control_repo_config =
      run ~name:"check_access_control_repo_config" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.access_control) (fetch Keys.pull_request_diff)
          >>= fun (access_control, diff) ->
          let open Abb.Future.Infix_monad in
          Access_control.eval_repo_config access_control diff
          >>= function
          | Ok None -> Abb.Future.return (Ok ())
          | Ok (Some match_list) -> (
              let open Irm in
              fetch Keys.is_interactive
              >>= function
              | true ->
                  fetch Keys.client
                  >>= fun client ->
                  fetch Keys.account
                  >>= fun account ->
                  fetch Keys.repo
                  >>= fun repo ->
                  fetch Keys.user
                  >>= fun user ->
                  fetch Keys.pull_request
                  >>= fun pull_request ->
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Access_control_denied
                       ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                         `Terrateam_config_update match_list ))
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | false -> Abb.Future.return (Error `Noop))
          | Error `Error -> (
              let open Irm in
              fetch Keys.is_interactive
              >>= function
              | true ->
                  fetch Keys.client
                  >>= fun client ->
                  fetch Keys.account
                  >>= fun account ->
                  fetch Keys.repo
                  >>= fun repo ->
                  fetch Keys.user
                  >>= fun user ->
                  fetch Keys.pull_request
                  >>= fun pull_request ->
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Access_control_denied
                       ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                         `Lookup_err ))
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | false -> Abb.Future.return (Error `Noop)))

    let check_access_control_files =
      run ~name:"check_access_control_files" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.access_control) (fetch Keys.pull_request_diff)
          >>= fun (access_control, diff) ->
          let open Abb.Future.Infix_monad in
          Access_control.eval_files access_control diff
          >>= function
          | Ok None -> Abb.Future.return (Ok ())
          | Ok (Some (fname, match_list)) -> (
              let open Irm in
              fetch Keys.is_interactive
              >>= function
              | true ->
                  fetch Keys.client
                  >>= fun client ->
                  fetch Keys.account
                  >>= fun account ->
                  fetch Keys.repo
                  >>= fun repo ->
                  fetch Keys.user
                  >>= fun user ->
                  fetch Keys.pull_request
                  >>= fun pull_request ->
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Access_control_denied
                       ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                         `Files (fname, match_list) ))
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | false -> Abb.Future.return (Error `Noop))
          | Error `Error -> (
              let open Irm in
              fetch Keys.is_interactive
              >>= function
              | true ->
                  fetch Keys.client
                  >>= fun client ->
                  fetch Keys.account
                  >>= fun account ->
                  fetch Keys.repo
                  >>= fun repo ->
                  fetch Keys.user
                  >>= fun user ->
                  fetch Keys.pull_request
                  >>= fun pull_request ->
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Access_control_denied
                       ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                         `Lookup_err ))
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | false -> Abb.Future.return (Error `Noop)))

    let check_access_control_ci_change =
      run ~name:"check_access_control_ci_change" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Fc.Result.all2 (fetch Keys.access_control) (fetch Keys.pull_request_diff)
          >>= fun (access_control, diff) ->
          let open Abb.Future.Infix_monad in
          Access_control.eval_ci_change access_control diff
          >>= function
          | Ok None -> Abb.Future.return (Ok ())
          | Ok (Some match_list) -> (
              let open Irm in
              fetch Keys.is_interactive
              >>= function
              | true ->
                  fetch Keys.client
                  >>= fun client ->
                  fetch Keys.account
                  >>= fun account ->
                  fetch Keys.repo
                  >>= fun repo ->
                  fetch Keys.user
                  >>= fun user ->
                  fetch Keys.pull_request
                  >>= fun pull_request ->
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Access_control_denied
                       ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                         `Ci_config_update match_list ))
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | false -> Abb.Future.return (Error `Noop))
          | Error `Error -> (
              let open Irm in
              fetch Keys.is_interactive
              >>= function
              | true ->
                  fetch Keys.client
                  >>= fun client ->
                  fetch Keys.account
                  >>= fun account ->
                  fetch Keys.repo
                  >>= fun repo ->
                  fetch Keys.user
                  >>= fun user ->
                  fetch Keys.pull_request
                  >>= fun pull_request ->
                  S.Comment.publish_comment
                    ~request_id:(Builder.log_id s)
                    client
                    (CCOption.map_or ~default:"" S.Api.User.to_string user)
                    pull_request
                    (Msg.Access_control_denied
                       ( S.Api.Ref.to_string access_control.Keys.Access_control_engine.policy_branch,
                         `Lookup_err ))
                  >>= fun () -> Abb.Future.return (Error `Noop)
              | false -> Abb.Future.return (Error `Noop)))

    let can_run_plan =
      run ~name:"can_run_plan" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.check_pull_request_state
          >>= fun () ->
          Abbs_future_combinators.Infix_result_app.(
            (fun () () () () () () () () () () -> ())
            <$> fetch Keys.check_access_control_ci_change
            <*> fetch Keys.check_access_control_files
            <*> fetch Keys.check_access_control_repo_config
            <*> fetch Keys.check_valid_destination_branch
            <*> fetch Keys.check_access_control_plan
            <*> fetch Keys.check_account_status_expired
            <*> fetch Keys.check_account_tier
            <*> fetch Keys.check_merge_conflict
            <*> fetch Keys.check_conflicting_plan_work_manifests
            <*> fetch Keys.react_to_comment))

    let publish_plan =
      run ~name:"publish_plan" (fun s ({ Bs.Fetcher.fetch } as fetcher) ->
          let open Irm in
          fetch Keys.check_pull_request_state
          >>= fun () ->
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          Tf_op_wm.Plan.run ~dest_branch_ref ~branch_ref ~name:"plan_wm" s fetcher
          >>= fun wms ->
          (* Do something useful here? *)
          Abb.Future.return (Ok ()))

    let can_run_apply =
      run ~name:"can_run_apply" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.check_pull_request_state
          >>= fun () ->
          Abbs_future_combinators.Infix_result_app.(
            (fun () () () () () () () () () () () () () -> ())
            <$> fetch Keys.check_access_control_ci_change
            <*> fetch Keys.check_access_control_apply
            <*> fetch Keys.check_access_control_files
            <*> fetch Keys.check_access_control_repo_config
            <*> fetch Keys.check_account_status_expired
            <*> fetch Keys.check_account_tier
            <*> fetch Keys.check_conflicting_apply_work_manifests
            <*> fetch Keys.check_dirspaces_missing_plans
            <*> fetch Keys.check_dirspaces_owned_by_other_pull_requests
            <*> fetch Keys.check_gates
            <*> fetch Keys.check_merge_conflict
            <*> fetch Keys.check_pull_request_state
            <*> fetch Keys.react_to_comment))

    let publish_apply =
      run ~name:"publish_apply" (fun s ({ Bs.Fetcher.fetch } as fetcher) ->
          let open Irm in
          fetch Keys.check_pull_request_state
          >>= fun () ->
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          Tf_op_wm.Apply.run ~dest_branch_ref ~branch_ref ~name:"apply_wm" s fetcher
          >>= fun wms ->
          (* Do something useful here? *)
          Abb.Future.return (Ok ()))

    (* User facing tasks *)
    let update_context_for_pull_request =
      run ~name:"update_context_for_pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Abbs_future_combinators.Infix_result_app.(
            (fun () () -> ()) <$> fetch Keys.store_repository <*> fetch Keys.store_pull_request)
          >>= fun () ->
          fetch Keys.repo
          >>= fun repo ->
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.context
          >>= fun context ->
          Builder.State.mark_dirty s Keys.context;
          Builder.run_db s ~f:(fun db ->
              S.Job_context.update_for_pull_request
                ~request_id:(Builder.log_id s)
                ~context_id:context.Tjc.Context.id
                db
                repo
                (S.Api.Pull_request.id pull_request)))

    let eval_compute_node_poll default_tasks =
      run ~name:"eval_compute_node_poll" (fun s { Bs.Fetcher.fetch } ->
          let module C = Tjc.Compute_node in
          let module Cw = Tjc.Compute_node_work in
          let module Offering = Terrat_api_components.Work_manifest_initiate in
          let module Wm = Terrat_work_manifest3 in
          let module Wmc = Terrat_api_components.Work_manifest in
          let module Wmd = Terrat_api_components.Work_manifest_done in
          let open Irm in
          fetch Keys.compute_node
          >>= function
          | { C.state = C.State.Terminated; _ } ->
              Abb.Future.return (Ok (Wmc.Work_manifest_done { Wmd.type_ = "done" }))
          | compute_node ->
              fetch Keys.compute_node_offering
              >>= fun offering ->
              if compute_node.C.capabilities.C.Capabilities.sha = offering.Offering.sha then
                (* TODO: Decouple compute node id and work manifest id *)
                let work_manifest_id = compute_node.C.id in
                (* If a work manifest response already exists for the compute node,
                   then deliver it. *)
                Builder.run_db s ~f:(fun db ->
                    S.Job_context.Compute_node.query_work
                      ~request_id:(Builder.log_id s)
                      ~compute_node_id:compute_node.C.id
                      db)
                >>= function
                | Some { Cw.work = wm_response; state = Cw.State.Created; _ } ->
                    Abb.Future.return (Ok wm_response)
                | Some _ ->
                    Builder.run_db s ~f:(fun db ->
                        S.Job_context.Compute_node.update_state
                          ~request_id:(Builder.log_id s)
                          ~compute_node_id:compute_node.C.id
                          db
                          C.State.Terminated)
                    >>= fun () ->
                    Abb.Future.return (Ok (Wmc.Work_manifest_done { Wmd.type_ = "done" }))
                | None -> (
                    Builder.run_db s ~f:(fun db ->
                        S.Work_manifest.query ~request_id:(Builder.log_id s) db work_manifest_id)
                    >>= function
                    | Some { Wm.state = Wm.State.(Completed | Aborted); _ } ->
                        Abb.Future.return (Ok (Wmc.Work_manifest_done { Wmd.type_ = "done" }))
                    | Some work_manifest -> (
                        let open Abb.Future.Infix_monad in
                        let work_manifest_event =
                          Keys.Work_manifest_event.Initiate
                            { work_manifest; run_id = offering.Offering.run_id }
                        in
                        let store =
                          Builder.State.store s
                          |> Hmap.add Keys.work_manifest_event (Some work_manifest_event)
                        in
                        Builder.run_db s ~f:(fun db ->
                            let open Abb.Future.Infix_monad in
                            Builder.State.make
                              ~log_id:(Builder.log_id s)
                              ~config:(Builder.State.config s)
                              ~store
                              ~db
                              ()
                            >>= fun s ->
                            Bs.build
                              Builder.rebuilder
                              (make_tasks @@ default_tasks ())
                              Keys.eval_work_manifest_event
                              (Bs.St.create s))
                        >>= function
                        | Ok () | Error (`Suspend_eval _) -> (
                            let open Irm in
                            Builder.run_db s ~f:(fun db ->
                                S.Job_context.Compute_node.query_work
                                  ~request_id:(Builder.log_id s)
                                  ~compute_node_id:compute_node.C.id
                                  db)
                            >>= function
                            | Some { Cw.work = wm_response; _ } ->
                                Abb.Future.return (Ok wm_response)
                            | None -> raise (Failure "nyi"))
                        | Error #Builder.err as err -> Abb.Future.return err)
                    | None -> raise (Failure "nyi"))
              else raise (Failure "nyi"))

    let eval_work_manifest_event default_tasks =
      run ~name:"eval_work_manifest_event" (fun s { Bs.Fetcher.fetch } ->
          let module Wm = Terrat_work_manifest3 in
          let open Irm in
          fetch Keys.work_manifest_event
          >>= function
          | Some event -> (
              let work_manifest =
                match event with
                | Keys.Work_manifest_event.(
                    ( Initiate { work_manifest; _ }
                    | Fail { work_manifest }
                    | Result { work_manifest; _ } )) -> work_manifest
              in
              Builder.run_db s ~f:(fun db ->
                  S.Job_context.Job.query_by_work_manifest_id
                    ~request_id:(Builder.log_id s)
                    db
                    ~work_manifest_id:work_manifest.Wm.id
                    ())
              >>= function
              | None -> raise (Failure "nyi")
              | Some job ->
                  let context = job.Tjc.Job.context in
                  Logs.info (fun m ->
                      m
                        "%s : context_id=%a : job_id=%a : initiator=%s"
                        (Builder.log_id s)
                        Uuidm.pp
                        context.Tjc.Context.id
                        Uuidm.pp
                        job.Tjc.Job.id
                        (CCOption.map_or ~default:"" S.Api.User.to_string job.Tjc.Job.initiator));
                  let open Abb.Future.Infix_monad in
                  let tasks =
                    Builder.union_tasks
                      (make_tasks @@ of_work_manifest_tasks work_manifest)
                      (make_tasks @@ default_tasks ())
                  in
                  let store =
                    Builder.State.store s
                    |> Hmap.add Keys.job job
                    |> Hmap.add Keys.context context
                    |> Hmap.add Keys.work_manifest_event (Some event)
                    |> Hmap.add Keys.user job.Tjc.Job.initiator
                  in
                  Builder.run_db s ~f:(fun db ->
                      Builder.State.make
                        ~log_id:(Uuidm.to_string job.Tjc.Job.id)
                        ~config:(Builder.State.config s)
                        ~store
                        ~db
                        ()
                      >>= fun s ->
                      Logs.info (fun m ->
                          m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info Keys.iter_job));
                      Bs.build Builder.rebuilder tasks Keys.iter_job (Bs.St.create s)))
          | None -> assert false)

    let iter_job =
      run ~name:"iter_job" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.job
          >>= fun job ->
          let go =
            match job.Tjc.Job.type_ with
            | Tjc.Job.Type_.Apply _ | Tjc.Job.Type_.Autoapply -> fetch Keys.publish_apply
            | Tjc.Job.Type_.Autoplan | Tjc.Job.Type_.Plan _ -> fetch Keys.publish_plan
            | Tjc.Job.Type_.Repo_config -> fetch Keys.publish_repo_config
            | Tjc.Job.Type_.Unlock _ -> fetch Keys.publish_unlock
          in
          let open Abb.Future.Infix_monad in
          go
          >>= function
          | Ok () | Error `Noop ->
              let open Irm in
              Builder.run_db s ~f:(fun db ->
                  S.Job_context.Job.update_state
                    ~request_id:(Builder.log_id s)
                    db
                    ~job_id:job.Tjc.Job.id
                    Tjc.Job.State.Completed)
              >>= fun () -> Abb.Future.return (Ok ())
          | Error (#Builder.err as err) ->
              let open Irm in
              Builder.run_db s ~f:(fun db ->
                  S.Job_context.Job.update_state
                    ~request_id:(Builder.log_id s)
                    db
                    ~job_id:job.Tjc.Job.id
                    Tjc.Job.State.Failed)
              >>= fun () -> Abb.Future.return (Error err))

    let eval_job =
      run ~name:"eval_job" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.job
          >>= fun job ->
          let go =
            match job.Tjc.Job.type_ with
            | Tjc.Job.Type_.Apply _ | Tjc.Job.Type_.Autoapply ->
                fetch Keys.can_run_apply >>= fun () -> fetch Keys.iter_job
            | Tjc.Job.Type_.Autoplan | Tjc.Job.Type_.Plan _ ->
                fetch Keys.can_run_plan >>= fun () -> fetch Keys.iter_job
            | Tjc.Job.Type_.Repo_config -> fetch Keys.publish_repo_config
            | Tjc.Job.Type_.Unlock _ -> fetch Keys.publish_unlock
          in
          let open Abb.Future.Infix_monad in
          go
          >>= function
          | Ok () | Error `Noop ->
              let open Irm in
              Builder.run_db s ~f:(fun db ->
                  S.Job_context.Job.update_state
                    ~request_id:(Builder.log_id s)
                    db
                    ~job_id:job.Tjc.Job.id
                    Tjc.Job.State.Completed)
              >>= fun () -> Abb.Future.return (Ok ())
          | Error (#Builder.err as err) ->
              let open Irm in
              Builder.run_db s ~f:(fun db ->
                  S.Job_context.Job.update_state
                    ~request_id:(Builder.log_id s)
                    db
                    ~job_id:job.Tjc.Job.id
                    Tjc.Job.State.Failed)
              >>= fun () -> Abb.Future.return (Error err))
  end

  let rec default_tasks () =
    let coerce = Builder.coerce_to_task in
    Hmap.empty
    |> Hmap.add (coerce Keys.access_control) Tasks.access_control
    |> Hmap.add (coerce Keys.access_control_eval_apply) Tasks.access_control_eval_apply
    |> Hmap.add (coerce Keys.access_control_eval_plan) Tasks.access_control_eval_plan
    |> Hmap.add (coerce Keys.account_status) Tasks.account_status
    |> Hmap.add (coerce Keys.all_matches) Tasks.all_matches
    |> Hmap.add (coerce Keys.all_tag_query_matches) Tasks.all_tag_query_matches
    |> Hmap.add (coerce Keys.all_unapplied_matches) Tasks.all_unapplied_matches
    |> Hmap.add (coerce Keys.branch_dirspaces) Tasks.branch_dirspaces
    |> Hmap.add (coerce Keys.branch_name) Tasks.branch_name
    |> Hmap.add (coerce Keys.branch_ref) Tasks.branch_ref
    |> Hmap.add (coerce Keys.built_repo_config_branch) Tasks.built_repo_config_branch
    |> Hmap.add
         (coerce Keys.built_repo_config_branch_wm_completed)
         Tasks.built_repo_config_branch_wm_completed
    |> Hmap.add (coerce Keys.built_repo_config_dest_branch) Tasks.built_repo_config_dest_branch
    |> Hmap.add
         (coerce Keys.built_repo_config_dest_branch_wm_completed)
         Tasks.built_repo_config_dest_branch_wm_completed
    |> Hmap.add (coerce Keys.built_repo_index_branch) Tasks.built_repo_index_branch
    |> Hmap.add (coerce Keys.built_repo_index_dest_branch) Tasks.built_repo_index_dest_branch
    |> Hmap.add (coerce Keys.built_repo_tree_branch) Tasks.built_repo_tree_branch
    |> Hmap.add (coerce Keys.built_repo_tree_dest_branch) Tasks.built_repo_tree_dest_branch
    |> Hmap.add (coerce Keys.check_access_control_apply) Tasks.check_access_control_apply
    |> Hmap.add (coerce Keys.check_access_control_ci_change) Tasks.check_access_control_ci_change
    |> Hmap.add (coerce Keys.check_access_control_files) Tasks.check_access_control_files
    |> Hmap.add (coerce Keys.check_access_control_plan) Tasks.check_access_control_plan
    |> Hmap.add
         (coerce Keys.check_access_control_repo_config)
         Tasks.check_access_control_repo_config
    |> Hmap.add (coerce Keys.check_account_status_expired) Tasks.check_account_status_expired
    |> Hmap.add (coerce Keys.check_account_tier) Tasks.check_account_tier
    |> Hmap.add
         (coerce Keys.check_conflicting_apply_work_manifests)
         Tasks.check_conflicting_apply_work_manifests
    |> Hmap.add
         (coerce Keys.check_conflicting_plan_work_manifests)
         Tasks.check_conflicting_plan_work_manifests
    |> Hmap.add (coerce Keys.check_dirspaces_missing_plans) Tasks.check_dirspaces_missing_plans
    |> Hmap.add
         (coerce Keys.check_dirspaces_owned_by_other_pull_requests)
         Tasks.check_dirspaces_owned_by_other_pull_requests
    |> Hmap.add (coerce Keys.check_gates) Tasks.check_gates
    |> Hmap.add (coerce Keys.check_merge_conflict) Tasks.check_merge_conflict
    |> Hmap.add (coerce Keys.check_pull_request_state) Tasks.check_pull_request_state
    |> Hmap.add (coerce Keys.check_valid_destination_branch) Tasks.check_valid_destination_branch
    |> Hmap.add (coerce Keys.client) Tasks.client
    |> Hmap.add (coerce Keys.compute_node) Tasks.compute_node
    |> Hmap.add (coerce Keys.context) Tasks.context
    |> Hmap.add (coerce Keys.default_branch_sha) Tasks.default_branch_sha
    |> Hmap.add (coerce Keys.derived_repo_config) Tasks.derived_repo_config
    |> Hmap.add (coerce Keys.derived_repo_config_dest_branch) Tasks.derived_repo_config_dest_branch
    |> Hmap.add
         (coerce Keys.derived_repo_config_dest_branch_empty_index)
         Tasks.derived_repo_config_dest_branch_empty_index
    |> Hmap.add (coerce Keys.derived_repo_config_empty_index) Tasks.derived_repo_config_empty_index
    |> Hmap.add (coerce Keys.dest_branch_dirspaces) Tasks.dest_branch_dirspaces
    |> Hmap.add (coerce Keys.dest_branch_name) Tasks.dest_branch_name
    |> Hmap.add (coerce Keys.dest_branch_ref) Tasks.dest_branch_ref
    |> Hmap.add (coerce Keys.eval_compute_node_poll) (Tasks.eval_compute_node_poll default_tasks)
    |> Hmap.add (coerce Keys.eval_job) Tasks.eval_job
    |> Hmap.add (coerce Keys.iter_job) Tasks.iter_job
    |> Hmap.add
         (coerce Keys.eval_work_manifest_event)
         (Tasks.eval_work_manifest_event default_tasks)
    |> Hmap.add (coerce Keys.initiator) Tasks.initiator
    |> Hmap.add (coerce Keys.is_interactive) Tasks.is_interactive
    |> Hmap.add (coerce Keys.matches) Tasks.matches
    |> Hmap.add (coerce Keys.can_run_apply) Tasks.can_run_apply
    |> Hmap.add (coerce Keys.can_run_plan) Tasks.can_run_plan
    |> Hmap.add (coerce Keys.publish_apply) Tasks.publish_apply
    |> Hmap.add (coerce Keys.publish_plan) Tasks.publish_plan
    |> Hmap.add (coerce Keys.publish_repo_config) Tasks.publish_repo_config
    |> Hmap.add (coerce Keys.publish_unlock) Tasks.publish_unlock
    |> Hmap.add (coerce Keys.pull_request) Tasks.pull_request
    |> Hmap.add (coerce Keys.pull_request_diff) Tasks.pull_request_diff
    |> Hmap.add (coerce Keys.react_to_comment) Tasks.react_to_comment
    |> Hmap.add (coerce Keys.repo_config) Tasks.repo_config
    |> Hmap.add (coerce Keys.repo_config_dest_branch) Tasks.repo_config_dest_branch
    |> Hmap.add (coerce Keys.repo_config_dest_branch_raw') Tasks.repo_config_dest_branch_raw'
    |> Hmap.add (coerce Keys.repo_config_dest_branch_raw) Tasks.repo_config_dest_branch_raw
    |> Hmap.add
         (coerce Keys.repo_config_dest_branch_with_provenance)
         Tasks.repo_config_dest_branch_with_provenance
    |> Hmap.add (coerce Keys.repo_config_raw') Tasks.repo_config_raw'
    |> Hmap.add (coerce Keys.repo_config_raw) Tasks.repo_config_raw
    |> Hmap.add (coerce Keys.repo_config_system_defaults) Tasks.repo_config_system_defaults
    |> Hmap.add (coerce Keys.repo_config_with_provenance) Tasks.repo_config_with_provenance
    |> Hmap.add (coerce Keys.repo_index_branch) Tasks.repo_index_branch
    |> Hmap.add (coerce Keys.repo_index_branch_wm_completed) Tasks.repo_index_branch_wm_completed
    |> Hmap.add (coerce Keys.repo_index_dest_branch) Tasks.repo_index_dest_branch
    |> Hmap.add
         (coerce Keys.repo_index_dest_branch_wm_completed)
         Tasks.repo_index_dest_branch_wm_completed
    |> Hmap.add (coerce Keys.repo_tree_branch) Tasks.repo_tree_branch
    |> Hmap.add (coerce Keys.repo_tree_branch_wm_completed) Tasks.repo_tree_branch_wm_completed
    |> Hmap.add (coerce Keys.repo_tree_dest_branch) Tasks.repo_tree_dest_branch
    |> Hmap.add (coerce Keys.repo_tree_dest_branch) Tasks.repo_tree_dest_branch
    |> Hmap.add (coerce Keys.repo_tree_dest_branch) Tasks.repo_tree_dest_branch
    |> Hmap.add
         (coerce Keys.repo_tree_dest_branch_wm_completed)
         Tasks.repo_tree_dest_branch_wm_completed
    |> Hmap.add (coerce Keys.store_pull_request) Tasks.store_pull_request
    |> Hmap.add (coerce Keys.store_repository) Tasks.store_repository
    |> Hmap.add (coerce Keys.synthesized_config) Tasks.synthesized_config
    |> Hmap.add (coerce Keys.synthesized_config_dest_branch) Tasks.synthesized_config_dest_branch
    |> Hmap.add
         (coerce Keys.synthesized_config_dest_branch_empty_index)
         Tasks.synthesized_config_dest_branch_empty_index
    |> Hmap.add (coerce Keys.synthesized_config_empty_index) Tasks.synthesized_config_empty_index
    |> Hmap.add (coerce Keys.target) Tasks.target
    |> Hmap.add (coerce Keys.update_context_for_pull_request) Tasks.update_context_for_pull_request
    |> Hmap.add (coerce Keys.work_manifests_for_job) Tasks.work_manifests_for_job
    |> Hmap.add (coerce Keys.working_branch_ref) Tasks.working_branch_ref
    |> Hmap.add (coerce Keys.working_layer) Tasks.working_layer
    |> Hmap.add (coerce Keys.working_set_matches) Tasks.working_set_matches
end
