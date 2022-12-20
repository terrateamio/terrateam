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
        [ Terrat_work_manifest.Pull_request.Run_type.to_string r; Bool.to_string c ]

  let run_overall_result_count =
    let help = "Count of the results of overall runs" in
    Prmths.Counter.v_label
      ~label_name:"success"
      ~help
      ~namespace
      ~subsystem
      "run_overall_result_count"
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
        // (* pull_number *) Ret.bigint
        // (* run_type *) Ret.ud' Terrat_work_manifest.Pull_request.Run_type.of_string
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
      Terrat_work_manifest.Pull_request.(
        run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
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
    Terrat_github.publish_comment
      ~access_token
      ~owner
      ~repo
      ~pull_number:(CCInt64.to_int pull_number)
      tmpl
    >>= fun () ->
    let unified_run_type =
      Terrat_work_manifest.Pull_request.(
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
    Terrat_github_commit_check.create ~access_token ~owner ~repo ~ref_:sha commit_statuses

  let run_workflow ~config ~access_token ~work_token ~owner ~repo ~branch ~workflow_id () =
    let client = Terrat_github.create (`Token access_token) in
    Githubc2_abb.call
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
            Terrat_github.load_workflow ~access_token ~owner ~repo
            >>= function
            | Some workflow_id -> (
                Abbs_time_it.run
                  (fun t ->
                    Logs.info (fun m ->
                        m "GITHUB_EVALUATOR : %s : START_COMMIT_STATUSES : %f" request_id t))
                  (fun () ->
                    start_commit_statuses ~access_token ~owner ~repo ~sha ~run_type ~dirspaces ())
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
                    run' request_id access_token_cache config db
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
                Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : MISSING_WORKFLOW" request_id);
                abort_work_manifest
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
        /^ "insert into github_dirspaces (base_sha, path, repository, sha, workspace) select * \
            from unnest($base_sha, $path, $repository, $sha, $workspace) on conflict (repository, \
            sha, path, workspace) do nothing"
        /% Var.(str_array (text "base_sha"))
        /% Var.(str_array (text "path"))
        /% Var.(array (bigint "repository"))
        /% Var.(str_array (text "sha"))
        /% Var.(str_array (text "workspace")))

    let insert_work_manifest =
      Pgsql_io.Typed_sql.(
        sql
        // (* id *) Ret.uuid
        // (* state *) Ret.text
        // (* created_at *) Ret.text
        /^ read "insert_github_work_manifest.sql"
        /% Var.text "base_sha"
        /% Var.bigint "pull_number"
        /% Var.bigint "repository"
        /% Var.text "run_type"
        /% Var.text "sha"
        /% Var.text "tag_query")

    let insert_work_manifest_dirspaceflow =
      Pgsql_io.Typed_sql.(
        sql
        /^ "insert into github_work_manifest_dirspaceflows (work_manifest, path, workspace, \
            workflow_idx) select * from unnest($work_manifest, $path, $workspace, $workflow_idx)"
        /% Var.(str_array (uuid "work_manifest"))
        /% Var.(str_array (text "path"))
        /% Var.(str_array (text "workspace"))
        /% Var.(array (option (smallint "workflow_idx"))))

    let select_out_of_diff_applies =
      Pgsql_io.Typed_sql.(
        sql
        // (* path *) Ret.text
        // (* workspace *) Ret.text
        /^ read "select_github_out_of_diff_applies.sql"
        /% Var.bigint "repository"
        /% Var.bigint "pull_number")

    let select_conflicting_work_manifests_in_repo =
      Pgsql_io.Typed_sql.(
        sql
        // (* base_hash *) Ret.text
        // (* created_at *) Ret.text
        // (* hash *) Ret.text
        // (* id *) Ret.uuid
        // (* run_id *) Ret.(option text)
        // (* run_type *) Ret.text
        // (* tag_query *) Ret.text
        // (* base_branch *) Ret.text
        // (* branch *) Ret.text
        // (* pull_number *) Ret.bigint
        // (* pr state *) Ret.text
        // (* merged_hash *) Ret.(option text)
        // (* merged_at *) Ret.(option text)
        // (* state *) Ret.(ud' Terrat_work_manifest.State.of_string)
        /^ read "select_github_conflicting_work_manifests_in_repo.sql"
        /% Var.bigint "repository"
        /% Var.bigint "pull_number"
        /% Var.(ud (text "run_type") Terrat_work_manifest.Pull_request.Run_type.to_string))

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

    let insert_pull_request_unlock =
      Pgsql_io.Typed_sql.(
        sql
        /^ "insert into github_pull_request_unlocks (repository, pull_number) values ($repository, \
            $pull_number)"
        /% Var.bigint "repository"
        /% Var.bigint "pull_number")

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
      tag_query : Terrat_tag_set.t;
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
            "GITHUB_EVALUATOR : %s : MAKE : %s : %s : %d : %s : %s"
            request_id
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            pull_number
            (Terrat_evaluator.Event.Event_type.to_string event_type)
            (Terrat_tag_set.to_string tag_query));
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

  let fetch_diff ~request_id ~access_token ~owner ~repo ~base_sha head_sha =
    let open Abbs_future_combinators.Infix_result_monad in
    Terrat_github.compare_commits ~access_token ~owner ~repo (base_sha, head_sha)
    >>= function
    | [] -> Abb.Future.return (Error `Bad_compare_response)
    | files ->
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
      | Pr.State.Open -> (None, None, "open")
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

  let store_pull_request_work_manifest db event work_manifest denied_dirspaces =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      let module Wm = Terrat_work_manifest in
      let module Pr = Terrat_pull_request in
      let module Ch = Terrat_change in
      let module Cm = Terrat_change_match in
      let module Ac = Terrat_access_control in
      let pull_request = work_manifest.Terrat_work_manifest.src in
      let hash =
        match pull_request.Pr.state with
        | Pr.State.(Merged Merged.{ merged_hash; _ }) -> merged_hash
        | _ -> work_manifest.Wm.hash
      in
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : STORE_WORK_MANIFEST : %s : %s : %Ld : %s : %s"
            (T.request_id event)
            event.T.repository.Gw.Repository.owner.Gw.User.login
            event.T.repository.Gw.Repository.name
            pull_request.Pr.id
            work_manifest.Wm.base_hash
            hash);
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.insert_work_manifest
        ~f:(fun id state created_at -> (id, state, created_at))
        work_manifest.Wm.base_hash
        pull_request.Pr.id
        (CCInt64.of_int event.T.repository.Gw.Repository.id)
        (Terrat_work_manifest.Pull_request.Run_type.to_string work_manifest.Wm.run_type)
        hash
        (Terrat_tag_set.to_string work_manifest.Wm.tag_query)
      >>= function
      | [] -> assert false
      | (id, state, created_at) :: _ ->
          Abbs_future_combinators.List_result.iter
            ~f:(fun changes ->
              Pgsql_io.Prepared_stmt.execute
                db
                Sql.insert_work_manifest_dirspaceflow
                (CCList.replicate (CCList.length changes) id)
                (CCList.map
                   (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; _ }; _ } -> dir)
                   changes)
                (CCList.map
                   (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.workspace; _ }; _ } ->
                     workspace)
                   changes)
                (CCList.map
                   (fun Terrat_change.{ Dirspaceflow.workflow_idx; _ } -> workflow_idx)
                   changes))
            (CCList.chunks 500 work_manifest.Wm.changes)
          >>= fun () ->
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
                     CCOption.map
                       (fun policy -> Yojson.Safe.to_string (Policy.to_yojson policy))
                       policy)
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
          Abb.Future.return (Ok wm)
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

  let fetch_repo_config event pull_request ref_ =
    let open Abb.Future.Infix_monad in
    Terrat_github.fetch_repo_config
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

  let fetch_pull_request event =
    let owner = event.T.repository.Gw.Repository.owner.Gw.User.login in
    let repo = event.T.repository.Gw.Repository.name in
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.fetch_pull_request
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
          let merged_sha = merge_commit_sha in
          let branch_name = Head.(head.primary.Primary.ref_) in
          let hash = CCOption.get_or ~default:head_sha merged_sha in
          let draft = CCOption.get_or ~default:false draft in
          fetch_diff
            ~request_id:event.T.request_id
            ~access_token:event.T.access_token
            ~owner
            ~repo
            ~base_sha
            hash
          >>= fun diff ->
          Logs.debug (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGEABLE : merged=%s : mergeable_state=%s"
                event.T.request_id
                (Bool.to_string merged)
                mergeable_state);
          Abb.Future.return
            (Ok
               Terrat_pull_request.
                 {
                   base_branch_name;
                   base_hash = base_sha;
                   branch_name;
                   diff;
                   hash = head_sha;
                   id = CCInt64.of_int event.T.pull_number;
                   state =
                     (match (state, merged, merged_sha, merged_at) with
                     | "open", _, _, _ -> State.Open
                     | "closed", true, Some merged_hash, Some merged_at ->
                         State.(Merged Merged.{ merged_hash; merged_at })
                     | "closed", false, _, _ -> State.Closed
                     | _, _, _, _ -> assert false);
                   checks =
                     merged
                     || CCList.mem
                          ~eq:CCString.equal
                          mergeable_state
                          [ "clean"; "unstable"; "has_hooks" ];
                   mergeable;
                   draft;
                 })
      | (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _) as err ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ERROR : %a"
                event.T.request_id
                Githubc2_pulls.Get.Responses.pp
                err);
          Abb.Future.return (Error `Error)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
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
    | Error `Bad_compare_response ->
        Logs.info (fun m ->
            m
              "GITHUB_EVALUATOR : %s : NO_FILES_CHANGED : %s : %s : %d"
              (T.request_id event)
              owner
              repo
              event.T.pull_number);
        Abb.Future.return (Error `Error)

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

  let fetch_tree event ~sha =
    let open Abb.Future.Infix_monad in
    let owner = event.T.repository.Gw.Repository.owner.Gw.User.login in
    let repo = event.T.repository.Gw.Repository.name in
    Terrat_github.get_tree ~access_token:event.T.access_token ~owner ~repo ~sha ()
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
        Sql.select_conflicting_work_manifests_in_repo
        ~f:
          (fun base_hash
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
               state ->
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
                  | "open", _, _ -> Terrat_pull_request.State.Open
                  | "closed", _, _ -> Terrat_pull_request.State.Closed
                  | "merged", Some merged_hash, Some merged_at ->
                      Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                  | _ -> assert false);
                checks = true;
                mergeable = None;
                draft = false;
              }
          in
          Terrat_work_manifest.
            {
              base_hash;
              changes = ();
              completed_at = None;
              created_at;
              hash;
              id;
              src = pull_request;
              run_id;
              run_type =
                CCOption.get_exn_or
                  ("run type " ^ run_type)
                  (Pull_request.Run_type.of_string run_type);
              state;
              tag_query = Terrat_tag_set.of_string tag_query;
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
      ~f:
        (fun dir workspace base_branch branch base_hash hash merged_hash merged_at pull_number state ->
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
                | "open", _, _ -> Terrat_pull_request.State.Open
                | "closed", _, _ -> Terrat_pull_request.State.Closed
                | "merged", Some merged_hash, Some merged_at ->
                    Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                | _ -> assert false);
              checks = true;
              mergeable = None;
              draft = false;
            } ))
      (CCInt64.of_int event.T.repository.Gw.Repository.id)
      pull_request.Terrat_pull_request.id
      (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
      (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
    >>= function
    | Ok res -> Abb.Future.return (Ok (Terrat_evaluator.Event.Dirspace_map.of_list res))
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %s" (T.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let publish_comment msg_type event body =
    let open Abb.Future.Infix_monad in
    Terrat_github.publish_comment
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

  let unlock_pull_request storage event =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.insert_pull_request_unlock
            (CCInt64.of_int event.T.repository.Gw.Repository.id)
            (CCInt64.of_int event.T.pull_number)
          >>= fun () ->
          Terrat_github_plan_cleanup.clean_pull_request
            ~owner:event.T.repository.Gw.Repository.owner.Gw.User.login
            ~repo:event.T.repository.Gw.Repository.name
            ~pull_number:event.T.pull_number
            db)
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
        let prs = Terrat_evaluator.Event.Dirspace_map.to_list prs in
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
                       (fun Terrat_work_manifest.
                              {
                                created_at;
                                run_type;
                                state;
                                src = Terrat_pull_request.{ id; _ };
                                _;
                              } ->
                         Map.of_list
                           [
                             ("pull_number", string (CCInt64.to_string id));
                             ( "run_type",
                               string
                                 (CCString.capitalize_ascii
                                    Terrat_work_manifest.Pull_request.Unified_run_type.(
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
        let module Ar = Terrat_evaluator.Event.Msg.Apply_requirements in
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
    | Msg.Pull_request_not_mergeable _ ->
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

      let run_type = function
        | Some s :: rest ->
            let open CCOption in
            Terrat_work_manifest.Pull_request.Run_type.of_string s
            >>= fun run_type -> Some (run_type, rest)
        | _ -> None

      let tag_query = function
        | Some s :: rest -> Some (Terrat_tag_set.of_string s, rest)
        | _ -> None

      let select_github_parameters_from_work_manifest () =
        Pgsql_io.Typed_sql.(
          sql
          // (* installation_id *) Ret.bigint
          // (* owner *) Ret.text
          // (* name *) Ret.text
          // (* branch *) Ret.text
          // (* sha *) Ret.text
          // (* base_sha *) Ret.text
          // (* pull_number *) Ret.bigint
          // (* run_type *) Ret.ud run_type
          // (* run_id *) Ret.(option text)
          // (* run time *) Ret.double
          /^ read "select_github_parameters_from_work_manifest.sql"
          /% Var.uuid "id")

      let initiate_work_manifest =
        Pgsql_io.Typed_sql.(
          sql
          // (* bash_hash *) Ret.text
          // (* completed_at *) Ret.(option text)
          // (* created_at *) Ret.text
          // (* hash *) Ret.text
          // (* run_type *) Ret.ud' Terrat_work_manifest.Pull_request.Run_type.of_string
          // (* state *) Ret.ud' Terrat_work_manifest.State.of_string
          // (* tag_query *) Ret.ud tag_query
          // (* repository *) Ret.bigint
          // (* pull_number *) Ret.bigint
          // (* base_branch *) Ret.text
          // (* installation_id *) Ret.bigint
          // (* owner *) Ret.text
          // (* repo *) Ret.text
          /^ read "github_initiate_work_manifest.sql"
          /% Var.uuid "id"
          /% Var.text "run_id"
          /% Var.text "sha")

      let select_work_manifest =
        Pgsql_io.Typed_sql.(
          sql
          // (* bash_hash *) Ret.text
          // (* completed_at *) Ret.(option text)
          // (* created_at *) Ret.text
          // (* hash *) Ret.text
          // (* run_type *) Ret.ud' Terrat_work_manifest.Pull_request.Run_type.of_string
          // (* state *) Ret.ud' Terrat_work_manifest.State.of_string
          // (* tag_query *) Ret.ud tag_query
          // (* repository *) Ret.bigint
          // (* pull_number *) Ret.bigint
          // (* base_branch *) Ret.text
          // (* installation_id *) Ret.bigint
          // (* owner *) Ret.text
          // (* repo *) Ret.text
          /^ read "select_github_work_manifest.sql"
          /% Var.uuid "id"
          /% Var.text "run_id"
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

      let abort_work_manifest =
        Pgsql_io.Typed_sql.(
          sql
          /^ "update github_work_manifests set state = 'aborted', completed_at = now() where id = \
              $id and state in ('queued', 'running')"
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
    end

    module Tmpl = struct
      let work_manifest_already_run =
        "github_work_manifest_already_run.tmpl"
        |> Terrat_files_tmpl.read
        |> CCOption.get_exn_or "github_work_manifest_already_run.tmpl"
    end

    type t = {
      config : Terrat_config.t;
      access_token : string;
      owner : string;
      name : string;
      pull_number : int;
      hash : string;
      base_hash : string;
      request_id : string;
      run_id : string;
      work_manifest : Uuidm.t;
    }

    module Pull_request = struct
      module Lite = struct
        type t = (int64, unit, unit) Terrat_pull_request.t [@@deriving show]
      end

      type t = {
        repo_id : int64;
        pull_number : int64;
        base_branch : string;
      }
      [@@deriving show]
    end

    let create
        ~request_id
        ~work_manifest_id
        config
        storage
        { Terrat_api_components.Work_manifest_initiate.run_id; sha } =
      let open Abb.Future.Infix_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            (Sql.select_github_parameters_from_work_manifest ())
            ~f:
              (fun installation_id
                   owner
                   name
                   branch
                   _sha
                   base_sha
                   pull_number
                   run_type
                   _run_id
                   run_time ->
              (installation_id, owner, name, branch, base_sha, pull_number, run_type, run_time))
            work_manifest_id)
      >>= function
      | Ok ((installation_id, owner, name, branch, base_sha, pull_number, run_type, run_time) :: _)
        -> (
          Metrics.Work_manifest_run_time_histogram.observe
            (Metrics.work_manifest_wait_duration_seconds
               (Terrat_work_manifest.Pull_request.Run_type.to_string run_type))
            run_time;
          Terrat_github.get_installation_access_token config (CCInt64.to_int installation_id)
          >>= function
          | Ok access_token ->
              Abb.Future.return
                (Ok
                   {
                     config;
                     access_token;
                     owner;
                     name;
                     pull_number = CCInt64.to_int pull_number;
                     hash = sha;
                     base_hash = base_sha;
                     request_id;
                     run_id;
                     work_manifest = work_manifest_id;
                   })
          | Error (#Terrat_github.get_installation_access_token_err as err) ->
              Prmths.Counter.inc_one Metrics.github_errors_total;
              Logs.err (fun m ->
                  m
                    "GITHUB_EVALUATOR : %s : ERROR : %s"
                    request_id
                    (Terrat_github.show_get_installation_access_token_err err));
              Abb.Future.return (Error `Error))
      | Ok [] -> Abb.Future.return (Error `Work_manifest_not_found)
      | Error (#Pgsql_pool.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : ERROR : %s" request_id (Pgsql_pool.show_err err));
          Abb.Future.return (Error `Error)
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : ERROR : %s" request_id (Pgsql_io.show_err err));
          Abb.Future.return (Error `Error)

    let fetch_all_dirspaces ~python ~access_token ~owner ~repo hash =
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.fetch_repo_config ~python ~access_token ~owner ~repo hash
      >>= fun repo_config ->
      Terrat_github.get_tree ~access_token ~owner ~repo ~sha:hash ()
      >>= fun files ->
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
                    workflow_idx =
                      CCOption.map
                        fst
                        (CCList.find_idx
                           (fun Terrat_repo_config.Workflow_entry.{ tag_query; _ } ->
                             Terrat_change_match.match_tag_query
                               ~tag_query:(Terrat_tag_set.of_string tag_query)
                               change)
                           workflows);
                  })
              matches
          in
          Abb.Future.return
            (Ok
               (CCList.map
                  (fun Terrat_change.
                         { Dirspaceflow.dirspace = Dirspace.{ dir; workspace }; workflow_idx } ->
                    Terrat_api_components.Work_manifest_dir.
                      { path = dir; workspace; workflow = workflow_idx; rank = 0 })
                  dirspaceflows))
      | Error (`Bad_glob _ as err) -> Abb.Future.return (Error err)

    let to_response' t (Terrat_evaluator.Work_manifest.Pull_request work_manifest) =
      let module Wm = Terrat_work_manifest in
      let request_id = t.request_id in
      let changed_dirspaces =
        CCList.map
          (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; workspace }; workflow_idx } ->
            (* TODO: Provide correct rank *)
            Terrat_api_components.Work_manifest_dir.
              { path = dir; workspace; workflow = workflow_idx; rank = 0 })
          work_manifest.Wm.changes
      in
      match work_manifest.Wm.run_type with
      | Wm.Pull_request.Run_type.Plan | Wm.Pull_request.Run_type.Autoplan ->
          let open Abbs_future_combinators.Infix_result_monad in
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
                          ~python:(Terrat_config.python_exec t.config)
                          ~access_token:t.access_token
                          ~owner:t.owner
                          ~repo:t.name
                          t.base_hash)
                <*> Abbs_time_it.run
                      (fun time ->
                        Logs.info (fun m ->
                            m "GITHUB_EVALUATOR : %s : FETCH_DIRSPACES : %f" request_id time))
                      (fun () ->
                        fetch_all_dirspaces
                          ~python:(Terrat_config.python_exec t.config)
                          ~access_token:t.access_token
                          ~owner:t.owner
                          ~repo:t.name
                          t.hash)))
          >>= fun (base_dirspaces, dirspaces) ->
          let ret =
            Terrat_api_components.(
              Work_manifest.Work_manifest_plan
                Work_manifest_plan.
                  {
                    type_ = "plan";
                    base_ref = work_manifest.Wm.src.Pull_request.base_branch;
                    changed_dirspaces;
                    dirspaces;
                    base_dirspaces;
                  })
          in
          Abb.Future.return (Ok ret)
      | Wm.Pull_request.Run_type.Apply | Wm.Pull_request.Run_type.Autoapply ->
          let ret =
            Terrat_api_components.(
              Work_manifest.Work_manifest_apply
                Work_manifest_apply.
                  {
                    type_ = "apply";
                    base_ref = work_manifest.Wm.src.Pull_request.base_branch;
                    changed_dirspaces;
                  })
          in
          Abb.Future.return (Ok ret)
      | Wm.Pull_request.Run_type.Unsafe_apply ->
          let ret =
            Terrat_api_components.(
              Work_manifest.Work_manifest_unsafe_apply
                Work_manifest_unsafe_apply.
                  {
                    type_ = "unsafe-apply";
                    base_ref = work_manifest.Wm.src.Pull_request.base_branch;
                    changed_dirspaces;
                  })
          in
          Abb.Future.return (Ok ret)

    let to_response t work_manifest =
      let open Abb.Future.Infix_monad in
      to_response' t work_manifest
      >>= function
      | Ok work_manifest -> Abb.Future.return (Ok work_manifest)
      | Error (#Terrat_github.fetch_repo_config_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ERROR : %s"
                t.request_id
                (Terrat_github.show_fetch_repo_config_err err));
          Abb.Future.return (Error `Error)
      | Error (`Bad_glob glob) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : BAD_GLOB : %s" t.request_id glob);
          Abb.Future.return (Error `Error)
      | Error (#Terrat_github.get_tree_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ERROR : %s"
                t.request_id
                (Terrat_github.show_get_tree_err err));
          Abb.Future.return (Error `Error)

    let request_id t = t.request_id

    let maybe_update_commit_status t installation_id owner repo_name run_type dirspaces hash =
      function
      | Terrat_work_manifest.State.Running ->
          let unified_run_type =
            Terrat_work_manifest.Pull_request.(
              run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
          in
          Abbs_future_combinators.ignore
            (Abb.Future.fork
               (let open Abbs_future_combinators.Infix_result_monad in
               Terrat_github.get_installation_access_token t.config (CCInt64.to_int installation_id)
               >>= fun access_token ->
               let target_url =
                 Printf.sprintf "https://github.com/%s/%s/actions/runs/%s" owner repo_name t.run_id
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
                 ~access_token
                 ~owner
                 ~repo:repo_name
                 ~ref_:hash
                 commit_statuses
               >>= function
               | Ok () -> Abb.Future.return (Ok ())
               | Error (#Terrat_github.get_installation_access_token_err as err) ->
                   Prmths.Counter.inc_one Metrics.github_errors_total;
                   Logs.err (fun m ->
                       m
                         "GITHUB_EVALUATOR : %s : COMMIT_CHECK : %s"
                         t.request_id
                         (Terrat_github.show_get_installation_access_token_err err));
                   Abb.Future.return (Ok ())))
      | Terrat_work_manifest.State.Queued
      | Terrat_work_manifest.State.Completed
      | Terrat_work_manifest.State.Aborted -> Abb.Future.return ()

    let initiate_work_manifest' db t =
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.initiate_work_manifest
        ~f:
          (fun base_hash
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
               repo_name ->
          (* This is done in this annoying way because the type system
             complains that "Pull_request" will escape its scope otherwise
             and I haven't figured out how to resolve that. *)
          ( base_hash,
            completed_at,
            created_at,
            hash,
            run_type,
            state,
            tag_query,
            repo_id,
            pull_number,
            base_branch,
            installation_id,
            owner,
            repo_name ))
        t.work_manifest
        t.run_id
        t.hash
      >>= function
      | wm :: _ -> Abb.Future.return (Ok (Some wm))
      | [] -> (
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_work_manifest
            ~f:
              (fun base_hash
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
                   repo_name ->
              (* This is done in this annoying way because the type system
                 complains that "Pull_request" will escape its scope otherwise
                 and I haven't figured out how to resolve that. *)
              ( base_hash,
                completed_at,
                created_at,
                hash,
                run_type,
                state,
                tag_query,
                repo_id,
                pull_number,
                base_branch,
                installation_id,
                owner,
                repo_name ))
            t.work_manifest
            t.run_id
            t.hash
          >>= function
          | wm :: _ -> Abb.Future.return (Ok (Some wm))
          | [] -> Abb.Future.return (Ok None))

    let initiate_work_manifest db t =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Abbs_time_it.run
          (fun time ->
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : INITIATE : %s : %s : %s : %f"
                  t.request_id
                  (Uuidm.to_string t.work_manifest)
                  t.run_id
                  t.hash
                  time))
          (fun () -> initiate_work_manifest' db t)
        >>= function
        | Some
            ( base_hash,
              completed_at,
              created_at,
              hash,
              run_type,
              state,
              tag_query,
              repo_id,
              pull_number,
              base_branch,
              installation_id,
              owner,
              repo_name ) ->
            let partial_work_manifest =
              {
                Terrat_work_manifest.base_hash;
                changes = ();
                completed_at;
                created_at;
                hash;
                id = t.work_manifest;
                src = Pull_request.{ repo_id; pull_number; base_branch };
                run_id = Some t.run_id;
                run_type;
                state;
                tag_query;
              }
            in
            Pgsql_io.Prepared_stmt.fetch
              db
              Sql.select_work_manifest_dirspaces
              ~f:(fun dir workspace workflow_idx ->
                Terrat_change.
                  {
                    Dirspaceflow.dirspace = { Dirspace.dir; workspace };
                    workflow_idx = CCOption.map CCInt32.to_int workflow_idx;
                  })
              t.work_manifest
            >>= fun dirspaces ->
            let open Abb.Future.Infix_monad in
            maybe_update_commit_status
              t
              installation_id
              owner
              repo_name
              run_type
              dirspaces
              hash
              state
            >>= fun () ->
            Abb.Future.return
              (Ok
                 (Some
                    (Terrat_evaluator.Work_manifest.Pull_request
                       Terrat_work_manifest.{ partial_work_manifest with changes = dirspaces })))
        | None ->
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : ABORT_WORK_MANIFEST : %s"
                  t.request_id
                  (Uuidm.to_string t.work_manifest));
            Pgsql_io.Prepared_stmt.execute db Sql.abort_work_manifest t.work_manifest
            >>= fun () -> Abb.Future.return (Ok None)
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : ERROR : %s" t.request_id (Pgsql_io.show_err err));
          Abb.Future.return (Error `Error)

    let query_dirspaces_without_valid_plans db t pull_request dirspaces =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
        Sql.select_dirspaces_without_valid_plans
        pull_request.Pull_request.repo_id
        pull_request.Pull_request.pull_number
        (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
        (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : ERROR : %s" t.request_id (Pgsql_io.show_err err));
          Abb.Future.return (Error `Error)

    let query_dirspaces_owned_by_other_pull_requests db t pull_request dirspaces =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_dirspaces_owned_by_other_pull_requests
        ~f:
          (fun dir
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
                diff = ();
                hash;
                id = pull_number;
                state =
                  (match (state, merged_hash, merged_at) with
                  | "open", _, _ -> Terrat_pull_request.State.Open
                  | "closed", _, _ -> Terrat_pull_request.State.Closed
                  | "merged", Some merged_hash, Some merged_at ->
                      Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                  | _ -> assert false);
                checks = ();
                mergeable = None;
                draft = false;
              } ))
        pull_request.Pull_request.repo_id
        pull_request.Pull_request.pull_number
        (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
        (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
      >>= function
      | Ok res -> Abb.Future.return (Ok (Terrat_evaluator.Event.Dirspace_map.of_list res))
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : ERROR : %s" t.request_id (Pgsql_io.show_err err));
          Abb.Future.return (Error `Error)

    let work_manifest_already_run t =
      let open Abb.Future.Infix_monad in
      Logs.err (fun m ->
          m
            "GITHUB_EVALUATOR : %s : WORK_MANIFEST_ALREADY_RUN : work_manifest=%s : owner=%s : \
             name=%s : pull_number=%d"
            t.request_id
            (Uuidm.to_string t.work_manifest)
            t.owner
            t.name
            t.pull_number);
      Terrat_github.publish_comment
        ~access_token:t.access_token
        ~owner:t.owner
        ~repo:t.name
        ~pull_number:t.pull_number
        Tmpl.work_manifest_already_run
      >>= fun _ -> Abb.Future.return (Ok ())
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

      let base64 = function
        | Some s :: rest -> (
            match Base64.decode (CCString.replace ~sub:"\n" ~by:"" s) with
            | Ok s -> Some (s, rest)
            | _ -> None)
        | _ -> None

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

    let store ~request_id ~path ~workspace storage work_manifest_id plan_data =
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

      let run_type = function
        | Some s :: rest ->
            let open CCOption in
            Terrat_work_manifest.Pull_request.Run_type.of_string s
            >>= fun run_type -> Some (run_type, rest)
        | _ -> None

      let policy =
        let module P = struct
          type t = string list [@@deriving yojson]
        end in
        CCFun.(
          CCOption.wrap Yojson.Safe.from_string
          %> CCOption.map P.of_yojson
          %> CCOption.flat_map CCResult.to_opt)

      let select_missing_dirspace_applies_for_pull_request =
        Pgsql_io.Typed_sql.(
          sql
          // (* path *) Ret.text
          // (* workspace *) Ret.text
          /^ read "select_github_missing_dirspace_applies_for_pull_request.sql"
          /% Var.text "owner"
          /% Var.text "name"
          /% Var.bigint "pull_number")

      let insert_github_work_manifest_result =
        Pgsql_io.Typed_sql.(
          sql
          /^ read "insert_github_work_manifest_result.sql"
          /% Var.uuid "work_manifest"
          /% Var.text "path"
          /% Var.text "workspace"
          /% Var.boolean "success")

      let complete_work_manifest =
        Pgsql_io.Typed_sql.(
          sql
          /^ "update github_work_manifests set state = 'completed', completed_at = now() where id \
              = $id"
          /% Var.uuid "id")

      let select_github_parameters_from_work_manifest () =
        Pgsql_io.Typed_sql.(
          sql
          // (* installation_id *) Ret.bigint
          // (* owner *) Ret.text
          // (* name *) Ret.text
          // (* branch *) Ret.text
          // (* sha *) Ret.text
          // (* base_sha *) Ret.text
          // (* pull_number *) Ret.bigint
          // (* run_type *) Ret.ud run_type
          // (* run_id *) Ret.(option text)
          // (* run time *) Ret.double
          /^ read "select_github_parameters_from_work_manifest.sql"
          /% Var.uuid "id")

      let select_work_manifest_access_control_denied_dirspaces =
        Pgsql_io.Typed_sql.(
          sql
          // (* path *) Ret.text
          // (* workspace *) Ret.text
          // (* policy *) Ret.(option (ud' policy))
          /^ read "select_github_work_manifest_access_control_denied_dirspaces.sql"
          /% Var.uuid "work_manifest")
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
    end

    module Workflow_step_output = struct
      type t = {
        success : bool;
        key : string option;
        text : string;
        step_type : string;
      }
    end

    let pre_hook_output_texts outputs =
      let module Output = Terrat_api_components_hook_outputs.Pre.Items in
      let module Text = Terrat_api_components_output_text in
      let module Run = Terrat_api_components_workflow_output_run in
      let module Checkout = Terrat_api_components_workflow_output_checkout in
      let module Ce = Terrat_api_components_workflow_output_cost_estimation in
      outputs
      |> CCList.filter_map (function
             | Output.Workflow_output_run
                 Run.
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
                 Some Workflow_step_output.{ key = output_key; text; success; step_type = type_ }
             | Output.Workflow_output_run
                 Run.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ } ->
                 Some Workflow_step_output.{ key = None; text = ""; success; step_type = type_ }
             | Output.Workflow_output_env _
             | Output.Workflow_output_cost_estimation
                 Ce.{ outputs = Outputs.Output_cost_estimation _; _ } -> None)

    let post_hook_output_texts (outputs : Terrat_api_components_hook_outputs.Post.t) =
      let module Output = Terrat_api_components_hook_outputs.Post.Items in
      let module Text = Terrat_api_components_output_text in
      let module Run = Terrat_api_components_workflow_output_run in
      outputs
      |> CCList.filter_map (function
             | Output.Workflow_output_run
                 Run.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Some Text.{ text; output_key };
                     success;
                     _;
                   } ->
                 Some Workflow_step_output.{ key = output_key; text; success; step_type = type_ }
             | Output.Workflow_output_run
                 Run.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ } ->
                 Some Workflow_step_output.{ key = None; text = ""; success; step_type = type_ }
             | Output.Workflow_output_env _ -> None)

    let workflow_output_texts outputs =
      let module Output = Terrat_api_components_workflow_outputs.Items in
      let module Run = Terrat_api_components_workflow_output_run in
      let module Init = Terrat_api_components_workflow_output_init in
      let module Plan = Terrat_api_components_workflow_output_plan in
      let module Apply = Terrat_api_components_workflow_output_apply in
      let module Text = Terrat_api_components_output_text in
      let module Output_plan = Terrat_api_components_output_plan in
      outputs
      |> CCList.flat_map (function
             | Output.Workflow_output_run
                 Run.
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
                 [ Workflow_step_output.{ step_type = type_; text; key = output_key; success } ]
             | Output.Workflow_output_plan
                 Plan.
                   {
                     workflow_step = Workflow_step.{ type_; _ };
                     outputs = Some (Plan.Outputs.Output_plan Output_plan.{ plan; plan_text });
                     success;
                     _;
                   } ->
                 [
                   Workflow_step_output.
                     { step_type = type_; text = plan_text; key = Some "plan_text"; success };
                   Workflow_step_output.
                     { step_type = type_; text = plan; key = Some "plan"; success };
                 ]
             | Output.Workflow_output_run _
             | Output.Workflow_output_plan _
             | Output.Workflow_output_env _
             | Output.Workflow_output_init Init.{ outputs = None; _ }
             | Output.Workflow_output_apply Apply.{ outputs = None; _ } -> [])

    let complete_check ~access_token ~owner ~repo ~branch ~run_id ~run_type ~sha ~results () =
      let module Wmr = Terrat_api_components.Work_manifest_result in
      let module R = Terrat_api_work_manifest.Results.Request_body in
      let module Hooks_output = Terrat_api_components.Hook_outputs in
      let unified_run_type =
        Terrat_work_manifest.Pull_request.(
          run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
      in
      let success = results.R.overall.R.Overall.success in
      let description = if success then "Completed" else "Failed" in
      let target_url =
        Printf.sprintf "https://github.com/%s/%s/actions/runs/%s" owner repo run_id
      in
      let pre_hooks_status =
        let module Run = Terrat_api_components.Workflow_output_run in
        let module Env = Terrat_api_components.Workflow_output_env in
        let module Checkout = Terrat_api_components.Workflow_output_checkout in
        let module Ce = Terrat_api_components.Workflow_output_cost_estimation in
        results.R.overall.R.Overall.outputs.Hooks_output.pre
        |> CCList.exists
             Hooks_output.Pre.Items.(
               function
               | Workflow_output_run Run.{ success; _ }
               | Workflow_output_env Env.{ success; _ }
               | Workflow_output_checkout Checkout.{ success; _ }
               | Workflow_output_cost_estimation Ce.{ success; _ } -> not success)
        |> function
        | true -> Terrat_commit_check.Status.Failed
        | false -> Terrat_commit_check.Status.Completed
      in
      let post_hooks_status =
        let module Run = Terrat_api_components.Workflow_output_run in
        let module Env = Terrat_api_components.Workflow_output_env in
        results.R.overall.R.Overall.outputs.Hooks_output.post
        |> CCList.exists
             Hooks_output.Post.Items.(
               function
               | Workflow_output_run Run.{ success; _ } | Workflow_output_env Env.{ success; _ } ->
                   not success)
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
      Terrat_github_commit_check.create ~access_token ~owner ~repo ~ref_:sha commit_statuses

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
               (function
                 | Workflow_step_output.{ key = Some key; text; success; step_type } ->
                     Map.of_list
                       [
                         (key, bool true);
                         ("text", string text);
                         ("success", bool success);
                         ("step_type", string step_type);
                       ]
                 | Workflow_step_output.{ success; text; step_type; _ } ->
                     Map.of_list
                       [
                         ("success", bool success);
                         ("text", string text);
                         ("step_type", string step_type);
                       ])
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
        match Terrat_work_manifest.Pull_request.Unified_run_type.of_run_type run_type with
        | Terrat_work_manifest.Pull_request.Unified_run_type.Plan -> Tmpl.plan_complete
        | Terrat_work_manifest.Pull_request.Unified_run_type.Apply -> Tmpl.apply_complete
      in
      match Snabela.apply tmpl kv with
      | Ok body -> body
      | Error (#Snabela.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : ERROR : %s" (Snabela.show_err err));
          assert false

    let rec iterate_comment_posts
        ?(compact_view = false)
        ~request_id
        ~access_token
        ~owner
        ~repo
        ~pull_number
        ~run_id
        ~sha
        ~run_type
        ~results
        ~denied_dirspaces
        () =
      let open Abb.Future.Infix_monad in
      let output = create_run_output ~compact_view run_type results denied_dirspaces in
      Metrics.Run_output_histogram.observe
        (Metrics.run_output_chars ~r:run_type ~c:compact_view)
        (CCFloat.of_int (CCString.length output));
      Terrat_github.publish_comment ~access_token ~owner ~repo ~pull_number output
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Terrat_github.publish_comment_err as err) when not compact_view ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ITERATE_COMMENT_POST : %s"
                request_id
                (Terrat_github.show_publish_comment_err err));
          iterate_comment_posts
            ~compact_view:true
            ~request_id
            ~access_token
            ~owner
            ~repo
            ~pull_number
            ~run_id
            ~sha
            ~run_type
            ~results
            ~denied_dirspaces
            ()
      | Error (#Terrat_github.publish_comment_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ITERATE_COMMENT_POST : %s"
                request_id
                (Terrat_github.show_publish_comment_err err));
          Terrat_github.publish_comment
            ~access_token
            ~owner
            ~repo
            ~pull_number
            Tmpl.comment_too_large

    let publish_results
        ~request_id
        ~config
        ~access_token
        ~owner
        ~repo
        ~branch
        ~pull_number
        ~run_type
        ~results
        ~denied_dirspaces
        ~run_id
        ~sha
        () =
      let run =
        Abbs_future_combinators.Infix_result_app.(
          (fun _ _ -> ())
          <$> Abbs_time_it.run
                (fun t ->
                  Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : COMMENT : %f" request_id t))
                (fun () ->
                  iterate_comment_posts
                    ~request_id
                    ~access_token
                    ~owner
                    ~repo
                    ~pull_number
                    ~run_id
                    ~sha
                    ~run_type
                    ~results
                    ~denied_dirspaces
                    ())
          <*> Abbs_time_it.run
                (fun t ->
                  Logs.info (fun m ->
                      m "GITHUB_EVALUATOR : %s : COMPLETE_COMMIT_STATUSES : %f" request_id t))
                (fun () ->
                  complete_check
                    ~access_token
                    ~owner
                    ~repo
                    ~branch
                    ~run_id
                    ~run_type
                    ~sha
                    ~results
                    ()))
      in
      let open Abb.Future.Infix_monad in
      Abbs_time_it.run
        (fun t ->
          Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : PUBLISH_RESULTS : %f" request_id t))
        (fun () -> run)
      >>= function
      | Ok () -> Abb.Future.return ()
      | Error (#Githubc2_abb.call_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : ERROR : %s" request_id (Githubc2_abb.show_call_err err));
          Abb.Future.return ()
      | Error (#Terrat_github.get_installation_access_token_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ERROR : %s"
                request_id
                (Terrat_github.show_get_installation_access_token_err err));
          Abb.Future.return ()
      | Error (#Terrat_github.publish_comment_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ERROR : %s"
                request_id
                (Terrat_github.show_publish_comment_err err));
          Abb.Future.return ()

    let automerge_config = function
      | Terrat_repo_config.(Version_1.{ automerge = Some _ as automerge; _ }) -> automerge
      | _ -> None

    let merge_pull_request request_id access_token owner repo pull_number =
      let open Abbs_future_combinators.Infix_result_monad in
      let client = Terrat_github.create (`Token access_token) in
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %s : %s : %Ld"
            request_id
            owner
            repo
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
                      ~commit_title:(Some (Printf.sprintf "Terrateam Automerge #%Ld" pull_number))
                      ()))
            Parameters.(make ~owner ~repo ~pull_number:(CCInt64.to_int pull_number)))
      >>= fun resp ->
      match Openapi.Response.value resp with
      | `OK _ -> Abb.Future.return (Ok ())
      | `Method_not_allowed _ -> (
          Logs.info (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGE_METHOD_NOT_ALLOWED : %s : %s : %Ld"
                request_id
                owner
                repo
                pull_number);
          Githubc2_abb.call
            client
            Githubc2_pulls.Merge.(
              make
                ~body:Request_body.(make Primary.(make ~merge_method:(Some "squash") ()))
                Parameters.(make ~owner ~repo ~pull_number:(CCInt64.to_int pull_number)))
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

    let delete_pull_request_branch request_id access_token owner repo pull_number =
      let open Abbs_future_combinators.Infix_result_monad in
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %Ld"
            request_id
            owner
            repo
            pull_number);
      Terrat_github.fetch_pull_request ~access_token ~owner ~repo (CCInt64.to_int pull_number)
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
                "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %Ld : %s"
                request_id
                owner
                repo
                pull_number
                branch);
          let client = Terrat_github.create (`Token access_token) in
          Githubc2_abb.call
            client
            Githubc2_git.Delete_ref.(make Parameters.(make ~owner ~repo ~ref_:("heads/" ^ branch)))
          >>= fun resp ->
          match Openapi.Response.value resp with
          | `No_content -> Abb.Future.return (Ok ())
          | `Unprocessable_entity err ->
              Logs.err (fun m ->
                  m
                    "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : ERROR : %s : %s : %Ld : \
                     %s"
                    request_id
                    owner
                    repo
                    pull_number
                    (Githubc2_git.Delete_ref.Responses.Unprocessable_entity.show err));
              Abb.Future.return (Ok ()))
      | (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _) as err ->
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Githubc2_pulls.Get.Responses.pp err);
          Abb.Future.return (Error `Error)

    let perform_post_apply
        ~request_id
        ~config
        ~storage
        ~access_token
        ~owner
        ~repo
        ~sha
        ~pull_number
        () =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Logs.info (fun m ->
            m
              "GITHUB_EVALUATOR : %s : AUTOMERGE : SELECT_MISSING_DIRSPACE_APPLIES : %s : %s : %Ld \
               : %s"
              request_id
              owner
              repo
              pull_number
              sha);
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.fetch
              db
              Sql.select_missing_dirspace_applies_for_pull_request
              ~f:(fun path workspace -> (path, workspace))
              owner
              repo
              pull_number)
        >>= function
        | [] -> (
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : ALL_DIRSPACES_APPLIED : %s : %s : %Ld : %s"
                  request_id
                  owner
                  repo
                  pull_number
                  sha);
            Terrat_github.fetch_repo_config
              ~python:(Terrat_config.python_exec config)
              ~access_token
              ~owner
              ~repo
              sha
            >>= fun repo_config ->
            match automerge_config repo_config with
            | Some Terrat_repo_config.Automerge.{ enabled = true; delete_branch } -> (
                merge_pull_request request_id access_token owner repo pull_number
                >>= function
                | () when delete_branch ->
                    delete_pull_request_branch request_id access_token owner repo pull_number
                | () -> Abb.Future.return (Ok ()))
            | _ -> Abb.Future.return (Ok ()))
        | _ :: _ ->
            (* Not everything is applied, so skip *)
            Abb.Future.return (Ok ())
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok () -> Abb.Future.return ()
      | Error (#Pgsql_pool.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
                request_id
                owner
                repo
                pull_number
                sha
                (Pgsql_pool.show_err err));
          Abb.Future.return ()
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
                request_id
                owner
                repo
                pull_number
                sha
                (Pgsql_io.show_err err));
          Abb.Future.return ()
      | Error `Error ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : ERROR"
                request_id
                owner
                repo
                pull_number
                sha);
          Abb.Future.return ()
      | Error (#Terrat_github.get_installation_access_token_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
                request_id
                owner
                repo
                pull_number
                sha
                (Terrat_github.show_get_installation_access_token_err err));
          Abb.Future.return ()
      | Error (#Terrat_github.fetch_repo_config_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
                request_id
                owner
                repo
                pull_number
                sha
                (Terrat_github.show_fetch_repo_config_err err));
          Abb.Future.return ()
      | Error (`Conflict err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
                request_id
                owner
                repo
                pull_number
                sha
                (Githubc2_pulls.Merge.Responses.Conflict.show err));
          Abb.Future.return ()
      | Error (`Method_not_allowed err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
                request_id
                owner
                repo
                pull_number
                sha
                (Githubc2_pulls.Merge.Responses.Method_not_allowed.show err));
          Abb.Future.return ()

    let complete_work_manifest
        ~config
        ~storage
        ~request_id
        ~installation_id
        ~owner
        ~repo
        ~branch
        ~sha
        ~pull_number
        ~run_type
        ~run_id
        ~results
        ~denied_dirspaces
        () =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_github.get_installation_access_token config (CCInt64.to_int installation_id)
        >>= fun access_token ->
        Abb.Future.Infix_app.(
          (fun () () -> Ok ())
          <$> publish_results
                ~request_id
                ~config
                ~access_token
                ~owner
                ~repo
                ~branch
                ~pull_number:(CCInt64.to_int pull_number)
                ~run_type
                ~results
                ~denied_dirspaces
                ~run_id:(CCOption.get_exn_or "run_id is None" run_id)
                ~sha
                ()
          <*>
          match Terrat_work_manifest.Pull_request.Unified_run_type.of_run_type run_type with
          | Terrat_work_manifest.Pull_request.Unified_run_type.Apply ->
              perform_post_apply
                ~request_id
                ~config
                ~storage
                ~access_token
                ~owner
                ~repo
                ~sha
                ~pull_number
                ()
          | Terrat_work_manifest.Pull_request.Unified_run_type.Plan -> Abb.Future.return ())
      in
      let open Abb.Future.Infix_monad in
      run
      >>= fun ret ->
      Abb.Future.fork (R.run ~request_id config storage)
      >>= fun _ ->
      match ret with
      | Ok () -> Abb.Future.return ()
      | Error (#Terrat_github.get_installation_access_token_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ERROR : %s"
                request_id
                (Terrat_github.show_get_installation_access_token_err err));
          Abb.Future.return ()

    let store ~request_id config storage work_manifest_id results =
      let open Abb.Future.Infix_monad in
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : RESULT : %a : %s"
            request_id
            Uuidm.pp
            work_manifest_id
            (if Terrat_api_work_manifest.Results.Request_body.(results.overall.Overall.success) then
             "SUCCESS"
            else "FAILURE"));
      Prmths.Counter.inc_one
        (Metrics.run_overall_result_count
           (Bool.to_string
              Terrat_api_work_manifest.Results.Request_body.(results.overall.Overall.success)));
      Pgsql_pool.with_conn storage ~f:(fun db ->
          let open Abbs_future_combinators.Infix_result_monad in
          Pgsql_io.tx db ~f:(fun () ->
              Abbs_time_it.run
                (fun t ->
                  Logs.info (fun m ->
                      m "GITHUB_EVALUATOR : %s : DIRSPACE_RESULT_STORE : %f" request_id t))
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
                    results.Terrat_api_work_manifest.Results.Request_body.dirspaces)
              >>= fun () ->
              Abbs_time_it.run
                (fun t ->
                  Logs.info (fun m ->
                      m "GITHUB_EVALUATOR : %s : COMPLETE_WORK_MANIFEST : %f" request_id t))
                (fun () ->
                  Pgsql_io.Prepared_stmt.execute db Sql.complete_work_manifest work_manifest_id)
              >>= fun () ->
              Abbs_time_it.run
                (fun t ->
                  Logs.info (fun m ->
                      m
                        "GITHUB_EVALUATOR : %s : FETCH_ACCESS_CONTROL_DENIED_DIRSPACES : %f"
                        request_id
                        t))
                (fun () ->
                  Pgsql_io.Prepared_stmt.fetch
                    db
                    Sql.select_work_manifest_access_control_denied_dirspaces
                    ~f:(fun dir workspace policy ->
                      (Terrat_change.Dirspace.{ dir; workspace }, policy))
                    work_manifest_id)
              >>= fun denied_dirspaces ->
              Abbs_time_it.run
                (fun t ->
                  Logs.info (fun m ->
                      m "GITHUB_EVALUATOR : %s : SELECT_GITHUB_PARAMETERS : %f" request_id t))
                (fun () ->
                  Pgsql_io.Prepared_stmt.fetch
                    db
                    (Sql.select_github_parameters_from_work_manifest ())
                    ~f:
                      (fun installation_id
                           owner
                           name
                           branch
                           sha
                           _base_sha
                           pull_number
                           run_type
                           run_id
                           run_time ->
                      ( installation_id,
                        owner,
                        name,
                        branch,
                        sha,
                        pull_number,
                        run_type,
                        run_id,
                        denied_dirspaces,
                        run_time ))
                    work_manifest_id)
              >>= function
              | values :: _ -> Abb.Future.return (Ok values)
              | [] -> assert false))
      >>= function
      | Ok
          ( installation_id,
            owner,
            repo,
            branch,
            sha,
            pull_number,
            run_type,
            run_id,
            denied_dirspaces,
            run_time ) ->
          Metrics.Work_manifest_run_time_histogram.observe
            (Metrics.work_manifest_run_time_duration_seconds
               (Terrat_work_manifest.Pull_request.Run_type.to_string run_type))
            run_time;
          complete_work_manifest
            ~config
            ~storage
            ~request_id
            ~installation_id
            ~owner
            ~repo
            ~branch
            ~sha
            ~pull_number
            ~run_type
            ~run_id
            ~results
            ~denied_dirspaces
            ()
          >>= fun () -> Abb.Future.return (Ok ())
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
end

module S = struct
  module Event = Ev
  module Runner = R
  module Work_manifest = Wm
end

include Terrat_evaluator.Make (S)
