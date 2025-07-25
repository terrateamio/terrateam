module Ira = Abbs_future_combinators.Infix_result_app
module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context
module Msg = Terrat_vcs_provider2.Msg

module Make (S : Terrat_vcs_provider2.S) = struct
  module Keys = Terrat_vcs_event_evaluator2_targets.Make (S)
  module Hmap = Keys.Hmap
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module B = Builder.B
  module Bs = Builder.Bs

  module Tasks = struct
    let run ~name f s fetcher =
      Abbs_time_it.run
        (fun t ->
          Logs.info (fun m -> m "%s: TASK : TIME : name=%s : time=%f" (B.State.log_id s) name t))
        (fun () ->
          let open Abb.Future.Infix_monad in
          Logs.info (fun m -> m "%s : TASK : START : name=%s" (B.State.log_id s) name);
          f s fetcher
          >>= function
          | Ok _ as r ->
              Logs.info (fun m -> m "%s : TASK : END : SUCCESS : name=%s" (B.State.log_id s) name);
              Abb.Future.return r
          | Error (#Builder.err as err) ->
              Logs.err (fun m ->
                  m
                    "%s : TASK : END : FAILURE : name=%s : %a"
                    (B.State.log_id s)
                    name
                    Builder.pp_err
                    err);
              Abb.Future.return (Error err))

    let account_status =
      run ~name:"account_status" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_account_status ~request_id:(B.State.log_id s) db account))

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

    let client =
      run ~name:"client" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          S.Api.create_client ~request_id:(B.State.log_id s) s.B.State.config account)

    let job_work_manifests =
      run ~name:"job_work_manifests" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.job
          >>= fun job ->
          Builder.run_db s ~f:(fun db ->
              S.Job_context.Job.query_work_manifests
                ~request_id:(B.State.log_id s)
                db
                ~job_id:job.Tjc.Job.id
                ())
          >>= function
          | [] -> raise (Failure "nyi")
          | work_manifest_ids ->
              let open Irm in
              Builder.run_db s ~f:(fun db ->
                  Abbs_future_combinators.List_result.map
                    ~f:(S.Work_manifest.query ~request_id:(B.State.log_id s) db)
                    work_manifest_ids)
              >>= fun work_manifests ->
              Abb.Future.return (Ok (CCList.filter_map CCFun.id work_manifests)))

    let default_branch_sha =
      run ~name:"default_branch_sha" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.client
          >>= fun client ->
          fetch Keys.repo
          >>= fun repo ->
          S.Api.fetch_remote_repo ~request_id:(B.State.log_id s) client repo
          >>= fun remote_repo ->
          let default_branch = S.Api.Remote_repo.default_branch remote_repo in
          S.Api.fetch_branch_sha ~request_id:(B.State.log_id s) client repo default_branch
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

    let repo_tree_wm_create =
      run ~name:"repo_tree_wm_create" (fun s { Bs.Fetcher.fetch } ->
          let module Wm = Terrat_work_manifest3 in
          let open Irm in
          fetch Keys.job_work_manifests
          >>= fun work_manifests ->
          match
            CCList.find_opt
              (function
                | { Wm.steps = Wm.Step.Build_tree :: _; _ } -> true
                | _ -> false)
              work_manifests
          with
          | Some wm -> Abb.Future.return (Ok wm)
          | None ->
              Ira.(
                (fun client base_ref working_branch_ref -> (client, base_ref, working_branch_ref))
                <$> fetch Keys.client
                <*> fetch Keys.dest_branch_ref
                <*> fetch Keys.working_branch_ref)
              >>= fun (client, base_ref, working_branch_ref) -> raise (Failure "nyi"))

    let repo_tree_wm_result =
      run ~name:"repo_tree_wm_result" (fun s { Bs.Fetcher.fetch } -> raise (Failure "nyi"))

    let repo_tree_wm_completed =
      run ~name:"repo_tree_wm_completed" (fun s { Bs.Fetcher.fetch } -> raise (Failure "nyi"))

    let built_repo_tree_branch =
      run ~name:"built_repo_tree_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          Builder.run_db s ~f:(fun db ->
              S.Db.query_repo_tree
                ~request_id:(B.State.log_id s)
                ~base_ref:dest_branch_ref
                db
                account
                branch_ref)
          >>= function
          | Some tree -> Abb.Future.return (Ok tree)
          | None -> (
              fetch Keys.repo_tree_wm_completed
              >>= fun _ ->
              Builder.run_db s ~f:(fun db ->
                  S.Db.query_repo_tree
                    ~request_id:(B.State.log_id s)
                    ~base_ref:dest_branch_ref
                    db
                    account
                    branch_ref)
              >>= function
              | Some tree -> Abb.Future.return (Ok tree)
              | None -> assert false))

    let repo_tree_branch =
      run ~name:"repo_tree_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          let module V1 = Terrat_base_repo_config_v1 in
          fetch Keys.repo_config_raw
          >>= fun (_, repo_config_raw) ->
          let tree_builder = V1.tree_builder repo_config_raw in
          if tree_builder.V1.Tree_builder.enabled then fetch Keys.built_repo_tree_branch
          else
            Ira.(
              (fun client repo branch_ref -> (client, repo, branch_ref))
              <$> fetch Keys.client
              <*> fetch Keys.repo
              <*> fetch Keys.branch_ref)
            >>= fun (client, repo, branch_ref) ->
            S.Api.fetch_tree ~request_id:(B.State.log_id s) client repo branch_ref)

    let repo_tree_dest_branch =
      run ~name:"repo_tree_dest_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.(
            (fun client repo branch_ref -> (client, repo, branch_ref))
            <$> fetch Keys.client
            <*> fetch Keys.repo
            <*> fetch Keys.dest_branch_ref)
          >>= fun (client, repo, dest_branch_ref) ->
          S.Api.fetch_tree ~request_id:(B.State.log_id s) client repo dest_branch_ref)

    let repo_config_system_defaults =
      run ~name:"repo_config_system_defaults" (fun s _ ->
          let module V1 = Terrat_base_repo_config_v1 in
          match Terrat_config.infracost @@ S.Api.Config.config @@ s.B.State.config with
          | Some _ -> Abb.Future.return (Ok V1.default)
          | None ->
              let system_defaults =
                {
                  (V1.to_view V1.default) with
                  V1.View.cost_estimation = V1.Cost_estimation.make ~enabled:false ();
                }
              in
              Abb.Future.return (Ok (V1.of_view system_defaults)))

    let repo_config_raw =
      run ~name:"repo_config_raw" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.(
            (fun client branch_ref system_defaults repo ->
              (client, branch_ref, system_defaults, repo))
            <$> fetch Keys.client
            <*> fetch Keys.branch_ref
            <*> fetch Keys.repo_config_system_defaults
            <*> fetch Keys.repo)
          >>= fun (client, branch_ref, system_defaults, repo) ->
          S.Repo_config.fetch_with_provenance
            ~system_defaults
            (B.State.log_id s)
            client
            repo
            branch_ref)

    let repo_config_with_provenance =
      run ~name:"repo_config_with_provenance" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.(
            (fun repo_config_raw pull_request repo_tree ->
              (repo_config_raw, pull_request, repo_tree))
            <$> fetch Keys.repo_config_raw
            <*> fetch Keys.pull_request
            <*> fetch Keys.repo_tree_branch)
          >>= fun ((provenance, repo_config_raw), pull_request, repo_tree) ->
          let index = Terrat_base_repo_config_v1.Index.empty in
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m ->
                  m "%s : repo_config_with_provenance : derive : time=%f" (B.State.log_id s) t))
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
          >>= fun repo_config ->
          match Terrat_change_match3.synthesize_config ~index repo_config with
          | Ok _ -> Abb.Future.return (Ok (provenance, repo_config))
          | Error (#Terrat_change_match3.synthesize_config_err as err) ->
              Abb.Future.return (Error err))

    let repo_config =
      run ~name:"repo_config" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.repo_config_with_provenance
          >>= fun (_, repo_config) -> Abb.Future.return (Ok repo_config))

    let publish_repo_config =
      run ~name:"publish_repo_config" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.(
            (fun client pull_request repo_config_with_provenance user () ->
              (client, pull_request, repo_config_with_provenance, user))
            <$> fetch Keys.client
            <*> fetch Keys.pull_request
            <*> fetch Keys.repo_config_with_provenance
            <*> fetch Keys.user
            <*> fetch Keys.react_to_comment)
          >>= fun (client, pull_request, repo_config_with_provenance, user) ->
          S.Comment.publish_comment
            ~request_id:(B.State.log_id s)
            client
            (S.Api.User.to_string user)
            pull_request
            (Msg.Repo_config repo_config_with_provenance))

    let react_to_comment =
      run ~name:"react_to_comment" (fun s { Bs.Fetcher.fetch } ->
          let open Abb.Future.Infix_monad in
          fetch Keys.comment_id
          >>= function
          | Ok comment_id ->
              let open Irm in
              Ira.(
                (fun comment_id pull_request client -> (comment_id, pull_request, client))
                <$> fetch Keys.comment_id
                <*> fetch Keys.pull_request
                <*> fetch Keys.client)
              >>= fun (comment_id, pull_request, client) ->
              S.Api.react_to_comment ~request_id:(B.State.log_id s) client pull_request comment_id
          | Error (`Missing_dep_err "comment_id") ->
              (* It's OK if no comment_id exists, this is an error we'll just ignore. *)
              Abb.Future.return (Ok ())
          | Error #Builder.err as err -> Abb.Future.return err)

    let pull_request =
      run ~name:"pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.(
            (fun account repo client pull_request_id -> (account, repo, client, pull_request_id))
            <$> fetch Keys.account
            <*> fetch Keys.repo
            <*> fetch Keys.client
            <*> fetch Keys.pull_request_id)
          >>= fun (account, repo, client, pull_request_id) ->
          S.Api.fetch_pull_request
            ~request_id:(B.State.log_id s)
            account
            client
            repo
            pull_request_id)

    let store_repository =
      run ~name:"store_repository" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          fetch Keys.repo
          >>= fun repo ->
          Builder.run_db s ~f:(fun db ->
              S.Db.store_account_repository ~request_id:(B.State.log_id s) db account repo))

    let store_pull_request =
      run ~name:"store_pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Builder.run_db s ~f:(fun db ->
              S.Db.store_pull_request ~request_id:(B.State.log_id s) db pull_request))

    let encryption_key =
      let select_encryption_key () =
        (* The hex conversion is so that there are no issues with escaping
         the string *)
        Pgsql_io.Typed_sql.(
          sql
          //
          (* data *)
          Ret.ud' CCFun.(Cstruct.of_hex %> CCOption.return)
          /^ "select encode(data, 'hex') from encryption_keys order by rank limit 1")
      in
      run ~name:"encryption_key" (fun s _ ->
          let open Irm in
          Builder.run_db s ~f:(fun db ->
              Pgsql_io.Prepared_stmt.fetch db (select_encryption_key ()) ~f:CCFun.id)
          >>= function
          | [] -> Abb.Future.return (Error (`Missing_dep_err "encryption_key"))
          | key :: _ -> Abb.Future.return (Ok key))

    (* User facing tasks *)
    let update_context_for_pull_request =
      run ~name:"update_context_for_pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.((fun () () -> ()) <$> fetch Keys.store_repository <*> fetch Keys.store_pull_request)
          >>= fun () ->
          fetch Keys.repo
          >>= fun repo ->
          fetch Keys.pull_request
          >>= fun pull_request ->
          fetch Keys.context
          >>= fun context ->
          Builder.run_db s ~f:(fun db ->
              S.Job_context.update_for_pull_request
                ~request_id:(B.State.log_id s)
                ~context_id:context.Tjc.Context.id
                db
                repo
                (S.Api.Pull_request.id pull_request)))

    let eval_job =
      run ~name:"eval_job" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.job
          >>= fun job ->
          match job.Tjc.Job.type_ with
          | Tjc.Job.Type_.Apply { tag_query } -> raise (Failure "nyi")
          | Tjc.Job.Type_.Autoapply -> raise (Failure "nyi")
          | Tjc.Job.Type_.Autoplan -> raise (Failure "nyi")
          | Tjc.Job.Type_.Plan { tag_query } -> raise (Failure "nyi")
          | Tjc.Job.Type_.Repo_config -> fetch Keys.publish_repo_config
          | Tjc.Job.Type_.Unlock _ ->
              fetch Keys.publish_unlock
              >>= fun () ->
              Builder.run_db s ~f:(fun db ->
                  S.Job_context.Job.update_state
                    ~request_id:(Builder.log_id s)
                    db
                    ~job_id:job.Tjc.Job.id
                    Tjc.Job.State.Completed))
  end

  let add_tasks tasks =
    let coerce = Builder.coerce_to_task in
    tasks
    |> Hmap.add (coerce Keys.account_status) Tasks.account_status
    |> Hmap.add (coerce Keys.branch_name) Tasks.branch_name
    |> Hmap.add (coerce Keys.branch_ref) Tasks.branch_ref
    |> Hmap.add (coerce Keys.dest_branch_name) Tasks.dest_branch_name
    |> Hmap.add (coerce Keys.dest_branch_ref) Tasks.dest_branch_ref
    |> Hmap.add (coerce Keys.client) Tasks.client
    |> Hmap.add (coerce Keys.repo_tree_branch) Tasks.repo_tree_branch
    |> Hmap.add (coerce Keys.repo_tree_dest_branch) Tasks.repo_tree_dest_branch
    |> Hmap.add (coerce Keys.repo_config_system_defaults) Tasks.repo_config_system_defaults
    |> Hmap.add (coerce Keys.repo_config_raw) Tasks.repo_config_raw
    |> Hmap.add (coerce Keys.repo_config_with_provenance) Tasks.repo_config_with_provenance
    |> Hmap.add (coerce Keys.repo_config) Tasks.repo_config
    |> Hmap.add (coerce Keys.publish_repo_config) Tasks.publish_repo_config
    |> Hmap.add (coerce Keys.react_to_comment) Tasks.react_to_comment
    |> Hmap.add (coerce Keys.pull_request) Tasks.pull_request
    |> Hmap.add (coerce Keys.update_context_for_pull_request) Tasks.update_context_for_pull_request
    |> Hmap.add (coerce Keys.store_repository) Tasks.store_repository
    |> Hmap.add (coerce Keys.store_pull_request) Tasks.store_pull_request
    |> Hmap.add (coerce Keys.encryption_key) Tasks.encryption_key
    |> Hmap.add (coerce Keys.job_work_manifests) Tasks.job_work_manifests
    |> Hmap.add (coerce Keys.eval_job) Tasks.eval_job
end
