let not_a_bad_chunk_size = 500
let replace_nul_byte = CCString.replace ~which:`All ~sub:"\x00" ~by:"\\0"

let rec replace_nul_byte_json = function
  | `Tuple l -> `Tuple (CCList.map replace_nul_byte_json l)
  | `Variant (k, None) -> `Variant (replace_nul_byte k, None)
  | `Variant (k, Some v) -> `Variant (replace_nul_byte k, Some (replace_nul_byte_json v))
  | `List l -> `List (CCList.map replace_nul_byte_json l)
  | `Assoc assoc ->
      `Assoc (CCList.map (fun (k, v) -> (replace_nul_byte k, replace_nul_byte_json v)) assoc)
  | `String s -> `String (replace_nul_byte s)
  | (`Bool _ | `Intlit _ | `Null | `Float _ | `Int _) as t -> t

module Metrics = struct
  module Psql_query_time = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_linear ~start:0.0 ~interval:0.1 ~count:15
  end)

  module Time_histogram = Prmths.DefaultHistogram

  let namespace = "terrat"
  let subsystem = "github_evaluator"
  let pgsql_errors_total = Terrat_metrics.errors_total ~m:subsystem ~t:"pgsql"

  let psql_query_time =
    let help = "Time for PostgreSQL query" in
    Psql_query_time.v_label ~help ~label_name:"q" ~namespace ~subsystem "psql_query_time"

  let run_overall_result_count =
    let help = "Count of the results of overall runs" in
    Prmths.Counter.v_label
      ~label_name:"success"
      ~help
      ~namespace
      ~subsystem
      "run_overall_result_count"
end

module Scope = struct
  type t =
    | Dirspace of Terrat_dirspace.t
    | Run of {
        flow : string;
        subflow : string;
      }
  [@@deriving eq, ord]

  let of_terrat_api_scope =
    let module S = Terrat_api_components.Workflow_step_output_scope in
    let module Ds = Terrat_api_components.Workflow_step_output_scope_dirspace in
    let module R = Terrat_api_components.Workflow_step_output_scope_run in
    function
    | S.Workflow_step_output_scope_dirspace { Ds.dir; workspace; _ } ->
        Dirspace { Terrat_dirspace.dir; workspace }
    | S.Workflow_step_output_scope_run { R.flow; subflow; _ } -> Run { flow; subflow }
end

module By_scope = Terrat_data.Group_by (struct
  module T = Terrat_api_components.Workflow_step_output

  type t = T.t
  type key = Scope.t

  let compare = Scope.compare
  let key { T.scope; _ } = Scope.of_terrat_api_scope scope
end)

module Api = Terrat_vcs_api_github

type ('diff, 'checks) pull_request =
  (Api.Pull_request.Id.t, 'diff, 'checks, Api.Repo.t, Api.Ref.t) Terrat_pull_request.t

module Unlock_id = struct
  type t =
    | Pull_request of int
    | Drift

  let of_pull_request id = Pull_request id
  let drift () = Drift

  let to_string = function
    | Pull_request id -> CCInt.to_string id
    | Drift -> "drift"
end

module Pull_request = struct
  include Terrat_pull_request

  type ('diff, 'checks) t =
    (Api.Pull_request.Id.t, 'diff, 'checks, Api.Repo.t, Api.Ref.t) Terrat_pull_request.t
end

