module Gw = Terrat_github_webhooks

module Metrics = struct
  module DefaultHistogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_list [ 0.005; 0.5; 1.0; 5.0; 10.0; 15.0; 20.0 ]
  end)

  module Work_manifest_run_time_histogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_exponential 20.0 1.5 10
  end)

  module Run_output_histogram = Prmths.Histogram (struct
    let spec =
      Prmths.Histogram_spec.of_list [ 500.0; 1000.0; 2500.0; 10000.0; 20000.0; 35000.0; 65000.0 ]
  end)

  let namespace = "terrat"
  let subsystem = "github_evaluator"
  let pgsql_pool_errors_total = Terrat_metrics.errors_total ~m:subsystem ~t:"pgsql_pool"
  let pgsql_errors_total = Terrat_metrics.errors_total ~m:subsystem ~t:"pgsql"
  let github_errors_total = Terrat_metrics.errors_total ~m:subsystem ~t:"github"

  let fetch_pull_request_errors_total =
    let help = "Number of errors in fetching a pull request" in
    Prmths.Counter.v ~help ~namespace ~subsystem "fetch_pull_request_errors_total"

  let work_manifest_wait_duration_seconds =
    let help = "Number of seconds a work manifest waited between creation and the initiate call" in
    Work_manifest_run_time_histogram.v_label
      ~label_name:"run_type"
      ~help
      ~namespace
      ~subsystem
      "work_manifest_wait_duration_seconds"

  let work_manifest_run_time_duration_seconds =
    let help = "Number of seconds since a work manifest was created vs when it was completed" in
    Work_manifest_run_time_histogram.v_label
      ~label_name:"run_type"
      ~help
      ~namespace
      ~subsystem
      "work_manifest_run_time_duration_seconds"

  let run_output_chars =
    let help = "Number of chars in run output" in
    let family =
      Run_output_histogram.v_labels
        ~label_names:[ "run_type"; "compact_view" ]
        ~help
        ~namespace
        ~subsystem
        "run_output_chars"
    in
    fun ~r ~c ->
      Run_output_histogram.labels
        family
        [ Terrat_work_manifest.Run_type.to_string r; Bool.to_string c ]

  let run_overall_result_count =
    let help = "Count of the results of overall runs" in
    Prmths.Counter.v_label
      ~label_name:"success"
      ~help
      ~namespace
      ~subsystem
      "run_overall_result_count"

  let pull_request_mergeable_state_count =
    let help = "Counts for the different mergeable states in pull requests fetches" in
    Prmths.Counter.v_label
      ~label_name:"mergeable_state"
      ~help
      ~namespace
      ~subsystem
      "pull_request_mergeable_state_count"
end

let fetch_pull_request_tries = 6

let base64 = function
  | Some s :: rest -> (
      match Base64.decode (CCString.replace ~sub:"\n" ~by:"" s) with
      | Ok s -> Some (s, rest)
      | _ -> None)
  | _ -> None

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map
         (fun s ->
           s
           |> CCString.split_on_char '\n'
           |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
           |> CCString.concat "\n")
         (Terrat_files_sql.read fname))

  let insert_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.uuid
      // (* state *) Ret.text
      // (* created_at *) Ret.text
      /^ read "insert_github_work_manifest.sql"
      /% Var.text "base_sha"
      /% Var.(option (bigint "pull_number"))
      /% Var.bigint "repository"
      /% Var.text "run_type"
      /% Var.text "sha"
      /% Var.text "tag_query")

  let insert_work_manifest_dirspaceflow () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_work_manifest_dirspaceflows (work_manifest, path, workspace, \
          workflow_idx) select * from unnest($work_manifest, $path, $workspace, $workflow_idx)"
      /% Var.(str_array (uuid "work_manifest"))
      /% Var.(str_array (text "path"))
      /% Var.(str_array (text "workspace"))
      /% Var.(array (option (smallint "workflow_idx"))))
end

let insert_work_manifest db repository_id work_manifest pull_number_opt =
  let module Wm = Terrat_work_manifest in
  let module Tc = Terrat_change in
  let module Dsf = Tc.Dirspaceflow in
  let module Ds = Tc.Dirspace in
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch
    db
    (Sql.insert_work_manifest ())
    ~f:(fun id state created_at -> (id, state, created_at))
    work_manifest.Wm.base_hash
    pull_number_opt
    (CCInt64.of_int repository_id)
    (Terrat_work_manifest.Run_type.to_string work_manifest.Wm.run_type)
    work_manifest.Wm.hash
    (Terrat_tag_query.to_string work_manifest.Wm.tag_query)
  >>= function
  | [] -> assert false
  | (id, state, created_at) :: _ ->
      Abbs_future_combinators.List_result.iter
        ~f:(fun changes ->
          Pgsql_io.Prepared_stmt.execute
            db
            (Sql.insert_work_manifest_dirspaceflow ())
            (CCList.replicate (CCList.length changes) id)
            (CCList.map (fun { Dsf.dirspace = { Ds.dir; _ }; _ } -> dir) changes)
            (CCList.map (fun { Dsf.dirspace = { Ds.workspace; _ }; _ } -> workspace) changes)
            (CCList.map
               (fun { Dsf.workflow; _ } ->
                 CCOption.map (fun Dsf.Workflow.{ idx; _ } -> idx) workflow)
               changes))
        (CCList.chunks 500 work_manifest.Wm.changes)
      >>= fun () -> Abb.Future.return (Ok (id, state, created_at))

