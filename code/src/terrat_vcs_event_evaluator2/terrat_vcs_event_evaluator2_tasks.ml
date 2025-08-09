module Ira = Abbs_future_combinators.Infix_result_app
module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context
module Msg = Terrat_vcs_provider2.Msg

module Make (S : Terrat_vcs_provider2.S) = struct
  module Wm_sm = Terrat_vcs_event_evaluator2_wm_sm.Make (S)
  module Keys = Terrat_vcs_event_evaluator2_targets.Make (S)
  module Hmap = Keys.Hmap
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module B = Builder.B
  module Bs = Builder.Bs

  let tasks tasks_map =
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
    let token encryption_key id =
      Base64.encode_exn
      @@ Cstruct.to_string
      @@ Mirage_crypto.Hash.SHA256.hmac ~key:encryption_key
      @@ Cstruct.of_string
      @@ Ouuid.to_string id
  end

  module Repo_tree_wm = struct
    module Wm = Terrat_work_manifest3
    module Wmr = Terrat_api_components.Work_manifest_result
    module Bt = Terrat_api_components.Work_manifest_build_tree_result
    module Bf = Terrat_api_components.Work_manifest_build_result_failure

    let eq base_ref' branch_ref' { Wm.base_ref; branch_ref; steps; _ } =
      base_ref = S.Api.Ref.to_string base_ref'
      && branch_ref = S.Api.Ref.to_string branch_ref'
      && steps = [ Wm.Step.Build_tree ]

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
          steps = [ Wm.Step.Build_tree ];
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
              ~title:"terrateam build-tree"
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
              ~title:"terrateam build-tree"
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
      let module B = Terrat_api_components.Work_manifest_build_tree in
      let config =
        repo_config_raw
        |> Terrat_base_repo_config_v1.to_version_1
        |> Terrat_repo_config.Version_1.to_yojson
      in
      let response =
        Terrat_api_components.Work_manifest.Work_manifest_build_tree
          {
            B.base_ref = S.Api.Ref.to_string dest_branch_name;
            token = H.token encryption_key id;
            type_ = "build-tree";
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
              ~title:"terrateam build-tree"
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
      | Wmr.Work_manifest_build_tree_result { Bt.files } -> (
          fetch Keys.account
          >>= fun account ->
          fetch Keys.working_branch_ref
          >>= fun working_branch_ref ->
          Builder.run_db s ~f:(fun db ->
              S.Db.store_repo_tree
                ~request_id:(Builder.log_id s)
                db
                account
                working_branch_ref
                files)
          >>= fun () ->
          fetch Keys.is_interactive
          >>= function
          | true ->
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
                  ~title:"terrateam build-tree"
                  ~status:Terrat_commit_check.Status.Failed
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
      | Wmr.Work_manifest_build_result_failure { Bf.msg } -> (
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
              fetch Keys.user
              >>= fun user ->
              fetch Keys.pull_request
              >>= fun pull_request ->
              let check =
                S.Commit_check.make
                  ~config:(Builder.State.config s)
                  ~description:"Failed"
                  ~title:"terrateam build-tree"
                  ~status:Terrat_commit_check.Status.Failed
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
              >>= fun () ->
              S.Comment.publish_comment
                ~request_id:(Builder.log_id s)
                client
                (CCOption.map_or ~default:"" S.Api.User.to_string user)
                pull_request
                (Msg.Build_tree_failure msg)
          | false -> Abb.Future.return (Ok ()))
      | Wmr.Work_manifest_build_config_result _ -> assert false
      | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result _ ->
          assert false
      | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result2 _ ->
          assert false
      | Terrat_api_components_work_manifest_result.Work_manifest_index_result _ -> assert false

    let run ~dest_branch_ref ~branch_ref ~name =
      Wm_sm.run ~name ~eq:(eq dest_branch_ref branch_ref) ~create ~initiate ~fail ~result
  end

  module Tasks = struct
    let run ~name f s fetcher =
      Abbs_time_it.run
        (fun t ->
          Logs.info (fun m -> m "%s: TASK : TIME : name=%s : time=%f" (Builder.log_id s) name t))
        (fun () ->
          let open Abb.Future.Infix_monad in
          Logs.info (fun m -> m "%s : TASK : START : name=%s" (Builder.log_id s) name);
          f s fetcher
          >>= function
          | Ok _ as r ->
              Logs.info (fun m -> m "%s : TASK : END : SUCCESS : name=%s" (Builder.log_id s) name);
              Abb.Future.return r
          | Error (#Builder.err as err) ->
              Logs.err (fun m ->
                  m
                    "%s : TASK : END : FAILURE : name=%s : %a"
                    (Builder.log_id s)
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

    let client =
      run ~name:"client" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.account
          >>= fun account ->
          S.Api.create_client ~request_id:(Builder.log_id s) (Builder.State.config s) account)

    let job_work_manifests =
      run ~name:"job_work_manifests" (fun s { Bs.Fetcher.fetch } ->
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

    let repo_tree_branch_wm_completed =
      run ~name:"repo_tree_branch_wm_completed" (fun s ({ Bs.Fetcher.fetch } as fetcher) ->
          let module Wm = Terrat_work_manifest3 in
          let open Irm in
          fetch Keys.dest_branch_ref
          >>= fun dest_branch_ref ->
          fetch Keys.branch_ref
          >>= fun branch_ref ->
          Repo_tree_wm.run ~dest_branch_ref ~branch_ref ~name:"repo_tree_branch" s fetcher
          >>= function
          | [] -> assert false
          | wm :: _ ->
              (* TODO: Handle failure *)
              Abb.Future.return (Ok wm))

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
                ~request_id:(Builder.log_id s)
                ~base_ref:dest_branch_ref
                db
                account
                branch_ref)
          >>= function
          | Some tree -> Abb.Future.return (Ok tree)
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
            S.Api.fetch_tree ~request_id:(Builder.log_id s) client repo branch_ref)

    let repo_tree_dest_branch =
      run ~name:"repo_tree_dest_branch" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          Ira.(
            (fun client repo branch_ref -> (client, repo, branch_ref))
            <$> fetch Keys.client
            <*> fetch Keys.repo
            <*> fetch Keys.dest_branch_ref)
          >>= fun (client, repo, dest_branch_ref) ->
          S.Api.fetch_tree ~request_id:(Builder.log_id s) client repo dest_branch_ref)

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
            (Builder.log_id s)
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
                  m "%s : repo_config_with_provenance : derive : time=%f" (Builder.log_id s) t))
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
              Ira.(
                (fun comment_id pull_request client -> (comment_id, pull_request, client))
                <$> fetch Keys.comment_id
                <*> fetch Keys.pull_request
                <*> fetch Keys.client)
              >>= fun (comment_id, pull_request, client) ->
              S.Api.react_to_comment ~request_id:(Builder.log_id s) client pull_request comment_id
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
            ~request_id:(Builder.log_id s)
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
              S.Db.store_account_repository ~request_id:(Builder.log_id s) db account repo))

    let store_pull_request =
      run ~name:"store_pull_request" (fun s { Bs.Fetcher.fetch } ->
          let open Irm in
          fetch Keys.pull_request
          >>= fun pull_request ->
          Builder.run_db s ~f:(fun db ->
              S.Db.store_pull_request ~request_id:(Builder.log_id s) db pull_request))

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
                | Some { Cw.work = wm_response; _ } -> Abb.Future.return (Ok wm_response)
                | None -> (
                    Builder.run_db s ~f:(fun db ->
                        S.Work_manifest.query ~request_id:(Builder.log_id s) db work_manifest_id)
                    >>= function
                    | Some { Wm.state = Wm.State.(Completed | Aborted); _ } ->
                        Abb.Future.return (Ok (Wmc.Work_manifest_done { Wmd.type_ = "done" }))
                    | Some work_manifest -> (
                        let work_manifest_event =
                          Keys.Work_manifest_event.Initiate
                            { work_manifest; run_id = offering.Offering.run_id }
                        in
                        let store =
                          Hmap.empty |> Hmap.add Keys.work_manifest_event (Some work_manifest_event)
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
                              (tasks @@ default_tasks ())
                              Keys.eval_work_manifest_event
                              (Bs.St.create s))
                        >>= fun () ->
                        Builder.run_db s ~f:(fun db ->
                            S.Job_context.Compute_node.query_work
                              ~request_id:(Builder.log_id s)
                              ~compute_node_id:compute_node.C.id
                              db)
                        >>= function
                        | Some { Cw.work = wm_response; _ } -> Abb.Future.return (Ok wm_response)
                        | None -> raise (Failure "nyi"))
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
                        "%s : context_id=%a : job_id=%a"
                        (Builder.log_id s)
                        Uuidm.pp
                        context.Tjc.Context.id
                        Uuidm.pp
                        job.Tjc.Job.id);
                  let open Abb.Future.Infix_monad in
                  let tasks =
                    Builder.union_tasks
                      (tasks @@ of_work_manifest_tasks work_manifest)
                      (tasks @@ default_tasks ())
                  in
                  let store =
                    Hmap.empty
                    |> Hmap.add Keys.job job
                    |> Hmap.add Keys.context context
                    |> Hmap.add Keys.work_manifest_event (Some event)
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
                          m "%s : target=%s" (Builder.log_id s) (Hmap.Key.info Keys.eval_job));
                      Bs.build Builder.rebuilder tasks Keys.eval_job (Bs.St.create s)))
          | None -> assert false)

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
          | Tjc.Job.Type_.Repo_config ->
              fetch Keys.publish_repo_config
              >>= fun () ->
              Builder.run_db s ~f:(fun db ->
                  S.Job_context.Job.update_state
                    ~request_id:(Builder.log_id s)
                    db
                    ~job_id:job.Tjc.Job.id
                    Tjc.Job.State.Completed)
          | Tjc.Job.Type_.Unlock -> raise (Failure "nyi"))
  end

  let rec default_tasks () =
    let coerce = Builder.coerce_to_task in
    Hmap.empty
    |> Hmap.add (coerce Keys.account_status) Tasks.account_status
    |> Hmap.add (coerce Keys.branch_name) Tasks.branch_name
    |> Hmap.add (coerce Keys.branch_ref) Tasks.branch_ref
    |> Hmap.add (coerce Keys.client) Tasks.client
    |> Hmap.add (coerce Keys.dest_branch_name) Tasks.dest_branch_name
    |> Hmap.add (coerce Keys.dest_branch_ref) Tasks.dest_branch_ref
    |> Hmap.add (coerce Keys.encryption_key) Tasks.encryption_key
    |> Hmap.add (coerce Keys.eval_compute_node_poll) (Tasks.eval_compute_node_poll default_tasks)
    |> Hmap.add (coerce Keys.eval_job) Tasks.eval_job
    |> Hmap.add
         (coerce Keys.eval_work_manifest_event)
         (Tasks.eval_work_manifest_event default_tasks)
    |> Hmap.add (coerce Keys.is_interactive) Tasks.is_interactive
    |> Hmap.add (coerce Keys.job_work_manifests) Tasks.job_work_manifests
    |> Hmap.add (coerce Keys.publish_repo_config) Tasks.publish_repo_config
    |> Hmap.add (coerce Keys.pull_request) Tasks.pull_request
    |> Hmap.add (coerce Keys.react_to_comment) Tasks.react_to_comment
    |> Hmap.add (coerce Keys.repo_config) Tasks.repo_config
    |> Hmap.add (coerce Keys.repo_config_raw) Tasks.repo_config_raw
    |> Hmap.add (coerce Keys.repo_config_system_defaults) Tasks.repo_config_system_defaults
    |> Hmap.add (coerce Keys.repo_config_with_provenance) Tasks.repo_config_with_provenance
    |> Hmap.add (coerce Keys.repo_tree_branch) Tasks.repo_tree_branch
    |> Hmap.add (coerce Keys.repo_tree_branch_wm_completed) Tasks.repo_tree_branch_wm_completed
    |> Hmap.add (coerce Keys.repo_tree_dest_branch) Tasks.repo_tree_dest_branch
    |> Hmap.add (coerce Keys.store_pull_request) Tasks.store_pull_request
    |> Hmap.add (coerce Keys.store_repository) Tasks.store_repository
    |> Hmap.add (coerce Keys.update_context_for_pull_request) Tasks.update_context_for_pull_request
end