module Db = struct
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
           (Terrat_files_github_sql.read fname))

    let policy =
      let module P = struct
        type t = Terrat_base_repo_config_v1.Access_control.Match_list.t [@@deriving yojson]
      end in
      CCFun.(
        CCOption.wrap Yojson.Safe.from_string
        %> CCOption.map P.of_yojson
        %> CCOption.flat_map CCResult.to_opt)

    let lock_policy = function
      | Terrat_base_repo_config_v1.Workflows.Entry.Lock_policy.Apply -> "apply"
      | Terrat_base_repo_config_v1.Workflows.Entry.Lock_policy.Merge -> "merge"
      | Terrat_base_repo_config_v1.Workflows.Entry.Lock_policy.None -> "none"
      | Terrat_base_repo_config_v1.Workflows.Entry.Lock_policy.Strict -> "strict"

    let select_work_manifest_dirspaceflows =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* path *)
        Ret.text
        //
        (* workflow_idx *)
        Ret.(option smallint)
        //
        (* workspace *)
        Ret.text
        /^ read "select_work_manifest_dirspaceflows.sql"
        /% Var.uuid "id")

    let select_work_manifest_access_control_denied_dirspaces =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* path *)
        Ret.text
        //
        (* workspace *)
        Ret.text
        //
        (* policy *)
        Ret.(option (ud' policy))
        /^ read "select_work_manifest_access_control_denied_dirspaces.sql"
        /% Var.uuid "work_manifest")

    let select_work_manifest_query = read "select_work_manifest2.sql"

    let select_work_manifest () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* base_sha *)
        Ret.text
        //
        (* completed_at *)
        Ret.(option text)
        //
        (* created_at *)
        Ret.text
        //
        (* pull_number *)
        Ret.(option bigint)
        //
        (* repository *)
        Ret.bigint
        //
        (* run_id *)
        Ret.(option text)
        //
        (* run_type *)
        Ret.(ud' Terrat_work_manifest3.Step.of_string)
        //
        (* sha *)
        Ret.text
        //
        (* state *)
        Ret.(ud' Terrat_work_manifest3.State.of_string)
        //
        (* tag_query *)
        Ret.(ud' CCFun.(Terrat_tag_query.of_string %> CCResult.to_opt))
        //
        (* username *)
        Ret.(option text)
        //
        (* run_kind *)
        Ret.text
        //
        (* installation_id *)
        Ret.bigint
        //
        (* repo_id *)
        Ret.bigint
        //
        (* repo_owner *)
        Ret.text
        //
        (* repo_name *)
        Ret.text
        //
        (* environment *)
        Ret.(option text)
        /^ select_work_manifest_query
        /% Var.uuid "id")

    let select_work_manifest_pull_request_query = read "select_work_manifest_pull_request.sql"

    let select_work_manifest_pull_request () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* base_branch_name *)
        Ret.text
        //
        (* base_ref *)
        Ret.text
        //
        (* branch_name *)
        Ret.text
        //
        (* branch_ref *)
        Ret.text
        //
        (* pull_number *)
        Ret.bigint
        //
        (* state *)
        Ret.text
        //
        (* merged_sha *)
        Ret.(option text)
        //
        (* merged_at *)
        Ret.(option text)
        //
        (* title *)
        Ret.(option text)
        //
        (* username *)
        Ret.(option text)
        /^ select_work_manifest_pull_request_query
        /% Var.uuid "id")

    let select_drift_work_manifest_query = read "select_drift_work_manifest.sql"

    let select_drift_work_manifest () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* branch *)
        Ret.text
        //
        (* reconcile *)
        Ret.boolean
        /^ select_drift_work_manifest_query
        /% Var.uuid "work_manifest")

    let insert_github_installation_repository =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "insert_installation_repository.sql"
        /% Var.bigint "id"
        /% Var.bigint "installation_id"
        /% Var.text "owner"
        /% Var.text "name")

    let insert_pull_request =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "insert_pull_request.sql"
        /% Var.text "base_branch"
        /% Var.text "base_sha"
        /% Var.text "branch"
        /% Var.bigint "pull_number"
        /% Var.bigint "repository"
        /% Var.text "sha"
        /% Var.(option (text "merged_sha"))
        /% Var.(option (timestamptz "merged_at"))
        /% Var.text "state"
        /% Var.(option (text "title"))
        /% Var.(option (text "username")))

    let insert_index_query = read "insert_code_index.sql"

    let insert_index () =
      Pgsql_io.Typed_sql.(sql /^ insert_index_query /% Var.uuid "work_manifest" /% Var.json "index")

    let insert_github_work_manifest_result =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "insert_work_manifest_result.sql"
        /% Var.(str_array (uuid "work_manifest"))
        /% Var.(str_array (text "path"))
        /% Var.(str_array (text "workspace"))
        /% Var.(array (boolean "success")))

    let insert_repo_config =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "insert_repo_config.sql"
        /% Var.bigint "installation_id"
        /% Var.text "sha"
        /% Var.json "data")

    let upsert_flow_state_query = read "update_flow_state.sql"

    let upsert_flow_state () =
      Pgsql_io.Typed_sql.(sql /^ upsert_flow_state_query /% Var.uuid "id" /% Var.text "data")

    let insert_dirspace =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "insert_dirspaces.sql"
        /% Var.(str_array (text "base_sha"))
        /% Var.(str_array (text "path"))
        /% Var.(array (bigint "repository"))
        /% Var.(str_array (text "sha"))
        /% Var.(str_array (text "workspace"))
        /% Var.(str_array (ud (text "lock_policy") lock_policy)))

    let insert_workflow_step_output =
      let query = read "insert_workflow_step_output.sql" in
      Pgsql_io.Typed_sql.(
        sql
        /^ query
        /% Var.(array (smallint "idx"))
        /% Var.(array (boolean "ignore_errors"))
        /% Var.(str_array (json "payload"))
        /% Var.(str_array (json "scope"))
        /% Var.(str_array (text "step"))
        /% Var.(array (boolean "success"))
        /% Var.(str_array (uuid "work_manifest")))

    let upsert_drift_schedule =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "upsert_drift_schedule.sql"
        /% Var.bigint "repo"
        /% Var.(ud (text "schedule") Terrat_base_repo_config_v1.Drift.Schedule.Sched.to_string)
        /% Var.boolean "reconcile"
        /% Var.(option (ud (text "tag_query") Terrat_tag_query.to_string))
        /% Var.text "name"
        /% Var.(option (timetz "window_start"))
        /% Var.(option (timetz "window_end")))

    let delete_drift_schedules =
      Pgsql_io.Typed_sql.(
        sql
        /^ "delete from github_drift_schedules where repository = $repo_id and not (name = \
            any($names))"
        /% Var.bigint "repo_id"
        /% Var.(str_array (text "names")))

    let select_installation_account_status_query = read "select_account_status.sql"

    let select_installation_account_status () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* account_status *)
        Ret.text
        //
        (* trial_end_days *)
        Ret.(option integer)
        /^ select_installation_account_status_query
        /% Var.bigint "installation_id")

    let select_index =
      let index =
        CCFun.(
          CCOption.wrap Yojson.Safe.from_string
          %> CCOption.map Terrat_code_idx.of_yojson
          %> CCOption.flat_map CCResult.to_opt)
      in
      Pgsql_io.Typed_sql.(
        sql
        //
        (* Index *)
        Ret.(ud' index)
        /^ read "select_index.sql"
        /% Var.bigint "installation_id"
        /% Var.text "sha")

    let select_repo_config =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* repo_config *)
        Ret.ud' (CCOption.wrap Yojson.Safe.from_string)
        /^ read "select_repo_config.sql"
        /% Var.bigint "installation_id"
        /% Var.text "sha")

    let select_next_work_manifest =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.uuid
        /^ read "select_next_work_manifest.sql")

    let select_flow_state_query = read "select_flow_data.sql"

    let select_flow_state () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* data *)
        Ret.text
        /^ select_flow_state_query
        /% Var.uuid "id")

    let delete_flow_state_query = read "delete_flow_state.sql"
    let delete_flow_state () = Pgsql_io.Typed_sql.(sql /^ delete_flow_state_query /% Var.uuid "id")

    let select_out_of_diff_applies =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* path *)
        Ret.text
        //
        (* workspace *)
        Ret.text
        /^ read "select_out_of_diff_applies.sql"
        /% Var.bigint "repository"
        /% Var.bigint "pull_number")

    let select_dirspace_applies_for_pull_request =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* path *)
        Ret.text
        //
        (* workspace *)
        Ret.text
        /^ read "select_dirspace_applies_for_pull_request.sql"
        /% Var.bigint "repo_id"
        /% Var.bigint "pull_number")

    let select_dirspaces_without_valid_plans =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* dir *)
        Ret.text
        //
        (* workspace *)
        Ret.text
        /^ read "select_dirspaces_without_valid_plans.sql"
        /% Var.bigint "repository"
        /% Var.bigint "pull_number"
        /% Var.(str_array (text "dirs"))
        /% Var.(str_array (text "workspaces")))

    let update_abort_duplicate_work_manifests_query = read "abort_duplicate_work_manifests.sql"

    let update_abort_duplicate_work_manifests () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* work manifest id *)
        Ret.uuid
        /^ update_abort_duplicate_work_manifests_query
        /% Var.bigint "repository"
        /% Var.bigint "pull_number"
        /% Var.(ud (text "run_type") Terrat_work_manifest3.Step.to_string)
        /% Var.(str_array (text "dirs"))
        /% Var.(str_array (text "workspaces")))

    let select_conflicting_work_manifests_in_repo_query =
      read "select_conflicting_work_manifests_in_repo2.sql"

    let select_conflicting_work_manifests_in_repo () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.uuid
        //
        (* maybe_stale *)
        Ret.boolean
        /^ select_conflicting_work_manifests_in_repo_query
        /% Var.bigint "repository"
        /% Var.bigint "pull_number"
        /% Var.(ud (text "run_type") Terrat_work_manifest3.Step.to_string)
        /% Var.(str_array (text "dirs"))
        /% Var.(str_array (text "workspaces")))

    let select_dirspaces_owned_by_other_pull_requests_query =
      read "select_dirspaces_owned_by_other_pull_requests.sql"

    let select_dirspaces_owned_by_other_pull_requests () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* dir *)
        Ret.text
        //
        (* workspace *)
        Ret.text
        //
        (* base_branch *)
        Ret.text
        //
        (* branch *)
        Ret.text
        //
        (* base_hash *)
        Ret.text
        //
        (* hash *)
        Ret.text
        //
        (* merged_hash *)
        Ret.(option text)
        //
        (* merged_at *)
        Ret.(option text)
        //
        (* pull_number *)
        Ret.bigint
        //
        (* state *)
        Ret.text
        //
        (* title *)
        Ret.(option text)
        //
        (* username *)
        Ret.(option text)
        /^ select_dirspaces_owned_by_other_pull_requests_query
        /% Var.bigint "repository"
        /% Var.bigint "pull_number"
        /% Var.(str_array (text "dirs"))
        /% Var.(str_array (text "workspaces")))

    let select_missing_drift_scheduled_runs_query = read "select_missing_drift_scheduled_runs.sql"

    let select_missing_drift_scheduled_runs () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* drift name *)
        Ret.text
        //
        (* installation_id *)
        Ret.bigint
        //
        (* repository *)
        Ret.bigint
        //
        (* owner *)
        Ret.text
        //
        (* name *)
        Ret.text
        //
        (* reconcile *)
        Ret.boolean
        //
        (* tag_query *)
        Ret.(option (ud' CCFun.(Terrat_tag_query.of_string %> CCResult.to_opt)))
        /^ select_missing_drift_scheduled_runs_query)

    let cleanup_repo_configs = Pgsql_io.Typed_sql.(sql /^ read "cleanup_repo_configs.sql")
    let delete_stale_flow_states_query = read "delete_stale_flow_states.sql"
    let delete_stale_flow_states () = Pgsql_io.Typed_sql.(sql /^ delete_stale_flow_states_query)
    let delete_old_plans = Pgsql_io.Typed_sql.(sql /^ read "delete_old_terraform_plans.sql")
    let insert_pull_request_unlock_query = read "insert_pull_request_unlock.sql"

    let insert_pull_request_unlock () =
      Pgsql_io.Typed_sql.(
        sql
        /^ insert_pull_request_unlock_query
        /% Var.bigint "repository"
        /% Var.bigint "pull_number")

    let insert_drift_unlock_query = read "insert_drift_unlock.sql"

    let insert_drift_unlock () =
      Pgsql_io.Typed_sql.(sql /^ insert_drift_unlock_query /% Var.bigint "repository")

    let select_recent_plan =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* data *)
        Ret.text
        /^ read "select_recent_plan.sql"
        /% Var.uuid "id"
        /% Var.text "dir"
        /% Var.text "workspace")

    let delete_plan_query = read "delete_terraform_plan.sql"

    let delete_plan () =
      Pgsql_io.Typed_sql.(
        sql /^ delete_plan_query /% Var.uuid "id" /% Var.text "dir" /% Var.text "workspace")

    let upsert_plan =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "upsert_terraform_plan.sql"
        /% Var.uuid "work_manifest"
        /% Var.text "path"
        /% Var.text "workspace"
        /% Var.(ud (text "data") Base64.encode_string)
        /% Var.boolean "has_changes")
  end

  type t = Pgsql_io.t

  let query_work_manifest ~request_id db work_manifest_id =
    let module Wm = Terrat_work_manifest3 in
    let module Dsf = Terrat_change.Dirspaceflow in
    let module Ds = Terrat_change.Dirspace in
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Metrics.Psql_query_time.time
        (Metrics.psql_query_time "select_work_manifest_dirspaceflows")
        (fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_work_manifest_dirspaceflows
            ~f:(fun dir idx workspace -> { Dsf.dirspace = { Ds.dir; workspace }; workflow = idx })
            work_manifest_id)
      >>= fun changes ->
      Metrics.Psql_query_time.time
        (Metrics.psql_query_time "select_work_manifest_access_control_denied_dirspaces")
        (fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_work_manifest_access_control_denied_dirspaces
            ~f:(fun dir workspace policy ->
              { Wm.Deny.dirspace = { Terrat_change.Dirspace.dir; workspace }; policy })
            work_manifest_id)
      >>= fun denied_dirspaces ->
      Metrics.Psql_query_time.time (Metrics.psql_query_time "select_work_manifest") (fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            (Sql.select_work_manifest ())
            ~f:(fun
                base_ref
                completed_at
                created_at
                pull_request_id
                repository
                run_id
                run_type
                branch_ref
                state
                tag_query
                user
                run_kind
                installation_id
                repo_id
                owner
                name
                environment
              ->
              {
                Wm.account = Api.Account.make (CCInt64.to_int installation_id);
                base_ref;
                branch_ref;
                changes;
                completed_at;
                created_at;
                denied_dirspaces;
                environment;
                id = work_manifest_id;
                initiator =
                  (match user with
                  | Some user -> Wm.Initiator.User user
                  | None -> Wm.Initiator.System);
                run_id;
                steps = [ run_type ];
                state;
                tag_query;
                target =
                  ( CCOption.map CCInt64.to_int pull_request_id,
                    Api.Repo.make ~id:(CCInt64.to_int repo_id) ~owner ~name () );
              })
            work_manifest_id)
      >>= function
      | [] -> Abb.Future.return (Ok None)
      | wm :: _ -> (
          match wm.Wm.target with
          | Some pull_request_id, repo -> (
              Metrics.Psql_query_time.time
                (Metrics.psql_query_time "select_work_manifest_pull_request")
                (fun () ->
                  Pgsql_io.Prepared_stmt.fetch
                    db
                    (Sql.select_work_manifest_pull_request ())
                    ~f:(fun
                        base_branch_name
                        base_ref
                        branch_name
                        branch_ref
                        pull_number
                        state
                        merged_sha
                        merged_at
                        title
                        user
                      ->
                      Pull_request.make
                        ~base_branch_name:(Api.Ref.of_string base_branch_name)
                        ~base_ref:(Api.Ref.of_string base_ref)
                        ~branch_name:(Api.Ref.of_string branch_name)
                        ~branch_ref:(Api.Ref.of_string branch_ref)
                        ~checks:()
                        ~diff:()
                        ~draft:false
                        ~id:(CCInt64.to_int pull_number)
                        ~mergeable:None
                        ~provisional_merge_ref:None
                        ~repo
                        ~state:
                          (match (state, merged_sha, merged_at) with
                          | "open", _, _ -> Terrat_pull_request.State.(Open Open_status.Mergeable)
                          | "closed", _, _ -> Terrat_pull_request.State.Closed
                          | "merged", Some merged_hash, Some merged_at ->
                              Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                          | _ -> assert false)
                        ~title
                        ~user
                        ())
                    work_manifest_id)
              >>= function
              | [] -> assert false
              | pr :: _ ->
                  Abb.Future.return
                    (Ok (Some { wm with Wm.target = Terrat_vcs_provider2.Target.Pr pr })))
          | None, repo -> (
              Metrics.Psql_query_time.time
                (Metrics.psql_query_time "select_drift_work_manifest")
                (fun () ->
                  Pgsql_io.Prepared_stmt.fetch
                    db
                    (Sql.select_drift_work_manifest ())
                    ~f:(fun branch _ -> branch)
                    work_manifest_id)
              >>= function
              | [] -> assert false
              | branch :: _ ->
                  Abb.Future.return
                    (Ok
                       (Some
                          { wm with Wm.target = Terrat_vcs_provider2.Target.Drift { repo; branch } }))
              ))
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let store_account_repository ~request_id db account repo =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time
      (Metrics.psql_query_time "insert_github_installation_repository")
      (fun () ->
        Pgsql_io.Prepared_stmt.execute
          db
          Sql.insert_github_installation_repository
          (CCInt64.of_int (Api.Repo.id repo))
          (CCInt64.of_int (Api.Account.id account))
          (Api.Repo.owner repo)
          (Api.Repo.name repo))
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let store_pull_request ~request_id db pull_request =
    let open Abb.Future.Infix_monad in
    let module Pr = Api.Pull_request in
    let module State = Terrat_pull_request.State in
    let merged_sha, merged_at, state =
      match Pr.state pull_request with
      | State.Open _ -> (None, None, "open")
      | State.Closed -> (None, None, "closed")
      | State.(Merged { Merged.merged_hash; merged_at }) ->
          (Some merged_hash, Some merged_at, "merged")
    in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "insert_pull_request") (fun () ->
        Pgsql_io.Prepared_stmt.execute
          db
          Sql.insert_pull_request
          (Api.Ref.to_string @@ Pr.base_branch_name pull_request)
          (Api.Ref.to_string @@ Pr.base_ref pull_request)
          (Api.Ref.to_string @@ Pr.branch_name pull_request)
          (CCInt64.of_int @@ Pr.id pull_request)
          (CCInt64.of_int @@ Api.Repo.id @@ Pr.repo pull_request)
          (Api.Ref.to_string @@ Pr.branch_ref pull_request)
          merged_sha
          merged_at
          state
          (Pr.title pull_request)
          (Pr.user pull_request))
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let index_of_index idx =
    let module Idx = Terrat_code_idx in
    let module Paths = Terrat_api_components.Work_manifest_index_paths in
    let module Symlinks = Terrat_api_components.Work_manifest_index_symlinks in
    let success = idx.Idx.success in
    let paths = Json_schema.String_map.to_list (Paths.additional idx.Idx.paths) in
    let symlinks =
      CCOption.map_or
        ~default:[]
        (fun idx -> Json_schema.String_map.to_list (Symlinks.additional idx))
        idx.Idx.symlinks
    in
    let failures =
      CCList.flat_map
        (fun (_path, { Paths.Additional.failures; _ }) ->
          let failures =
            Json_schema.String_map.to_list (Paths.Additional.Failures.additional failures)
          in
          CCList.map
            (fun (path, { Paths.Additional.Failures.Additional.lnum; msg }) ->
              { Terrat_vcs_provider2.Index.Failure.file = path; line_num = lnum; error = msg })
            failures)
        paths
    in
    let index =
      Terrat_base_repo_config_v1.Index.make
        ~symlinks
        (CCList.map
           (fun (path, { Paths.Additional.modules; _ }) ->
             (path, CCList.map (fun m -> Terrat_base_repo_config_v1.Index.Dep.Module m) modules))
           paths)
    in
    { Terrat_vcs_provider2.Index.success; failures; index }

  let store_index ~request_id db work_manifest_id index =
    let module R = Terrat_api_components.Work_manifest_index_result in
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "insert_index") (fun () ->
        Pgsql_io.Prepared_stmt.execute
          db
          (Sql.insert_index ())
          work_manifest_id
          (Yojson.Safe.to_string (R.to_yojson index)))
    >>= function
    | Ok () -> Abb.Future.return (Ok (index_of_index index))
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let store_index_result ~request_id db work_manifest_id index =
    let module Wm = Terrat_work_manifest3 in
    let module Idx = Terrat_code_idx in
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      let success = index.Idx.success in
      query_work_manifest ~request_id db work_manifest_id
      >>= function
      | Some { Wm.changes; _ } ->
          Abbs_future_combinators.List_result.iter
            ~f:(fun chunk ->
              let module Ds = Terrat_change.Dirspace in
              let work_manifest_id = CCList.replicate (CCList.length chunk) work_manifest_id in
              let success = CCList.replicate (CCList.length chunk) success in
              let dir =
                CCList.map
                  (fun dsf ->
                    let { Ds.dir; _ } = Terrat_change.Dirspaceflow.to_dirspace dsf in
                    dir)
                  chunk
              in
              let workspace =
                CCList.map
                  (fun dsf ->
                    let { Ds.workspace; _ } = Terrat_change.Dirspaceflow.to_dirspace dsf in
                    workspace)
                  chunk
              in
              Metrics.Psql_query_time.time
                (Metrics.psql_query_time "insert_github_work_manifest_result")
                (fun () ->
                  Pgsql_io.Prepared_stmt.execute
                    db
                    Sql.insert_github_work_manifest_result
                    work_manifest_id
                    dir
                    workspace
                    success))
            (CCList.chunks not_a_bad_chunk_size changes)
      | None -> assert false
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)
    | Error `Error -> Abb.Future.return (Error `Error)

  let store_repo_config_json ~request_id db account ref_ json =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "insert_repo_config") (fun () ->
        Pgsql_io.Prepared_stmt.execute
          db
          Sql.insert_repo_config
          (CCInt64.of_int @@ Api.Account.id account)
          (Api.Ref.to_string ref_)
          (Yojson.Safe.to_string json))
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let store_flow_state ~request_id db work_manifest_id data =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "upsert_flow_state") (fun () ->
        Pgsql_io.Prepared_stmt.execute db (Sql.upsert_flow_state ()) work_manifest_id data)
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let store_dirspaceflows ~request_id ~base_ref ~branch_ref db repo dirspaceflows =
    let id = CCInt64.of_int (Api.Repo.id repo) in
    let run =
      Abbs_future_combinators.List_result.iter
        ~f:(fun dirspaceflows ->
          Metrics.Psql_query_time.time (Metrics.psql_query_time "insert_dirspace") (fun () ->
              Pgsql_io.Prepared_stmt.execute
                db
                Sql.insert_dirspace
                (CCList.replicate (CCList.length dirspaceflows) (Api.Ref.to_string base_ref))
                (CCList.map
                   (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; _ }; _ } -> dir)
                   dirspaceflows)
                (CCList.replicate (CCList.length dirspaceflows) id)
                (CCList.replicate (CCList.length dirspaceflows) (Api.Ref.to_string branch_ref))
                (CCList.map
                   (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.workspace; _ }; _ } ->
                     workspace)
                   dirspaceflows)
                (CCList.map
                   (fun Terrat_change.{ Dirspaceflow.workflow; _ } ->
                     let module Dfwf = Terrat_change.Dirspaceflow.Workflow in
                     let module Wf = Terrat_base_repo_config_v1.Workflows.Entry in
                     CCOption.map_or
                       ~default:Terrat_base_repo_config_v1.Workflows.Entry.Lock_policy.Strict
                       (fun { Dfwf.workflow = { Wf.lock_policy; _ }; _ } -> lock_policy)
                       workflow)
                   dirspaceflows)))
        (CCList.chunks not_a_bad_chunk_size dirspaceflows)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let store_tf_operation_result ~request_id db work_manifest_id result =
    let module Rb = Terrat_api_components_work_manifest_tf_operation_result in
    let open Abb.Future.Infix_monad in
    Prmths.Counter.inc_one
      (Metrics.run_overall_result_count (Bool.to_string result.Rb.overall.Rb.Overall.success));
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m "GITHUB_EVALUATOR : %s : DIRSPACE_RESULT_STORE : time=%f" request_id time))
      (fun () ->
        let module Wmr = Terrat_api_components.Work_manifest_dirspace_result in
        CCList.iter
          (fun result ->
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : RESULT_STORE : id=%a : dir=%s : workspace=%s : result=%s"
                  request_id
                  Uuidm.pp
                  work_manifest_id
                  result.Wmr.path
                  result.Wmr.workspace
                  (if result.Wmr.success then "SUCCESS" else "FAILURE")))
          result.Rb.dirspaces;
        Abbs_future_combinators.List_result.iter
          ~f:(fun chunk ->
            let work_manifest_id = CCList.replicate (CCList.length chunk) work_manifest_id in
            let dir = CCList.map (fun result -> result.Wmr.path) chunk in
            let workspace = CCList.map (fun result -> result.Wmr.workspace) chunk in
            let success = CCList.map (fun result -> result.Wmr.success) chunk in
            Metrics.Psql_query_time.time
              (Metrics.psql_query_time "insert_github_work_manifest_result")
              (fun () ->
                Pgsql_io.Prepared_stmt.execute
                  db
                  Sql.insert_github_work_manifest_result
                  work_manifest_id
                  dir
                  workspace
                  success))
          (CCList.chunks not_a_bad_chunk_size result.Rb.dirspaces))
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)
    | Error `Error -> Abb.Future.return (Error `Error)

  let store_tf_operation_result2 ~request_id db work_manifest_id result =
    let module R2 = Terrat_api_components_work_manifest_tf_operation_result2 in
    let open Abb.Future.Infix_monad in
    let steps_success steps =
      let module O = Terrat_api_components.Workflow_step_output in
      CCList.for_all (fun { O.success; ignore_errors; _ } -> success || ignore_errors) steps
    in
    let by_scope = By_scope.group result.R2.steps in
    let overall_success = CCList.for_all (fun (_, steps) -> steps_success steps) by_scope in
    let dirspaces =
      CCList.filter_map
        (function
          | Scope.Dirspace dirspace, steps -> Some (dirspace, steps)
          | _ -> None)
        by_scope
    in
    Prmths.Counter.inc_one (Metrics.run_overall_result_count (Bool.to_string overall_success));
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m "GITHUB_EVALUATOR : %s : DIRSPACE_RESULT_STORE : time=%f" request_id time))
      (fun () ->
        let module O = Terrat_api_components.Workflow_step_output in
        let module Scope = Terrat_api_components.Workflow_step_output_scope in
        let open Abbs_future_combinators.Infix_result_monad in
        let steps = CCList.mapi (fun idx step -> (idx, step)) result.R2.steps in
        Abbs_future_combinators.List_result.iter
          ~f:(fun chunk ->
            let idx = CCList.map (fun (idx, _) -> idx) chunk in
            let ignore_errors =
              CCList.map (fun (_, { O.ignore_errors; _ }) -> ignore_errors) chunk
            in
            let payload =
              CCList.map
                (fun (_, { O.payload; _ }) ->
                  Yojson.Safe.to_string (replace_nul_byte_json (O.Payload.to_yojson payload)))
                chunk
            in
            let scope =
              CCList.map
                (fun (_, { O.scope; _ }) ->
                  Yojson.Safe.to_string (replace_nul_byte_json (Scope.to_yojson scope)))
                chunk
            in
            let step = CCList.map (fun (_, { O.step; _ }) -> replace_nul_byte step) chunk in
            let success = CCList.map (fun (_, { O.success; _ }) -> success) chunk in
            let work_manifest_id = CCList.replicate (CCList.length chunk) work_manifest_id in
            Metrics.Psql_query_time.time
              (Metrics.psql_query_time "insert_workflow_step_output")
              (fun () ->
                Pgsql_io.Prepared_stmt.execute
                  db
                  Sql.insert_workflow_step_output
                  idx
                  ignore_errors
                  payload
                  scope
                  step
                  success
                  work_manifest_id))
          (CCList.chunks not_a_bad_chunk_size steps)
        >>= fun () ->
        let dirspaces =
          CCList.map (fun (dirspace, steps) -> (dirspace, steps_success steps)) dirspaces
        in
        CCList.iter
          (fun ({ Terrat_dirspace.dir; workspace }, success) ->
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : RESULT_STORE : id=%a : dir=%s : workspace=%s : result=%s"
                  request_id
                  Uuidm.pp
                  work_manifest_id
                  dir
                  workspace
                  (if success then "SUCCESS" else "FAILURE")))
          dirspaces;
        Abbs_future_combinators.List_result.iter
          ~f:(fun chunk ->
            let work_manifest_id = CCList.replicate (CCList.length chunk) work_manifest_id in
            let dir = CCList.map (fun ({ Terrat_dirspace.dir; _ }, _) -> dir) chunk in
            let workspace =
              CCList.map (fun ({ Terrat_dirspace.workspace; _ }, _) -> workspace) chunk
            in
            let success = CCList.map (fun (_, success) -> success) chunk in
            Metrics.Psql_query_time.time
              (Metrics.psql_query_time "insert_github_work_manifest_result")
              (fun () ->
                Pgsql_io.Prepared_stmt.execute
                  db
                  Sql.insert_github_work_manifest_result
                  work_manifest_id
                  dir
                  workspace
                  success))
          (CCList.chunks not_a_bad_chunk_size dirspaces))
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)
    | Error `Error -> Abb.Future.return (Error `Error)

  let store_drift_schedule ~request_id db repo drift =
    let module V1 = Terrat_base_repo_config_v1 in
    let module D = Terrat_base_repo_config_v1.Drift in
    let { D.enabled; schedules; _ } = drift in
    let open Abb.Future.Infix_monad in
    (if enabled then
       Metrics.Psql_query_time.time (Metrics.psql_query_time "upsert_drift_schedule") (fun () ->
           let open Abbs_future_combinators.Infix_result_monad in
           let names = Iter.to_list @@ V1.String_map.keys schedules in
           Pgsql_io.Prepared_stmt.execute
             db
             Sql.delete_drift_schedules
             (CCInt64.of_int @@ Api.Repo.id repo)
             names
           >>= fun () ->
           Abbs_future_combinators.List_result.iter
             ~f:(fun (name, { D.Schedule.reconcile; schedule; tag_query; window }) ->
               let window_start, window_end =
                 CCOption.map_or
                   ~default:(None, None)
                   (fun { D.Window.start; end_ } -> (Some start, Some end_))
                   window
               in
               Pgsql_io.Prepared_stmt.execute
                 db
                 Sql.upsert_drift_schedule
                 (CCInt64.of_int @@ Api.Repo.id repo)
                 schedule
                 reconcile
                 (Some tag_query)
                 name
                 window_start
                 window_end)
             (V1.String_map.to_list schedules))
     else
       Pgsql_io.Prepared_stmt.execute
         db
         Sql.delete_drift_schedules
         (CCInt64.of_int @@ Api.Repo.id repo)
         [])
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_account_status ~request_id db account =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time
      (Metrics.psql_query_time "select_installation_account_status")
      (fun () ->
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.select_installation_account_status ())
          ~f:(fun account_status trial_end_days -> (account_status, trial_end_days))
          (CCInt64.of_int @@ Api.Account.id account))
    >>= function
    | Ok (("expired", _) :: _) -> Abb.Future.return (Ok `Expired)
    | Ok (("disabled", _) :: _) -> Abb.Future.return (Ok `Disabled)
    | Ok (("trial_ending", Some trial_end_days) :: _) ->
        (* Ensure that trial end always is now or in the future *)
        Abb.Future.return
          (Ok (`Trial_ending (Duration.of_day (CCInt.max 0 (CCInt32.to_int trial_end_days)))))
    | Ok (("trial_ending", None) :: _) -> Abb.Future.return (Ok (`Trial_ending (Duration.of_day 0)))
    | Ok _ -> Abb.Future.return (Ok `Active)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_index ~request_id db account ref_ =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "select_index") (fun () ->
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_index
          ~f:CCFun.id
          (CCInt64.of_int @@ Api.Account.id account)
          (Api.Ref.to_string ref_))
    >>= function
    | Ok (idx :: _) -> Abb.Future.return (Ok (Some (index_of_index idx)))
    | Ok [] -> Abb.Future.return (Ok None)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_repo_config_json ~request_id db account ref_ =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "select_repo_config") (fun () ->
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_repo_config
          ~f:CCFun.id
          (CCInt64.of_int @@ Api.Account.id account)
          (Api.Ref.to_string ref_))
    >>= function
    | Ok (repo_config :: _) -> Abb.Future.return (Ok (Some repo_config))
    | Ok [] -> Abb.Future.return (Ok None)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_next_pending_work_manifest ~request_id db =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Metrics.Psql_query_time.time (Metrics.psql_query_time "select_next_work_manifest") (fun () ->
          Pgsql_io.Prepared_stmt.fetch db ~f:CCFun.id Sql.select_next_work_manifest)
      >>= function
      | [] -> Abb.Future.return (Ok None)
      | [ id ] ->
          Abbs_time_it.run
            (fun time ->
              Logs.info (fun m ->
                  m
                    "GITHUB_EVALUATOR : %s : QUERY_WORK_MANIFEST : id=%a : time=%f"
                    request_id
                    Uuidm.pp
                    id
                    time))
            (fun () ->
              query_work_manifest ~request_id db id
              >>= function
              | Some wm ->
                  let module Wm = Terrat_work_manifest3 in
                  assert (wm.Wm.state = Wm.State.Queued);
                  Abb.Future.return (Ok (Some wm))
              | None -> Abb.Future.return (Ok None))
      | _ :: _ -> assert false
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)
    | Error (#Pgsql_pool.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_pool.pp_err err);
        Abb.Future.return (Error `Error)
    | Error `Error -> Abb.Future.return (Error `Error)

  let query_flow_state ~request_id db work_manifest_id =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "select_flow_state") (fun () ->
        Pgsql_io.Prepared_stmt.fetch db (Sql.select_flow_state ()) ~f:CCFun.id work_manifest_id)
    >>= function
    | Ok (data :: _) -> Abb.Future.return (Ok (Some data))
    | Ok [] -> Abb.Future.return (Ok None)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let delete_flow_state ~request_id db work_manifest_id =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "delete_flow_state") (fun () ->
        Pgsql_io.Prepared_stmt.execute db (Sql.delete_flow_state ()) work_manifest_id)
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_pull_request_out_of_change_applies ~request_id db pull_request =
    let run =
      Metrics.Psql_query_time.time (Metrics.psql_query_time "select_out_of_diff_applies") (fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_out_of_diff_applies
            ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
            (CCInt64.of_int @@ Api.Repo.id @@ Pull_request.repo pull_request)
            (CCInt64.of_int @@ Pull_request.id pull_request))
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_applied_dirspaces ~request_id db pull_request =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time
      (Metrics.psql_query_time "select_dirspace_applies_for_pull_request")
      (fun () ->
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_dirspace_applies_for_pull_request
          ~f:(fun dir workspace -> { Terrat_dirspace.dir; workspace })
          (CCInt64.of_int @@ Api.Repo.id @@ Pull_request.repo pull_request)
          (CCInt64.of_int @@ Pull_request.id pull_request))
    >>= function
    | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_dirspaces_without_valid_plans ~request_id db pull_request dirspaces =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time
      (Metrics.psql_query_time "select_dirspaces_without_valid_plans")
      (fun () ->
        Pgsql_io.Prepared_stmt.fetch
          db
          ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
          Sql.select_dirspaces_without_valid_plans
          (CCInt64.of_int @@ Api.Repo.id @@ Pull_request.repo pull_request)
          (CCInt64.of_int @@ Pull_request.id pull_request)
          (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
          (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces))
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_conflicting_work_manifests_in_repo ~request_id db pull_request dirspaces op =
    let run_type =
      match op with
      | `Plan -> Terrat_work_manifest3.Step.Plan
      | `Apply -> Terrat_work_manifest3.Step.Apply
    in
    let dirs = CCList.map (fun Terrat_change.Dirspace.{ dir; _ } -> dir) dirspaces in
    let workspaces =
      CCList.map (fun Terrat_change.Dirspace.{ workspace; _ } -> workspace) dirspaces
    in
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Metrics.Psql_query_time.time
        (Metrics.psql_query_time "update_abort_duplicate_work_manifests")
        (fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            (Sql.update_abort_duplicate_work_manifests ())
            ~f:CCFun.id
            (CCInt64.of_int @@ Api.Repo.id @@ Pull_request.repo pull_request)
            (CCInt64.of_int @@ Pull_request.id pull_request)
            run_type
            dirs
            workspaces)
      >>= fun ids ->
      CCList.iter
        (fun id ->
          Logs.info (fun m ->
              m "GITHUB_EVALUATOR : %s : ABORTED_WORK_MANIFEST : %a" request_id Uuidm.pp id))
        ids;
      Metrics.Psql_query_time.time
        (Metrics.psql_query_time "select_conflicting_work_manifests_in_repo")
        (fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            (Sql.select_conflicting_work_manifests_in_repo ())
            ~f:(fun id maybe_stale -> (id, maybe_stale))
            (CCInt64.of_int @@ Api.Repo.id @@ Pull_request.repo pull_request)
            (CCInt64.of_int @@ Pull_request.id pull_request)
            run_type
            dirs
            workspaces)
      >>= fun ids ->
      match
        CCList.partition_filter_map
          (function
            | id, true -> `Right id
            | id, false -> `Left id)
          ids
      with
      | (_ :: _ as conflicting), _ ->
          Abbs_future_combinators.List_result.map
            ~f:(query_work_manifest ~request_id db)
            conflicting
          >>= fun wms ->
          Abb.Future.return
            (Ok
               (Some
                  (Terrat_vcs_provider2.Conflicting_work_manifests.Conflicting
                     (CCList.filter_map CCFun.id wms))))
      | _, (_ :: _ as maybe_stale) ->
          Abbs_future_combinators.List_result.map
            ~f:(query_work_manifest ~request_id db)
            maybe_stale
          >>= fun wms ->
          Abb.Future.return
            (Ok
               (Some
                  (Terrat_vcs_provider2.Conflicting_work_manifests.Maybe_stale
                     (CCList.filter_map CCFun.id wms))))
      | _, _ -> Abb.Future.return (Ok None)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok wms -> Abb.Future.return (Ok wms)
    | Error `Error -> Abb.Future.return (Error `Error)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_dirspaces_owned_by_other_pull_requests ~request_id db pull_request dirspaces =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time
      (Metrics.psql_query_time "select_dirspaces_owned_by_other_pull_requests")
      (fun () ->
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.select_dirspaces_owned_by_other_pull_requests ())
          ~f:(fun
              dir
              workspace
              base_branch
              branch
              base_hash
              hash
              merged_hash
              merged_at
              pull_number
              state
              title
              user
            ->
            ( Terrat_change.Dirspace.{ dir; workspace },
              Pull_request.make
                ~base_branch_name:(Api.Ref.of_string base_branch)
                ~base_ref:(Api.Ref.of_string base_hash)
                ~branch_name:(Api.Ref.of_string branch)
                ~branch_ref:(Api.Ref.of_string hash)
                ~checks:()
                ~diff:()
                ~draft:false
                ~id:(CCInt64.to_int pull_number)
                ~mergeable:None
                ~provisional_merge_ref:None
                ~repo:(Pull_request.repo pull_request)
                ~state:
                  (match (state, merged_hash, merged_at) with
                  | "open", _, _ -> Terrat_pull_request.State.(Open Open_status.Mergeable)
                  | "closed", _, _ -> Terrat_pull_request.State.Closed
                  | "merged", Some merged_hash, Some merged_at ->
                      Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                  | _ -> assert false)
                ~title
                ~user
                () ))
          (CCInt64.of_int @@ Api.Repo.id @@ Pull_request.repo pull_request)
          (CCInt64.of_int @@ Pull_request.id pull_request)
          (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
          (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces))
    >>= function
    | Ok _ as res -> Abb.Future.return res
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_missing_drift_scheduled_runs ~request_id db =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time
      (Metrics.psql_query_time "select_missing_drift_scheduled_runs")
      (fun () ->
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.select_missing_drift_scheduled_runs ())
          ~f:(fun drift_name installation_id repository_id owner name reconcile tag_query ->
            ( drift_name,
              Api.Account.make @@ CCInt64.to_int installation_id,
              Api.Repo.make ~id:(CCInt64.to_int repository_id) ~owner ~name (),
              reconcile,
              CCOption.get_or ~default:Terrat_tag_query.any tag_query )))
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : DRIFT : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let cleanup_repo_configs ~request_id db =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "cleanup_repo_configs") (fun () ->
        Pgsql_io.Prepared_stmt.execute db Sql.cleanup_repo_configs)
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let cleanup_flow_states ~request_id db =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "delete_stale_flow_states") (fun () ->
        Pgsql_io.Prepared_stmt.execute db (Sql.delete_stale_flow_states ()))
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let cleanup_plans ~request_id db =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "delete_old_plans") (fun () ->
        Pgsql_io.Prepared_stmt.execute db Sql.delete_old_plans)
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let unlock' db repo = function
    | Unlock_id.Pull_request pull_request_id ->
        Metrics.Psql_query_time.time
          (Metrics.psql_query_time "insert_pull_request_unlock")
          (fun () ->
            Pgsql_io.Prepared_stmt.execute
              db
              (Sql.insert_pull_request_unlock ())
              (CCInt64.of_int @@ Api.Repo.id repo)
              (CCInt64.of_int pull_request_id))
    | Unlock_id.Drift ->
        Metrics.Psql_query_time.time (Metrics.psql_query_time "insert_drift_unlock") (fun () ->
            Pgsql_io.Prepared_stmt.execute
              db
              (Sql.insert_drift_unlock ())
              (CCInt64.of_int @@ Api.Repo.id repo))

  let unlock ~request_id db repo unlock_id =
    let open Abb.Future.Infix_monad in
    unlock' db repo unlock_id
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)
    | Error (#Pgsql_pool.err as err) ->
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_pool.pp_err err);
        Abb.Future.return (Error `Error)

  let query_plan ~request_id db work_manifest_id dirspace =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Metrics.Psql_query_time.time (Metrics.psql_query_time "select_recent_plan") (fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_recent_plan
            ~f:CCFun.id
            work_manifest_id
            dirspace.Terrat_dirspace.dir
            dirspace.Terrat_dirspace.workspace)
      >>= function
      | [] -> Abb.Future.return (Ok None)
      | data :: _ ->
          Metrics.Psql_query_time.time (Metrics.psql_query_time "delete_plan") (fun () ->
              Pgsql_io.Prepared_stmt.execute
                db
                (Sql.delete_plan ())
                work_manifest_id
                dirspace.Terrat_dirspace.dir
                dirspace.Terrat_dirspace.workspace)
          >>= fun () -> Abb.Future.return (Ok (Some data))
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let store_plan ~request_id db work_manifest_id dirspace data has_changes =
    let open Abb.Future.Infix_monad in
    Metrics.Psql_query_time.time (Metrics.psql_query_time "upsert_plan") (fun () ->
        Pgsql_io.Prepared_stmt.execute
          db
          Sql.upsert_plan
          work_manifest_id
          dirspace.Terrat_dirspace.dir
          dirspace.Terrat_dirspace.workspace
          data
          has_changes)
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)
end

module Apply_requirements = struct
  module Result = struct
    type result = {
      approved : bool option;
      approved_reviews : Terrat_pull_request_review.t list;
      match_ : Terrat_change_match3.Dirspace_config.t;
      merge_conflicts : bool option;
      passed : bool;
      ready_for_review : bool option;
      status_checks : bool option;
      status_checks_failed : Terrat_commit_check.t list;
    }

    type t = result list

    let passed t = CCList.for_all (fun { passed; _ } -> passed) t

    let approved_reviews t =
      CCList.flatten (CCList.map (fun { approved_reviews; _ } -> approved_reviews) t)
  end

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

  let match_query ~request_id client repo user =
    let module M = Terrat_base_repo_config_v1.Access_control.Match in
    function
    | M.User value -> Abb.Future.return (Ok (CCString.equal value @@ Api.User.to_string user))
    | M.Team value -> (
        let open Abb.Future.Infix_monad in
        Api.is_member_of_team ~request_id ~team:value ~user repo client
        >>= function
        | Ok res -> Abb.Future.return (Ok res)
        | Error _ -> Abb.Future.return (Error `Error))
    | M.Role value -> (
        let open Abb.Future.Infix_monad in
        match CCList.find_idx CCFun.(fst %> CCString.equal value) repo_permission_levels with
        | Some (idx, _) -> (
            Api.get_repo_role ~request_id repo user client
            >>= function
            | Ok (Some role) -> (
                match CCList.find_idx CCFun.(snd %> CCString.equal role) repo_permission_levels with
                | Some (idx_role, _) ->
                    (* Test if their actual role has an index less than or
                           equal to the index of the role in the query. *)
                    Abb.Future.return (Ok (idx_role <= idx))
                | None -> Abb.Future.return (Ok false))
            | Ok None -> Abb.Future.return (Ok false)
            | Error _ -> Abb.Future.return (Error `Error))
        | None -> raise (Failure "nyi")
        (* Abb.Future.return (Error (`Invalid_query query)) *))
    | M.Any -> Abb.Future.return (Ok true)

  let compute_approved ~request_id client repo approved approved_reviews =
    let module Match_set = CCSet.Make (Terrat_base_repo_config_v1.Access_control.Match) in
    let module Match_map = CCMap.Make (Terrat_base_repo_config_v1.Access_control.Match) in
    let open Abbs_future_combinators.Infix_result_monad in
    let module Tprr = Terrat_pull_request_review in
    let module Ac = Terrat_base_repo_config_v1.Apply_requirements.Approved in
    let { Ac.all_of; any_of; any_of_count; enabled } = approved in
    let combined_queries = Match_set.(to_list (of_list (all_of @ any_of))) in
    Abbs_future_combinators.List_result.fold_left
      ~init:Match_map.empty
      ~f:(fun acc query ->
        Abbs_future_combinators.List_result.filter_map
          ~f:(function
            | { Tprr.user = Some user; _ } -> (
                let user = Api.User.make user in
                match_query ~request_id client repo user query
                >>= function
                | true -> Abb.Future.return (Ok (Some user))
                | false -> Abb.Future.return (Ok None))
            | _ -> Abb.Future.return (Ok None))
          approved_reviews
        >>= fun matching_reviews ->
        Abb.Future.return
          (Ok
             (CCList.fold_left
                (fun acc user -> Match_map.add_to_list query user acc)
                acc
                matching_reviews)))
      combined_queries
    >>= fun matching_reviews ->
    let all_of_results = CCList.map (CCFun.flip Match_map.mem matching_reviews) all_of in
    let any_of_results =
      CCList.flatten (CCList.filter_map (CCFun.flip Match_map.find_opt matching_reviews) any_of)
    in
    let all_of_passed = CCList.for_all CCFun.id all_of_results in
    let any_of_passed =
      (CCList.is_empty any_of && CCList.length approved_reviews >= any_of_count)
      || ((not (CCList.is_empty any_of)) && CCList.length any_of_results >= any_of_count)
    in
    Logs.info (fun m ->
        m
          "GITHUB_EVALUATOR : %s : COMPUTE_APPROVED : all_of_passed=%s : any_of_passed=%s"
          request_id
          (Bool.to_string all_of_passed)
          (Bool.to_string any_of_passed));
    (* Considered approved if all "all_of" passes and any "any_of" passes OR
         "all of" and "any of" are empty and the approvals is more than count *)
    Abb.Future.return (Ok (all_of_passed && any_of_passed))

  let eval ~request_id config user client repo_config pull_request dirspace_configs =
    let max_parallel = 20 in
    let module R = Terrat_base_repo_config_v1 in
    let module Ar = R.Apply_requirements in
    let module Abc = Ar.Check in
    let module Mc = Ar.Merge_conflicts in
    let module Sc = Ar.Status_checks in
    let module Ac = Ar.Approved in
    let open Abbs_future_combinators.Infix_result_monad in
    let log_time ?m request_id name t =
      Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : %s : %f" request_id name t);
      match m with
      | Some m -> Metrics.Time_histogram.observe m t
      | None -> ()
    in
    let filter_relevant_commit_checks ignore_matching_pats ignore_matching commit_checks =
      CCList.filter
        (fun Terrat_commit_check.{ title; _ } ->
          not
            (CCString.equal "terrateam apply" title
            || CCString.prefix ~pre:"terrateam apply:" title
            || CCString.prefix ~pre:"terrateam plan:" title
            || CCList.mem
                 ~eq:CCString.equal
                 title
                 [ "terrateam apply pre-hooks"; "terrateam apply post-hooks" ]
            || CCList.exists CCFun.(Lua_pattern.find title %> CCOption.is_some) ignore_matching_pats
            || CCList.exists (CCString.equal title) ignore_matching))
        commit_checks
    in
    let { Ar.checks; _ } = R.apply_requirements repo_config in
    Abbs_future_combinators.Infix_result_app.(
      (fun reviews commit_checks -> (reviews, commit_checks))
      <$> Abbs_time_it.run (log_time request_id "FETCH_APPROVED_TIME") (fun () ->
              Api.fetch_pull_request_reviews
                ~request_id
                (Pull_request.repo pull_request)
                (Pull_request.id pull_request)
                client)
      <*> Abbs_time_it.run (log_time request_id "FETCH_COMMIT_CHECKS_TIME") (fun () ->
              Api.fetch_commit_checks
                ~request_id
                client
                (Pull_request.repo pull_request)
                (Pull_request.branch_ref pull_request)))
    >>= fun (reviews, commit_checks) ->
    let approved_reviews =
      CCList.filter
        (function
          | Terrat_pull_request_review.{ status = Status.Approved; _ } -> true
          | _ -> false)
        reviews
    in
    let merge_result = CCOption.get_or ~default:false @@ Pull_request.mergeable pull_request in
    if CCOption.is_none @@ Pull_request.mergeable pull_request then
      Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : MERGEABLE_NONE" request_id);
    let open Abb.Future.Infix_monad in
    Abbs_future_combinators.List_result.map
      ~f:(fun chunk ->
        Abbs_future_combinators.List_result.map
          ~f:(fun ({ Terrat_change_match3.Dirspace_config.tags; dirspace; _ } as match_) ->
            let open Abbs_future_combinators.Infix_result_monad in
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : CHECK_APPLY_REQUIREMENTS : dir=%s : workspace=%s"
                  request_id
                  dirspace.Terrat_dirspace.dir
                  dirspace.Terrat_dirspace.workspace);
            match
              CCList.find_opt
                (fun { Abc.tag_query; _ } ->
                  let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
                  Terrat_tag_query.match_ ~ctx ~tag_set:tags tag_query)
                checks
            with
            | Some
                {
                  Abc.tag_query;
                  merge_conflicts;
                  status_checks;
                  approved;
                  require_ready_for_review_pr;
                } ->
                compute_approved
                  ~request_id
                  client
                  (Pull_request.repo pull_request)
                  approved
                  approved_reviews
                >>= fun approved_result ->
                let ignore_matching = status_checks.Sc.ignore_matching in
                (* Convert all patterns and ignore those that don't compile.  This eats
                     errors.

                     TODO: Improve handling errors here *)
                let ignore_matching_pats =
                  CCList.filter_map Lua_pattern.of_string ignore_matching
                in
                (* Relevant checks exclude our terrateam checks, and also exclude any
                     ignored patterns.  We check both if a pattern matches OR if there is an
                     exact match with the string.  This is because someone might put in an
                     invalid pattern (because secretly we are using Lua patterns underneath
                     which have a slightly different syntax) *)
                let relevant_commit_checks =
                  filter_relevant_commit_checks ignore_matching_pats ignore_matching commit_checks
                in
                let failed_commit_checks =
                  CCList.filter
                    (function
                      | Terrat_commit_check.{ status = Status.Completed; _ } -> false
                      | _ -> true)
                    relevant_commit_checks
                in
                CCList.iter
                  (fun { Terrat_commit_check.title; status; _ } ->
                    Logs.debug (fun m ->
                        m
                          "GITHUB_EVALUATOR : %s : COMMIT_CHECK : %s : %a"
                          request_id
                          title
                          Terrat_commit_check.Status.pp
                          status))
                  relevant_commit_checks;
                let all_commit_check_success = CCList.is_empty failed_commit_checks in
                let merged =
                  let module St = Terrat_pull_request.State in
                  match Pull_request.state pull_request with
                  | St.Merged _ -> true
                  | St.Open _ | St.Closed -> false
                in
                let ready_for_review =
                  (not require_ready_for_review_pr) || not (Pull_request.is_draft_pr pull_request)
                in
                let passed =
                  merged
                  || ((not approved.Ac.enabled) || approved_result)
                     && ((not merge_conflicts.Mc.enabled) || merge_result)
                     && ((not status_checks.Sc.enabled) || all_commit_check_success)
                     && ready_for_review
                in
                let apply_requirements =
                  {
                    Result.passed;
                    match_;
                    approved = (if approved.Ac.enabled then Some approved_result else None);
                    merge_conflicts =
                      (if merge_conflicts.Mc.enabled then Some merge_result else None);
                    ready_for_review =
                      (if require_ready_for_review_pr then Some ready_for_review else None);
                    status_checks =
                      (if status_checks.Sc.enabled then Some all_commit_check_success else None);
                    status_checks_failed = failed_commit_checks;
                    approved_reviews;
                  }
                in
                Logs.info (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : APPLY_REQUIREMENTS_CHECKS : tag_query=%s \
                       approved=%s merge_conflicts=%s status_checks=%s require_ready_for_review=%s"
                      request_id
                      (Terrat_tag_query.to_string tag_query)
                      (Bool.to_string approved.Ac.enabled)
                      (Bool.to_string merge_conflicts.Mc.enabled)
                      (Bool.to_string status_checks.Sc.enabled)
                      (Bool.to_string require_ready_for_review_pr));
                Logs.info (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : APPLY_REQUIREMENTS_RESULT : tag_query=%s \
                       approved=%s merge_check=%s commit_check=%s merged=%s ready_for_review=%s \
                       passed=%s"
                      request_id
                      (Terrat_tag_query.to_string tag_query)
                      (Bool.to_string approved_result)
                      (Bool.to_string merge_result)
                      (Bool.to_string all_commit_check_success)
                      (Bool.to_string merged)
                      (Bool.to_string ready_for_review)
                      (Bool.to_string passed));
                Abb.Future.return (Ok apply_requirements)
            | None ->
                Abb.Future.return
                  (Ok
                     {
                       Result.passed = false;
                       match_;
                       approved = None;
                       merge_conflicts = None;
                       ready_for_review = None;
                       status_checks = None;
                       status_checks_failed = [];
                       approved_reviews = [];
                     }))
          chunk)
      (CCList.chunks (CCInt.max 1 (CCList.length dirspace_configs / max_parallel)) dirspace_configs)
    >>= function
    | Ok ret -> Abb.Future.return (Ok (CCList.flatten ret))
    | Error (`Error as ret) -> Abb.Future.return (Error ret)
end

module Comment = struct
  let publish_comment ~request_id client user pull_request msg = raise (Failure "nyi")
end

module Work_manifest = struct
  let run ~request_id config client = raise (Failure "nyi")
  let create ~request_id db work_manifest = raise (Failure "nyi")
  let query ~request_id db work_manifest_id = raise (Failure "nyi")
  let update_state ~request_id db work_manifest_id state = raise (Failure "nyi")
  let update_run_id ~request_id db work_manifest_id run_id = raise (Failure "nyi")
  let update_changes ~request_id db work_manifest_id dirspaceflows = raise (Failure "nyi")
  let update_denied_dirspaces ~request_id db work_manifest_id denies = raise (Failure "nyi")
  let update_steps ~request_id db work_manifest_id steps = raise (Failure "nyi")
  let result result = raise (Failure "nyi")
  let result2 result = raise (Failure "nyi")
end