module Dr = struct
  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map
           (fun s ->
             s
             |> CCString.split_on_char '\n'
             |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
             |> CCString.concat "\n")
           (Terrat_files_sql.read fname))

    let select_missing_drift_scheduled_runs () =
      Pgsql_io.Typed_sql.(
        sql
        // (* installation_id *) Ret.bigint
        // (* repository *) Ret.bigint
        // (* owner *) Ret.text
        // (* name *) Ret.text
        // (* reconcile *) Ret.boolean
        /^ read "github_select_missing_drift_scheduled_runs.sql")

    let insert_drift_work_manifest () =
      Pgsql_io.Typed_sql.(
        sql
        /^ "insert into github_drift_work_manifests (work_manifest, branch) values($work_manifest, \
            $branch)"
        /% Var.uuid "work_manifest"
        /% Var.text "branch")
  end

  module Schedule = struct
    type t = {
      installation_id : int64;
      repository : int64;
      owner : string;
      name : string;
      reconcile : bool;
    }
    [@@deriving show]

    let make installation_id repository owner name reconcile =
      { installation_id; repository; owner; name; reconcile }

    let id t = CCInt64.to_string t.repository
    let owner t = t.owner
    let name t = t.name
    let reconcile t = t.reconcile
  end

  module Repo = struct
    type t = {
      repo_config : Terrat_repo_config.Version_1.t;
      tree : string list;
      branch : Githubc2_components.Branch_with_protection.t;
    }

    let repo_config t = t.repo_config
    let tree t = t.tree
  end

  let query_missing_scheduled_runs config db =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch db (Sql.select_missing_drift_scheduled_runs ()) ~f:Schedule.make
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : DRIFT : %a" Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let fetch_repo_config config access_token owner repo branch =
    Terrat_github.fetch_repo_config
      ~config
      ~python:(Terrat_config.python_exec config)
      ~access_token
      ~owner
      ~repo
      branch

  let fetch_tree config access_token owner repo branch =
    Terrat_github.get_tree ~config ~access_token ~owner ~repo ~sha:branch ()

  let fetch_branch config access_token owner repo branch =
    Terrat_github.fetch_branch ~config ~access_token ~owner ~repo branch

  let fetch_repo config schedule =
    let run =
      let module S = Schedule in
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.get_installation_access_token config (CCInt64.to_int schedule.S.installation_id)
      >>= fun access_token ->
      Terrat_github.fetch_repo ~config ~access_token ~owner:schedule.S.owner ~repo:schedule.S.name
      >>= fun repo ->
      let module R = Githubc2_components.Full_repository in
      let default_branch = repo.R.primary.R.Primary.default_branch in
      Abbs_future_combinators.Infix_result_app.(
        (fun repo_config tree branch -> (repo_config, tree, branch))
        <$> fetch_repo_config config access_token schedule.S.owner schedule.S.name default_branch
        <*> fetch_tree config access_token schedule.S.owner schedule.S.name default_branch
        <*> fetch_branch config access_token schedule.S.owner schedule.S.name default_branch)
      >>= fun (repo_config, tree, branch) ->
      Abb.Future.return (Ok { Repo.repo_config; tree; branch })
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : DRIFT : %a" Terrat_github.pp_get_installation_access_token_err err);
        Abb.Future.return (Error `Error)
    | Error (#Terrat_github.fetch_repo_err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : DRIFT : %a" Terrat_github.pp_fetch_repo_err err);
        Abb.Future.return (Error `Error)
    | Error (#Terrat_github.fetch_repo_config_err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : DRIFT : %a" Terrat_github.pp_fetch_repo_config_err err);
        Abb.Future.return (Error `Error)

  let store_work_manifest config db schedule repo dirspaceflows run_type =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      let module S = Schedule in
      let module R = Repo in
      let module B = Githubc2_components.Branch_with_protection in
      let module C = Githubc2_components.Commit in
      let branch = repo.R.branch in
      let branch_name = branch.B.primary.B.Primary.name in
      let commit = branch.B.primary.B.Primary.commit in
      let hash = commit.C.primary.C.Primary.sha in
      let work_manifest =
        {
          Terrat_work_manifest.base_hash = hash;
          changes = dirspaceflows;
          completed_at = None;
          created_at = ();
          hash;
          id = ();
          src = ();
          run_id = ();
          run_type;
          state = ();
          tag_query = Terrat_tag_query.any;
        }
      in
      insert_work_manifest db (CCInt64.to_int schedule.S.repository) work_manifest None
      >>= fun (id, _, _) ->
      Logs.info (fun m -> m "GITHUB_EVALUATOR : DRIFT : STORE_WORK_MANIFEST : %a" Uuidm.pp id);
      Pgsql_io.Prepared_stmt.execute db (Sql.insert_drift_work_manifest ()) id branch_name
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : DRIFT : %a" Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let store_plan_work_manifest config db schedule repo dirspaceflows =
    store_work_manifest config db schedule repo dirspaceflows Terrat_work_manifest.Run_type.Plan

  let store_reconcile_work_manifest config db schedule repo dirspaceflows =
    store_work_manifest config db schedule repo dirspaceflows Terrat_work_manifest.Run_type.Apply
end

module R = struct
  module Int64_map = CCMap.Make (CCInt64)

  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map
           (fun s ->
             s
             |> CCString.split_on_char '\n'
             |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
             |> CCString.concat "\n")
           (Terrat_files_sql.read fname))

    let select_next_work_manifest =
      Pgsql_io.Typed_sql.(sql // (* id *) Ret.uuid /^ read "select_next_github_work_manifest.sql")

    let select_action_parameters =
      Pgsql_io.Typed_sql.(
        sql
        // (* installation_id *) Ret.bigint
        // (* repository owner *) Ret.text
        // (* repository name *) Ret.text
        // (* branch *) Ret.text
        // (* sha *) Ret.text
        // (* pull_number *) Ret.(option bigint)
        // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
        /^ read "select_github_action_parameters.sql"
        /% Var.uuid "work_manifest")

    let abort_work_manifest =
      Pgsql_io.Typed_sql.(
        sql
        /^ "update github_work_manifests set state = 'aborted', completed_at = now() where id = \
            $id and state in ('queued', 'running')"
        /% Var.uuid "id")

    let select_work_manifest_dirspaces =
      Pgsql_io.Typed_sql.(
        sql
        // (* dir *) Ret.text
        // (* workspace *) Ret.text
        /^ "select path, workspace from github_work_manifest_dirspaceflows where work_manifest = \
            $id"
        /% Var.uuid "id")
  end

  module Tmpl = struct
    let read fname = CCOption.get_exn_or fname (Terrat_files_tmpl.read fname)
    let failed_to_start_workflow = read "github_failed_to_start_workflow.tmpl"
    let failed_to_find_workflow = read "github_failed_to_find_workflow.tmpl"
  end

  type err =
    [ Pgsql_pool.err
    | Pgsql_io.err
    | Terrat_github.get_installation_access_token_err
    ]
  [@@deriving show]

  let load_access_token access_token_cache config installation_id =
    match Int64_map.get installation_id access_token_cache with
    | Some token -> Abb.Future.return (Ok (token, access_token_cache))
    | None ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_github.get_installation_access_token config (CCInt64.to_int installation_id)
        >>= fun token ->
        Abb.Future.return (Ok (token, Int64_map.add installation_id token access_token_cache))

  let start_commit_statuses ~access_token ~owner ~repo ~sha ~run_type ~dirspaces () =
    let unified_run_type =
      Terrat_work_manifest.(run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
    in
    let target_url = Printf.sprintf "https://github.com/%s/%s/actions" owner repo in
    let commit_statuses =
      let aggregate =
        Terrat_commit_check.
          [
            make
              ~details_url:target_url
              ~description:"Running"
              ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
              ~status:Status.Queued;
            make
              ~details_url:target_url
              ~description:"Running"
              ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
              ~status:Status.Queued;
          ]
      in
      let dirspaces =
        CCList.map
          (fun Terrat_change.Dirspace.{ dir; workspace } ->
            Terrat_commit_check.(
              make
                ~details_url:target_url
                ~description:"Running"
                ~title:(Printf.sprintf "terrateam %s: %s %s" unified_run_type dir workspace)
                ~status:Status.Queued))
          dirspaces
      in
      aggregate @ dirspaces
    in
    Terrat_github_commit_check.create ~access_token ~owner ~repo ~ref_:sha commit_statuses

  let abort_work_manifest
      ~config
      ~access_token
      ~db
      ~owner
      ~repo
      ~sha
      ~pull_number
      ~run_type
      ~dirspaces
      ~tmpl
      work_manifest_id =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_io.Prepared_stmt.execute db Sql.abort_work_manifest work_manifest_id
    >>= fun () ->
    match pull_number with
    | Some pull_number ->
        Terrat_github.publish_comment
          ~config
          ~access_token
          ~owner
          ~repo
          ~pull_number:(CCInt64.to_int pull_number)
          tmpl
        >>= fun () ->
        let unified_run_type =
          Terrat_work_manifest.(
            run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
        in
        let target_url = Printf.sprintf "https://github.com/%s/%s/actions" owner repo in
        let commit_statuses =
          let aggregate =
            Terrat_commit_check.
              [
                make
                  ~details_url:target_url
                  ~description:"Failed"
                  ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
                  ~status:Status.Failed;
                make
                  ~details_url:target_url
                  ~description:"Failed"
                  ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
                  ~status:Status.Failed;
              ]
          in
          let dirspaces =
            CCList.map
              (fun Terrat_change.Dirspace.{ dir; workspace } ->
                Terrat_commit_check.(
                  make
                    ~details_url:target_url
                    ~description:"Failed"
                    ~title:(Printf.sprintf "terrateam %s: %s %s" unified_run_type dir workspace)
                    ~status:Status.Failed))
              dirspaces
          in
          aggregate @ dirspaces
        in
        Terrat_github_commit_check.create
          ~config
          ~access_token
          ~owner
          ~repo
          ~ref_:sha
          commit_statuses
    | None -> Abb.Future.return (Ok ())

  let run_workflow ~config ~access_token ~work_token ~owner ~repo ~branch ~workflow_id () =
    let client = Terrat_github.create config (`Token access_token) in
    Terrat_github.call
      client
      Githubc2_actions.Create_workflow_dispatch.(
        make
          ~body:
            Request_body.
              {
                primary =
                  Primary.
                    {
                      ref_ = branch;
                      inputs =
                        Some
                          Inputs.
                            {
                              primary = Json_schema.Empty_obj.t;
                              additional =
                                Json_schema.String_map.of_list
                                  [
                                    ("work-token", Uuidm.to_string work_token);
                                    ("api-base-url", Terrat_config.api_base config ^ "/github");
                                  ];
                            };
                    };
                additional = Json_schema.String_map.empty;
              }
          Parameters.(make ~owner ~repo ~workflow_id:(Workflow_id.V0 workflow_id)))

  let rec run' request_id access_token_cache config db =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_io.Prepared_stmt.fetch db ~f:CCFun.id Sql.select_next_work_manifest
    >>= function
    | [] -> Abb.Future.return (Ok ())
    | [ id ] -> (
        Logs.info (fun m ->
            m "GITHUB_EVALUATOR : %s : RUNNING : %s" request_id (Uuidm.to_string id));
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_work_manifest_dirspaces
          ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
          id
        >>= fun dirspaces ->
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_action_parameters
          ~f:(fun installation_id owner repo branch sha pull_number run_type ->
            (installation_id, owner, repo, branch, sha, pull_number, run_type))
          id
        >>= function
        | [] -> assert false
        | (installation_id, owner, repo, branch, sha, pull_number, run_type) :: _ -> (
            load_access_token access_token_cache config installation_id
            >>= fun (access_token, access_token_cache) ->
            Terrat_github.load_workflow ~config ~access_token ~owner ~repo
            >>= function
            | Some workflow_id -> (
                (if CCOption.is_some pull_number then
                   Abbs_time_it.run
                     (fun t ->
                       Logs.info (fun m ->
                           m "GITHUB_EVALUATOR : %s : START_COMMIT_STATUSES : %f" request_id t))
                     (fun () ->
                       start_commit_statuses
                         ~config
                         ~access_token
                         ~owner
                         ~repo
                         ~sha
                         ~run_type
                         ~dirspaces
                         ())
                 else Abb.Future.return (Ok ()))
                >>= fun () ->
                let open Abb.Future.Infix_monad in
                Abbs_time_it.run
                  (fun t ->
                    Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : RUN_WORKFLOW : %f" request_id t))
                  (fun () ->
                    run_workflow
                      ~config
                      ~access_token
                      ~work_token:id
                      ~owner
                      ~repo
                      ~branch
                      ~workflow_id
                      ())
                >>= function
                | Ok _ ->
                    (* TODO: Handle failing because workflow is not present in branch *)
                    Terrat_telemetry.send
                      (Terrat_config.telemetry config)
                      (Terrat_telemetry.Event.Run
                         {
                           github_app_id = Terrat_config.github_app_id config;
                           run_type;
                           owner;
                           repo;
                         })
                    >>= fun () -> run' request_id access_token_cache config db
                | Error (#Githubc2_abb.call_err as err) ->
                    Logs.err (fun m ->
                        m
                          "GITHUB_EVALUATOR : %s : ERROR : COULD_NOT_RUN_WORKFLOW : %s : %s : %s : \
                           %s"
                          request_id
                          owner
                          repo
                          branch
                          (Githubc2_abb.show_call_err err));
                    abort_work_manifest
                      ~config
                      ~access_token
                      ~db
                      ~owner
                      ~repo
                      ~sha
                      ~pull_number
                      ~run_type
                      ~dirspaces
                      ~tmpl:Tmpl.failed_to_start_workflow
                      id
                    >>= fun _ -> run' request_id access_token_cache config db)
            | None ->
                let open Abb.Future.Infix_monad in
                Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : MISSING_WORKFLOW" request_id);
                abort_work_manifest
                  ~config
                  ~access_token
                  ~db
                  ~owner
                  ~repo
                  ~sha
                  ~pull_number
                  ~run_type
                  ~dirspaces
                  ~tmpl:Tmpl.failed_to_find_workflow
                  id
                >>= fun _ -> run' request_id access_token_cache config db))
    | _ :: _ ->
        (* Should only ever be one result *)
        assert false

  let run ~request_id config storage =
    let open Abb.Future.Infix_monad in
    Pgsql_pool.with_conn storage ~f:(fun db -> run' request_id Int64_map.empty config db)
    >>= function
    | Ok () -> Abb.Future.return ()
    | Error (#err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : ERROR : %s" (show_err err));
        Abb.Future.return ()
end

module Ev = struct
  module String_set = CCSet.Make (CCString)

  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map
           (fun s ->
             s
             |> CCString.split_on_char '\n'
             |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
             |> CCString.concat "\n")
           (Terrat_files_sql.read fname))

    let insert_pull_request =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "insert_github_pull_request.sql"
        /% Var.text "base_branch"
        /% Var.text "base_sha"
        /% Var.text "branch"
        /% Var.bigint "pull_number"
        /% Var.bigint "repository"
        /% Var.text "sha"
        /% Var.(option (text "merged_sha"))
        /% Var.(option (timestamptz "merged_at"))
        /% Var.text "state")

    let insert_dirspace =
      Pgsql_io.Typed_sql.(
        sql
        /^ "insert into github_dirspaces (base_sha, path, repository, sha, workspace, lock_policy) \
            select * from unnest($base_sha, $path, $repository, $sha, $workspace, $lock_policy) on \
            conflict (repository, sha, path, workspace) do nothing"
        /% Var.(str_array (text "base_sha"))
        /% Var.(str_array (text "path"))
        /% Var.(array (bigint "repository"))
        /% Var.(str_array (text "sha"))
        /% Var.(str_array (text "workspace"))
        /% Var.(str_array (text "lock_policy")))

    let select_out_of_diff_applies =
      Pgsql_io.Typed_sql.(
        sql
        // (* path *) Ret.text
        // (* workspace *) Ret.text
        /^ read "select_github_out_of_diff_applies.sql"
        /% Var.bigint "repository"
        /% Var.bigint "pull_number")

    let select_conflicting_work_manifests_in_repo () =
      Pgsql_io.Typed_sql.(
        sql
        // (* base_hash *) Ret.text
        // (* created_at *) Ret.text
        // (* hash *) Ret.text
        // (* id *) Ret.uuid
        // (* run_id *) Ret.(option text)
        // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
        // (* tag_query *) Ret.ud' CCFun.(Terrat_tag_query.of_string %> CCOption.of_result)
        // (* base_branch *) Ret.(option text)
        // (* branch *) Ret.(option text)
        // (* pull_number *) Ret.(option bigint)
        // (* pr state *) Ret.(option text)
        // (* merged_hash *) Ret.(option text)
        // (* merged_at *) Ret.(option text)
        // (* state *) Ret.(ud' Terrat_work_manifest.State.of_string)
        // (* run_kind *) Ret.text
        /^ read "select_github_conflicting_work_manifests_in_repo.sql"
        /% Var.bigint "repository"
        /% Var.bigint "pull_number"
        /% Var.(ud (text "run_type") Terrat_work_manifest.Run_type.to_string))

    let select_dirspaces_owned_by_other_pull_requests =
      Pgsql_io.Typed_sql.(
        sql
        // (* dir *) Ret.text
        // (* workspace *) Ret.text
        // (* base_branch *) Ret.text
        // (* branch *) Ret.text
        // (* base_hash *) Ret.text
        // (* hash *) Ret.text
        // (* merged_hash *) Ret.(option text)
        // (* merged_at *) Ret.(option text)
        // (* pull_number *) Ret.bigint
        // (* state *) Ret.text
        /^ read "select_github_dirspaces_owned_by_other_pull_requests.sql"
        /% Var.bigint "repository"
        /% Var.bigint "pull_number"
        /% Var.(str_array (text "dirs"))
        /% Var.(str_array (text "workspaces")))

    let select_dirspaces_without_valid_plans =
      Pgsql_io.Typed_sql.(
        sql
        // (* dir *) Ret.text
        // (* workspace *) Ret.text
        /^ read "select_github_dirspaces_without_valid_plans.sql"
        /% Var.bigint "repository"
        /% Var.bigint "pull_number"
        /% Var.(str_array (text "dirs"))
        /% Var.(str_array (text "workspaces")))

    let insert_pull_request_unlock () =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "insert_github_pull_request_unlock.sql"
        /% Var.bigint "repository"
        /% Var.bigint "pull_number")

    let insert_drift_unlock () =
      Pgsql_io.Typed_sql.(sql /^ read "insert_github_drift_unlock.sql" /% Var.bigint "repository")

    let select_missing_dirspace_applies_for_pull_request =
      Pgsql_io.Typed_sql.(
        sql
        // (* path *) Ret.text
        // (* workspace *) Ret.text
        /^ read "select_github_missing_dirspace_applies_for_pull_request.sql"
        /% Var.text "owner"
        /% Var.text "name"
        /% Var.bigint "pull_number")

    let insert_work_manifest_access_control_denied_dirspace =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "insert_github_work_manifest_access_control_denied_dirspace.sql"
        /% Var.(str_array (text "path"))
        /% Var.(str_array (text "workspace"))
        /% Var.(str_array (option (json "policy")))
        /% Var.(str_array (uuid "work_manifest")))

    let select_installation_account_status =
      Pgsql_io.Typed_sql.(
        sql
        // (* account_status *) Ret.text
        /^ "select account_status from github_installations where id = $installation_id"
        /% Var.bigint "installation_id")
  end

  module Tmpl = struct
    let read fname =
      fname
      |> Terrat_files_tmpl.read
      |> CCOption.get_exn_or fname
      |> Snabela.Template.of_utf8_string
      |> CCResult.get_exn
      |> fun tmpl -> Snabela.of_template tmpl []

    let missing_plans = read "github_missing_plans.tmpl"

    let dirspaces_owned_by_other_pull_requests =
      read "github_dirspaces_owned_by_other_pull_requests.tmpl"

    let conflicting_work_manifests = read "github_conflicting_work_manifests.tmpl"
    let repo_config_parse_failure = read "github_repo_config_parse_failure.tmpl"
    let repo_config_generic_failure = read "github_repo_config_generic_failure.tmpl"
    let pull_request_not_appliable = read "github_pull_request_not_appliable.tmpl"
    let pull_request_not_mergeable = read "github_pull_request_not_mergeable.tmpl"
    let apply_no_matching_dirspaces = read "apply_no_matching_dirspaces.tmpl"
    let plan_no_matching_dirspaces = read "plan_no_matching_dirspaces.tmpl"
    let base_branch_not_default_branch = read "dest_branch_no_match.tmpl"
    let auto_apply_running = read "auto_apply_running.tmpl"
    let bad_glob = read "bad_glob.tmpl"
    let unlock_success = read "unlock_success.tmpl"
    let access_control_all_dirspaces_denied = read "access_control_all_dirspaces_denied.tmpl"
    let access_control_invalid_query = read "access_control_invalid_query.tmpl"
    let access_control_dirspaces_denied = read "access_control_dirspaces_denied.tmpl"
    let access_control_unlock_denied = read "access_control_unlock_denied.tmpl"

    let access_control_terrateam_config_update_denied =
      read "access_control_terrateam_config_update_denied.tmpl"

    let access_control_terrateam_config_update_bad_query =
      read "access_control_terrateam_config_update_bad_query.tmpl"

    let access_control_lookup_err = read "access_control_lookup_err.tmpl"
    let tag_query_error = read "tag_query_error.tmpl"
    let account_expired_err = read "account_expired_err.tmpl"
    let unexpected_temporary_err = read "unexpected_temporary_err.tmpl"
  end

  module Apply_requirements = struct
    type t = {
      approved : bool option;
      merge_conflicts : bool option;
      status_checks : bool option;
      status_checks_failed : Terrat_commit_check.t list;
      approved_reviews : Terrat_pull_request_review.t list;
      passed : bool;
    }

    let passed { passed; _ } = passed
    let approved_reviews { approved_reviews; _ } = approved_reviews
  end

  module T = struct
    type t = {
      access_token : string;
      config : Terrat_config.t;
      installation_id : int;
      pull_number : int;
      repository : Gw.Repository.t;
      request_id : string;
      event_type : Terrat_evaluator.Event.Event_type.t;
      tag_query : Terrat_tag_query.t;
      user : string;
    }

    let make
        ~access_token
        ~config
        ~installation_id
        ~pull_number
        ~repository
        ~request_id
        ~event_type
        ~tag_query
        ~user =
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : MAKE : %s : %s : pull_number=%d : event_type=%s : \
             installation_id=%d : tag_query=%s"
            request_id
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            pull_number
            (Terrat_evaluator.Event.Event_type.to_string event_type)
            installation_id
            (Terrat_tag_query.to_string tag_query));
      {
        access_token;
        config;
        installation_id;
        pull_number;
        repository;
        request_id;
        event_type;
        tag_query;
        user;
      }

    let request_id t = t.request_id
    let tag_query t = t.tag_query
    let event_type t = t.event_type
    let default_branch t = t.repository.Gw.Repository.default_branch
    let user t = t.user
  end

  let log_time ?m event name t =
    Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : %s : %f" (T.request_id event) name t);
    match m with
    | Some m -> Metrics.DefaultHistogram.observe m t
    | None -> ()

  let diff_of_github_diff =
    CCList.map
      Githubc2_components.Diff_entry.(
        function
        | { primary = { Primary.filename; status = "added" | "copied"; _ }; _ } ->
            Terrat_change.Diff.Add { filename }
        | { primary = { Primary.filename; status = "removed"; _ }; _ } ->
            Terrat_change.Diff.Remove { filename }
        | { primary = { Primary.filename; status = "modified" | "changed" | "unchanged"; _ }; _ } ->
            Terrat_change.Diff.Change { filename }
        | {
            primary =
              {
                Primary.filename;
                status = "renamed";
                previous_filename = Some previous_filename;
                _;
              };
            _;
          } -> Terrat_change.Diff.Move { filename; previous_filename }
        | _ -> failwith "nyi1")

  let fetch_diff ~config ~request_id ~access_token ~owner ~repo ~base_sha head_sha =
    let open Abbs_future_combinators.Infix_result_monad in
    Terrat_github.compare_commits ~config ~access_token ~owner ~repo (base_sha, head_sha)
    >>= fun files ->
    let diff = diff_of_github_diff files in
    Abb.Future.return (Ok diff)

  module Pull_request = struct
    type t = (int64, Terrat_change.Diff.t list, bool) Terrat_pull_request.t

    let base_branch_name t = t.Terrat_pull_request.base_branch_name
    let base_hash t = t.Terrat_pull_request.base_hash
    let hash t = t.Terrat_pull_request.hash
    let diff t = t.Terrat_pull_request.diff
    let state t = t.Terrat_pull_request.state
    let passed_all_checks t = t.Terrat_pull_request.checks
    let mergeable t = t.Terrat_pull_request.mergeable
    let is_draft_pr t = t.Terrat_pull_request.draft
    let branch_name t = t.Terrat_pull_request.branch_name

    let change_hash t =
      CCOption.get_or
        ~default:t.Terrat_pull_request.hash
        t.Terrat_pull_request.provisional_merge_sha
  end

  module Src = struct
    type t =
      | Pull_request of Pull_request.t
      | Drift
  end

  module Access_control = struct
    type ctx = {
      user : string;
      event : T.t;
    }

    (* Order matters here.  Roles closer to the beginning of the search are more
       powerful than those closer to the end *)
    let repo_permission_levels =
      [
        ("admin", "admin");
        ("maintain", "maintain");
        ("write", "write");
        ("triage", "triage");
        ("read", "read");
      ]

    let query ctx query =
      match CCString.Split.left ~by:":" query with
      | Some ("user", value) -> Abb.Future.return (Ok (CCString.equal value ctx.user))
      | Some ("team", value) -> (
          let open Abb.Future.Infix_monad in
          Terrat_github.get_team_membership_in_org
            ~config:ctx.event.T.config
            ~access_token:ctx.event.T.access_token
            ~org:ctx.event.T.repository.Gw.Repository.owner.Gw.User.login
            ~team:value
            ~user:ctx.user
            ()
          >>= function
          | Ok res -> Abb.Future.return (Ok res)
          | Error _ -> Abb.Future.return (Error `Error))
      | Some ("repo", value) -> (
          let open Abb.Future.Infix_monad in
          match CCList.find_idx CCFun.(fst %> CCString.equal value) repo_permission_levels with
          | Some (idx, _) -> (
              Terrat_github.get_repo_collaborator_permission
                ~config:ctx.event.T.config
                ~access_token:ctx.event.T.access_token
                ~org:ctx.event.T.repository.Gw.Repository.owner.Gw.User.login
                ~repo:ctx.event.T.repository.Gw.Repository.name
                ~user:ctx.user
                ()
              >>= function
              | Ok (Some role) -> (
                  match
                    CCList.find_idx CCFun.(snd %> CCString.equal role) repo_permission_levels
                  with
                  | Some (idx_role, _) ->
                      (* Test if their actual role has an index less than or
                         equal to the index of the role in the query. *)
                      Abb.Future.return (Ok (idx_role <= idx))
                  | None -> Abb.Future.return (Ok false))
              | Ok None -> Abb.Future.return (Ok false)
              | Error _ -> Abb.Future.return (Error `Error))
          | None -> Abb.Future.return (Error (`Invalid_query query)))
      | Some (_, _) -> Abb.Future.return (Error (`Invalid_query query))
      | None -> Abb.Future.return (Error (`Invalid_query query))
  end

  let create_access_control_ctx ~user event = Access_control.{ user; event }

  let query_account_status storage event =
    let open Abb.Future.Infix_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_installation_account_status
          ~f:CCFun.id
          (CCInt64.of_int event.T.installation_id))
    >>= function
    | Ok ("expired" :: _) -> Abb.Future.return (Ok `Expired)
    | Ok _ -> Abb.Future.return (Ok `Active)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)
    | Error (#Pgsql_pool.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_pool.show_err err));
        Abb.Future.return (Error `Error)

  let store_dirspaceflows db event pull_request dirspaceflows =
    let id = CCInt64.of_int event.T.repository.Gw.Repository.id in
    let run =
      Abbs_future_combinators.List_result.iter
        ~f:(fun dirspaceflows ->
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.insert_dirspace
            (CCList.replicate (CCList.length dirspaceflows) (Pull_request.base_hash pull_request))
            (CCList.map
               (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; _ }; _ } -> dir)
               dirspaceflows)
            (CCList.replicate (CCList.length dirspaceflows) id)
            (CCList.replicate (CCList.length dirspaceflows) (Pull_request.hash pull_request))
            (CCList.map
               (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.workspace; _ }; _ } ->
                 workspace)
               dirspaceflows)
            (CCList.map
               (fun Terrat_change.{ Dirspaceflow.workflow; _ } ->
                 let module Dfwf = Terrat_change.Dirspaceflow.Workflow in
                 let module Wf = Terrat_repo_config_workflow_entry in
                 CCOption.map_or
                   ~default:"strict"
                   (fun { Dfwf.workflow = { Wf.lock_policy; _ }; _ } -> lock_policy)
                   workflow)
               dirspaceflows))
        (CCList.chunks 500 dirspaceflows)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let store_pull_request db event pull_request =
    let open Abb.Future.Infix_monad in
    let module Pr = Terrat_pull_request in
    let merged_sha, merged_at, state =
      match pull_request.Pr.state with
      | Pr.State.Open _ -> (None, None, "open")
      | Pr.State.Closed -> (None, None, "closed")
      | Pr.State.(Merged { Merged.merged_hash; merged_at }) ->
          (Some merged_hash, Some merged_at, "merged")
    in
    Pgsql_io.Prepared_stmt.execute
      db
      Sql.insert_pull_request
      pull_request.Pr.base_branch_name
      pull_request.Pr.base_hash
      pull_request.Pr.branch_name
      pull_request.Pr.id
      (CCInt64.of_int event.T.repository.Gw.Repository.id)
      pull_request.Pr.hash
      merged_sha
      merged_at
      state
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let fetch_pull_request' event =
    let owner = event.T.repository.Gw.Repository.owner.Gw.User.login in
    let repo = event.T.repository.Gw.Repository.name in
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.fetch_pull_request
        ~config:event.T.config
        ~access_token:event.T.access_token
        ~owner
        ~repo
        event.T.pull_number
      >>= fun resp ->
      let module Ghc_comp = Githubc2_components in
      let module Pr = Ghc_comp.Pull_request in
      let module Head = Pr.Primary.Head in
      let module Base = Pr.Primary.Base in
      match Openapi.Response.value resp with
      | `OK
          {
            Ghc_comp.Pull_request.primary =
              {
                Ghc_comp.Pull_request.Primary.head;
                base;
                state;
                merged;
                merged_at;
                merge_commit_sha;
                mergeable_state;
                mergeable;
                draft;
                _;
              };
            _;
          } ->
          let base_branch_name = Base.(base.primary.Primary.ref_) in
          let base_sha = Base.(base.primary.Primary.sha) in
          let head_sha = Head.(head.primary.Primary.sha) in
          let branch_name = Head.(head.primary.Primary.ref_) in
          let draft = CCOption.get_or ~default:false draft in
          Prmths.Counter.inc_one (Metrics.pull_request_mergeable_state_count mergeable_state);
          fetch_diff
            ~config:event.T.config
            ~request_id:event.T.request_id
            ~access_token:event.T.access_token
            ~owner
            ~repo
            ~base_sha
            (CCOption.get_or ~default:head_sha merge_commit_sha)
          >>= fun diff ->
          Logs.debug (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGEABLE : merged=%s : mergeable_state=%s : \
                 merge_commit_sha=%s"
                event.T.request_id
                (Bool.to_string merged)
                mergeable_state
                (CCOption.get_or ~default:"" merge_commit_sha));
          Abb.Future.return
            (Ok
               ( mergeable_state,
                 Terrat_pull_request.
                   {
                     base_branch_name;
                     base_hash = base_sha;
                     branch_name;
                     diff;
                     hash = head_sha;
                     id = CCInt64.of_int event.T.pull_number;
                     state =
                       (match (merge_commit_sha, state, merged, merged_at) with
                       | Some _, "open", _, _ -> State.(Open Open_status.Mergeable)
                       | None, "open", _, _ -> State.(Open Open_status.Merge_conflict)
                       | Some merge_commit_sha, "closed", true, Some merged_at ->
                           State.(Merged Merged.{ merged_hash = merge_commit_sha; merged_at })
                       | _, "closed", false, _ -> State.Closed
                       | _, _, _, _ -> assert false);
                     checks =
                       merged
                       || CCList.mem
                            ~eq:CCString.equal
                            mergeable_state
                            [ "clean"; "unstable"; "has_hooks" ];
                     mergeable;
                     provisional_merge_sha = merge_commit_sha;
                     draft;
                   } ))
      | (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _) as err ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ERROR : %a"
                event.T.request_id
                Githubc2_pulls.Get.Responses.pp
                err);
          Abb.Future.return (Error err)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _) as
      err -> Abb.Future.return err
    | Error `Error ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s : %s : ERROR" (T.request_id event) owner repo);
        Abb.Future.return (Error `Error)
    | Error (#Terrat_github.compare_commits_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : %s : %s : %a"
              (T.request_id event)
              owner
              repo
              Terrat_github.pp_compare_commits_err
              err);
        Abb.Future.return (Error `Error)
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : %s : %s : %s"
              (T.request_id event)
              owner
              repo
              (Terrat_github.show_get_installation_access_token_err err));
        Abb.Future.return (Error `Error)

  let fetch_pull_request event =
    (* We require a merge commit to continue, but GitHub may not be able to
       create it in time between us getting the event and querying.  So retry a
       few times. *)
    let open Abb.Future.Infix_monad in
    Abbs_future_combinators.retry
      ~f:(fun () -> fetch_pull_request' event)
      ~while_:
        (Abbs_future_combinators.finite_tries fetch_pull_request_tries (function
            | Error _ | Ok ("unknown", Terrat_pull_request.{ state = State.Open _; _ }) -> true
            | Ok _ -> false))
      ~betwixt:
        (Abbs_future_combinators.series ~start:2.0 ~step:(( *. ) 1.5) (fun n _ ->
             Prmths.Counter.inc_one Metrics.fetch_pull_request_errors_total;
             Abb.Sys.sleep (CCFloat.min n 8.0)))
    >>= function
    | Ok (_, ret) -> Abb.Future.return (Ok ret)
    | Error (`Not_found _)
    | Error (`Internal_server_error _)
    | Error `Not_modified
    | Error (`Service_unavailable _)
    | Error `Error -> Abb.Future.return (Error `Error)

  let query_pull_request_out_of_diff_applies db event pull_request =
    let run =
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_out_of_diff_applies
        ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
        (CCInt64.of_int event.T.repository.Gw.Repository.id)
        pull_request.Terrat_pull_request.id
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let fetch_tree event pull_request =
    let open Abb.Future.Infix_monad in
    let owner = event.T.repository.Gw.Repository.owner.Gw.User.login in
    let repo = event.T.repository.Gw.Repository.name in
    Terrat_github.get_tree
      ~config:event.T.config
      ~access_token:event.T.access_token
      ~owner
      ~repo
      ~sha:(Pull_request.change_hash pull_request)
      ()
    >>= function
    | Ok files -> Abb.Future.return (Ok files)
    | Error (#Terrat_github.get_tree_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : %s"
              (T.request_id event)
              (Terrat_github.show_get_tree_err err));
        Abb.Future.return (Error `Error)

  let fetch_commit_checks event pull_request =
    let open Abb.Future.Infix_monad in
    let owner = event.T.repository.Gw.Repository.owner.Gw.User.login in
    let repo = event.T.repository.Gw.Repository.name in
    Abbs_time_it.run
      (fun t ->
        Logs.info (fun m ->
            m "GITHUB_EVALUATOR : %s : LIST_COMMIT_CHECKS : %f" (T.request_id event) t))
      (fun () ->
        Terrat_github_commit_check.list
          ~config:event.T.config
          ~log_id:(T.request_id event)
          ~access_token:event.T.access_token
          ~owner
          ~repo
          ~ref_:pull_request.Terrat_pull_request.hash
          ())
    >>= function
    | Ok _ as res -> Abb.Future.return res
    | Error (#Terrat_github_commit_check.list_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : FETCH_COMMIT_CHECKS : %s"
              (T.request_id event)
              (Terrat_github_commit_check.show_list_err err));
        Abb.Future.return (Error `Error)

  let fetch_pull_request_reviews event pull_request =
    let open Abb.Future.Infix_monad in
    let owner = event.T.repository.Gw.Repository.owner.Gw.User.login in
    let repo = event.T.repository.Gw.Repository.name in
    let pull_number = CCInt64.to_int pull_request.Terrat_pull_request.id in
    Terrat_github.Pull_request_reviews.list
      ~config:event.T.config
      ~access_token:event.T.access_token
      ~owner
      ~repo
      ~pull_number
      ()
    >>= function
    | Ok reviews ->
        let module Prr = Githubc2_components.Pull_request_review in
        Abb.Future.return
          (Ok
             (CCList.map
                (fun Prr.{ primary = Primary.{ node_id; state; user; _ }; _ } ->
                  Terrat_pull_request_review.
                    {
                      id = node_id;
                      status =
                        (match state with
                        | "APPROVED" -> Status.Approved
                        | _ -> Status.Unknown);
                      user =
                        CCOption.map
                          (fun Githubc2_components.Nullable_simple_user.
                                 { primary = Primary.{ login; _ }; _ } -> login)
                          user;
                    })
                reviews))
    | Error (#Terrat_github.Pull_request_reviews.list_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : %s"
              (T.request_id event)
              (Terrat_github.Pull_request_reviews.show_list_err err));
        Abb.Future.return (Error `Error)

  let query_conflicting_work_manifests_in_repo db event operation =
    let run =
      Pgsql_io.Prepared_stmt.fetch
        db
        (Sql.select_conflicting_work_manifests_in_repo ())
        ~f:(fun base_hash
                created_at
                hash
                id
                run_id
                run_type
                tag_query
                base_branch
                branch
                pull_number
                pr_state
                merged_hash
                merged_at
                state
                run_kind ->
          let src =
            match (pull_number, base_branch, branch, pr_state) with
            | Some pull_number, Some base_branch, Some branch, Some pr_state ->
                let pull_request =
                  Terrat_pull_request.
                    {
                      base_branch_name = base_branch;
                      base_hash;
                      branch_name = branch;
                      diff = [];
                      hash;
                      id = pull_number;
                      state =
                        (match (pr_state, merged_hash, merged_at) with
                        | "open", _, _ -> Terrat_pull_request.State.(Open Open_status.Mergeable)
                        | "closed", _, _ -> Terrat_pull_request.State.Closed
                        | "merged", Some merged_hash, Some merged_at ->
                            Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                        | _ -> assert false);
                      checks = true;
                      mergeable = None;
                      provisional_merge_sha = None;
                      draft = false;
                    }
                in
                Src.Pull_request pull_request
            | _ -> Src.Drift
          in
          Terrat_work_manifest.
            {
              base_hash;
              changes = ();
              completed_at = None;
              created_at;
              hash;
              id;
              src;
              run_id;
              run_type;
              state;
              tag_query;
            })
        (CCInt64.of_int event.T.repository.Gw.Repository.id)
        (CCInt64.of_int event.T.pull_number)
        (Terrat_evaluator.Event.Op_class.run_type_of_tf operation)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok wms -> Abb.Future.return (Ok wms)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let create_commit_checks event pull_request checks =
    let open Abb.Future.Infix_monad in
    Terrat_github_commit_check.create
      ~config:event.T.config
      ~access_token:event.T.access_token
      ~owner:event.T.repository.Gw.Repository.owner.Gw.User.login
      ~repo:event.T.repository.Gw.Repository.name
      ~ref_:pull_request.Terrat_pull_request.hash
      checks
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Githubc2_abb.call_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : %s"
              (T.request_id event)
              (Githubc2_abb.show_call_err err));
        Abb.Future.return (Error `Error)

  let get_commit_check_details_url event pull_request =
    Printf.sprintf
      "https://github.com/%s/%s/actions"
      event.T.repository.Gw.Repository.owner.Gw.User.login
      event.T.repository.Gw.Repository.name

  let maybe_replace_old_commit_statuses event pull_request commit_checks =
    let open Abb.Future.Infix_monad in
    let replacement_commit_statuses =
      commit_checks
      |> CCList.filter (fun Terrat_commit_check.{ title; status; _ } ->
             (not Terrat_commit_check.Status.(equal status Completed))
             && (CCList.mem ~eq:CCString.equal title [ "terrateam plan"; "terrateam apply" ]
                || CCString.prefix ~pre:"terrateam plan " title
                || CCString.prefix ~pre:"terrateam apply " title))
      |> CCList.map (fun check -> Terrat_commit_check.{ check with status = Status.Completed })
    in
    create_commit_checks event pull_request replacement_commit_statuses
    >>= function
    | Ok () -> Abb.Future.return ()
    | Error _ ->
        Logs.err (fun m ->
            m "EVALUATOR : %s : FAILED_REPLACE_OLD_COMMIT_STATUSES" (T.request_id event));
        Abb.Future.return ()

  let create_queued_commit_checks event run_type pull_request dirspaces =
    let details_url = get_commit_check_details_url event pull_request in
    let unified_run_type =
      let module Urt = Terrat_work_manifest.Unified_run_type in
      run_type |> Urt.of_run_type |> Urt.to_string
    in
    let aggregate =
      Terrat_commit_check.
        [
          make
            ~details_url
            ~description:"Queued"
            ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
            ~status:Status.Queued;
          make
            ~details_url
            ~description:"Queued"
            ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
            ~status:Status.Queued;
        ]
    in
    let dirspace_checks =
      CCList.map
        (fun Terrat_change.Dirspace.{ dir; workspace; _ } ->
          Terrat_commit_check.(
            make
              ~details_url
              ~description:"Queued"
              ~title:(Printf.sprintf "terrateam %s: %s %s" unified_run_type dir workspace)
              ~status:Status.Queued))
        dirspaces
    in
    aggregate @ dirspace_checks

  let maybe_create_pending_apply event pull_request repo_config = function
    | [] ->
        (* No matches so don't make anything *)
        Abb.Future.return (Ok ())
    | all_matches ->
        let open Abb.Future.Infix_monad in
        let module Rc = Terrat_repo_config.Version_1 in
        let module Ar = Rc.Apply_requirements in
        let apply_requirements =
          CCOption.get_or ~default:(Rc.Apply_requirements.make ()) repo_config.Rc.apply_requirements
        in
        if apply_requirements.Ar.create_pending_apply_check then (
          Abbs_time_it.run (log_time event "FETCH_COMMIT_CHECKS") (fun () ->
              fetch_commit_checks event pull_request)
          >>= function
          | Ok commit_checks -> (
              Abb.Future.fork (maybe_replace_old_commit_statuses event pull_request commit_checks)
              >>= fun _ ->
              let details_url = get_commit_check_details_url event pull_request in
              let commit_check_titles =
                commit_checks
                |> CCList.map (fun Terrat_commit_check.{ title; _ } -> title)
                |> String_set.of_list
              in
              let missing_commit_checks =
                all_matches
                |> CCList.filter_map
                     (fun
                       Terrat_change_match.
                         {
                           dirspace = Terrat_change.Dirspace.{ dir; workspace };
                           when_modified = Terrat_repo_config.When_modified.{ autoapply; _ };
                           _;
                         }
                     ->
                       let name = Printf.sprintf "terrateam apply: %s %s" dir workspace in
                       if (not autoapply) && not (String_set.mem name commit_check_titles) then
                         Some
                           Terrat_commit_check.(
                             make
                               ~details_url
                               ~description:"Waiting"
                               ~title:(Printf.sprintf "terrateam apply: %s %s" dir workspace)
                               ~status:Status.Queued)
                       else None)
              in
              create_commit_checks event pull_request missing_commit_checks
              >>= function
              | Ok _ -> Abb.Future.return (Ok ())
              | Error `Error ->
                  Logs.err (fun m ->
                      m "EVALUATOR : %s : FAILED_CREATE_APPLY_CHECK" (T.request_id event));
                  Abb.Future.return (Ok ()))
          | Error _ as err ->
              Logs.err (fun m ->
                  m "EVALUATOR : %s : FAILED_FETCH_COMMIT_CHECKS" (T.request_id event));
              Abb.Future.return err)
        else Abb.Future.return (Ok ())

  let store_pull_request_work_manifest db event repo_config changes work_manifest denied_dirspaces =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      let module Wm = Terrat_work_manifest in
      let module Pr = Terrat_pull_request in
      let module Ch = Terrat_change in
      let module Cm = Terrat_change_match in
      let module Ac = Terrat_access_control in
      let pull_request = work_manifest.Terrat_work_manifest.src in
      let work_manifest =
        {
          work_manifest with
          Wm.hash =
            (match pull_request.Pr.state with
            | Pr.State.(Merged Merged.{ merged_hash; _ }) -> merged_hash
            | _ -> work_manifest.Wm.hash);
        }
      in
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : STORE_WORK_MANIFEST : %s : %s : %Ld : %s : %s"
            (T.request_id event)
            event.T.repository.Gw.Repository.owner.Gw.User.login
            event.T.repository.Gw.Repository.name
            pull_request.Pr.id
            work_manifest.Wm.base_hash
            work_manifest.Wm.hash);
      insert_work_manifest
        db
        event.T.repository.Gw.Repository.id
        work_manifest
        (Some pull_request.Pr.id)
      >>= fun (id, state, created_at) ->
      let module Policy = struct
        type t = string list [@@deriving yojson]
      end in
      Abbs_future_combinators.List_result.iter
        ~f:(fun denied_dirspaces ->
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.insert_work_manifest_access_control_denied_dirspace
            (CCList.map
               (fun Ac.R.Deny.{ change_match = Cm.{ dirspace = Ch.Dirspace.{ dir; _ }; _ }; _ } ->
                 dir)
               denied_dirspaces)
            (CCList.map
               (fun Ac.R.Deny.
                      { change_match = Cm.{ dirspace = Ch.Dirspace.{ workspace; _ }; _ }; _ } ->
                 workspace)
               denied_dirspaces)
            (CCList.map
               (fun Ac.R.Deny.{ policy; _ } ->
                 (* This has a very awkward JSON conversion because we are
                    performing this insert by passing in a bunch of arrays
                    of values.  However policy is already an array and SQL
                    does not support multidimensional arrays where the
                    inner arrays can have different dimensions.  So we need
                    to convert the policy to a string so that we can pass
                    in an array of strings, and it needs to be in a format
                    postgresql can turn back into an array.  So we use JSON
                    as the intermediate representation. *)
                 CCOption.map (fun policy -> Yojson.Safe.to_string (Policy.to_yojson policy)) policy)
               denied_dirspaces)
            (CCList.replicate (CCList.length denied_dirspaces) id))
        (CCList.chunks 500 denied_dirspaces)
      >>= fun () ->
      let wm =
        {
          work_manifest with
          Wm.id;
          state = CCOption.get_exn_or "work manifest state" (Wm.State.of_string state);
          created_at;
          run_id = None;
          changes = ();
        }
      in
      let dirspaces =
        CCList.map
          (fun Terrat_change.Dirspaceflow.{ dirspace; _ } -> dirspace)
          work_manifest.Wm.changes
      in
      Abbs_time_it.run (log_time event "CREATE_COMMIT_CHECKS") (fun () ->
          create_commit_checks
            event
            pull_request
            (create_queued_commit_checks event wm.Wm.run_type pull_request dirspaces))
      >>= fun () ->
      let module Urt = Terrat_work_manifest.Unified_run_type in
      (match Urt.of_run_type work_manifest.Wm.run_type with
      | Urt.Plan -> maybe_create_pending_apply event pull_request repo_config changes
      | Urt.Apply -> Abb.Future.return (Ok ()))
      >>= fun () -> Abb.Future.return (Ok wm)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok wm -> Abb.Future.return (Ok wm)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)
    | Error (#Githubc2_abb.call_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : %s"
              (T.request_id event)
              (Githubc2_abb.show_call_err err));
        Abb.Future.return (Error `Error)
    | Error `Error -> Abb.Future.return (Error `Error)

  let fetch_repo_config_by_ref event ref_ =
    let open Abb.Future.Infix_monad in
    Terrat_github.fetch_repo_config
      ~config:event.T.config
      ~python:(Terrat_config.python_exec event.T.config)
      ~access_token:event.T.access_token
      ~owner:event.T.repository.Gw.Repository.owner.Gw.User.login
      ~repo:event.T.repository.Gw.Repository.name
      ref_
    >>= function
    | Ok repo_config -> Abb.Future.return (Ok repo_config)
    | Error (`Repo_config_parse_err err) -> Abb.Future.return (Error (`Repo_config_parse_err err))
    (* TODO: Pull these error messages below into something more abstract *)
    | Error `Repo_config_in_sub_module ->
        Abb.Future.return (Error (`Repo_config_err "Repo config in sub module, not supported."))
    | Error `Repo_config_is_symlink ->
        Abb.Future.return (Error (`Repo_config_err "Repo config is a symlink, not supported."))
    | Error `Repo_config_is_dir ->
        Abb.Future.return
          (Error (`Repo_config_err "Repo config is a directory but should be a file."))
    | Error `Repo_config_permission_denied ->
        Abb.Future.return
          (Error (`Repo_config_err "Repo config is inaccessible due to permissions."))
    | Error `Repo_config_unknown_err ->
        Abb.Future.return
          (Error (`Repo_config_err "An unknown error occurred while reading the repo config."))
    | Error (#Terrat_github.fetch_repo_config_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : %s"
              (T.request_id event)
              (Terrat_github.show_fetch_repo_config_err err));
        Abb.Future.return
          (Error (`Repo_config_err "An unknown error occurred while reading the repo config."))

  let fetch_base_repo_config event = fetch_repo_config_by_ref event (T.default_branch event)

  let fetch_repo_config event pull_request =
    fetch_repo_config_by_ref event (Pull_request.change_hash pull_request)

  let check_apply_requirements event pull_request repo_config =
    let module Rc = Terrat_repo_config.Version_1 in
    let module Ar = Rc.Apply_requirements in
    let open Abbs_future_combinators.Infix_result_monad in
    let apply_requirements =
      CCOption.get_or ~default:(Rc.Apply_requirements.make ()) repo_config.Rc.apply_requirements
    in
    let Ar.Checks.{ approved; merge_conflicts; status_checks } =
      CCOption.get_or ~default:(Ar.Checks.make ()) apply_requirements.Ar.checks
    in
    let approved = CCOption.get_or ~default:(Ar.Checks.Approved.make ()) approved in
    let merge_conflicts =
      CCOption.get_or ~default:(Ar.Checks.Merge_conflicts.make ()) merge_conflicts
    in
    let status_checks = CCOption.get_or ~default:(Ar.Checks.Status_checks.make ()) status_checks in
    Abbs_future_combinators.Infix_result_app.(
      (fun reviews commit_checks -> (reviews, commit_checks))
      <$> Abbs_time_it.run (log_time event "FETCH_APPROVED_TIME") (fun () ->
              fetch_pull_request_reviews event pull_request)
      <*> Abbs_time_it.run (log_time event "FETCH_COMMIT_CHECKS_TIME") (fun () ->
              fetch_commit_checks event pull_request))
    >>= fun (reviews, commit_checks) ->
    Abbs_future_combinators.to_result
      (Abb.Future.fork (maybe_replace_old_commit_statuses event pull_request commit_checks))
    >>= fun _ ->
    let approved_reviews =
      CCList.filter
        (function
          | Terrat_pull_request_review.{ status = Status.Approved; _ } -> true
          | _ -> false)
        reviews
    in
    let approved_result = CCList.length approved_reviews >= approved.Ar.Checks.Approved.count in
    let merge_result = CCOption.get_or ~default:false (Pull_request.mergeable pull_request) in
    let ignore_matching =
      CCOption.get_or ~default:[] status_checks.Ar.Checks.Status_checks.ignore_matching
    in
    if CCOption.is_none (Pull_request.mergeable pull_request) then
      Logs.debug (fun m -> m "GITHUB_EVALUATOR : %s : MERGEABLE_NONE" (T.request_id event));
    (* Convert all patterns and ignore those that don't compile.  This eats
       errors.

       TODO: Improve handling errors here *)
    let ignore_matching_pats = CCList.filter_map Lua_pattern.of_string ignore_matching in
    (* Relevant checks exclude our terrateam checks, and also exclude any
       ignored patterns.  We check both if a pattern matches OR if there is an
       exact match with the string.  This is because someone might put in an
       invalid pattern (because secretly we are using Lua patterns underneath
       which have a slightly different syntax) *)
    let relevant_commit_checks =
      CCList.filter
        (fun Terrat_commit_check.{ title; _ } ->
          not
            (CCString.prefix ~pre:"terrateam apply:" title
            || CCString.prefix ~pre:"terrateam plan:" title
            || CCList.mem
                 ~eq:CCString.equal
                 title
                 [ "terrateam apply pre-hooks"; "terrateam apply post-hooks" ]
            || CCList.exists CCFun.(Lua_pattern.find title %> CCOption.is_some) ignore_matching_pats
            || CCList.exists (CCString.equal title) ignore_matching))
        commit_checks
    in
    let failed_commit_checks =
      CCList.filter
        (function
          | Terrat_commit_check.{ status = Status.Completed; _ } -> false
          | _ -> true)
        relevant_commit_checks
    in
    let all_commit_check_success = CCList.is_empty failed_commit_checks in
    let merged =
      let module St = Terrat_pull_request.State in
      match Pull_request.state pull_request with
      | St.Merged _ -> true
      | St.Open _ | St.Closed -> false
    in
    (* If it's merged, nothing should stop an apply because it's already
       merged. *)
    let passed =
      merged
      || ((not approved.Ar.Checks.Approved.enabled) || approved_result)
         && ((not merge_conflicts.Ar.Checks.Merge_conflicts.enabled) || merge_result)
         && ((not status_checks.Ar.Checks.Status_checks.enabled) || all_commit_check_success)
    in
    let apply_requirements =
      {
        Apply_requirements.passed;
        approved = (if approved.Ar.Checks.Approved.enabled then Some approved_result else None);
        merge_conflicts =
          (if merge_conflicts.Ar.Checks.Merge_conflicts.enabled then Some merge_result else None);
        status_checks =
          (if status_checks.Ar.Checks.Status_checks.enabled then Some all_commit_check_success
           else None);
        status_checks_failed = failed_commit_checks;
        approved_reviews;
      }
    in
    Logs.info (fun m ->
        m
          "GITHUB_EVALUATOR : %s : APPLY_REQUIREMENTS_CHECKS : approved=%s merge_conflicts=%s \
           status_checks=%s"
          (T.request_id event)
          (Bool.to_string approved.Ar.Checks.Approved.enabled)
          (Bool.to_string merge_conflicts.Ar.Checks.Merge_conflicts.enabled)
          (Bool.to_string status_checks.Ar.Checks.Status_checks.enabled));
    Logs.info (fun m ->
        m
          "GITHUB_EVALUATOR : %s : APPLY_REQUIREMENTS_RESULT : approved=%s merge_check=%s \
           commit_check=%s merged=%s passed=%s"
          (T.request_id event)
          (Bool.to_string approved_result)
          (Bool.to_string merge_result)
          (Bool.to_string all_commit_check_success)
          (Bool.to_string merged)
          (Bool.to_string passed));
    Abb.Future.return (Ok apply_requirements)

  let query_unapplied_dirspaces db event pull_request =
    let module Pr = Terrat_pull_request in
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db
      Sql.select_missing_dirspace_applies_for_pull_request
      ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
      event.T.repository.Gw.Repository.owner.Gw.User.login
      event.T.repository.Gw.Repository.name
      pull_request.Pr.id
    >>= function
    | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let query_dirspaces_without_valid_plans db event pull_request dirspaces =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db
      ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
      Sql.select_dirspaces_without_valid_plans
      (CCInt64.of_int event.T.repository.Gw.Repository.id)
      pull_request.Terrat_pull_request.id
      (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
      (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let query_dirspaces_owned_by_other_pull_requests db event pull_request dirspaces =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db
      Sql.select_dirspaces_owned_by_other_pull_requests
      ~f:(fun dir
              workspace
              base_branch
              branch
              base_hash
              hash
              merged_hash
              merged_at
              pull_number
              state ->
        ( Terrat_change.Dirspace.{ dir; workspace },
          Terrat_pull_request.
            {
              base_branch_name = base_branch;
              base_hash;
              branch_name = branch;
              diff = [];
              hash;
              id = pull_number;
              state =
                (match (state, merged_hash, merged_at) with
                | "open", _, _ -> Terrat_pull_request.State.(Open Open_status.Mergeable)
                | "closed", _, _ -> Terrat_pull_request.State.Closed
                | "merged", Some merged_hash, Some merged_at ->
                    Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                | _ -> assert false);
              checks = true;
              mergeable = None;
              provisional_merge_sha = None;
              draft = false;
            } ))
      (CCInt64.of_int event.T.repository.Gw.Repository.id)
      pull_request.Terrat_pull_request.id
      (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
      (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
    >>= function
    | Ok _ as res -> Abb.Future.return res
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let publish_comment msg_type event body =
    let open Abb.Future.Infix_monad in
    Terrat_github.publish_comment
      ~config:event.T.config
      ~access_token:event.T.access_token
      ~owner:event.T.repository.Gw.Repository.owner.Gw.User.login
      ~repo:event.T.repository.Gw.Repository.name
      ~pull_number:event.T.pull_number
      body
    >>= function
    | Ok () ->
        Logs.info (fun m ->
            m "GITHUB_EVALUATOR : %s : PUBLISHED_COMMENT : %s" (T.request_id event) msg_type);
        Abb.Future.return ()
    | Error (#Terrat_github.publish_comment_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : %s : ERROR : %s"
              (T.request_id event)
              msg_type
              (Terrat_github.show_publish_comment_err err));
        Abb.Future.return ()

  let apply_template_and_publish msg_type template kv event =
    match Snabela.apply template kv with
    | Ok body -> publish_comment msg_type event body
    | Error (#Snabela.err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : TEMPLATE_ERROR : %s"
              (T.request_id event)
              (Snabela.show_err err));
        Abb.Future.return ()

  let perform_unlock_pull_request event db pull_number =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_io.Prepared_stmt.execute
      db
      (Sql.insert_pull_request_unlock ())
      (CCInt64.of_int event.T.repository.Gw.Repository.id)
      (CCInt64.of_int pull_number)
    >>= fun () ->
    Terrat_github_plan_cleanup.clean_pull_request
      ~owner:event.T.repository.Gw.Repository.owner.Gw.User.login
      ~repo:event.T.repository.Gw.Repository.name
      ~pull_number
      db

  let perform_unlock_drift event db =
    Pgsql_io.Prepared_stmt.execute
      db
      (Sql.insert_drift_unlock ())
      (CCInt64.of_int event.T.repository.Gw.Repository.id)

  let perform_unlock storage event unlock_id =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          match unlock_id with
          | Terrat_evaluator.Event.Unlock_id.Pull_request pull_number ->
              perform_unlock_pull_request event db pull_number
          | Terrat_evaluator.Event.Unlock_id.Drift -> perform_unlock_drift event db)
      >>= fun () ->
      let open Abb.Future.Infix_monad in
      Abb.Future.fork (R.run ~request_id:event.T.request_id event.T.config storage)
      >>= fun _ -> Abb.Future.return (Ok ())
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_pool.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_pool.show_err err));
        Abb.Future.return (Error `Error)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let publish_msg event =
    let module Msg = Terrat_evaluator.Event.Msg in
    function
    | Msg.Missing_plans dirspaces ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ( "dirspaces",
                  list
                    (CCList.map
                       (fun Terrat_change.Dirspace.{ dir; workspace } ->
                         Map.of_list [ ("dir", string dir); ("workspace", string workspace) ])
                       dirspaces) );
              ])
        in
        CCList.iter
          (fun Terrat_change.Dirspace.{ dir; workspace } ->
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : MISSING_PLANS : %s : %s"
                  (T.request_id event)
                  dir
                  workspace))
          dirspaces;
        apply_template_and_publish "MISSING_PLANS" Tmpl.missing_plans kv event
    | Msg.Dirspaces_owned_by_other_pull_request prs ->
        let unique_pull_request_ids =
          prs
          |> CCList.map (fun (_, Terrat_pull_request.{ id; _ }) -> id)
          |> CCList.sort_uniq ~cmp:CCInt64.compare
        in
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ( "dirspaces",
                  list
                    (CCList.map
                       (fun ( Terrat_change.Dirspace.{ dir; workspace },
                              Terrat_pull_request.{ id; _ } ) ->
                         Map.of_list
                           [
                             ("dir", string dir);
                             ("workspace", string workspace);
                             ("pull_request_id", string (CCInt64.to_string id));
                           ])
                       prs) );
                ( "unique_pull_request_ids",
                  list
                    (CCList.map
                       (fun id -> Map.of_list [ ("id", string (CCInt64.to_string id)) ])
                       unique_pull_request_ids) );
              ])
        in
        CCList.iter
          (fun (Terrat_change.Dirspace.{ dir; workspace }, Terrat_pull_request.{ id; _ }) ->
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : DIRSPACES_OWNED_BY_OTHER_PR : %s : %s : %Ld"
                  (T.request_id event)
                  dir
                  workspace
                  id))
          prs;
        apply_template_and_publish
          "DIRSPACES_OWNED_BY_OTHER_PRS"
          Tmpl.dirspaces_owned_by_other_pull_requests
          kv
          event
    | Msg.Conflicting_work_manifests wms ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ( "work_manifests",
                  list
                    (CCList.map
                       (fun Terrat_work_manifest.{ created_at; run_type; state; src; _ } ->
                         let pull_number, is_drift =
                           match src with
                           | Src.Pull_request Terrat_pull_request.{ id; _ } ->
                               (CCInt64.to_string id, false)
                           | Src.Drift -> ("drift", true)
                         in
                         Map.of_list
                           [
                             ("pull_number", string pull_number);
                             ("is_drift", bool is_drift);
                             ( "run_type",
                               string
                                 (CCString.capitalize_ascii
                                    Terrat_work_manifest.Unified_run_type.(
                                      to_string (of_run_type run_type))) );
                             ( "state",
                               string
                                 (CCString.capitalize_ascii
                                    (Terrat_work_manifest.State.to_string state)) );
                             ( "created_at",
                               string
                                 (let Unix.{ tm_year; tm_mon; tm_mday; tm_hour; tm_min; _ } =
                                    Unix.gmtime (ISO8601.Permissive.datetime created_at)
                                  in
                                  Printf.sprintf
                                    "%d-%d-%d %d:%d"
                                    (1900 + tm_year)
                                    (tm_mon + 1)
                                    tm_mday
                                    tm_hour
                                    tm_min) );
                           ])
                       wms) );
              ])
        in
        apply_template_and_publish
          "CONFLICTING_WORK_MANIFESTS"
          Tmpl.conflicting_work_manifests
          kv
          event
    | Msg.Repo_config_parse_failure err ->
        let kv = Snabela.Kv.(Map.of_list [ ("msg", string err) ]) in
        apply_template_and_publish
          "REPO_CONFIG_PARSE_FAILURE"
          Tmpl.repo_config_parse_failure
          kv
          event
    | Msg.Repo_config_failure err ->
        let kv = Snabela.Kv.(Map.of_list [ ("msg", string err) ]) in
        apply_template_and_publish
          "REPO_CONFIG_GENERIC_FAILURE"
          Tmpl.repo_config_generic_failure
          kv
          event
    | Msg.Pull_request_not_appliable (_, apply_requirements) ->
        let module Ar = Apply_requirements in
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ("approved_enabled", bool (CCOption.is_some apply_requirements.Ar.approved));
                ( "approved_check",
                  bool (CCOption.get_or ~default:false apply_requirements.Ar.approved) );
                ( "merge_conflicts_enabled",
                  bool (CCOption.is_some apply_requirements.Ar.merge_conflicts) );
                ( "merge_conflicts_check",
                  bool (CCOption.get_or ~default:false apply_requirements.Ar.merge_conflicts) );
                ( "status_checks_enabled",
                  bool (CCOption.is_some apply_requirements.Ar.status_checks) );
                ( "status_checks_check",
                  bool (CCOption.get_or ~default:false apply_requirements.Ar.status_checks) );
                ( "status_checks_failed",
                  list
                    (CCList.map
                       (fun Terrat_commit_check.{ title; _ } ->
                         Map.of_list [ ("title", string title) ])
                       apply_requirements.Ar.status_checks_failed) );
              ])
        in
        apply_template_and_publish
          "PULL_REQUEST_NOT_APPLIABLE"
          Tmpl.pull_request_not_appliable
          kv
          event
    | Msg.Pull_request_not_mergeable ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish
          "PULL_REQUEST_NOT_MERGEABLE"
          Tmpl.pull_request_not_mergeable
          kv
          event
    | Msg.Apply_no_matching_dirspaces ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish
          "APPLY_NO_MATCHING_DIRSPACES"
          Tmpl.apply_no_matching_dirspaces
          kv
          event
    | Msg.Plan_no_matching_dirspaces ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish
          "PLAN_NO_MATCHING_DIRSPACES"
          Tmpl.plan_no_matching_dirspaces
          kv
          event
    | Msg.Dest_branch_no_match pull_request ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ( "source_branch",
                  string (CCString.lowercase_ascii (Pull_request.branch_name pull_request)) );
                ( "dest_branch",
                  string (CCString.lowercase_ascii (Pull_request.base_branch_name pull_request)) );
              ])
        in
        apply_template_and_publish
          "DEST_BRANCH_NO_MATCH"
          Tmpl.base_branch_not_default_branch
          kv
          event
    | Msg.Autoapply_running ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish "AUTO_APPLY_RUNNING" Tmpl.auto_apply_running kv event
    | Msg.Bad_glob s ->
        let kv = Snabela.Kv.(Map.of_list [ ("glob", string s) ]) in
        apply_template_and_publish "BAD_GLOB" Tmpl.bad_glob kv event
    | Msg.Access_control_denied (`All_dirspaces denies) ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ("user", string event.T.user);
                ("default_branch", string (T.default_branch event));
                ( "denies",
                  list
                    (CCList.map
                       (fun Terrat_access_control.R.Deny.
                              {
                                change_match =
                                  Terrat_change_match.
                                    { dirspace = Terrat_change.Dirspace.{ dir; workspace }; _ };
                                policy;
                              } ->
                         Map.of_list
                           (CCList.flatten
                              [
                                [ ("dir", string dir); ("workspace", string workspace) ];
                                CCOption.map_or
                                  ~default:[]
                                  (fun policy ->
                                    [
                                      ( "match_list",
                                        list
                                          (CCList.map
                                             (fun s -> Map.of_list [ ("item", string s) ])
                                             policy) );
                                    ])
                                  policy;
                              ]))
                       denies) );
              ])
        in
        apply_template_and_publish
          "ACCESS_CONTROL_ALL_DIRSPACES_DENIED"
          Tmpl.access_control_all_dirspaces_denied
          kv
          event
    | Msg.Access_control_denied (`Invalid_query query) ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ("user", string event.T.user);
                ("default_branch", string (T.default_branch event));
                ("query", string query);
              ])
        in
        apply_template_and_publish
          "ACCESS_CONTROL_INVALID_QUERY"
          Tmpl.access_control_invalid_query
          kv
          event
    | Msg.Access_control_denied (`Dirspaces denies) ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ("user", string event.T.user);
                ("default_branch", string (T.default_branch event));
                ( "denies",
                  list
                    (CCList.map
                       (fun Terrat_access_control.R.Deny.
                              {
                                change_match =
                                  Terrat_change_match.
                                    { dirspace = Terrat_change.Dirspace.{ dir; workspace }; _ };
                                policy;
                              } ->
                         Map.of_list
                           (CCList.flatten
                              [
                                [ ("dir", string dir); ("workspace", string workspace) ];
                                CCOption.map_or
                                  ~default:[]
                                  (fun policy ->
                                    [
                                      ( "match_list",
                                        list
                                          (CCList.map
                                             (fun s -> Map.of_list [ ("item", string s) ])
                                             policy) );
                                    ])
                                  policy;
                              ]))
                       denies) );
              ])
        in
        apply_template_and_publish
          "ACCESS_CONTROL_DIRSPACES_DENIED"
          Tmpl.access_control_dirspaces_denied
          kv
          event
    | Msg.Access_control_denied (`Terrateam_config_update match_list) ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ("user", string event.T.user);
                ("default_branch", string (T.default_branch event));
                ( "match_list",
                  list (CCList.map (fun s -> Map.of_list [ ("item", string s) ]) match_list) );
              ])
        in
        apply_template_and_publish
          "ACCESS_CONTROL_TERRATEAM_CONFIG_UPDATE_DENIED"
          Tmpl.access_control_terrateam_config_update_denied
          kv
          event
    | Msg.Access_control_denied (`Terrateam_config_update_bad_query query) ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ("user", string event.T.user);
                ("default_branch", string (T.default_branch event));
                ("query", string query);
              ])
        in
        apply_template_and_publish
          "ACCESS_CONTROL_TERRATEAM_CONFIG_UPDATE_BAD_QUERY"
          Tmpl.access_control_terrateam_config_update_bad_query
          kv
          event
    | Msg.Access_control_denied `Lookup_err ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [ ("user", string event.T.user); ("default_branch", string (T.default_branch event)) ])
        in
        apply_template_and_publish
          "ACCESS_CONTROL_LOOKUP_ERR"
          Tmpl.access_control_lookup_err
          kv
          event
    | Msg.Access_control_denied (`Unlock match_list) ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ("user", string event.T.user);
                ("default_branch", string (T.default_branch event));
                ( "match_list",
                  list (CCList.map (fun s -> Map.of_list [ ("item", string s) ]) match_list) );
              ])
        in
        apply_template_and_publish
          "ACCESS_CONTROL_UNLOCK_DENIED"
          Tmpl.access_control_unlock_denied
          kv
          event
    | Msg.Unlock_success ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish "UNLOCK_SUCCESS" Tmpl.unlock_success kv event
    | Msg.Tag_query_err (`Tag_query_error (s, err)) ->
        let kv = Snabela.Kv.(Map.of_list [ ("query", string s); ("err", string err) ]) in
        apply_template_and_publish "TAG_QUERY_ERR" Tmpl.tag_query_error kv event
    | Msg.Account_expired ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish "ACCOUNT_EXPIRED" Tmpl.account_expired_err kv event
    | Msg.Unexpected_temporary_err ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish "UNEXPECTED_TEMPORARY_ERR" Tmpl.unexpected_temporary_err kv event
end

module Wm = struct
  module Initiate = struct
    module Sql = struct
      let read fname =
        CCOption.get_exn_or
          fname
          (CCOption.map
             (fun s ->
               s
               |> CCString.split_on_char '\n'
               |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
               |> CCString.concat "\n")
             (Terrat_files_sql.read fname))

      let initiate_work_manifest () =
        Pgsql_io.Typed_sql.(
          sql
          // (* bash_hash *) Ret.text
          // (* completed_at *) Ret.(option text)
          // (* created_at *) Ret.text
          // (* hash *) Ret.text
          // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
          // (* state *) Ret.ud' Terrat_work_manifest.State.of_string
          // (* tag_query *) Ret.ud' CCFun.(Terrat_tag_query.of_string %> CCOption.of_result)
          // (* repository *) Ret.bigint
          // (* pull_number *) Ret.(option bigint)
          // (* base_branch *) Ret.text
          // (* installation_id *) Ret.bigint
          // (* owner *) Ret.text
          // (* repo *) Ret.text
          // (* run_time *) Ret.double
          // (* run_kind *) Ret.text
          /^ read "github_initiate_work_manifest.sql"
          /% Var.uuid "id"
          /% Var.text "run_id"
          /% Var.text "sha")

      let select_work_manifest () =
        Pgsql_io.Typed_sql.(
          sql
          // (* bash_hash *) Ret.text
          // (* completed_at *) Ret.(option text)
          // (* created_at *) Ret.text
          // (* hash *) Ret.text
          // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
          // (* state *) Ret.ud' Terrat_work_manifest.State.of_string
          // (* tag_query *) Ret.ud' CCFun.(Terrat_tag_query.of_string %> CCOption.of_result)
          // (* repository *) Ret.bigint
          // (* pull_number *) Ret.(option bigint)
          // (* base_branch *) Ret.text
          // (* installation_id *) Ret.bigint
          // (* owner *) Ret.text
          // (* repo *) Ret.text
          // (* run_kind *) Ret.text
          /^ read "select_github_work_manifest.sql"
          /% Var.uuid "id"
          /% Var.text "sha")

      let select_work_manifest_dirspaces =
        Pgsql_io.Typed_sql.(
          sql
          // (* path *) Ret.text
          // (* workspace *) Ret.text
          // (* workflow_idx *) Ret.(option integer)
          /^ "select path, workspace, workflow_idx from github_work_manifest_dirspaceflows where \
              work_manifest = $id"
          /% Var.uuid "id")

      let select_dirspaces_without_valid_plans =
        Pgsql_io.Typed_sql.(
          sql
          // (* dir *) Ret.text
          // (* workspace *) Ret.text
          /^ read "select_github_dirspaces_without_valid_plans.sql"
          /% Var.bigint "repository"
          /% Var.bigint "pull_number"
          /% Var.(str_array (text "dirs"))
          /% Var.(str_array (text "workspaces")))

      let select_dirspaces_owned_by_other_pull_requests =
        Pgsql_io.Typed_sql.(
          sql
          // (* dir *) Ret.text
          // (* workspace *) Ret.text
          // (* base_branch *) Ret.text
          // (* branch *) Ret.text
          // (* base_hash *) Ret.text
          // (* hash *) Ret.text
          // (* merged_hash *) Ret.(option text)
          // (* merged_at *) Ret.(option text)
          // (* pull_number *) Ret.bigint
          // (* state *) Ret.text
          /^ read "select_github_dirspaces_owned_by_other_pull_requests.sql"
          /% Var.bigint "repository"
          /% Var.bigint "pull_number"
          /% Var.(str_array (text "dirs"))
          /% Var.(str_array (text "workspaces")))

      let select_encryption_key () =
        (* The base64 conversion is so that there are no issues with escaping
           the string *)
        Pgsql_io.Typed_sql.(
          sql
          // (* data *) Ret.ud' CCFun.(Cstruct.of_hex %> CCOption.return)
          /^ "select encode(data, 'hex') from encryption_keys order by rank limit 1")
    end

    module Tmpl = struct
      let work_manifest_already_run =
        "github_work_manifest_already_run.tmpl"
        |> Terrat_files_tmpl.read
        |> CCOption.get_exn_or "github_work_manifest_already_run.tmpl"
    end

    module Pull_request = struct
      module Lite = struct
        type t = (int64, unit, unit) Terrat_pull_request.t [@@deriving show]
      end
    end

    module Src = struct
      type t = {
        base_branch : string;
        installation_id : int64;
        owner : string;
        pull_number : int64 option;
        repo_name : string;
        repository : int64;
        run_kind : string;
      }
    end

    type t = {
      access_token : string;
      config : Terrat_config.t;
      name : string;
      owner : string;
      pull_number : int64 option;
      repository_id : int64;
      request_id : string;
      run_id : string;
      work_manifest : Src.t Terrat_work_manifest.Existing.t;
      encryption_key : Cstruct.t;
    }

    let work_manifest_state { work_manifest = Terrat_work_manifest.{ state; _ }; _ } = state

    let work_manifest_run_type { work_manifest = Terrat_work_manifest.{ run_type; _ }; _ } =
      run_type

    let maybe_update_commit_status
        config
        access_token
        request_id
        run_id
        installation_id
        owner
        repo_name
        run_type
        dirspaces
        hash = function
      | Terrat_work_manifest.State.Running ->
          let unified_run_type =
            Terrat_work_manifest.(
              run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
          in
          Abbs_future_combinators.ignore
            (Abb.Future.fork
               (let target_url =
                  Printf.sprintf "https://github.com/%s/%s/actions/runs/%s" owner repo_name run_id
                in
                let commit_statuses =
                  let aggregate =
                    Terrat_commit_check.
                      [
                        make
                          ~details_url:target_url
                          ~description:"Running"
                          ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
                          ~status:Status.Queued;
                        make
                          ~details_url:target_url
                          ~description:"Running"
                          ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
                          ~status:Status.Queued;
                      ]
                  in
                  let dirspaces =
                    CCList.map
                      (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; workspace }; _ } ->
                        Terrat_commit_check.(
                          make
                            ~details_url:target_url
                            ~description:"Running"
                            ~title:
                              (Printf.sprintf "terrateam %s: %s %s" unified_run_type dir workspace)
                            ~status:Status.Queued))
                      dirspaces
                  in
                  aggregate @ dirspaces
                in
                let open Abb.Future.Infix_monad in
                Terrat_github_commit_check.create
                  ~config
                  ~access_token
                  ~owner
                  ~repo:repo_name
                  ~ref_:hash
                  commit_statuses
                >>= function
                | Ok () -> Abb.Future.return (Ok ())
                | Error (#Terrat_github_commit_check.err as err) ->
                    Prmths.Counter.inc_one Metrics.github_errors_total;
                    Logs.err (fun m ->
                        m
                          "GITHUB_EVALUATOR : %s : COMMIT_CHECK : %s"
                          request_id
                          (Terrat_github.show_get_installation_access_token_err err));
                    Abb.Future.return (Ok ())))
      | Terrat_work_manifest.State.Queued
      | Terrat_work_manifest.State.Completed
      | Terrat_work_manifest.State.Aborted -> Abb.Future.return ()

    let fetch_all_dirspaces ~config ~python ~access_token ~owner ~repo hash =
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun repo_config files -> (repo_config, files))
        <$> Terrat_github.fetch_repo_config ~config ~python ~access_token ~owner ~repo hash
        <*> Terrat_github.get_tree ~config ~access_token ~owner ~repo ~sha:hash ())
      >>= fun (repo_config, files) ->
      match Terrat_change_match.synthesize_dir_config ~file_list:files repo_config with
      | Ok dirs ->
          let matches =
            Terrat_change_match.match_diff_list
              dirs
              (CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) files)
          in
          let workflows =
            CCOption.get_or ~default:[] repo_config.Terrat_repo_config.Version_1.workflows
          in
          let dirspaceflows =
            CCList.map
              (fun (Terrat_change_match.{ dirspace; _ } as change) ->
                Terrat_change.Dirspaceflow.
                  {
                    dirspace;
                    workflow =
                      CCOption.map
                        (fun (idx, workflow) -> Workflow.{ idx; workflow })
                        (CCList.find_idx
                           (fun Terrat_repo_config.Workflow_entry.{ tag_query; _ } ->
                             Terrat_change_match.match_tag_query
                               ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string tag_query))
                               change)
                           workflows);
                  })
              matches
          in
          Abb.Future.return
            (Ok
               (CCList.map
                  (fun Terrat_change.
                         { Dirspaceflow.dirspace = Dirspace.{ dir; workspace }; workflow } ->
                    Terrat_api_components.Work_manifest_dir.
                      {
                        path = dir;
                        workspace;
                        workflow =
                          CCOption.map
                            (fun Terrat_change.Dirspaceflow.Workflow.{ idx; _ } -> idx)
                            workflow;
                        rank = 0;
                      })
                  dirspaceflows))
      | Error (`Bad_glob _ as err) -> Abb.Future.return (Error err)

    let fetch_and_initiate_work_manifest db work_manifest_id work_manifest_initiate =
      let module I = Terrat_api_components.Work_manifest_initiate in
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        (Sql.initiate_work_manifest ())
        ~f:(fun base_hash
                completed_at
                created_at
                hash
                run_type
                state
                tag_query
                repository
                pull_number
                base_branch
                installation_id
                owner
                repo_name
                run_time
                run_kind ->
          ( run_time,
            {
              Terrat_work_manifest.base_hash;
              changes = ();
              completed_at;
              created_at;
              hash;
              id = work_manifest_id;
              src =
                Src.
                  {
                    base_branch;
                    installation_id;
                    owner;
                    pull_number;
                    repo_name;
                    repository;
                    run_kind;
                  };
              run_id = Some work_manifest_initiate.I.run_id;
              run_type;
              state;
              tag_query;
            } ))
        work_manifest_id
        work_manifest_initiate.I.run_id
        work_manifest_initiate.I.sha
      >>= function
      | (run_time, work_manifest) :: _ ->
          let module Wm = Terrat_work_manifest in
          Metrics.Work_manifest_run_time_histogram.observe
            (Metrics.work_manifest_wait_duration_seconds
               (Terrat_work_manifest.Run_type.to_string work_manifest.Wm.run_type))
            run_time;
          Abb.Future.return (Ok work_manifest)
      | [] -> (
          (* The initiate only returns the work manifest if it could be
             initiated.  If it returns nothing, it's possible that the work
             manifest still exists, just that it was not in a state that it was
             possible to be initiated.  So fetch the underlying work manifest,
             if it exists. *)
          Pgsql_io.Prepared_stmt.fetch
            db
            (Sql.select_work_manifest ())
            ~f:(fun base_hash
                    completed_at
                    created_at
                    hash
                    run_type
                    state
                    tag_query
                    repository
                    pull_number
                    base_branch
                    installation_id
                    owner
                    repo_name
                    run_kind ->
              {
                Terrat_work_manifest.base_hash;
                changes = ();
                completed_at;
                created_at;
                hash;
                id = work_manifest_id;
                src =
                  Src.
                    {
                      base_branch;
                      installation_id;
                      owner;
                      pull_number;
                      repo_name;
                      repository;
                      run_kind;
                    };
                run_id = Some work_manifest_initiate.I.run_id;
                run_type;
                state;
                tag_query;
              })
            work_manifest_id
            work_manifest_initiate.I.sha
          >>= function
          | work_manifest :: _ -> Abb.Future.return (Ok work_manifest)
          | [] -> Abb.Future.return (Error `Work_manifest_not_found))

    let initiate_work_manifest ~request_id ~work_manifest_id config db work_manifest_initiate =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Abbs_time_it.run
          (fun t ->
            Logs.info (fun m ->
                m "GITHUB_EVALUATOR : %s : FETCH_AND_INITIATE_WORK_MANIFEST : %f" request_id t))
          (fun () -> fetch_and_initiate_work_manifest db work_manifest_id work_manifest_initiate)
        >>= fun work_manifest ->
        let module Wm = Terrat_work_manifest in
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_work_manifest_dirspaces
          ~f:(fun dir workspace workflow_idx ->
            Terrat_change.
              {
                Dirspaceflow.dirspace = { Dirspace.dir; workspace };
                workflow = CCOption.map CCInt32.to_int workflow_idx;
              })
          work_manifest_id
        >>= fun dirspaceflows ->
        Pgsql_io.Prepared_stmt.fetch db (Sql.select_encryption_key ()) ~f:CCFun.id
        >>= fun keys ->
        let key =
          match keys with
          | key :: _ -> key
          | [] -> assert false
        in
        let run_id = work_manifest_initiate.Terrat_api_components.Work_manifest_initiate.run_id in
        let wm = { work_manifest with Wm.changes = dirspaceflows } in
        Terrat_github.get_installation_access_token
          config
          (CCInt64.to_int wm.Wm.src.Src.installation_id)
        >>= fun access_token ->
        let open Abb.Future.Infix_monad in
        maybe_update_commit_status
          config
          access_token
          request_id
          run_id
          wm.Wm.src.Src.installation_id
          wm.Wm.src.Src.owner
          wm.Wm.src.Src.repo_name
          wm.Wm.run_type
          dirspaceflows
          wm.Wm.hash
          wm.Wm.state
        >>= fun () ->
        let t =
          {
            access_token;
            config;
            name = wm.Wm.src.Src.repo_name;
            owner = wm.Wm.src.Src.owner;
            pull_number = wm.Wm.src.Src.pull_number;
            repository_id = wm.Wm.src.Src.repository;
            request_id;
            run_id;
            work_manifest = wm;
            encryption_key = key;
          }
        in
        Abb.Future.return (Ok t)
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok wm -> Abb.Future.return (Ok (Some wm))
      | Error `Work_manifest_not_found -> Abb.Future.return (Ok None)
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)
      | Error (#Terrat_github.get_installation_access_token_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : COMMIT_CHECK : %a"
                request_id
                Terrat_github.pp_get_installation_access_token_err
                err);
          Abb.Future.return (Error `Error)

    let query_dirspaces_without_valid_plans db t =
      let module Wm = Terrat_work_manifest in
      let module Tc = Terrat_change in
      let module Dsf = Tc.Dirspaceflow in
      let module Ds = Tc.Dirspace in
      let open Abb.Future.Infix_monad in
      let changes = t.work_manifest.Wm.changes in
      match t.pull_number with
      | Some pull_number -> (
          Pgsql_io.Prepared_stmt.fetch
            db
            ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
            Sql.select_dirspaces_without_valid_plans
            t.repository_id
            pull_number
            (CCList.map (fun { Dsf.dirspace = Ds.{ dir; _ }; _ } -> dir) changes)
            (CCList.map (fun { Dsf.dirspace = Ds.{ workspace; _ }; _ } -> workspace) changes)
          >>= function
          | Ok _ as ret -> Abb.Future.return ret
          | Error (#Pgsql_io.err as err) ->
              Prmths.Counter.inc_one Metrics.pgsql_errors_total;
              Logs.err (fun m ->
                  m "GITHUB_EVALUATOR : %s : ERROR : %s" t.request_id (Pgsql_io.show_err err));
              Abb.Future.return (Error `Error))
      | None -> Abb.Future.return (Ok [])

    let query_dirspaces_owned_by_other_pull_requests db t =
      let module Wm = Terrat_work_manifest in
      let module Tc = Terrat_change in
      let module Dsf = Tc.Dirspaceflow in
      let module Ds = Tc.Dirspace in
      let open Abb.Future.Infix_monad in
      let changes = t.work_manifest.Wm.changes in
      match t.pull_number with
      | Some pull_number -> (
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_dirspaces_owned_by_other_pull_requests
            ~f:(fun dir
                    workspace
                    base_branch
                    branch
                    base_hash
                    hash
                    merged_hash
                    merged_at
                    pull_number
                    state ->
              ( Tc.Dirspace.{ dir; workspace },
                Terrat_pull_request.
                  {
                    base_branch_name = base_branch;
                    base_hash;
                    branch_name = branch;
                    diff = ();
                    hash;
                    id = pull_number;
                    state =
                      (match (state, merged_hash, merged_at) with
                      | "open", _, _ -> Terrat_pull_request.State.(Open Open_status.Mergeable)
                      | "closed", _, _ -> Terrat_pull_request.State.Closed
                      | "merged", Some merged_hash, Some merged_at ->
                          Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                      | _ -> assert false);
                    checks = ();
                    mergeable = None;
                    provisional_merge_sha = None;
                    draft = false;
                  } ))
            t.repository_id
            pull_number
            (CCList.map (fun { Dsf.dirspace = Ds.{ dir; _ }; _ } -> dir) changes)
            (CCList.map (fun { Dsf.dirspace = Ds.{ workspace; _ }; _ } -> workspace) changes)
          >>= function
          | Ok res -> Abb.Future.return (Ok (Terrat_evaluator.Event.Dirspace_map.of_list res))
          | Error (#Pgsql_io.err as err) ->
              Prmths.Counter.inc_one Metrics.pgsql_errors_total;
              Logs.err (fun m ->
                  m "GITHUB_EVALUATOR : %s : ERROR : %s" t.request_id (Pgsql_io.show_err err));
              Abb.Future.return (Error `Error))
      | None -> Abb.Future.return (Ok (Terrat_evaluator.Event.Dirspace_map.of_list []))

    let work_manifest_already_run t =
      match t.pull_number with
      | Some pull_number ->
          let open Abb.Future.Infix_monad in
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : WORK_MANIFEST_ALREADY_RUN : work_manifest=%s : owner=%s : \
                 name=%s : pull_number=%Ld"
                t.request_id
                (Uuidm.to_string t.work_manifest.Terrat_work_manifest.id)
                t.owner
                t.name
                pull_number);
          Terrat_github.publish_comment
            ~config:t.config
            ~access_token:t.access_token
            ~owner:t.owner
            ~repo:t.name
            ~pull_number:(CCInt64.to_int pull_number)
            Tmpl.work_manifest_already_run
          >>= fun _ -> Abb.Future.return (Ok ())
      | None -> Abb.Future.return (Ok ())

    let to_response' t =
      let module Wm = Terrat_work_manifest in
      let request_id = t.request_id in
      let work_manifest = t.work_manifest in
      let changed_dirspaces =
        let module Tc = Terrat_change in
        let module Dsf = Tc.Dirspaceflow in
        CCList.map
          (fun Tc.{ Dsf.dirspace = { Dirspace.dir; workspace }; workflow } ->
            (* TODO: Provide correct rank *)
            Terrat_api_components.Work_manifest_dir.{ path = dir; workspace; workflow; rank = 0 })
          work_manifest.Wm.changes
      in
      let token =
        Base64.encode_exn
          (Cstruct.to_string
             (Mirage_crypto.Hash.SHA256.hmac
                ~key:t.encryption_key
                (Cstruct.of_string (Uuidm.to_string work_manifest.Wm.id))))
      in
      match work_manifest.Wm.run_type with
      | Wm.Run_type.Plan | Wm.Run_type.Autoplan ->
          let open Abbs_future_combinators.Infix_result_monad in
          Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : FETCH_ALL_DIRSPACES" request_id);
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : FETCH_ALL_DIRSPACES : %f" request_id t))
            (fun () ->
              Abbs_future_combinators.Infix_result_app.(
                (fun base_dirspaces dirspaces -> (base_dirspaces, dirspaces))
                <$> Abbs_time_it.run
                      (fun time ->
                        Logs.info (fun m ->
                            m "GITHUB_EVALUATOR : %s : FETCH_BASE_DIRSPACES : %f" request_id time))
                      (fun () ->
                        fetch_all_dirspaces
                          ~config:t.config
                          ~python:(Terrat_config.python_exec t.config)
                          ~access_token:t.access_token
                          ~owner:t.owner
                          ~repo:t.name
                          work_manifest.Wm.base_hash)
                <*> Abbs_time_it.run
                      (fun time ->
                        Logs.info (fun m ->
                            m "GITHUB_EVALUATOR : %s : FETCH_DIRSPACES : %f" request_id time))
                      (fun () ->
                        fetch_all_dirspaces
                          ~config:t.config
                          ~python:(Terrat_config.python_exec t.config)
                          ~access_token:t.access_token
                          ~owner:t.owner
                          ~repo:t.name
                          work_manifest.Wm.hash)))
          >>= fun (base_dirspaces, dirspaces) ->
          let ret =
            Terrat_api_components.(
              Work_manifest.Work_manifest_plan
                Work_manifest_plan.
                  {
                    token;
                    base_dirspaces;
                    base_ref = work_manifest.Wm.src.Src.base_branch;
                    changed_dirspaces;
                    dirspaces;
                    run_kind = work_manifest.Wm.src.Src.run_kind;
                    type_ = "plan";
                  })
          in
          Abb.Future.return (Ok ret)
      | Wm.Run_type.Apply | Wm.Run_type.Autoapply ->
          let ret =
            Terrat_api_components.(
              Work_manifest.Work_manifest_apply
                Work_manifest_apply.
                  {
                    token;
                    base_ref = work_manifest.Wm.src.Src.base_branch;
                    changed_dirspaces;
                    run_kind = "";
                    type_ = "apply";
                  })
          in
          Abb.Future.return (Ok ret)
      | Wm.Run_type.Unsafe_apply ->
          let ret =
            Terrat_api_components.(
              Work_manifest.Work_manifest_unsafe_apply
                Work_manifest_unsafe_apply.
                  {
                    token;
                    base_ref = work_manifest.Wm.src.Src.base_branch;
                    changed_dirspaces;
                    run_kind = "";
                    type_ = "unsafe-apply";
                  })
          in
          Abb.Future.return (Ok ret)

    let to_response t =
      let open Abb.Future.Infix_monad in
      to_response' t
      >>= function
      | Ok work_manifest -> Abb.Future.return (Ok work_manifest)
      | Error (#Terrat_github.fetch_repo_config_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ERROR : %a"
                t.request_id
                Terrat_github.pp_fetch_repo_config_err
                err);
          Abb.Future.return (Error `Error)
      | Error (`Bad_glob glob) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : BAD_GLOB : %s" t.request_id glob);
          Abb.Future.return (Error `Error)
      | Error (#Terrat_github.get_tree_err as err) ->
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : ERROR : %a" t.request_id Terrat_github.pp_get_tree_err err);
          Abb.Future.return (Error `Error)
  end

  module Plans = struct
    module Sql = struct
      let read fname =
        CCOption.get_exn_or
          fname
          (CCOption.map
             (fun s ->
               s
               |> CCString.split_on_char '\n'
               |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
               |> CCString.concat "\n")
             (Terrat_files_sql.read fname))

      let upsert_terraform_plan =
        Pgsql_io.Typed_sql.(
          sql
          /^ read "upsert_terraform_plan.sql"
          /% Var.uuid "work_manifest"
          /% Var.text "path"
          /% Var.text "workspace"
          /% Var.(ud (text "data") Base64.encode_string))

      let select_recent_plan =
        Pgsql_io.Typed_sql.(
          sql
          // (* data *) Ret.ud base64
          /^ read "select_github_recent_plan.sql"
          /% Var.uuid "id"
          /% Var.text "dir"
          /% Var.text "workspace")
    end

    let delete_plan request_id db work_manifest dir workspace =
      let open Abb.Future.Infix_monad in
      Terrat_github_plan_cleanup.clean ~work_manifest ~dir ~workspace db
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : DELETE_PLAN : ERROR : %s"
                request_id
                (Pgsql_io.show_err err));
          Abb.Future.return (Ok ())

    let fetch ~request_id ~path ~workspace storage work_manifest_id =
      let open Abb.Future.Infix_monad in
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : PLAN_GET : %a : %s : %s"
            request_id
            Uuidm.pp
            work_manifest_id
            path
            workspace);
      Pgsql_pool.with_conn storage ~f:(fun db ->
          let open Abbs_future_combinators.Infix_result_monad in
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_recent_plan
            ~f:CCFun.id
            work_manifest_id
            path
            workspace
          >>= fun res ->
          delete_plan request_id db work_manifest_id path workspace
          >>= fun () -> Abb.Future.return (Ok res))
      >>= function
      | Ok [] -> Abb.Future.return (Ok None)
      | Ok (data :: _) -> Abb.Future.return (Ok (Some data))
      | Error (#Pgsql_pool.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : PLAN_GET : %a : ERROR : %s"
                request_id
                Uuidm.pp
                work_manifest_id
                (Pgsql_pool.show_err err));
          Abb.Future.return (Error `Error)
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : PLAN_GET : %a : ERROR : %s"
                request_id
                Uuidm.pp
                work_manifest_id
                (Pgsql_io.show_err err));
          Abb.Future.return (Error `Error)

    let store ~request_id ~path ~workspace ~has_changes storage work_manifest_id plan_data =
      let open Abb.Future.Infix_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.upsert_terraform_plan
            work_manifest_id
            path
            workspace
            plan_data)
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_pool.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : PLAN : %a : ERROR : %s"
                request_id
                Uuidm.pp
                work_manifest_id
                (Pgsql_pool.show_err err));
          Abb.Future.return (Error `Error)
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : PLAN : %a : ERROR : %s"
                request_id
                Uuidm.pp
                work_manifest_id
                (Pgsql_io.show_err err));
          Abb.Future.return (Error `Error)
  end

  module Results = struct
    let maybe_credential_error_strings =
      [
        "no valid credential";
        "Required token could not be found";
        "could not find default credentials";
      ]

    module Sql = struct
      let read fname =
        CCOption.get_exn_or
          fname
          (CCOption.map
             (fun s ->
               s
               |> CCString.split_on_char '\n'
               |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
               |> CCString.concat "\n")
             (Terrat_files_sql.read fname))

      let policy =
        let module P = struct
          type t = string list [@@deriving yojson]
        end in
        CCFun.(
          CCOption.wrap Yojson.Safe.from_string
          %> CCOption.map P.of_yojson
          %> CCOption.flat_map CCResult.to_opt)

      let select_work_manifest_for_update () =
        Pgsql_io.Typed_sql.(
          sql
          // (* bash_hash *) Ret.text
          // (* completed_at *) Ret.(option text)
          // (* created_at *) Ret.text
          // (* hash *) Ret.text
          // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
          // (* state *) Ret.ud' Terrat_work_manifest.State.of_string
          // (* tag_query *) Ret.ud' CCFun.(Terrat_tag_query.of_string %> CCOption.of_result)
          // (* repository *) Ret.bigint
          // (* pull_number *) Ret.(option bigint)
          // (* base_branch *) Ret.text
          // (* installation_id *) Ret.bigint
          // (* owner *) Ret.text
          // (* repo *) Ret.text
          // (* run_id *) Ret.(option text)
          /^ read "select_github_work_manifest_for_update.sql"
          /% Var.uuid "id")

      let complete_work_manifest =
        Pgsql_io.Typed_sql.(
          sql
          // (* run_time *) Ret.double
          /^ "update github_work_manifests set state = 'completed', completed_at = now() where id \
              = $id returning extract(epoch from (completed_at - created_at))"
          /% Var.uuid "id")

      let insert_github_work_manifest_result =
        Pgsql_io.Typed_sql.(
          sql
          /^ read "insert_github_work_manifest_result.sql"
          /% Var.uuid "work_manifest"
          /% Var.text "path"
          /% Var.text "workspace"
          /% Var.boolean "success")

      let select_work_manifest_access_control_denied_dirspaces =
        Pgsql_io.Typed_sql.(
          sql
          // (* path *) Ret.text
          // (* workspace *) Ret.text
          // (* policy *) Ret.(option (ud' policy))
          /^ read "select_github_work_manifest_access_control_denied_dirspaces.sql"
          /% Var.uuid "work_manifest")

      let select_missing_dirspace_applies_for_pull_request =
        Pgsql_io.Typed_sql.(
          sql
          // (* path *) Ret.text
          // (* workspace *) Ret.text
          /^ read "select_github_missing_dirspace_applies_for_pull_request.sql"
          /% Var.text "owner"
          /% Var.text "name"
          /% Var.bigint "pull_number")

      let select_drift_schedule_from_work_manifest_id () =
        Pgsql_io.Typed_sql.(
          sql
          // (* installation_id *) Ret.bigint
          // (* repository *) Ret.bigint
          // (* owner *) Ret.text
          // (* name *) Ret.text
          // (* reconcile *) Ret.boolean
          /^ read "select_drift_schedule_from_work_manifest_id.sql"
          /% Var.uuid "work_manifest_id")
    end

    module Tmpl = struct
      module Transformers = struct
        let money =
          ( "money",
            Snabela.Kv.(
              function
              | F num -> S (Printf.sprintf "%01.02f" num)
              | any -> any) )

        let plan_diff =
          ( "plan_diff",
            Snabela.Kv.(
              function
              | S plan -> S (Terrat_plan_diff.transform plan)
              | any -> any) )

        let compact_plan =
          ( "compact_plan",
            Snabela.Kv.(
              function
              | S plan ->
                  S
                    (plan
                    |> CCString.split_on_char '\n'
                    |> CCList.filter (fun s -> CCString.find ~sub:"= (known after apply)" s = -1)
                    |> CCString.concat "\n")
              | any -> any) )
      end

      let read fname =
        fname
        |> Terrat_files_tmpl.read
        |> CCOption.get_exn_or fname
        |> Snabela.Template.of_utf8_string
        |> function
        | Ok tmpl -> Snabela.of_template tmpl Transformers.[ money; compact_plan; plan_diff ]
        | Error (#Snabela.Template.err as err) -> failwith (Snabela.Template.show_err err)

      let plan_complete = read "github_plan_complete.tmpl"
      let apply_complete = read "github_apply_complete.tmpl"

      let comment_too_large =
        "github_comment_too_large.tmpl"
        |> Terrat_files_tmpl.read
        |> CCOption.get_exn_or "github_comment_too_large.tmpl"

      let automerge_error = read "github_automerge_error.tmpl"
    end

    module Workflow_step_output = struct
      type t = {
        success : bool;
        key : string option;
        text : string;
        step_type : string;
        details : string option;
      }
    end

    module Kind = struct
      module Pull_request = struct
        type t = int
      end

      module Drift = struct
        type t = { branch : string }
      end

      type t = (Pull_request.t, Drift.t) Terrat_work_manifest.Kind.t
    end

    type t = {
      access_token : string;
      config : Terrat_config.t;
      installation_id : int64;
      name : string;
      owner : string;
      request_id : string;
      run_id : string;
      storage : Terrat_storage.t;
      work_manifest : Kind.t Terrat_work_manifest.Existing_lite.t;
    }

    let kind t = t.work_manifest.Terrat_work_manifest.src

    let merge_pull_request t pull_number =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        let client = Terrat_github.create t.config (`Token t.access_token) in
        Logs.info (fun m ->
            m
              "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %s : %s : %d"
              t.request_id
              t.owner
              t.name
              pull_number);
        Githubc2_abb.call
          client
          Githubc2_pulls.Merge.(
            make
              ~body:
                Request_body.(
                  make
                    Primary.(
                      make
                        ~commit_title:(Some (Printf.sprintf "Terrateam Automerge #%d" pull_number))
                        ()))
              Parameters.(make ~owner:t.owner ~repo:t.name ~pull_number))
        >>= fun resp ->
        match Openapi.Response.value resp with
        | `OK _ -> Abb.Future.return (Ok ())
        | `Method_not_allowed _ -> (
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : MERGE_METHOD_NOT_ALLOWED : %s : %s : %d"
                  t.request_id
                  t.owner
                  t.name
                  pull_number);
            Githubc2_abb.call
              client
              Githubc2_pulls.Merge.(
                make
                  ~body:Request_body.(make Primary.(make ~merge_method:(Some "squash") ()))
                  Parameters.(make ~owner:t.owner ~repo:t.name ~pull_number))
            >>= fun resp ->
            match Openapi.Response.value resp with
            | `OK _ -> Abb.Future.return (Ok ())
            | ( `Method_not_allowed _
              | `Conflict _
              | `Forbidden _
              | `Not_found _
              | `Unprocessable_entity _ ) as err -> Abb.Future.return (Error err))
        | (`Conflict _ | `Forbidden _ | `Not_found _ | `Unprocessable_entity _) as err ->
            Abb.Future.return (Error err)
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Githubc2_abb.call_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %a"
                t.request_id
                Githubc2_abb.pp_call_err
                err);
          Abb.Future.return (Error `Error)
      | Error
          (`Method_not_allowed
             Githubc2_pulls.Merge.Responses.Method_not_allowed.
               { primary = Primary.{ message = Some message; _ }; _ } as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %a"
                t.request_id
                Githubc2_pulls.Merge.Responses.pp
                err);
          Abb.Future.return (Error (`Error_with_msg message))
      | Error (#Githubc2_pulls.Merge.Responses.t as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %a"
                t.request_id
                Githubc2_pulls.Merge.Responses.pp
                err);
          Abb.Future.return (Error `Error)

    let delete_pull_request_branch t pull_number =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Logs.info (fun m ->
            m
              "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %d"
              t.request_id
              t.owner
              t.name
              pull_number);
        Terrat_github.fetch_pull_request
          ~config:t.config
          ~access_token:t.access_token
          ~owner:t.owner
          ~repo:t.name
          pull_number
        >>= fun resp ->
        match Openapi.Response.value resp with
        | `OK
            Githubc2_components.Pull_request.
              {
                primary = Primary.{ head = Head.{ primary = Primary.{ ref_ = branch; _ }; _ }; _ };
                _;
              } -> (
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %d : %s"
                  t.request_id
                  t.owner
                  t.name
                  pull_number
                  branch);
            let client = Terrat_github.create t.config (`Token t.access_token) in
            Githubc2_abb.call
              client
              Githubc2_git.Delete_ref.(
                make Parameters.(make ~owner:t.owner ~repo:t.name ~ref_:("heads/" ^ branch)))
            >>= fun resp ->
            match Openapi.Response.value resp with
            | `No_content -> Abb.Future.return (Ok ())
            | `Unprocessable_entity err ->
                Logs.err (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %d : %a"
                      t.request_id
                      t.owner
                      t.name
                      pull_number
                      Githubc2_git.Delete_ref.Responses.Unprocessable_entity.pp
                      err);
                Abb.Future.return (Ok ()))
        | (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _) as err
          ->
            Prmths.Counter.inc_one Metrics.github_errors_total;
            Logs.err (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : ERROR : %a"
                  t.request_id
                  Githubc2_pulls.Get.Responses.pp
                  err);
            Abb.Future.return (Error `Error)
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | (Ok _ | Error `Error) as ret -> Abb.Future.return ret
      | Error (#Githubc2_abb.call_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %a"
                t.request_id
                Githubc2_abb.pp_call_err
                err);
          Abb.Future.return (Error `Error)

    let query_missing_applied_dirspaces t pull_number =
      let open Abb.Future.Infix_monad in
      Pgsql_pool.with_conn t.storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_missing_dirspace_applies_for_pull_request
            ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
            t.owner
            t.name
            (CCInt64.of_int pull_number))
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : QUERY_MISSING_APPLIED_DIRSPACES : %a"
                t.request_id
                Pgsql_pool.pp_err
                err);
          Abb.Future.return (Error `Error)
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : QUERY_MISSING_APPLIED_DIRSPACES : %a"
                t.request_id
                Pgsql_io.pp_err
                err);
          Abb.Future.return (Error `Error)

    let query_drift_schedule t storage drift =
      let open Abb.Future.Infix_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            (Sql.select_drift_schedule_from_work_manifest_id ())
            ~f:Dr.Schedule.make
            t.work_manifest.Terrat_work_manifest.id)
      >>= function
      | Ok [] -> assert false
      | Ok (schedule :: _) -> Abb.Future.return (Ok schedule)
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : DRIFT : %a" t.request_id Pgsql_pool.pp_err err);
          Abb.Future.return (Error `Error)
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : DRIFT : %a" t.request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let fetch_repo_config t =
      let open Abb.Future.Infix_monad in
      Terrat_github.fetch_repo_config
        ~config:t.config
        ~python:(Terrat_config.python_exec t.config)
        ~access_token:t.access_token
        ~owner:t.owner
        ~repo:t.name
        t.work_manifest.Terrat_work_manifest.hash
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Terrat_github.fetch_repo_config_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : FETCH_PULL_REQUEST : ERROR : %a"
                t.request_id
                Terrat_github.pp_fetch_repo_config_err
                err);
          Abb.Future.return (Error `Error)

    let fetch_work_manifest db work_manifest_id =
      Pgsql_io.Prepared_stmt.fetch
        db
        (Sql.select_work_manifest_for_update ())
        work_manifest_id
        ~f:(fun
             base_hash
             completed_at
             created_at
             hash
             run_type
             state
             tag_query
             repo_id
             pull_number
             base_branch
             installation_id
             owner
             name
             run_id
           ->
          ( (installation_id, owner, name, pull_number),
            {
              Terrat_work_manifest.base_hash;
              changes = ();
              completed_at;
              created_at;
              hash;
              id = work_manifest_id;
              src =
                (match pull_number with
                | Some pull_number ->
                    Terrat_work_manifest.Kind.Pull_request (CCInt64.to_int pull_number)
                | None -> Terrat_work_manifest.Kind.Drift Kind.Drift.{ branch = base_branch });
              run_id;
              run_type;
              state;
              tag_query;
            } ))

    let log_work_manifest_result request_id work_manifest_id success =
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : RESULT : %a : %s"
            request_id
            Uuidm.pp
            work_manifest_id
            (if success then "SUCCESS" else "FAILURE"));
      Prmths.Counter.inc_one (Metrics.run_overall_result_count (Bool.to_string success))

    let complete_work_manifest request_id db work_manifest_id =
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_time_it.run
        (fun t ->
          Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : COMPLETE_WORK_MANIFEST : %f" request_id t))
        (fun () ->
          Pgsql_io.Prepared_stmt.fetch db Sql.complete_work_manifest work_manifest_id ~f:CCFun.id)
      >>= function
      | run_time :: _ -> Abb.Future.return (Ok run_time)
      | [] -> assert false

    let store_dirspace_results request_id db work_manifest_id dirspaces =
      Abbs_time_it.run
        (fun t ->
          Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : DIRSPACE_RESULT_STORE : %f" request_id t))
        (fun () ->
          Abbs_future_combinators.List_result.iter
            ~f:(fun result ->
              let module Wmr = Terrat_api_components.Work_manifest_result in
              Logs.info (fun m ->
                  m
                    "GITHUB_EVALUATOR : %s : RESULT_STORE : %a : %s : %s : %s"
                    request_id
                    Uuidm.pp
                    work_manifest_id
                    result.Wmr.path
                    result.Wmr.workspace
                    (if result.Wmr.success then "SUCCESS" else "FAILURE"));
              Pgsql_io.Prepared_stmt.execute
                db
                Sql.insert_github_work_manifest_result
                work_manifest_id
                result.Wmr.path
                result.Wmr.workspace
                result.Wmr.success)
            dirspaces)

    let fetch_denied_dirspaces request_id db work_manifest_id =
      Abbs_time_it.run
        (fun t ->
          Logs.info (fun m ->
              m "GITHUB_EVALUATOR : %s : FETCH_ACCESS_CONTROL_DENIED_DIRSPACES : %f" request_id t))
        (fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_work_manifest_access_control_denied_dirspaces
            ~f:(fun dir workspace policy -> (Terrat_change.Dirspace.{ dir; workspace }, policy))
            work_manifest_id)

    let fetch_access_token request_id config installation_id =
      Abbs_time_it.run
        (fun t ->
          Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : FETCH_ACCESS_TOKEN : %f" request_id t))
        (fun () ->
          Terrat_github.get_installation_access_token config (CCInt64.to_int installation_id))

    let pre_hook_output_texts outputs =
      let module Output = Terrat_api_components_hook_outputs.Pre.Items in
      let module Text = Terrat_api_components_output_text in
      let module Run = Terrat_api_components_workflow_output_run in
      let module Checkout = Terrat_api_components_workflow_output_checkout in
      let module Ce = Terrat_api_components_workflow_output_cost_estimation in
      let module Oidc = Terrat_api_components_workflow_output_oidc in
      outputs
      |> CCList.filter_map (function
             | Output.Workflow_output_run
                 Run.
                   {
                     workflow_step = Workflow_step.{ type_; cmd; _ };
                     outputs = Some Text.{ text; output_key };
                     success;
                     _;
                   } ->
                 Some
                   Workflow_step_output.
                     {
                       key = output_key;
                       text;
                       success;
                       step_type = type_;
                       details = Some (CCString.concat " " cmd);
                     }
             | Output.Workflow_output_oidc
                 Oidc.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Some Text.{ text; output_key };
                     success;
                     _;
                   }
             | Output.Workflow_output_checkout
                 Checkout.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Text.{ text; output_key };
                     success;
                   }
             | Output.Workflow_output_cost_estimation
                 Ce.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Outputs.Output_text Text.{ text; output_key };
                     success;
                     _;
                   } ->
                 Some
                   Workflow_step_output.
                     { key = output_key; text; success; step_type = type_; details = None }
             | Output.Workflow_output_run
                 Run.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ }
             | Output.Workflow_output_oidc
                 Oidc.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ } ->
                 Some
                   Workflow_step_output.
                     { key = None; text = ""; success; step_type = type_; details = None }
             | Output.Workflow_output_env _
             | Output.Workflow_output_cost_estimation
                 Ce.{ outputs = Outputs.Output_cost_estimation _; _ } -> None)

    let post_hook_output_texts (outputs : Terrat_api_components_hook_outputs.Post.t) =
      let module Output = Terrat_api_components_hook_outputs.Post.Items in
      let module Text = Terrat_api_components_output_text in
      let module Run = Terrat_api_components_workflow_output_run in
      let module Oidc = Terrat_api_components_workflow_output_oidc in
      let module Drift_create_issue = Terrat_api_components_workflow_output_drift_create_issue in
      outputs
      |> CCList.filter_map (function
             | Output.Workflow_output_run
                 Run.
                   {
                     workflow_step = Workflow_step.{ type_; cmd; _ };
                     outputs = Some Text.{ text; output_key };
                     success;
                     _;
                   } ->
                 Some
                   Workflow_step_output.
                     {
                       key = output_key;
                       text;
                       success;
                       step_type = type_;
                       details = Some (CCString.concat " " cmd);
                     }
             | Output.Workflow_output_oidc
                 Oidc.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Some Text.{ text; output_key };
                     success;
                     _;
                   }
             | Output.Workflow_output_drift_create_issue
                 Drift_create_issue.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Some Text.{ text; output_key };
                     success;
                     _;
                   } ->
                 Some
                   Workflow_step_output.
                     { key = output_key; text; success; step_type = type_; details = None }
             | Output.Workflow_output_run
                 Run.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ }
             | Output.Workflow_output_oidc
                 Oidc.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ }
             | Output.Workflow_output_drift_create_issue
                 Drift_create_issue.
                   { workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ } ->
                 Some
                   Workflow_step_output.
                     { key = None; text = ""; success; step_type = type_; details = None }
             | Output.Workflow_output_env _ -> None)

    let workflow_output_texts outputs =
      let module Output = Terrat_api_components_workflow_outputs.Items in
      let module Run = Terrat_api_components_workflow_output_run in
      let module Init = Terrat_api_components_workflow_output_init in
      let module Plan = Terrat_api_components_workflow_output_plan in
      let module Apply = Terrat_api_components_workflow_output_apply in
      let module Text = Terrat_api_components_output_text in
      let module Output_plan = Terrat_api_components_output_plan in
      let module Oidc = Terrat_api_components_workflow_output_oidc in
      outputs
      |> CCList.flat_map (function
             | Output.Workflow_output_run
                 Run.
                   {
                     workflow_step = Workflow_step.{ type_; cmd; _ };
                     outputs = Some Text.{ text; output_key };
                     success;
                     _;
                   } ->
                 [
                   Workflow_step_output.
                     {
                       key = output_key;
                       text;
                       success;
                       step_type = type_;
                       details = Some (CCString.concat " " cmd);
                     };
                 ]
             | Output.Workflow_output_oidc
                 Oidc.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Some Text.{ text; output_key };
                     success;
                     _;
                   }
             | Output.Workflow_output_init
                 Init.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Some Text.{ text; output_key };
                     success;
                     _;
                   }
             | Output.Workflow_output_plan
                 Plan.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Some (Plan.Outputs.Output_text Text.{ text; output_key });
                     success;
                     _;
                   }
             | Output.Workflow_output_apply
                 Apply.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Some Text.{ text; output_key };
                     success;
                     _;
                   } ->
                 [
                   Workflow_step_output.
                     { step_type = type_; text; key = output_key; success; details = None };
                 ]
             | Output.Workflow_output_plan
                 Plan.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Some (Plan.Outputs.Output_plan Output_plan.{ plan; plan_text; _ });
                     success;
                     _;
                   } ->
                 [
                   Workflow_step_output.
                     {
                       step_type = type_;
                       text = plan_text;
                       key = Some "plan_text";
                       success;
                       details = None;
                     };
                   Workflow_step_output.
                     { step_type = type_; text = plan; key = Some "plan"; success; details = None };
                 ]
             | Output.Workflow_output_run _
             | Output.Workflow_output_oidc _
             | Output.Workflow_output_plan _
             | Output.Workflow_output_env _
             | Output.Workflow_output_init Init.{ outputs = None; _ }
             | Output.Workflow_output_apply Apply.{ outputs = None; _ } -> [])

    let create_run_output ~compact_view run_type results denied_dirspaces =
      let module Wmr = Terrat_api_components.Work_manifest_result in
      let module R = Terrat_api_work_manifest.Results.Request_body in
      let module Dirspace_result_compare = struct
        type t = bool * string * string [@@deriving ord]
      end in
      let dirspaces =
        results.R.dirspaces
        |> CCList.sort
             (fun
               Wmr.{ path = p1; workspace = w1; success = s1; _ }
               Wmr.{ path = p2; workspace = w2; success = s2; _ }
             -> Dirspace_result_compare.compare (s1, p1, w1) (s2, p2, w2))
      in
      let maybe_credentials_error =
        dirspaces
        |> CCList.exists (fun Wmr.{ outputs; _ } ->
               let module Text = Terrat_api_components_output_text in
               let texts = workflow_output_texts outputs in
               CCList.exists
                 (fun Workflow_step_output.{ text; _ } ->
                   CCList.exists
                     (fun sub -> CCString.find ~sub text <> -1)
                     maybe_credential_error_strings)
                 texts)
      in
      let module Hook_outputs = Terrat_api_components.Hook_outputs in
      let pre = results.R.overall.R.Overall.outputs.Hook_outputs.pre in
      let post = results.R.overall.R.Overall.outputs.Hook_outputs.post in
      let cost_estimation =
        let module Wce = Terrat_api_components_workflow_output_cost_estimation in
        let module Ce = Terrat_api_components_output_cost_estimation in
        pre
        |> CCList.filter_map (function
               | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_cost_estimation
                   {
                     Wce.outputs = Wce.Outputs.Output_cost_estimation Ce.{ cost_estimation; _ };
                     success = true;
                     _;
                   } -> Some cost_estimation
               | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_run _
               | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_oidc _
               | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_env _
               | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_checkout _
               | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_cost_estimation _ ->
                   None)
        |> CCOption.of_list
        |> CCOption.map (function
               | Ce.Cost_estimation.
                   { currency; total_monthly_cost; prev_monthly_cost; diff_monthly_cost; dirspaces }
               ->
               Snabela.Kv.(
                 Map.of_list
                   [
                     ("prev_monthly_cost", float prev_monthly_cost);
                     ("total_monthly_cost", float total_monthly_cost);
                     ("diff_monthly_cost", float diff_monthly_cost);
                     ("currency", string currency);
                     ( "dirspaces",
                       list
                         (CCList.map
                            (fun Ce.Cost_estimation.Dirspaces.Items.
                                   {
                                     path;
                                     workspace;
                                     total_monthly_cost;
                                     prev_monthly_cost;
                                     diff_monthly_cost;
                                   } ->
                              Map.of_list
                                [
                                  ("dir", string path);
                                  ("workspace", string workspace);
                                  ("prev_monthly_cost", float prev_monthly_cost);
                                  ("total_monthly_cost", float total_monthly_cost);
                                  ("diff_monthly_cost", float diff_monthly_cost);
                                ])
                            dirspaces) );
                   ]))
      in
      let kv_of_workflow_step steps =
        Snabela.Kv.(
          list
            (CCList.map
               (fun Workflow_step_output.{ key; text; success; step_type; details } ->
                 Map.of_list
                   (CCList.concat
                      [
                        [
                          ("text", string text);
                          ("success", bool success);
                          ("step_type", string step_type);
                        ]
                        @ CCOption.map_or ~default:[] (fun key -> [ (key, bool true) ]) key
                        @ CCOption.map_or
                            ~default:[]
                            (fun details ->
                              [
                                ( "details",
                                  string
                                    (match step_type with
                                    | "run" -> "`" ^ details ^ "`"
                                    | _ -> details) );
                              ])
                            details;
                      ]))
               steps))
      in
      let kv =
        Snabela.Kv.(
          Map.of_list
            (CCList.flatten
               [
                 CCOption.map_or
                   ~default:[]
                   (fun cost_estimation -> [ ("cost_estimation", list [ cost_estimation ]) ])
                   cost_estimation;
                 [
                   ("maybe_credentials_error", bool maybe_credentials_error);
                   ("overall_success", bool results.R.overall.R.Overall.success);
                   ("pre_hooks", kv_of_workflow_step (pre_hook_output_texts pre));
                   ("post_hooks", kv_of_workflow_step (post_hook_output_texts post));
                   ("compact_view", bool compact_view);
                   ("compact_dirspaces", bool (CCList.length dirspaces > 5));
                   ( "results",
                     list
                       (CCList.map
                          (fun Wmr.{ path; workspace; success; outputs; _ } ->
                            let module Text = Terrat_api_components_output_text in
                            Map.of_list
                              [
                                ("dir", string path);
                                ("workspace", string workspace);
                                ("success", bool success);
                                ("outputs", kv_of_workflow_step (workflow_output_texts outputs));
                              ])
                          dirspaces) );
                 ];
                 (match denied_dirspaces with
                 | [] -> []
                 | dirspaces ->
                     [
                       ( "denied_dirspaces",
                         list
                           (CCList.map
                              (fun (Terrat_change.Dirspace.{ dir; workspace }, policy) ->
                                Map.of_list
                                  (CCList.flatten
                                     [
                                       [ ("dir", string dir); ("workspace", string workspace) ];
                                       (match policy with
                                       | Some policy ->
                                           [
                                             ( "policy",
                                               list
                                                 (CCList.map
                                                    (fun p -> Map.of_list [ ("item", string p) ])
                                                    policy) );
                                           ]
                                       | None -> []);
                                     ]))
                              denied_dirspaces) );
                     ]);
               ]))
      in
      let tmpl =
        match Terrat_work_manifest.Unified_run_type.of_run_type run_type with
        | Terrat_work_manifest.Unified_run_type.Plan -> Tmpl.plan_complete
        | Terrat_work_manifest.Unified_run_type.Apply -> Tmpl.apply_complete
      in
      match Snabela.apply tmpl kv with
      | Ok body -> body
      | Error (#Snabela.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : ERROR : %s" (Snabela.show_err err));
          assert false

    let rec iterate_comment_posts ?(compact_view = false) t pull_number results denied_dirspaces =
      let module Wm = Terrat_work_manifest in
      let open Abb.Future.Infix_monad in
      let output =
        create_run_output ~compact_view t.work_manifest.Wm.run_type results denied_dirspaces
      in
      Metrics.Run_output_histogram.observe
        (Metrics.run_output_chars ~r:t.work_manifest.Wm.run_type ~c:compact_view)
        (CCFloat.of_int (CCString.length output));
      Terrat_github.publish_comment
        ~config:t.config
        ~access_token:t.access_token
        ~owner:t.owner
        ~repo:t.name
        ~pull_number
        output
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Terrat_github.publish_comment_err as err) when not compact_view ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ITERATE_COMMENT_POST : %s"
                t.request_id
                (Terrat_github.show_publish_comment_err err));
          iterate_comment_posts ~compact_view:true t pull_number results denied_dirspaces
      | Error (#Terrat_github.publish_comment_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ITERATE_COMMENT_POST : %s"
                t.request_id
                (Terrat_github.show_publish_comment_err err));
          Terrat_github.publish_comment
            ~config:t.config
            ~access_token:t.access_token
            ~owner:t.owner
            ~repo:t.name
            ~pull_number
            Tmpl.comment_too_large

    let complete_status_checks t results =
      let module Wm = Terrat_work_manifest in
      let module Wmr = Terrat_api_components.Work_manifest_result in
      let module R = Terrat_api_work_manifest.Results.Request_body in
      let module Hooks_output = Terrat_api_components.Hook_outputs in
      let unified_run_type =
        Terrat_work_manifest.(
          t.work_manifest.Wm.run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
      in
      let success = results.R.overall.R.Overall.success in
      let description = if success then "Completed" else "Failed" in
      let target_url =
        Printf.sprintf "https://github.com/%s/%s/actions/runs/%s" t.owner t.name t.run_id
      in
      let pre_hooks_status =
        let module Run = Terrat_api_components.Workflow_output_run in
        let module Env = Terrat_api_components.Workflow_output_env in
        let module Checkout = Terrat_api_components.Workflow_output_checkout in
        let module Ce = Terrat_api_components.Workflow_output_cost_estimation in
        let module Oidc = Terrat_api_components.Workflow_output_oidc in
        results.R.overall.R.Overall.outputs.Hooks_output.pre
        |> CCList.exists
             Hooks_output.Pre.Items.(
               function
               | Workflow_output_run Run.{ success; _ }
               | Workflow_output_env Env.{ success; _ }
               | Workflow_output_checkout Checkout.{ success; _ }
               | Workflow_output_cost_estimation Ce.{ success; _ }
               | Workflow_output_oidc Oidc.{ success; _ } -> not success)
        |> function
        | true -> Terrat_commit_check.Status.Failed
        | false -> Terrat_commit_check.Status.Completed
      in
      let post_hooks_status =
        let module Run = Terrat_api_components.Workflow_output_run in
        let module Env = Terrat_api_components.Workflow_output_env in
        let module Oidc = Terrat_api_components.Workflow_output_oidc in
        let module Drift_create_issue = Terrat_api_components.Workflow_output_drift_create_issue in
        results.R.overall.R.Overall.outputs.Hooks_output.post
        |> CCList.exists
             Hooks_output.Post.Items.(
               function
               | Workflow_output_run Run.{ success; _ }
               | Workflow_output_env Env.{ success; _ }
               | Workflow_output_oidc Oidc.{ success; _ }
               | Workflow_output_drift_create_issue Drift_create_issue.{ success; _ } -> not success)
        |> function
        | true -> Terrat_commit_check.Status.Failed
        | false -> Terrat_commit_check.Status.Completed
      in
      let commit_statuses =
        let aggregate =
          Terrat_commit_check.
            [
              make
                ~details_url:target_url
                ~description
                ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
                ~status:pre_hooks_status;
              make
                ~details_url:target_url
                ~description
                ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
                ~status:post_hooks_status;
            ]
        in
        let dirspaces =
          CCList.map
            (fun Wmr.{ path; workspace; success; _ } ->
              let status = Terrat_commit_check.Status.(if success then Completed else Failed) in
              let description = if success then "Completed" else "Failed" in
              Terrat_commit_check.make
                ~details_url:target_url
                ~description
                ~title:(Printf.sprintf "terrateam %s: %s %s" unified_run_type path workspace)
                ~status)
            results.R.dirspaces
        in
        aggregate @ dirspaces
      in
      Terrat_github_commit_check.create
        ~config:t.config
        ~access_token:t.access_token
        ~owner:t.owner
        ~repo:t.name
        ~ref_:t.work_manifest.Wm.hash
        commit_statuses

    let publish_results t pull_number results denied_dirspaces =
      Abbs_time_it.run
        (fun d ->
          Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : PUBLISH_RESULTS : %f" t.request_id d))
        (fun () ->
          Abbs_future_combinators.Infix_result_app.(
            (fun _ _ -> ())
            <$> Abbs_time_it.run
                  (fun d ->
                    Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : COMMENT : %f" t.request_id d))
                  (fun () -> iterate_comment_posts t pull_number results denied_dirspaces)
            <*> Abbs_time_it.run
                  (fun d ->
                    Logs.info (fun m ->
                        m "GITHUB_EVALUATOR : %s : COMPLETE_COMMIT_STATUSES : %f" t.request_id d))
                  (fun () -> complete_status_checks t results)))

    let maybe_publish_results t result denied_dirspaces =
      let module Wm = Terrat_work_manifest in
      match t.work_manifest.Wm.src with
      | Wm.Kind.Pull_request pull_number -> publish_results t pull_number result denied_dirspaces
      | Wm.Kind.Drift _ -> Abb.Future.return (Ok ())

    let store ~request_id config storage work_manifest_id results =
      let run =
        let module Rb = Terrat_api_work_manifest.Results.Request_body in
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.tx db ~f:(fun () ->
                fetch_work_manifest db work_manifest_id
                >>= function
                | ((installation_id, owner, name, pull_number), work_manifest) :: _ -> (
                    log_work_manifest_result
                      request_id
                      work_manifest_id
                      results.Rb.overall.Rb.Overall.success;
                    complete_work_manifest request_id db work_manifest_id
                    >>= fun run_time ->
                    store_dirspace_results request_id db work_manifest_id results.Rb.dirspaces
                    >>= fun () ->
                    fetch_access_token request_id config installation_id
                    >>= fun access_token ->
                    match work_manifest.Terrat_work_manifest.run_id with
                    | Some run_id ->
                        let t =
                          {
                            access_token;
                            config;
                            installation_id;
                            name;
                            owner;
                            request_id;
                            storage;
                            work_manifest;
                            run_id;
                          }
                        in
                        fetch_denied_dirspaces request_id db work_manifest_id
                        >>= fun denied_dirspaces ->
                        maybe_publish_results t results denied_dirspaces
                        >>= fun () -> Abb.Future.return (Ok (run_time, t))
                    | None -> Abb.Future.return (Error `Work_manifest_missing_run_id))
                | [] -> Abb.Future.return (Error `Workflow_not_found)))
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok (run_time, t) ->
          let module Wm = Terrat_work_manifest in
          Metrics.Work_manifest_run_time_histogram.observe
            (Metrics.work_manifest_run_time_duration_seconds
               (Wm.Run_type.to_string t.work_manifest.Wm.run_type))
            run_time;
          Abb.Future.return (Ok t)
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : STORE : %a : %a"
                request_id
                Uuidm.pp
                work_manifest_id
                Pgsql_pool.pp_err
                err);
          Abb.Future.return (Error `Error)
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : STORE : %a : %a"
                request_id
                Uuidm.pp
                work_manifest_id
                Pgsql_io.pp_err
                err);
          Abb.Future.return (Error `Error)
      | Error (#Terrat_github.publish_comment_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : STORE : %a : %a"
                request_id
                Uuidm.pp
                work_manifest_id
                Terrat_github.pp_publish_comment_err
                err);
          Abb.Future.return (Error `Error)
      | Error (#Terrat_github.get_installation_access_token_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : STORE : %a : %a"
                request_id
                Uuidm.pp
                work_manifest_id
                Terrat_github.pp_get_installation_access_token_err
                err);
          Abb.Future.return (Error `Error)
      | Error `Work_manifest_missing_run_id ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : STORE : %a : WORK_MANIFEST_MISSING_RUN_ID"
                request_id
                Uuidm.pp
                work_manifest_id);
          Abb.Future.return (Error `Error)
      | Error `Workflow_not_found ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : STORE : %a : WORKFLOW_NOT_FOUND"
                request_id
                Uuidm.pp
                work_manifest_id);
          Abb.Future.return (Error `Error)

    let publish_msg_automerge t pull_number msg =
      let kv = Snabela.Kv.(Map.of_list [ ("msg", string msg) ]) in
      match Snabela.apply Tmpl.automerge_error kv with
      | Ok body -> (
          let open Abb.Future.Infix_monad in
          Terrat_github.publish_comment
            ~config:t.config
            ~access_token:t.access_token
            ~owner:t.owner
            ~repo:t.name
            ~pull_number
            body
          >>= function
          | Ok () -> Abb.Future.return (Ok ())
          | Error (#Terrat_github.publish_comment_err as err) ->
              Prmths.Counter.inc_one Metrics.github_errors_total;
              Logs.err (fun m ->
                  m
                    "GITHUB_EVALUATOR : %s : PUBLISH_MSG_AUTOMERGE : %a"
                    t.request_id
                    Terrat_github.pp_publish_comment_err
                    err);
              Abb.Future.return (Error `Error))
      | Error (#Snabela.err as err) ->
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : PUBLISH_MSG_AUTOMERGE : %a" t.request_id Snabela.pp_err err);
          Abb.Future.return (Error `Error)
  end
end

module S = struct
  module Event = Ev
  module Drift = Dr
  module Runner = R
  module Work_manifest = Wm
end

include Terrat_evaluator.Make (S)

module Push = struct
  module Sql = struct
    let select_repository =
      Pgsql_io.Typed_sql.(
        sql
        // (* repository *) Ret.bigint
        /^ "select id from github_installation_repositories where installation_id = \
            $installation_id and owner = $owner and name = $name"
        /% Var.bigint "installation_id"
        /% Var.text "owner"
        /% Var.text "name")

    let upsert_drift_schedule =
      Pgsql_io.Typed_sql.(
        sql
        // (* repository *) Ret.bigint
        /^ "insert into github_drift_schedules (repository, schedule, reconcile) values($repo, \
            $schedule, $reconcile) on conflict (repository) do update set (schedule, reconcile) = \
            (excluded.schedule, excluded.reconcile) where (github_drift_schedules.schedule, \
            github_drift_schedules.reconcile) <> (excluded.schedule, excluded.reconcile) returning \
            repository"
        /% Var.bigint "repo"
        /% Var.text "schedule"
        /% Var.boolean "reconcile")

    let delete_drift_schedule =
      Pgsql_io.Typed_sql.(
        sql
        /^ "delete from github_drift_schedules where repository in (select id from \
            github_installation_repositories where installation_id = $installation_id and owner = \
            $owner and name = $name)"
        /% Var.bigint "installation_id"
        /% Var.text "owner"
        /% Var.text "name")
  end

  let enable_drift_schedule storage installation_id owner name schedule reconcile =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.tx db ~f:(fun () ->
            Pgsql_io.Prepared_stmt.fetch
              db
              Sql.select_repository
              ~f:CCFun.id
              (CCInt64.of_int installation_id)
              owner
              name
            >>= function
            | repository_id :: _ ->
                Pgsql_io.Prepared_stmt.fetch
                  db
                  Sql.upsert_drift_schedule
                  ~f:CCFun.id
                  repository_id
                  schedule
                  reconcile
            | [] -> assert false))

  let disable_drift_schedule storage installation_id owner name =
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.execute
          db
          Sql.delete_drift_schedule
          (CCInt64.of_int installation_id)
          owner
          name)

  let update_drift_schedule request_id config storage installation_id owner name =
    let module D = Terrat_repo_config.Drift in
    function
    | Some { D.enabled = true; schedule; reconcile } ->
        let open Abbs_future_combinators.Infix_result_monad in
        Logs.info (fun m ->
            m
              "GITHUB_EVALUATOR : %s : DRIFT : ENABLE : owner=%s : name=%s : schedule=%s : \
               reconcile=%s"
              request_id
              owner
              name
              schedule
              (Bool.to_string reconcile));
        enable_drift_schedule storage installation_id owner name schedule reconcile
        >>= fun repositories ->
        Abbs_future_combinators.to_result
          (Abbs_future_combinators.List.iter
             ~f:(fun repository ->
               Logs.info (fun m ->
                   m "GITHUB_EVALUATOR : %s : DRIFT : RUNNING : repo_id=%Ld" request_id repository);
               Drift.run_schedule
                 config
                 storage
                 {
                   Dr.Schedule.installation_id = CCInt64.of_int installation_id;
                   repository;
                   owner;
                   name;
                   reconcile;
                 })
             repositories)
        >>= fun () -> Abbs_future_combinators.to_result (R.run ~request_id:"DRIFT" config storage)
    | Some { D.enabled = false; _ } | None ->
        Logs.info (fun m ->
            m "GITHUB_EVALUATOR : %s : DRIFT : DISABLE : owner=%s : name=%s" request_id owner name);
        disable_drift_schedule storage installation_id owner name

  let eval ~request_id ~installation_id ~owner ~name ~default_branch config storage =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.get_installation_access_token config installation_id
      >>= fun access_token ->
      Terrat_github.fetch_repo_config
        ~config
        ~python:(Terrat_config.python_exec config)
        ~access_token
        ~owner
        ~repo:name
        default_branch
      >>= fun repo_config ->
      let module C = Terrat_repo_config.Version_1 in
      let drift_config = repo_config.C.drift in
      update_drift_schedule request_id config storage installation_id owner name drift_config
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok () -> Abb.Future.return ()
    | Error (#Pgsql_pool.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : DRIFT : ERROR : %a" request_id Pgsql_pool.pp_err err);
        Abb.Future.return ()
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : DRIFT : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return ()
    | Error (#Terrat_github.fetch_repo_config_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : DRIFT : ERROR : %a"
              request_id
              Terrat_github.pp_fetch_repo_config_err
              err);
        Abb.Future.return ()
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : DRIFT : ERROR : %a"
              request_id
              Terrat_github.pp_get_installation_access_token_err
              err);
        Abb.Future.return ()
end
