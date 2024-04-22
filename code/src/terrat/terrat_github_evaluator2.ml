module String_set = CCSet.Make (CCString)

let fetch_pull_request_tries = 6

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
        [ Terrat_work_manifest2.Run_type.to_string r; Bool.to_string c ]

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

  let policy =
    let module P = struct
      type t = string list [@@deriving yojson]
    end in
    CCFun.(
      CCOption.wrap Yojson.Safe.from_string
      %> CCOption.map P.of_yojson
      %> CCOption.flat_map CCResult.to_opt)

  let select_index =
    let index =
      CCFun.(
        CCOption.wrap Yojson.Safe.from_string
        %> CCOption.map Terrat_code_idx.of_yojson
        %> CCOption.flat_map CCResult.to_opt)
    in
    Pgsql_io.Typed_sql.(
      sql
      // (* Index *) Ret.(ud' index)
      /^ "select index from github_code_index where sha = $sha and installation_id = \
          $installation_id"
      /% Var.bigint "installation_id"
      /% Var.text "sha")

  let select_installation_account_status =
    Pgsql_io.Typed_sql.(
      sql
      // (* account_status *) Ret.text
      /^ "select account_status from github_installations where id = $installation_id"
      /% Var.bigint "installation_id")

  let select_out_of_diff_applies =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_out_of_diff_applies.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number")

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

  let update_abort_duplicate_work_manifests () =
    Pgsql_io.Typed_sql.(
      sql
      // (* work manifest id *) Ret.uuid
      /^ read "github_abort_duplicate_work_manifests.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.(ud (text "run_type") Terrat_work_manifest2.Run_type.to_string)
      /% Var.(str_array (text "dirs"))
      /% Var.(str_array (text "workspaces")))

  let select_conflicting_work_manifests_in_repo () =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.uuid
      // (* maybe_stale *) Ret.boolean
      /^ read "select_github_conflicting_work_manifests_in_repo2.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.(ud (text "run_type") Terrat_work_manifest2.Run_type.to_string)
      /% Var.(str_array (text "dirs"))
      /% Var.(str_array (text "workspaces")))

  let select_missing_dirspace_applies_for_pull_request =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_missing_dirspace_applies_for_pull_request.sql"
      /% Var.bigint "repo_id"
      /% Var.bigint "pull_number")

  let select_dirspaces_owned_by_other_pull_requests () =
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
      // (* title *) Ret.(option text)
      // (* username *) Ret.(option text)
      /^ read "select_github_dirspaces_owned_by_other_pull_requests.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.(str_array (text "dirs"))
      /% Var.(str_array (text "workspaces")))

  let insert_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.uuid
      // (* state *) Ret.ud' Terrat_work_manifest2.State.of_string
      // (* created_at *) Ret.text
      /^ read "insert_github_work_manifest.sql"
      /% Var.text "base_sha"
      /% Var.(option (bigint "pull_number"))
      /% Var.bigint "repository"
      /% Var.text "run_type"
      /% Var.text "sha"
      /% Var.text "tag_query"
      /% Var.(option (text "username"))
      /% Var.json "dirspaces"
      /% Var.text "run_kind")

  let update_work_manifest_state () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_work_manifests set state = $state where id = $id"
      /% Var.uuid "id"
      /% Var.(ud (text "state") Terrat_work_manifest2.State.to_string))

  let update_work_manifest_state_completed () =
    Pgsql_io.Typed_sql.(
      sql
      // (* completed_at *) Ret.text
      /^ "update github_work_manifests set state = 'completed', completed_at = now() where id = \
          $id returning to_char(completed_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')"
      /% Var.uuid "id")

  let update_work_manifest_run_id () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_work_manifests set run_id = $run_id where id = $id"
      /% Var.uuid "id"
      /% Var.(option (text "run_id")))

  let insert_work_manifest_dirspaceflow () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_work_manifest_dirspaceflows (work_manifest, path, workspace, \
          workflow_idx) select * from unnest($work_manifest, $path, $workspace, $workflow_idx)"
      /% Var.(str_array (uuid "work_manifest"))
      /% Var.(str_array (text "path"))
      /% Var.(str_array (text "workspace"))
      /% Var.(array (option (smallint "workflow_idx"))))

  let insert_work_manifest_access_control_denied_dirspace =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_work_manifest_access_control_denied_dirspace.sql"
      /% Var.(str_array (text "path"))
      /% Var.(str_array (text "workspace"))
      /% Var.(str_array (option (json "policy")))
      /% Var.(str_array (uuid "work_manifest")))

  let insert_dirspace =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_dirspaces.sql"
      /% Var.(str_array (text "base_sha"))
      /% Var.(str_array (text "path"))
      /% Var.(array (bigint "repository"))
      /% Var.(str_array (text "sha"))
      /% Var.(str_array (text "workspace"))
      /% Var.(str_array (text "lock_policy")))

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
      /% Var.text "state"
      /% Var.(option (text "title"))
      /% Var.(option (text "username")))

  let select_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      // (* base_sha *) Ret.text
      // (* completed_at *) Ret.(option text)
      // (* created_at *) Ret.text
      // (* pull_number *) Ret.(option bigint)
      // (* repository *) Ret.bigint
      // (* run_id *) Ret.(option text)
      // (* run_type *) Ret.(ud' Terrat_work_manifest2.Run_type.of_string)
      // (* sha *) Ret.text
      // (* state *) Ret.(ud' Terrat_work_manifest2.State.of_string)
      // (* tag_query *) Ret.(ud' CCFun.(Terrat_tag_query.of_string %> CCResult.to_opt))
      // (* username *) Ret.(option text)
      // (* run_kind *) Ret.text
      // (* installation_id *) Ret.bigint
      // (* repo_id *) Ret.bigint
      // (* repo_owner *) Ret.text
      // (* repo_name *) Ret.text
      /^ read "select_github_work_manifest2.sql"
      /% Var.uuid "id")

  let select_work_manifest_access_control_denied_dirspaces =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      // (* policy *) Ret.(option (ud' policy))
      /^ read "select_github_work_manifest_access_control_denied_dirspaces.sql"
      /% Var.uuid "work_manifest")

  let select_work_manifest_dirspaceflows =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workflow_idx *) Ret.(option smallint)
      // (* workspace *) Ret.text
      /^ "select path, workflow_idx, workspace from github_work_manifest_dirspaceflows where \
          work_manifest = $id"
      /% Var.uuid "id")

  let select_work_manifest_pull_request () =
    Pgsql_io.Typed_sql.(
      sql
      // (* base_branch_name *) Ret.text
      // (* base_ref *) Ret.text
      // (* branch_name *) Ret.text
      // (* branch_ref *) Ret.text
      // (* pull_number *) Ret.bigint
      // (* state *) Ret.text
      // (* merged_sha *) Ret.(option text)
      // (* merged_at *) Ret.(option text)
      // (* title *) Ret.(option text)
      // (* username *) Ret.(option text)
      /^ read "select_github_work_manifest_pull_request.sql"
      /% Var.uuid "id")

  let select_next_work_manifest =
    Pgsql_io.Typed_sql.(sql // (* id *) Ret.uuid /^ read "select_next_github_work_manifest.sql")

  let abort_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_work_manifests set state = 'aborted', completed_at = now() where id = $id \
          and state in ('queued', 'running')"
      /% Var.uuid "id")

  let insert_pull_request_unlock () =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_pull_request_unlock.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number")

  let insert_drift_unlock () =
    Pgsql_io.Typed_sql.(sql /^ read "insert_github_drift_unlock.sql" /% Var.bigint "repository")

  let select_missing_drift_scheduled_runs () =
    Pgsql_io.Typed_sql.(
      sql
      // (* installation_id *) Ret.bigint
      // (* repository *) Ret.bigint
      // (* owner *) Ret.text
      // (* name *) Ret.text
      // (* reconcile *) Ret.boolean
      // (* tag_query *) Ret.(option (ud' CCFun.(Terrat_tag_query.of_string %> CCResult.to_opt)))
      /^ read "github_select_missing_drift_scheduled_runs.sql")

  let upsert_drift_schedule =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "github_upsert_drift_schedule.sql"
      /% Var.bigint "repo"
      /% Var.text "schedule"
      /% Var.boolean "reconcile"
      /% Var.(option (ud (text "tag_query") Terrat_tag_query.to_string)))

  let delete_drift_schedule =
    Pgsql_io.Typed_sql.(
      sql
      /^ "delete from github_drift_schedules where repository = $repo_id"
      /% Var.bigint "repo_id")

  let insert_index () =
    Pgsql_io.Typed_sql.(
      sql /^ read "github_insert_code_index.sql" /% Var.uuid "work_manifest" /% Var.json "index")

  let insert_github_work_manifest_result =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_work_manifest_result.sql"
      /% Var.uuid "work_manifest"
      /% Var.text "path"
      /% Var.text "workspace"
      /% Var.boolean "success")

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

  let delete_old_plans = Pgsql_io.Typed_sql.(sql /^ read "delete_github_old_terraform_plans.sql")

  let delete_plan () =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "delete_github_terraform_plan.sql"
      /% Var.uuid "id"
      /% Var.text "dir"
      /% Var.text "workspace")

  let delete_pull_request_plans () =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "delete_github_pull_request_plans.sql"
      /% Var.bigint "repo_id"
      /% Var.bigint "pull_number")

  let select_drift_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      // (* branch *) Ret.text
      // (* reconcile *) Ret.boolean
      /^ read "select_github_drift_work_manifest.sql"
      /% Var.uuid "work_manifest")

  let insert_drift_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_drift_work_manifests (work_manifest, branch) values($work_manifest, \
          $branch)"
      /% Var.uuid "work_manifest"
      /% Var.text "branch")

  let select_index_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      // (* branch *) Ret.text
      /^ "select branch from github_index_work_manifests where work_manifest = $work_manifest"
      /% Var.uuid "work_manifest")

  let insert_index_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_index_work_manifests (work_manifest, branch) values($work_manifest, \
          $branch)"
      /% Var.uuid "work_manifest"
      /% Var.text "branch")
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
    |> CCResult.get_exn
    |> fun tmpl -> Snabela.of_template tmpl Transformers.[ money; compact_plan; plan_diff ]

  let read_raw fname = CCOption.get_exn_or fname (Terrat_files_tmpl.read fname)
  let missing_plans = read "github_missing_plans.tmpl"

  let dirspaces_owned_by_other_pull_requests =
    read "github_dirspaces_owned_by_other_pull_requests.tmpl"

  let conflicting_work_manifests = read "github_conflicting_work_manifests.tmpl"
  let maybe_stale_work_manifests = read "github_maybe_stale_work_manifests.tmpl"
  let repo_config_parse_failure = read "github_repo_config_parse_failure.tmpl"
  let repo_config_generic_failure = read "github_repo_config_generic_failure.tmpl"
  let pull_request_not_appliable = read "github_pull_request_not_appliable.tmpl"
  let pull_request_not_mergeable = read "github_pull_request_not_mergeable.tmpl"
  let apply_no_matching_dirspaces = read "apply_no_matching_dirspaces.tmpl"
  let plan_no_matching_dirspaces = read "plan_no_matching_dirspaces.tmpl"
  let base_branch_not_default_branch = read "dest_branch_no_match.tmpl"
  let auto_apply_running = read "auto_apply_running.tmpl"
  let bad_custom_branch_tag_pattern = read "bad_custom_branch_tag_pattern.tmpl"
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
  let repo_config = read "repo_config.tmpl"
  let unexpected_temporary_err = read "unexpected_temporary_err.tmpl"
  let failed_to_start_workflow = read_raw "github_failed_to_start_workflow.tmpl"
  let failed_to_find_workflow = read_raw "github_failed_to_find_workflow.tmpl"
  let plan_complete = read "github_plan_complete.tmpl"
  let apply_complete = read "github_apply_complete.tmpl"

  let comment_too_large =
    "github_comment_too_large.tmpl"
    |> Terrat_files_tmpl.read
    |> CCOption.get_exn_or "github_comment_too_large.tmpl"

  let index_complete = read "github_index_complete.tmpl"
end

let log_time ?m request_id name t =
  Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : %s : %f" request_id name t);
  match m with
  | Some m -> Metrics.DefaultHistogram.observe m t
  | None -> ()

let clean_pull_request_plans ~repo_id ~pull_number db =
  Pgsql_io.Prepared_stmt.execute
    db
    (Sql.delete_pull_request_plans ())
    (CCInt64.of_int repo_id)
    (CCInt64.of_int pull_number)

let clean_work_manifest_dirspace_plan ~work_manifest_id ~dir ~workspace db =
  Pgsql_io.Prepared_stmt.execute db (Sql.delete_plan ()) work_manifest_id dir workspace

module S = struct
  module Account = struct
    type t = {
      installation_id : int;
      request_id : string;
    }

    let to_string t = CCInt.to_string t.installation_id
  end

  module Db = struct
    type err = Pgsql_io.err [@@deriving show]

    type t = {
      request_id : string;
      db : Pgsql_io.t;
    }

    let request_id t = t.request_id

    let tx t ~f =
      let open Abb.Future.Infix_monad in
      Pgsql_io.tx t.db ~f
      >>= function
      | Ok _ as r -> Abb.Future.return r
      | Error _ as err -> Abb.Future.return err
  end

  module Client = struct
    type t = {
      client : Githubc2_abb.t;
      config : Terrat_config.t;
      request_id : string;
    }

    let request_id t = t.request_id
  end

  module Ref = struct
    type t = string

    let to_string = CCFun.id
    let of_string = CCFun.id
  end

  module Repo = struct
    type t = {
      id : int;
      name : string;
      owner : string;
    }

    let id t = t.id
    let make ~id ~name ~owner () = { id; name; owner }
    let name t = t.name
    let owner t = t.owner
    let to_string t = t.owner ^ "/" ^ t.name
  end

  module Remote_repo = struct
    module R = Githubc2_components.Full_repository

    type t = R.t

    let default_branch t = t.R.primary.R.Primary.default_branch
  end

  module Index = struct
    type t = {
      account : Account.t;
      branch : string;
      pull_number : int option;
      repo : Repo.t;
    }

    let make ?pull_number ~account ~branch ~repo () = { account; branch; pull_number; repo }
    let account t = t.account
    let pull_number t = t.pull_number
    let repo t = t.repo
  end

  module Drift = struct
    type t = {
      account : Account.t;
      branch : string;
      reconcile : bool;
      repo : Repo.t;
    }

    let make ~account ~branch ~reconcile ~repo () = { account; branch; reconcile; repo }
    let account t = t.account
    let branch t = t.branch
    let reconcile t = t.reconcile
    let repo t = t.repo
  end

  module Pull_request = struct
    type fetched = {
      checks : bool;
      diff : Terrat_change.Diff.t list;
      is_draft_pr : bool;
      mergeable : bool option;
      provisional_merge_ref : Ref.t option;
    }

    type stored = unit

    type 'a t = {
      account : Account.t;
      base_branch_name : Ref.t;
      base_ref : Ref.t;
      branch_name : Ref.t;
      branch_ref : Ref.t;
      id : int;
      repo : Repo.t;
      state : Terrat_pull_request.State.t;
      title : string option;
      user : string option;
      value : 'a;
    }

    let account t = t.account
    let base_branch_name t = t.base_branch_name
    let base_ref t = t.base_ref
    let branch_name t = t.branch_name
    let branch_ref t = t.branch_ref
    let diff t = t.value.diff
    let id t = t.id
    let is_draft_pr t = t.value.is_draft_pr
    let provisional_merge_ref t = t.value.provisional_merge_ref
    let repo t = t.repo
    let state t = t.state
  end

  module Access_control = struct
    type ctx = {
      client : Githubc2_abb.t;
      config : Terrat_config.t;
      repo : Repo.t;
      user : string;
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
            ~org:ctx.repo.Repo.owner
            ~team:value
            ~user:ctx.user
            ctx.client
          >>= function
          | Ok res -> Abb.Future.return (Ok res)
          | Error _ -> Abb.Future.return (Error `Error))
      | Some ("repo", value) -> (
          let open Abb.Future.Infix_monad in
          match CCList.find_idx CCFun.(fst %> CCString.equal value) repo_permission_levels with
          | Some (idx, _) -> (
              Terrat_github.get_repo_collaborator_permission
                ~org:ctx.repo.Repo.owner
                ~repo:ctx.repo.Repo.name
                ~user:ctx.user
                ctx.client
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

    let set_user user ctx = { ctx with user }
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

  let create_client' config { Account.installation_id; request_id } =
    let open Abbs_future_combinators.Infix_result_monad in
    Terrat_github.get_installation_access_token config installation_id
    >>= fun access_token ->
    let client = Terrat_github.create config (`Token access_token) in
    Abb.Future.return (Ok { Client.client; request_id; config })

  let create_client config account =
    let open Abb.Future.Infix_monad in
    create_client' config account
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s: ERROR : %a"
              account.Account.request_id
              Terrat_github.pp_get_installation_access_token_err
              err);
        Abb.Future.return (Error `Error)

  let query_work_manifest db work_manifest_id =
    let module Wm = Terrat_work_manifest2 in
    let module Dsf = Terrat_change.Dirspaceflow in
    let module Ds = Terrat_change.Dirspace in
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_io.Prepared_stmt.fetch
        db.Db.db
        Sql.select_work_manifest_dirspaceflows
        ~f:(fun dir idx workspace -> { Dsf.dirspace = { Ds.dir; workspace }; workflow = idx })
        work_manifest_id
      >>= fun changes ->
      Pgsql_io.Prepared_stmt.fetch
        db.Db.db
        Sql.select_work_manifest_access_control_denied_dirspaces
        ~f:(fun dir workspace policy ->
          { Wm.Deny.dirspace = { Terrat_change.Dirspace.dir; workspace }; policy })
        work_manifest_id
      >>= fun denied_dirspaces ->
      Pgsql_io.Prepared_stmt.fetch
        db.Db.db
        (Sql.select_work_manifest ())
        ~f:(fun
            base_hash
            completed_at
            created_at
            pull_number
            repository
            run_id
            run_type
            hash
            state
            tag_query
            user
            run_kind
            installation_id
            repo_id
            owner
            name
          ->
          {
            Wm.base_hash;
            changes;
            completed_at;
            created_at;
            denied_dirspaces;
            hash;
            id = work_manifest_id;
            run_id;
            run_type;
            src =
              ( run_kind,
                {
                  Account.installation_id = CCInt64.to_int installation_id;
                  request_id = db.Db.request_id;
                },
                { Repo.id = CCInt64.to_int repo_id; owner; name },
                pull_number );
            state;
            tag_query;
            user;
          })
        work_manifest_id
      >>= function
      | [] -> Abb.Future.return (Ok None)
      | wm :: _ -> (
          match wm.Wm.src with
          | "index", account, repo, pull_number -> (
              Pgsql_io.Prepared_stmt.fetch
                db.Db.db
                (Sql.select_index_work_manifest ())
                ~f:CCFun.id
                work_manifest_id
              >>= function
              | [] -> assert false
              | branch :: _ ->
                  Abb.Future.return
                    (Ok
                       (Some
                          {
                            wm with
                            Wm.src =
                              Wm.Kind.Index
                                {
                                  Index.account;
                                  branch;
                                  pull_number = CCOption.map CCInt64.to_int pull_number;
                                  repo;
                                };
                          })))
          | "drift", account, repo, _ -> (
              Pgsql_io.Prepared_stmt.fetch
                db.Db.db
                (Sql.select_drift_work_manifest ())
                ~f:(fun branch reconcile -> (branch, reconcile))
                work_manifest_id
              >>= function
              | [] -> assert false
              | (branch, reconcile) :: _ ->
                  Abb.Future.return
                    (Ok
                       (Some
                          {
                            wm with
                            Wm.src = Wm.Kind.Drift { Drift.account; branch; reconcile; repo };
                          })))
          | "pr", account, repo, _ -> (
              Pgsql_io.Prepared_stmt.fetch
                db.Db.db
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
                  {
                    Pull_request.account;
                    base_branch_name;
                    base_ref;
                    branch_name;
                    branch_ref;
                    id = CCInt64.to_int pull_number;
                    repo;
                    state =
                      (match (state, merged_sha, merged_at) with
                      | "open", _, _ -> Terrat_pull_request.State.(Open Open_status.Mergeable)
                      | "closed", _, _ -> Terrat_pull_request.State.Closed
                      | "merged", Some merged_hash, Some merged_at ->
                          Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                      | _ -> assert false);
                    title;
                    user;
                    value = ();
                  })
                work_manifest_id
              >>= function
              | [] -> assert false
              | pr :: _ ->
                  Abb.Future.return (Ok (Some { wm with Wm.src = Wm.Kind.Pull_request pr })))
          | _ -> assert false)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

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

  let fetch_diff ~client ~owner ~repo pull_number =
    let open Abbs_future_combinators.Infix_result_monad in
    Terrat_github.fetch_pull_request_files ~owner ~repo ~pull_number client.Client.client
    >>= fun github_diff ->
    let diff = diff_of_github_diff github_diff in
    Abb.Future.return (Ok diff)

  let fetch_pull_request' account client repo pull_number =
    let owner = repo.Repo.owner in
    let repo_name = repo.Repo.name in
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun resp diff -> (resp, diff))
        <$> Terrat_github.fetch_pull_request
              ~owner
              ~repo:repo_name
              ~pull_number
              client.Client.client
        <*> fetch_diff ~client ~owner ~repo:repo_name pull_number)
      >>= fun (resp, diff) ->
      let module Ghc_comp = Githubc2_components in
      let module Pr = Ghc_comp.Pull_request in
      let module Head = Pr.Primary.Head in
      let module Base = Pr.Primary.Base in
      let module User = Ghc_comp.Simple_user in
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
                title;
                user = User.{ primary = Primary.{ login; _ }; _ };
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
          Logs.debug (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGEABLE : merged=%s : mergeable_state=%s : \
                 merge_commit_sha=%s"
                client.Client.request_id
                (Bool.to_string merged)
                mergeable_state
                (CCOption.get_or ~default:"" merge_commit_sha));
          Abb.Future.return
            (Ok
               ( mergeable_state,
                 {
                   Pull_request.account;
                   base_branch_name;
                   base_ref = base_sha;
                   branch_name;
                   branch_ref = head_sha;
                   id = pull_number;
                   state =
                     (match (merge_commit_sha, state, merged, merged_at) with
                     | Some _, "open", _, _ ->
                         Terrat_pull_request.State.(Open Open_status.Mergeable)
                     | None, "open", _, _ ->
                         Terrat_pull_request.State.(Open Open_status.Merge_conflict)
                     | Some merge_commit_sha, "closed", true, Some merged_at ->
                         Terrat_pull_request.State.(
                           Merged Merged.{ merged_hash = merge_commit_sha; merged_at })
                     | _, "closed", false, _ -> Terrat_pull_request.State.Closed
                     | _, _, _, _ -> assert false);
                   title = Some title;
                   user = Some login;
                   repo;
                   value =
                     {
                       Pull_request.checks =
                         merged
                         || CCList.mem
                              ~eq:CCString.equal
                              mergeable_state
                              [ "clean"; "unstable"; "has_hooks" ];
                       diff;
                       is_draft_pr = draft;
                       mergeable;
                       provisional_merge_ref = merge_commit_sha;
                     };
                 } ))
      | (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _) as err ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ERROR : %a"
                client.Client.request_id
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
            m
              "GITHUB_EVALUATOR : %s : ERROR : %s : %s : ERROR"
              client.Client.request_id
              owner
              repo_name);
        Abb.Future.return (Error `Error)
    | Error (#Terrat_github.compare_commits_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : %s : %s : %a"
              client.Client.request_id
              owner
              repo_name
              Terrat_github.pp_compare_commits_err
              err);
        Abb.Future.return (Error `Error)
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : %s : %s : %s"
              client.Client.request_id
              owner
              repo_name
              (Terrat_github.show_get_installation_access_token_err err));
        Abb.Future.return (Error `Error)

  let fetch_pull_request account client repo pull_number =
    (* We require a merge commit to continue, but GitHub may not be able to
       create it in time between us getting the event and querying.  So retry a
       few times. *)
    let open Abb.Future.Infix_monad in
    Abbs_future_combinators.retry
      ~f:(fun () -> fetch_pull_request' account client repo pull_number)
      ~while_:
        (Abbs_future_combinators.finite_tries fetch_pull_request_tries (function
            | Error _ | Ok ("unknown", Pull_request.{ state = Terrat_pull_request.State.Open _; _ })
              -> true
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

  let store_pull_request db pull_request =
    let open Abb.Future.Infix_monad in
    let module Pr = Pull_request in
    let module State = Terrat_pull_request.State in
    let merged_sha, merged_at, state =
      match pull_request.Pr.state with
      | State.Open _ -> (None, None, "open")
      | State.Closed -> (None, None, "closed")
      | State.(Merged { Merged.merged_hash; merged_at }) ->
          (Some merged_hash, Some merged_at, "merged")
    in
    Pgsql_io.Prepared_stmt.execute
      db.Db.db
      Sql.insert_pull_request
      pull_request.Pr.base_branch_name
      pull_request.Pr.base_ref
      pull_request.Pr.branch_name
      (CCInt64.of_int pull_request.Pr.id)
      (CCInt64.of_int pull_request.Pr.repo.Repo.id)
      pull_request.Pr.branch_ref
      merged_sha
      merged_at
      state
      pull_request.Pr.title
      pull_request.Pr.user
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let fetch_repo_config client repo ref_ =
    let open Abb.Future.Infix_monad in
    Terrat_github.fetch_repo_config
      ~python:(Terrat_config.python_exec client.Client.config)
      ~owner:repo.Repo.owner
      ~repo:repo.Repo.name
      ~ref_
      client.Client.client
    >>= function
    | Ok _ as r -> Abb.Future.return r
    | Error (#Terrat_github.fetch_repo_config_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : FETCH_REPO_CONFIG : %a"
              client.Client.request_id
              Terrat_github.pp_fetch_repo_config_err
              err);
        Abb.Future.return (Error (`Parse_err (Terrat_github.show_fetch_repo_config_err err)))

  let fetch_remote_repo client repo =
    let open Abb.Future.Infix_monad in
    Terrat_github.fetch_repo ~owner:repo.Repo.owner ~repo:repo.Repo.name client.Client.client
    >>= function
    | Ok _ as r -> Abb.Future.return r
    | Error (#Terrat_github.fetch_repo_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : FETCH_REMOTE_REPO : %a"
              client.Client.request_id
              Terrat_github.pp_fetch_repo_err
              err);
        Abb.Future.return (Error `Error)

  let fetch_tree client repo ref_ =
    let open Abb.Future.Infix_monad in
    Terrat_github.get_tree
      ~owner:repo.Repo.owner
      ~repo:repo.Repo.name
      ~sha:ref_
      client.Client.client
    >>= function
    | Ok _ as r -> Abb.Future.return r
    | Error (#Terrat_github.get_tree_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : FETCH_TREE : %a"
              client.Client.request_id
              Terrat_github.pp_get_tree_err
              err);
        Abb.Future.return (Error `Error)

  let query_index db account ref_ =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db.Db.db
      Sql.select_index
      ~f:CCFun.id
      (CCInt64.of_int account.Account.installation_id)
      ref_
    >>= function
    | Ok (idx :: _) ->
        let module Idx = Terrat_code_idx in
        let module Paths = Terrat_api_components.Work_manifest_index_paths in
        let module Symlinks = Terrat_api_components.Work_manifest_index_symlinks in
        let paths = Json_schema.String_map.to_list (Paths.additional idx.Idx.paths) in
        let symlinks =
          CCOption.map_or
            ~default:[]
            (fun idx -> Json_schema.String_map.to_list (Symlinks.additional idx))
            idx.Idx.symlinks
        in
        Abb.Future.return
          (Ok
             (Some
                (Terrat_change_match.Index.make
                   ~symlinks
                   (CCList.map
                      (fun (path, { Paths.Additional.modules; _ }) ->
                        (path, CCList.map (fun m -> Terrat_change_match.Index.Dep.Module m) modules))
                      paths))))
    | Ok [] -> Abb.Future.return (Ok None)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_account_status db account =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db.Db.db
      Sql.select_installation_account_status
      ~f:CCFun.id
      (CCInt64.of_int account.Account.installation_id)
    >>= function
    | Ok ("expired" :: _) -> Abb.Future.return (Ok `Expired)
    | Ok ("disabled" :: _) -> Abb.Future.return (Ok `Disabled)
    | Ok _ -> Abb.Future.return (Ok `Active)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)
    | Error (#Pgsql_pool.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_pool.pp_err err);
        Abb.Future.return (Error `Error)

  let query_pull_request_out_of_change_applies db pull_request =
    let run =
      Pgsql_io.Prepared_stmt.fetch
        db.Db.db
        Sql.select_out_of_diff_applies
        ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
        (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
        (CCInt64.of_int pull_request.Pull_request.id)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_dirspaces_without_valid_plans db pull_request dirspaces =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db.Db.db
      ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
      Sql.select_dirspaces_without_valid_plans
      (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
      (CCInt64.of_int pull_request.Pull_request.id)
      (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
      (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_conflicting_work_manifests_in_repo db pull_request dirspaces operation =
    let run_type = Terrat_evaluator2.Tf_operation.to_run_type operation in
    let dirs = CCList.map (fun Terrat_change.Dirspace.{ dir; _ } -> dir) dirspaces in
    let workspaces =
      CCList.map (fun Terrat_change.Dirspace.{ workspace; _ } -> workspace) dirspaces
    in
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_io.Prepared_stmt.fetch
        db.Db.db
        (Sql.update_abort_duplicate_work_manifests ())
        ~f:CCFun.id
        (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
        (CCInt64.of_int pull_request.Pull_request.id)
        run_type
        dirs
        workspaces
      >>= fun ids ->
      CCList.iter
        (fun id ->
          Logs.info (fun m ->
              m "GITHUB_EVALUATOR : %s : ABORTED_WORK_MANIFEST : %a" db.Db.request_id Uuidm.pp id))
        ids;
      Pgsql_io.Prepared_stmt.fetch
        db.Db.db
        (Sql.select_conflicting_work_manifests_in_repo ())
        ~f:(fun id maybe_stale -> (id, maybe_stale))
        (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
        (CCInt64.of_int pull_request.Pull_request.id)
        run_type
        dirs
        workspaces
      >>= fun ids ->
      match
        CCList.partition_filter_map
          (function
            | id, true -> `Right id
            | id, false -> `Left id)
          ids
      with
      | (_ :: _ as conflicting), _ ->
          Abbs_future_combinators.List_result.map ~f:(query_work_manifest db) conflicting
          >>= fun wms ->
          Abb.Future.return
            (Ok
               (Some
                  (Terrat_evaluator2.Conflicting_work_manifests.Conflicting
                     (CCList.filter_map CCFun.id wms))))
      | _, (_ :: _ as maybe_stale) ->
          Abbs_future_combinators.List_result.map ~f:(query_work_manifest db) maybe_stale
          >>= fun wms ->
          Abb.Future.return
            (Ok
               (Some
                  (Terrat_evaluator2.Conflicting_work_manifests.Maybe_stale
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
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_unapplied_dirspaces db pull_request =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db.Db.db
      Sql.select_missing_dirspace_applies_for_pull_request
      ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
      (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
      (CCInt64.of_int pull_request.Pull_request.id)
    >>= function
    | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let query_dirspaces_owned_by_other_pull_requests db pull_request dirspaces =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db.Db.db
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
          {
            Pull_request.account = pull_request.Pull_request.account;
            base_branch_name = base_branch;
            base_ref = base_hash;
            branch_name = branch;
            branch_ref = hash;
            id = CCInt64.to_int pull_number;
            repo = pull_request.Pull_request.repo;
            state =
              (match (state, merged_hash, merged_at) with
              | "open", _, _ -> Terrat_pull_request.State.(Open Open_status.Mergeable)
              | "closed", _, _ -> Terrat_pull_request.State.Closed
              | "merged", Some merged_hash, Some merged_at ->
                  Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
              | _ -> assert false);
            title;
            user;
            value = ();
          } ))
      (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
      (CCInt64.of_int pull_request.Pull_request.id)
      (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
      (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
    >>= function
    | Ok _ as res -> Abb.Future.return res
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let create_work_manifest db work_manifest =
    let run =
      let module Wm = Terrat_work_manifest2 in
      let module Tc = Terrat_change in
      let module Dsf = Tc.Dirspaceflow in
      let module Ds = Tc.Dirspace in
      let open Abbs_future_combinators.Infix_result_monad in
      let dirspaces_json =
        `List
          (CCList.map
             (fun dsf ->
               let ds = Dsf.to_dirspace dsf in
               `Assoc [ ("dir", `String ds.Ds.dir); ("workspace", `String ds.Ds.workspace) ])
             work_manifest.Wm.changes)
      in
      let dirspaces = Yojson.Safe.to_string dirspaces_json in
      let pull_number_opt =
        match work_manifest.Wm.src with
        | Wm.Kind.Pull_request { Pull_request.id; _ } -> Some id
        | Wm.Kind.Index { Index.pull_number; _ } -> pull_number
        | Wm.Kind.Drift _ -> None
      in
      let repo_id =
        match work_manifest.Wm.src with
        | Wm.Kind.Pull_request { Pull_request.repo = { Repo.id; _ }; _ }
        | Wm.Kind.Drift { Drift.repo = { Repo.id; _ }; _ }
        | Wm.Kind.Index { Index.repo = { Repo.id; _ }; _ } -> id
      in
      let run_kind =
        match work_manifest.Wm.src with
        | Wm.Kind.Pull_request _ -> "pr"
        | Wm.Kind.Drift _ -> "drift"
        | Wm.Kind.Index _ -> "index"
      in
      let src =
        match work_manifest.Wm.src with
        | Wm.Kind.Pull_request pr ->
            Wm.Kind.Pull_request { pr with Pull_request.value = (() : Pull_request.stored) }
        | (Wm.Kind.Drift _ | Wm.Kind.Index _) as any -> any
      in
      Pgsql_io.Prepared_stmt.fetch
        db.Db.db
        (Sql.insert_work_manifest ())
        ~f:(fun id state created_at -> (id, state, created_at))
        work_manifest.Wm.base_hash
        (CCOption.map CCInt64.of_int pull_number_opt)
        (CCInt64.of_int repo_id)
        (Terrat_work_manifest2.Run_type.to_string work_manifest.Wm.run_type)
        work_manifest.Wm.hash
        (Terrat_tag_query.to_string work_manifest.Wm.tag_query)
        work_manifest.Wm.user
        dirspaces
        run_kind
      >>= function
      | [] -> assert false
      | (id, state, created_at) :: _ -> (
          let work_manifest = { work_manifest with Wm.id; state; created_at; run_id = None; src } in
          match work_manifest.Wm.src with
          | Wm.Kind.Pull_request _ -> Abb.Future.return (Ok work_manifest)
          | Wm.Kind.Drift { Drift.branch; _ } ->
              Pgsql_io.Prepared_stmt.execute db.Db.db (Sql.insert_drift_work_manifest ()) id branch
              >>= fun () -> Abb.Future.return (Ok work_manifest)
          | Wm.Kind.Index { Index.branch; _ } ->
              Pgsql_io.Prepared_stmt.execute db.Db.db (Sql.insert_index_work_manifest ()) id branch
              >>= fun () -> Abb.Future.return (Ok work_manifest))
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let insert_work_manifest_changes db work_manifest =
    let module Wm = Terrat_work_manifest2 in
    let module Tc = Terrat_change in
    let module Dsf = Tc.Dirspaceflow in
    let module Ds = Tc.Dirspace in
    Abbs_future_combinators.List_result.iter
      ~f:(fun changes ->
        Pgsql_io.Prepared_stmt.execute
          db.Db.db
          (Sql.insert_work_manifest_dirspaceflow ())
          (CCList.replicate (CCList.length changes) work_manifest.Wm.id)
          (CCList.map (fun { Dsf.dirspace = { Ds.dir; _ }; _ } -> dir) changes)
          (CCList.map (fun { Dsf.dirspace = { Ds.workspace; _ }; _ } -> workspace) changes)
          (CCList.map (fun { Dsf.workflow; _ } -> workflow) changes))
      (CCList.chunks 500 work_manifest.Wm.changes)

  let update_work_manifest db work_manifest =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      let module Wm = Terrat_work_manifest2 in
      let module Ch = Terrat_change in
      let module Cm = Terrat_change_match in
      let module Ac = Terrat_access_control in
      insert_work_manifest_changes db work_manifest
      >>= fun () ->
      let module Policy = struct
        type t = string list [@@deriving yojson]
      end in
      Abbs_future_combinators.List_result.iter
        ~f:(fun denied_dirspaces ->
          Pgsql_io.Prepared_stmt.execute
            db.Db.db
            Sql.insert_work_manifest_access_control_denied_dirspace
            (CCList.map
               (fun { Wm.Deny.dirspace = { Ch.Dirspace.dir; _ }; _ } -> dir)
               denied_dirspaces)
            (CCList.map
               (fun { Wm.Deny.dirspace = { Ch.Dirspace.workspace; _ }; _ } -> workspace)
               denied_dirspaces)
            (CCList.map
               (fun { Wm.Deny.policy; _ } ->
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
            (CCList.replicate (CCList.length denied_dirspaces) work_manifest.Wm.id))
        (CCList.chunks 500 work_manifest.Wm.denied_dirspaces)
      >>= fun () -> Abb.Future.return (Ok work_manifest)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let update_work_manifest_state' db work_manifest =
    let open Abbs_future_combinators.Infix_result_monad in
    let module Wm = Terrat_work_manifest2 in
    match work_manifest.Wm.state with
    | Wm.State.Queued | Wm.State.Running | Wm.State.Aborted ->
        Pgsql_io.Prepared_stmt.execute
          db.Db.db
          (Sql.update_work_manifest_state ())
          work_manifest.Wm.id
          work_manifest.Wm.state
        >>= fun () -> Abb.Future.return (Ok work_manifest)
    | Wm.State.Completed -> (
        Pgsql_io.Prepared_stmt.fetch
          db.Db.db
          (Sql.update_work_manifest_state_completed ())
          ~f:CCFun.id
          work_manifest.Wm.id
        >>= function
        | [] -> assert false
        | completed_at :: _ ->
            Abb.Future.return (Ok { work_manifest with Wm.completed_at = Some completed_at }))

  let update_work_manifest_state db work_manifest =
    let open Abb.Future.Infix_monad in
    update_work_manifest_state' db work_manifest
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let update_work_manifest_run_id' db work_manifest =
    let open Abbs_future_combinators.Infix_result_monad in
    let module Wm = Terrat_work_manifest2 in
    Pgsql_io.Prepared_stmt.execute
      db.Db.db
      (Sql.update_work_manifest_run_id ())
      work_manifest.Wm.id
      work_manifest.Wm.run_id
    >>= fun () -> Abb.Future.return (Ok work_manifest)

  let update_work_manifest_run_id db work_manifest =
    let open Abb.Future.Infix_monad in
    update_work_manifest_run_id' db work_manifest
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Prmths.Counter.inc_one Metrics.pgsql_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let store_dirspaceflows ~base_ref ~branch_ref db repo dirspaceflows =
    let id = CCInt64.of_int repo.Repo.id in
    let run =
      Abbs_future_combinators.List_result.iter
        ~f:(fun dirspaceflows ->
          Pgsql_io.Prepared_stmt.execute
            db.Db.db
            Sql.insert_dirspace
            (CCList.replicate (CCList.length dirspaceflows) base_ref)
            (CCList.map
               (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; _ }; _ } -> dir)
               dirspaceflows)
            (CCList.replicate (CCList.length dirspaceflows) id)
            (CCList.replicate (CCList.length dirspaceflows) branch_ref)
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
            m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
        Abb.Future.return (Error `Error)

  let make_commit_check ?work_manifest ~config ~description ~title ~status account =
    let module Wm = Terrat_work_manifest2 in
    let details_url =
      match work_manifest with
      | Some work_manifest ->
          Uri.to_string
            (Uri.add_query_param'
               (Uri.of_string
                  (Printf.sprintf
                     "%s/i/%d/audit-trail"
                     (Uri.to_string (Terrat_config.terrateam_web_base_url config))
                     account.Account.installation_id))
               ("q", "id:" ^ Uuidm.to_string work_manifest.Wm.id))
      | None -> Uri.to_string (Terrat_config.terrateam_web_base_url config)
    in
    Terrat_commit_check.make ~details_url ~description ~title ~status

  let create_commit_checks client repo ref_ checks =
    let open Abb.Future.Infix_monad in
    Logs.info (fun m ->
        m
          "GITHUB_EVALUATOR : %s : CREATE_COMMIT_CHECKS : num=%d"
          client.Client.request_id
          (CCList.length checks));
    Terrat_github_commit_check.create
      ~owner:repo.Repo.owner
      ~repo:repo.Repo.name
      ~ref_
      ~checks
      client.Client.client
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Githubc2_abb.call_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : %a"
              client.Client.request_id
              Githubc2_abb.pp_call_err
              err);
        Abb.Future.return (Error `Error)

  let fetch_commit_checks client repo ref_ =
    let open Abb.Future.Infix_monad in
    let owner = repo.Repo.owner in
    let repo = repo.Repo.name in
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m "GITHUB_EVALUATOR : %s : LIST_COMMIT_CHECKS : %f" client.Client.request_id time))
      (fun () ->
        Terrat_github_commit_check.list
          ~log_id:client.Client.request_id
          ~owner
          ~repo
          ~ref_
          client.Client.client)
    >>= function
    | Ok _ as res -> Abb.Future.return res
    | Error (#Terrat_github_commit_check.list_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : FETCH_COMMIT_CHECKS : %a"
              client.Client.request_id
              Terrat_github_commit_check.pp_list_err
              err);
        Abb.Future.return (Error `Error)

  let merge_pull_request' client pull_request =
    let open Abbs_future_combinators.Infix_result_monad in
    let repo = pull_request.Pull_request.repo in
    Logs.info (fun m ->
        m
          "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %s : %s : %d"
          client.Client.request_id
          repo.Repo.owner
          repo.Repo.name
          pull_request.Pull_request.id);
    Githubc2_abb.call
      client.Client.client
      Githubc2_pulls.Merge.(
        make
          ~body:
            Request_body.(
              make
                Primary.(
                  make
                    ~commit_title:
                      (Some (Printf.sprintf "Terrateam Automerge #%d" pull_request.Pull_request.id))
                    ()))
          Parameters.(
            make
              ~owner:repo.Repo.owner
              ~repo:repo.Repo.name
              ~pull_number:pull_request.Pull_request.id))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK _ -> Abb.Future.return (Ok ())
    | `Method_not_allowed _ -> (
        Logs.info (fun m ->
            m
              "GITHUB_EVALUATOR : %s : MERGE_METHOD_NOT_ALLOWED : %s : %s : %d"
              client.Client.request_id
              repo.Repo.owner
              repo.Repo.name
              pull_request.Pull_request.id);
        Githubc2_abb.call
          client.Client.client
          Githubc2_pulls.Merge.(
            make
              ~body:Request_body.(make Primary.(make ~merge_method:(Some "squash") ()))
              Parameters.(
                make
                  ~owner:repo.Repo.owner
                  ~repo:repo.Repo.name
                  ~pull_number:pull_request.Pull_request.id))
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

  let merge_pull_request client pull_request =
    let open Abb.Future.Infix_monad in
    merge_pull_request' client pull_request
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Githubc2_abb.call_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %a"
              client.Client.request_id
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
              client.Client.request_id
              Githubc2_pulls.Merge.Responses.pp
              err);
        Abb.Future.return (Error `Error)
    | Error (#Githubc2_pulls.Merge.Responses.t as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %a"
              client.Client.request_id
              Githubc2_pulls.Merge.Responses.pp
              err);
        Abb.Future.return (Error `Error)

  let delete_pull_request_branch' client pull_request =
    let open Abbs_future_combinators.Infix_result_monad in
    let repo = pull_request.Pull_request.repo in
    Logs.info (fun m ->
        m
          "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %d"
          client.Client.request_id
          repo.Repo.owner
          repo.Repo.name
          pull_request.Pull_request.id);
    Terrat_github.fetch_pull_request
      ~owner:repo.Repo.owner
      ~repo:repo.Repo.name
      ~pull_number:pull_request.Pull_request.id
      client.Client.client
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK
        Githubc2_components.Pull_request.
          { primary = Primary.{ head = Head.{ primary = Primary.{ ref_ = branch; _ }; _ }; _ }; _ }
      -> (
        Logs.info (fun m ->
            m
              "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %d : %s"
              client.Client.request_id
              repo.Repo.owner
              repo.Repo.name
              pull_request.Pull_request.id
              branch);
        Githubc2_abb.call
          client.Client.client
          Githubc2_git.Delete_ref.(
            make
              Parameters.(
                make ~owner:repo.Repo.owner ~repo:repo.Repo.name ~ref_:("heads/" ^ branch)))
        >>= fun resp ->
        match Openapi.Response.value resp with
        | `No_content -> Abb.Future.return (Ok ())
        | `Unprocessable_entity err ->
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %d : %a"
                  client.Client.request_id
                  repo.Repo.owner
                  repo.Repo.name
                  pull_request.Pull_request.id
                  Githubc2_git.Delete_ref.Responses.Unprocessable_entity.pp
                  err);
            Abb.Future.return (Ok ()))
    | (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _) as err ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : %a"
              client.Client.request_id
              Githubc2_pulls.Get.Responses.pp
              err);
        Abb.Future.return (Error `Error)

  let delete_pull_request_branch client pull_request =
    let open Abb.Future.Infix_monad in
    delete_pull_request_branch' client pull_request
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Githubc2_abb.call_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.info (fun m ->
            m
              "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %a"
              client.Client.request_id
              Githubc2_abb.pp_call_err
              err);
        Abb.Future.return (Error `Error)
    | Error `Error -> Abb.Future.return (Error `Error)

  module Publish_msg = struct
    type t = {
      client : Client.t;
      pull_number : int;
      repo : Repo.t;
      user : string;
    }

    (* Publish messages back *)
    let publish_comment msg_type t body =
      let open Abb.Future.Infix_monad in
      Terrat_github.publish_comment
        ~owner:t.repo.Repo.owner
        ~repo:t.repo.Repo.name
        ~pull_number:t.pull_number
        ~body
        t.client.Client.client
      >>= function
      | Ok () ->
          Logs.info (fun m ->
              m "GITHUB_EVALUATOR : %s : PUBLISHED_COMMENT : %s" t.client.Client.request_id msg_type);
          Abb.Future.return ()
      | Error (#Terrat_github.publish_comment_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : %s : ERROR : %a"
                t.client.Client.request_id
                msg_type
                Terrat_github.pp_publish_comment_err
                err);
          Abb.Future.return ()

    let apply_template_and_publish msg_type template kv t =
      match Snabela.apply template kv with
      | Ok body -> publish_comment msg_type t body
      | Error (#Snabela.err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : TEMPLATE_ERROR : %a"
                t.client.Client.request_id
                Snabela.pp_err
                err);
          Abb.Future.return ()

    let publish_msg' t =
      let module Msg = Terrat_evaluator2.Msg in
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
                    t.client.Client.request_id
                    dir
                    workspace))
            dirspaces;
          apply_template_and_publish "MISSING_PLANS" Tmpl.missing_plans kv t
      | Msg.Dirspaces_owned_by_other_pull_request prs ->
          let unique_pull_request_ids =
            prs
            |> CCList.map (fun (_, Pull_request.{ id; _ }) -> id)
            |> CCList.sort_uniq ~cmp:CCInt.compare
          in
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ( "dirspaces",
                    list
                      (CCList.map
                         (fun (Terrat_change.Dirspace.{ dir; workspace }, Pull_request.{ id; _ }) ->
                           Map.of_list
                             [
                               ("dir", string dir);
                               ("workspace", string workspace);
                               ("pull_request_id", int id);
                             ])
                         prs) );
                  ( "unique_pull_request_ids",
                    list
                      (CCList.map
                         (fun id -> Map.of_list [ ("id", int id) ])
                         unique_pull_request_ids) );
                ])
          in
          CCList.iter
            (fun (Terrat_change.Dirspace.{ dir; workspace }, Pull_request.{ id; _ }) ->
              Logs.info (fun m ->
                  m
                    "GITHUB_EVALUATOR : %s : DIRSPACES_OWNED_BY_OTHER_PR : dir=%s : workspace=%s : \
                     pull_number=%d"
                    t.client.Client.request_id
                    dir
                    workspace
                    id))
            prs;
          apply_template_and_publish
            "DIRSPACES_OWNED_BY_OTHER_PRS"
            Tmpl.dirspaces_owned_by_other_pull_requests
            kv
            t
      | Msg.Index_complete (success, failures) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("success", bool success);
                  ( "failures",
                    list
                      (CCList.map
                         (fun (path, lnum, msg) ->
                           Map.of_list
                             (CCList.flatten
                                [
                                  [ ("path", string path); ("failure", string msg) ];
                                  CCOption.map_or
                                    ~default:[]
                                    (fun lnum -> [ ("line", int lnum) ])
                                    lnum;
                                ]))
                         failures) );
                ])
          in
          apply_template_and_publish "INDEX_COMPLETE" Tmpl.index_complete kv t
      | Msg.Conflicting_work_manifests wms ->
          let module Wm = Terrat_work_manifest2 in
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ( "work_manifests",
                    list
                      (CCList.map
                         (fun Wm.{ created_at; run_type; state; src; _ } ->
                           let id, is_pr =
                             match src with
                             | Wm.Kind.Pull_request Pull_request.{ id; _ } ->
                                 (CCInt.to_string id, true)
                             | Wm.Kind.Drift _ -> ("drift", false)
                             | Wm.Kind.Index _ -> ("index", false)
                           in
                           Map.of_list
                             [
                               ("id", string id);
                               ("is_pr", bool is_pr);
                               ( "run_type",
                                 string
                                   (CCString.capitalize_ascii
                                      Wm.Unified_run_type.(to_string (of_run_type run_type))) );
                               ( "state",
                                 string (CCString.capitalize_ascii (Wm.State.to_string state)) );
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
            t
      | Msg.Maybe_stale_work_manifests wms ->
          let module Wm = Terrat_work_manifest2 in
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ( "work_manifests",
                    list
                      (CCList.map
                         (fun Wm.{ created_at; run_type; state; src; _ } ->
                           let id, is_pr =
                             match src with
                             | Wm.Kind.Pull_request Pull_request.{ id; _ } ->
                                 (CCInt.to_string id, true)
                             | Wm.Kind.Drift _ -> ("drift", false)
                             | Wm.Kind.Index _ -> ("index", false)
                           in
                           Map.of_list
                             [
                               ("id", string id);
                               ("is_pr", bool is_pr);
                               ( "run_type",
                                 string
                                   (CCString.capitalize_ascii
                                      Wm.Unified_run_type.(to_string (of_run_type run_type))) );
                               ( "state",
                                 string (CCString.capitalize_ascii (Wm.State.to_string state)) );
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
            "MAYBE_STALE_WORK_MANIFESTS"
            Tmpl.maybe_stale_work_manifests
            kv
            t
      | Msg.Repo_config_parse_failure err ->
          let kv = Snabela.Kv.(Map.of_list [ ("msg", string err) ]) in
          apply_template_and_publish "REPO_CONFIG_PARSE_FAILURE" Tmpl.repo_config_parse_failure kv t
      | Msg.Repo_config_failure err ->
          let kv = Snabela.Kv.(Map.of_list [ ("msg", string err) ]) in
          apply_template_and_publish
            "REPO_CONFIG_GENERIC_FAILURE"
            Tmpl.repo_config_generic_failure
            kv
            t
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
            t
      | Msg.Pull_request_not_mergeable ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            "PULL_REQUEST_NOT_MERGEABLE"
            Tmpl.pull_request_not_mergeable
            kv
            t
      | Msg.Apply_no_matching_dirspaces ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            "APPLY_NO_MATCHING_DIRSPACES"
            Tmpl.apply_no_matching_dirspaces
            kv
            t
      | Msg.Plan_no_matching_dirspaces ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            "PLAN_NO_MATCHING_DIRSPACES"
            Tmpl.plan_no_matching_dirspaces
            kv
            t
      | Msg.Dest_branch_no_match pull_request ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ( "source_branch",
                    string (CCString.lowercase_ascii pull_request.Pull_request.branch_name) );
                  ( "dest_branch",
                    string (CCString.lowercase_ascii pull_request.Pull_request.base_branch_name) );
                ])
          in
          apply_template_and_publish "DEST_BRANCH_NO_MATCH" Tmpl.base_branch_not_default_branch kv t
      | Msg.Autoapply_running ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish "AUTO_APPLY_RUNNING" Tmpl.auto_apply_running kv t
      | Msg.Bad_custom_branch_tag_pattern (tag, pat) ->
          let kv = Snabela.Kv.(Map.of_list [ ("tag", string tag); ("pattern", string pat) ]) in
          apply_template_and_publish
            "BAD_CUSTOM_BRANCH_TAG_PATTERN"
            Tmpl.bad_custom_branch_tag_pattern
            kv
            t
      | Msg.Bad_glob s ->
          let kv = Snabela.Kv.(Map.of_list [ ("glob", string s) ]) in
          apply_template_and_publish "BAD_GLOB" Tmpl.bad_glob kv t
      | Msg.Access_control_denied (default_branch, `All_dirspaces denies) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string t.user);
                  ("default_branch", string default_branch);
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
            t
      | Msg.Access_control_denied (default_branch, `Invalid_query query) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string t.user);
                  ("default_branch", string default_branch);
                  ("query", string query);
                ])
          in
          apply_template_and_publish
            "ACCESS_CONTROL_INVALID_QUERY"
            Tmpl.access_control_invalid_query
            kv
            t
      | Msg.Access_control_denied (default_branch, `Dirspaces denies) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string t.user);
                  ("default_branch", string default_branch);
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
            t
      | Msg.Access_control_denied (default_branch, `Terrateam_config_update match_list) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string t.user);
                  ("default_branch", string default_branch);
                  ( "match_list",
                    list (CCList.map (fun s -> Map.of_list [ ("item", string s) ]) match_list) );
                ])
          in
          apply_template_and_publish
            "ACCESS_CONTROL_TERRATEAM_CONFIG_UPDATE_DENIED"
            Tmpl.access_control_terrateam_config_update_denied
            kv
            t
      | Msg.Access_control_denied (default_branch, `Terrateam_config_update_bad_query query) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string t.user);
                  ("default_branch", string default_branch);
                  ("query", string query);
                ])
          in
          apply_template_and_publish
            "ACCESS_CONTROL_TERRATEAM_CONFIG_UPDATE_BAD_QUERY"
            Tmpl.access_control_terrateam_config_update_bad_query
            kv
            t
      | Msg.Access_control_denied (default_branch, `Lookup_err) ->
          let kv =
            Snabela.Kv.(
              Map.of_list [ ("user", string t.user); ("default_branch", string default_branch) ])
          in
          apply_template_and_publish "ACCESS_CONTROL_LOOKUP_ERR" Tmpl.access_control_lookup_err kv t
      | Msg.Access_control_denied (default_branch, `Unlock match_list) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string t.user);
                  ("default_branch", string default_branch);
                  ( "match_list",
                    list (CCList.map (fun s -> Map.of_list [ ("item", string s) ]) match_list) );
                ])
          in
          apply_template_and_publish
            "ACCESS_CONTROL_UNLOCK_DENIED"
            Tmpl.access_control_unlock_denied
            kv
            t
      | Msg.Unlock_success ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish "UNLOCK_SUCCESS" Tmpl.unlock_success kv t
      | Msg.Tag_query_err (`Tag_query_error (s, err)) ->
          let kv = Snabela.Kv.(Map.of_list [ ("query", string s); ("err", string err) ]) in
          apply_template_and_publish "TAG_QUERY_ERR" Tmpl.tag_query_error kv t
      | Msg.Account_expired ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish "ACCOUNT_EXPIRED" Tmpl.account_expired_err kv t
      | Msg.Repo_config (repo_config, dirs) ->
          let repo_config_json =
            Yojson.Safe.pretty_to_string (Terrat_repo_config_version_1.to_yojson repo_config)
          in
          let dirs_json = Yojson.Safe.pretty_to_string (Terrat_change_match.Dirs.to_yojson dirs) in
          let kv =
            Snabela.Kv.(
              Map.of_list [ ("repo_config", string repo_config_json); ("dirs", string dirs_json) ])
          in
          apply_template_and_publish "REPO_CONFIG" Tmpl.repo_config kv t
      | Msg.Unexpected_temporary_err ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish "UNEXPECTED_TEMPORARY_ERR" Tmpl.unexpected_temporary_err kv t

    let publish_msg t msg =
      let open Abb.Future.Infix_monad in
      publish_msg' t msg
      >>= function
      | () -> Abb.Future.return (Ok ())

    let make ~client ~pull_number ~repo ~user () = { client; pull_number; repo; user }
  end

  module Event = struct
    module Terraform = struct
      type t = {
        config : Terrat_config.t;
        installation_id : int;
        operation : Terrat_evaluator2.Tf_operation.t;
        pull_number : int;
        repo : Repo.t;
        request_id : string;
        storage : Terrat_storage.t;
        tag_query : Terrat_tag_query.t;
        user : string;
      }

      type r =
        (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
        Terrat_work_manifest2.Existing.t
        option

      let account t = { Account.installation_id = t.installation_id; request_id = t.request_id }
      let config t = t.config
      let pull_number t = t.pull_number
      let repo t = t.repo
      let request_id t = t.request_id
      let tag_query t = t.tag_query
      let tf_operation t = t.operation
      let user t = t.user

      let publish_msg t client =
        { Publish_msg.client; pull_number = t.pull_number; repo = t.repo; user = t.user }

      (* Return operations *)
      let noop t = None
      let created_work_manifest _ work_manifest = Some work_manifest

      (* Operations *)
      let with_db t ~f =
        Pgsql_pool.with_conn t.storage ~f:(fun db -> f { Db.db; request_id = t.request_id })

      let create_access_control_ctx t client =
        {
          Access_control.client = client.Client.client;
          config = t.config;
          repo = t.repo;
          user = t.user;
        }

      let fetch_pull_request_reviews t client pull_request =
        let open Abb.Future.Infix_monad in
        let owner = t.repo.Repo.owner in
        let repo = t.repo.Repo.name in
        let pull_number = pull_request.Pull_request.id in
        Terrat_github.Pull_request_reviews.list ~owner ~repo ~pull_number client.Client.client
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
                  "GITHUB_EVALUATOR : %s : ERROR : %a"
                  t.request_id
                  Terrat_github.Pull_request_reviews.pp_list_err
                  err);
            Abb.Future.return (Error `Error)

      let fetch_commit_checks t client pull_request =
        let open Abb.Future.Infix_monad in
        let owner = t.repo.Repo.owner in
        let repo = t.repo.Repo.name in
        Abbs_time_it.run
          (fun time ->
            Logs.info (fun m ->
                m "GITHUB_EVALUATOR : %s : LIST_COMMIT_CHECKS : %f" t.request_id time))
          (fun () ->
            Terrat_github_commit_check.list
              ~log_id:t.request_id
              ~owner
              ~repo
              ~ref_:pull_request.Pull_request.branch_ref
              client.Client.client)
        >>= function
        | Ok _ as res -> Abb.Future.return res
        | Error (#Terrat_github_commit_check.list_err as err) ->
            Prmths.Counter.inc_one Metrics.github_errors_total;
            Logs.err (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : FETCH_COMMIT_CHECKS : %a"
                  t.request_id
                  Terrat_github_commit_check.pp_list_err
                  err);
            Abb.Future.return (Error `Error)

      let check_apply_requirements t client pull_request repo_config =
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
        let status_checks =
          CCOption.get_or ~default:(Ar.Checks.Status_checks.make ()) status_checks
        in
        Abbs_future_combinators.Infix_result_app.(
          (fun reviews commit_checks -> (reviews, commit_checks))
          <$> Abbs_time_it.run (log_time t.request_id "FETCH_APPROVED_TIME") (fun () ->
                  fetch_pull_request_reviews t client pull_request)
          <*> Abbs_time_it.run (log_time t.request_id "FETCH_COMMIT_CHECKS_TIME") (fun () ->
                  fetch_commit_checks t client pull_request))
        >>= fun (reviews, commit_checks) ->
        let approved_reviews =
          CCList.filter
            (function
              | Terrat_pull_request_review.{ status = Status.Approved; _ } -> true
              | _ -> false)
            reviews
        in
        let approved_result = CCList.length approved_reviews >= approved.Ar.Checks.Approved.count in
        let merge_result =
          CCOption.get_or ~default:false pull_request.Pull_request.value.Pull_request.mergeable
        in
        let ignore_matching =
          CCOption.get_or ~default:[] status_checks.Ar.Checks.Status_checks.ignore_matching
        in
        if CCOption.is_none pull_request.Pull_request.value.Pull_request.mergeable then
          Logs.debug (fun m -> m "GITHUB_EVALUATOR : %s : MERGEABLE_NONE" t.request_id);
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
                (CCString.equal "terrateam apply" title
                || CCString.prefix ~pre:"terrateam apply:" title
                || CCString.prefix ~pre:"terrateam plan:" title
                || CCList.mem
                     ~eq:CCString.equal
                     title
                     [ "terrateam apply pre-hooks"; "terrateam apply post-hooks" ]
                || CCList.exists
                     CCFun.(Lua_pattern.find title %> CCOption.is_some)
                     ignore_matching_pats
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
              t.request_id
              (Bool.to_string approved.Ar.Checks.Approved.enabled)
              (Bool.to_string merge_conflicts.Ar.Checks.Merge_conflicts.enabled)
              (Bool.to_string status_checks.Ar.Checks.Status_checks.enabled));
        Logs.info (fun m ->
            m
              "GITHUB_EVALUATOR : %s : APPLY_REQUIREMENTS_RESULT : approved=%s merge_check=%s \
               commit_check=%s merged=%s passed=%s"
              t.request_id
              (Bool.to_string approved_result)
              (Bool.to_string merge_result)
              (Bool.to_string all_commit_check_success)
              (Bool.to_string merged)
              (Bool.to_string passed));
        Abb.Future.return (Ok apply_requirements)
    end

    module Initiate = struct
      type t = {
        branch_ref : Ref.t;
        config : Terrat_config.t;
        encryption_key : Cstruct.t;
        request_id : string;
        run_id : string;
        storage : Terrat_storage.t;
        work_manifest_id : Uuidm.t;
      }

      type r = Terrat_api_components.Work_manifest.t

      let terraform_event t pull_request work_manifest =
        let module Wm = Terrat_work_manifest2 in
        {
          Terraform.config = t.config;
          installation_id = pull_request.Pull_request.account.Account.installation_id;
          operation = Terrat_evaluator2.Tf_operation.of_run_type work_manifest.Wm.run_type;
          pull_number = pull_request.Pull_request.id;
          repo = pull_request.Pull_request.repo;
          request_id = t.request_id;
          storage = t.storage;
          tag_query = work_manifest.Wm.tag_query;
          user = CCOption.get_exn_or "user" work_manifest.Wm.user;
        }

      let work_manifest_of_terraform_r = CCFun.id

      let token encryption_key id =
        Base64.encode_exn
          (Cstruct.to_string
             (Mirage_crypto.Hash.SHA256.hmac
                ~key:encryption_key
                (Cstruct.of_string (Uuidm.to_string id))))

      let fetch_dirspaces' client repo dest_branch branch ref_ =
        let run =
          let open Abbs_future_combinators.Infix_result_monad in
          Abbs_future_combinators.Infix_result_app.(
            (fun repo_config files -> (repo_config, files))
            <$> fetch_repo_config client repo ref_
            <*> fetch_tree client repo ref_)
          >>= fun (repo_config, files) ->
          Abb.Future.return
            (Terrat_change_match.synthesize_dir_config
               ~ctx:(Terrat_change_match.Ctx.make ~dest_branch ~branch ())
               ~index:Terrat_change_match.Index.empty
               ~file_list:files
               repo_config)
          >>= fun dirs ->
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
        in
        let open Abb.Future.Infix_monad in
        run
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (`Bad_glob msg) -> Abb.Future.return (Error (`Bad_glob_err (msg, ref_)))
        | Error (`Parse_err _) -> Abb.Future.return (Error `Error)
        | Error (`Bad_branch_pattern pat) -> failwith "nyi"
        | Error (`Bad_dest_branch_pattern pat) -> failwith "nyi"
        | Error `Error -> Abb.Future.return (Error `Error)

      let fetch_dirspaces client repo dest_branch_name branch_name base_ref ref_ =
        Abbs_future_combinators.Infix_result_app.(
          (fun base_dirs dirs -> (base_dirs, dirs))
          <$> fetch_dirspaces' client repo dest_branch_name branch_name base_ref
          <*> fetch_dirspaces' client repo dest_branch_name branch_name ref_)

      let run_kind_of_src =
        let module Wm = Terrat_work_manifest2 in
        function
        | Wm.Kind.Pull_request _ -> "pr"
        | Wm.Kind.Drift _ -> "drift"
        | Wm.Kind.Index _ -> "index"

      let run_kind_data_of_src =
        let module Wm = Terrat_work_manifest2 in
        let module Rkd = Terrat_api_components.Work_manifest_plan.Run_kind_data in
        let module Rkdpr = Terrat_api_components.Run_kind_data_pull_request in
        function
        | Wm.Kind.Pull_request { Pull_request.id; _ } ->
            Some (Rkd.Run_kind_data_pull_request { Rkdpr.id = CCInt.to_string id })
        | Wm.Kind.Drift _ | Wm.Kind.Index _ -> None

      let changed_dirspaces changes =
        let module Tc = Terrat_change in
        let module Dsf = Tc.Dirspaceflow in
        CCList.map
          (fun Tc.{ Dsf.dirspace = { Dirspace.dir; workspace }; workflow } ->
            (* TODO: Provide correct rank *)
            Terrat_api_components.Work_manifest_dir.{ path = dir; workspace; workflow; rank = 0 })
          changes

      let of_work_manifest t work_manifest =
        let open Abb.Future.Infix_monad in
        let module Wm = Terrat_work_manifest2 in
        Abb.Sys.time ()
        >>= fun now ->
        let created_at = ISO8601.Permissive.datetime work_manifest.Wm.created_at in
        Metrics.Work_manifest_run_time_histogram.observe
          (Metrics.work_manifest_wait_duration_seconds
             (Wm.Run_type.to_string work_manifest.Wm.run_type))
          (now -. created_at);
        Logs.info (fun m ->
            m
              "GITHUB_EVALUATOR : %s : WORK_MANIFEST_WAIT_DURATION : id=%a : duration=%f"
              t.request_id
              Uuidm.pp
              work_manifest.Wm.id
              (now -. created_at));
        match work_manifest with
        | {
            Wm.id;
            src = Wm.Kind.Pull_request { Pull_request.account; base_branch_name; repo; _ } as src;
            run_type = Wm.Run_type.(Plan | Autoplan);
            base_hash = base_ref;
            hash = ref_;
            changes;
            _;
          }
        | {
            Wm.id;
            src = Wm.Kind.Drift { Drift.account; branch = base_branch_name; repo; _ } as src;
            run_type = Wm.Run_type.(Plan | Autoplan);
            base_hash = base_ref;
            hash = ref_;
            changes;
            _;
          } ->
            let open Abbs_future_combinators.Infix_result_monad in
            let branch_name =
              match src with
              | Wm.Kind.Pull_request { Pull_request.branch_name; _ } -> branch_name
              | Wm.Kind.Drift _ -> base_branch_name
              | Wm.Kind.Index _ -> assert false
            in
            create_client t.config account
            >>= fun client ->
            fetch_dirspaces client repo base_branch_name branch_name base_ref ref_
            >>= fun (base_dirspaces, dirspaces) ->
            Abb.Future.return
              (Ok
                 Terrat_api_components.(
                   Work_manifest.Work_manifest_plan
                     Work_manifest_plan.
                       {
                         token = token t.encryption_key id;
                         base_dirspaces;
                         base_ref = base_branch_name;
                         changed_dirspaces = changed_dirspaces changes;
                         dirspaces;
                         run_kind = run_kind_of_src src;
                         run_kind_data = run_kind_data_of_src src;
                         type_ = "plan";
                       }))
        | {
            Wm.id;
            src = Wm.Kind.Pull_request { Pull_request.account; base_branch_name; repo; _ } as src;
            run_type = Wm.Run_type.(Apply | Autoapply);
            base_hash = base_ref;
            hash = ref_;
            changes;
            _;
          }
        | {
            Wm.id;
            src = Wm.Kind.Drift { Drift.account; branch = base_branch_name; repo; _ } as src;
            run_type = Wm.Run_type.(Apply | Autoapply);
            base_hash = base_ref;
            hash = ref_;
            changes;
            _;
          } ->
            let open Abbs_future_combinators.Infix_result_monad in
            let branch_name =
              match src with
              | Wm.Kind.Pull_request { Pull_request.branch_name; _ } -> branch_name
              | Wm.Kind.Drift _ -> base_branch_name
              | Wm.Kind.Index _ -> assert false
            in
            create_client t.config account
            >>= fun client ->
            fetch_dirspaces client repo base_branch_name branch_name base_ref ref_
            >>= fun (base_dirspaces, dirspaces) ->
            Abb.Future.return
              (Ok
                 Terrat_api_components.(
                   Work_manifest.Work_manifest_apply
                     Work_manifest_apply.
                       {
                         token = token t.encryption_key id;
                         base_ref = base_branch_name;
                         changed_dirspaces = changed_dirspaces changes;
                         run_kind = run_kind_of_src src;
                         type_ = "apply";
                       }))
        | {
            Wm.id;
            src = Wm.Kind.Pull_request { Pull_request.account; base_branch_name; repo; _ } as src;
            run_type = Wm.Run_type.Unsafe_apply;
            base_hash = base_ref;
            hash = ref_;
            changes;
            _;
          }
        | {
            Wm.id;
            src = Wm.Kind.Drift { Drift.account; branch = base_branch_name; repo; _ } as src;
            run_type = Wm.Run_type.Unsafe_apply;
            base_hash = base_ref;
            hash = ref_;
            changes;
            _;
          } ->
            let open Abbs_future_combinators.Infix_result_monad in
            let branch_name =
              match src with
              | Wm.Kind.Pull_request { Pull_request.branch_name; _ } -> branch_name
              | Wm.Kind.Drift _ -> base_branch_name
              | Wm.Kind.Index _ -> assert false
            in
            create_client t.config account
            >>= fun client ->
            fetch_dirspaces client repo base_branch_name branch_name base_ref ref_
            >>= fun (base_dirspaces, dirspaces) ->
            Abb.Future.return
              (Ok
                 Terrat_api_components.(
                   Work_manifest.Work_manifest_unsafe_apply
                     Work_manifest_unsafe_apply.
                       {
                         token = token t.encryption_key id;
                         base_ref = base_branch_name;
                         changed_dirspaces = changed_dirspaces changes;
                         run_kind = run_kind_of_src src;
                         type_ = "unsafe-apply";
                       }))
        | { Wm.id; src = Wm.Kind.Index index; changes; _ } ->
            let module Idx = Terrat_api_components.Work_manifest_index in
            let dirs =
              changes
              |> CCList.map Terrat_change.Dirspaceflow.to_dirspace
              |> CCList.map (fun Terrat_change.Dirspace.{ dir; _ } -> dir)
            in
            Abb.Future.return
              (Ok
                 (Terrat_api_components.Work_manifest.Work_manifest_index
                    {
                      Idx.dirs;
                      base_ref = index.Index.branch;
                      token = token t.encryption_key id;
                      type_ = "index";
                    }))

      let done_ t work_manifest =
        let open Abb.Future.Infix_monad in
        let module Wm = Terrat_work_manifest2 in
        let module D = Terrat_api_components.Work_manifest_done in
        Abb.Sys.time ()
        >>= fun now ->
        let created_at = ISO8601.Permissive.datetime work_manifest.Wm.created_at in
        Metrics.Work_manifest_run_time_histogram.observe
          (Metrics.work_manifest_run_time_duration_seconds
             (Wm.Run_type.to_string work_manifest.Wm.run_type))
          (now -. created_at);
        Logs.info (fun m ->
            m
              "GITHUB_EVALUATOR : %s : WORK_MANIFEST_RUN_TIME_DURATION : id=%a : duration=%f"
              t.request_id
              Uuidm.pp
              work_manifest.Wm.id
              (now -. created_at));
        Abb.Future.return
          (Terrat_api_components.Work_manifest.Work_manifest_done { D.type_ = "done" })

      let work_manifest_not_found _ =
        let module D = Terrat_api_components.Work_manifest_done in
        Terrat_api_components.Work_manifest.Work_manifest_done { D.type_ = "done" }

      let with_db t ~f =
        Pgsql_pool.with_conn t.storage ~f:(fun db -> f { Db.db; request_id = t.request_id })

      let branch_ref t = t.branch_ref
      let config t = t.config
      let request_id t = t.request_id
      let run_id t = t.run_id
      let work_manifest_id t = t.work_manifest_id
    end

    module Plan = struct
      type t = { data : string }
    end

    module Plan_cleanup = struct
      type t = {
        request_id : string;
        storage : Terrat_storage.t;
      }

      type r = unit

      let request_id t = t.request_id

      let delete_expired_plans' t =
        Pgsql_pool.with_conn t.storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.execute db Sql.delete_old_plans)

      let delete_expired_plans t =
        let open Abb.Future.Infix_monad in
        delete_expired_plans' t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (#Pgsql_io.err as err) ->
            Prmths.Counter.inc_one Metrics.pgsql_errors_total;
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s : ERROR : %a" t.request_id Pgsql_io.pp_err err);
            Abb.Future.return (Error `Error)
        | Error (#Pgsql_pool.err as err) ->
            Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s : ERROR : %a" t.request_id Pgsql_pool.pp_err err);
            Abb.Future.return (Error `Error)

      let done_ _ = ()
    end

    module Plan_get = struct
      type t = {
        config : Terrat_config.t;
        dir : string;
        request_id : string;
        storage : Terrat_storage.t;
        work_manifest_id : Uuidm.t;
        workspace : string;
      }

      type r = string option

      let dir t = t.dir
      let request_id t = t.request_id
      let work_manifest_id t = t.work_manifest_id
      let workspace t = t.workspace

      let query_plan' t =
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_pool.with_conn t.storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.fetch
              db
              Sql.select_recent_plan
              ~f:CCFun.id
              t.work_manifest_id
              t.dir
              t.workspace
            >>= function
            | [] -> Abb.Future.return (Ok None)
            | data :: _ ->
                clean_work_manifest_dirspace_plan
                  ~work_manifest_id:t.work_manifest_id
                  ~dir:t.dir
                  ~workspace:t.workspace
                  db
                >>= fun () -> Abb.Future.return (Ok (Some { Plan.data })))

      let query_plan t =
        let open Abb.Future.Infix_monad in
        query_plan' t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (#Pgsql_io.err as err) ->
            Prmths.Counter.inc_one Metrics.pgsql_errors_total;
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s : ERROR : %a" t.request_id Pgsql_io.pp_err err);
            Abb.Future.return (Error `Error)
        | Error (#Pgsql_pool.err as err) ->
            Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s : ERROR : %a" t.request_id Pgsql_pool.pp_err err);
            Abb.Future.return (Error `Error)

      let of_plan _ plan = Some plan.Plan.data
      let plan_not_found _ = None
    end

    module Plan_set = struct
      type t = {
        config : Terrat_config.t;
        data : string;
        dir : string;
        has_changes : bool;
        request_id : string;
        storage : Terrat_storage.t;
        work_manifest_id : Uuidm.t;
        workspace : string;
      }

      type r = unit

      let dir t = t.dir
      let request_id t = t.request_id
      let work_manifest_id t = t.work_manifest_id
      let workspace t = t.workspace

      let store_plan' t =
        Pgsql_pool.with_conn t.storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.execute
              db
              Sql.upsert_terraform_plan
              t.work_manifest_id
              t.dir
              t.workspace
              t.data)

      let store_plan t =
        let open Abb.Future.Infix_monad in
        store_plan' t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (#Pgsql_io.err as err) ->
            Prmths.Counter.inc_one Metrics.pgsql_errors_total;
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s : ERROR : %a" t.request_id Pgsql_io.pp_err err);
            Abb.Future.return (Error `Error)
        | Error (#Pgsql_pool.err as err) ->
            Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s : ERROR : %a" t.request_id Pgsql_pool.pp_err err);
            Abb.Future.return (Error `Error)

      let done_ _ = ()
    end

    module Result = struct
      module Type = struct
        type tf_operation = Terrat_api_components_work_manifest_tf_operation_result.t
        type index = Terrat_api_components_work_manifest_index_result.t
      end

      type t = {
        config : Terrat_config.t;
        request_id : string;
        result : Terrat_api_components.Work_manifest_result.t;
        storage : Terrat_storage.t;
        work_manifest_id : Uuidm.t;
      }

      type r = unit

      let with_db t ~f =
        Pgsql_pool.with_conn t.storage ~f:(fun db -> f { Db.db; request_id = t.request_id })

      let config t = t.config
      let request_id t = t.request_id
      let work_manifest_id t = t.work_manifest_id

      let result_type t =
        match t.result with
        | Terrat_api_components_work_manifest_result.Work_manifest_index_result index ->
            `Index index
        | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result tf_operation
          -> `Tf_operation tf_operation

      let store_result' db t =
        match t.result with
        | Terrat_api_components_work_manifest_result.Work_manifest_index_result index -> (
            let module R = Terrat_api_components.Work_manifest_index_result in
            let module Wm = Terrat_work_manifest2 in
            let open Abbs_future_combinators.Infix_result_monad in
            query_work_manifest db t.work_manifest_id
            >>= function
            | Some { Wm.changes; _ } ->
                Pgsql_io.Prepared_stmt.execute
                  db.Db.db
                  (Sql.insert_index ())
                  t.work_manifest_id
                  (Yojson.Safe.to_string (R.to_yojson index))
                >>= fun () ->
                Abbs_future_combinators.List_result.iter
                  ~f:(fun dsf ->
                    let module Ds = Terrat_change.Dirspace in
                    let { Ds.dir; workspace } = Terrat_change.Dirspaceflow.to_dirspace dsf in
                    Pgsql_io.Prepared_stmt.execute
                      db.Db.db
                      Sql.insert_github_work_manifest_result
                      t.work_manifest_id
                      dir
                      workspace
                      true)
                  changes
            | None -> assert false)
        | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result tf_operation
          ->
            let module Rb = Terrat_api_components_work_manifest_tf_operation_result in
            Prmths.Counter.inc_one
              (Metrics.run_overall_result_count
                 (Bool.to_string tf_operation.Rb.overall.Rb.Overall.success));
            Abbs_time_it.run
              (fun time ->
                Logs.info (fun m ->
                    m "GITHUB_EVALUATOR : %s : DIRSPACE_RESULT_STORE : time=%f" t.request_id time))
              (fun () ->
                Abbs_future_combinators.List_result.iter
                  ~f:(fun result ->
                    let module Wmr = Terrat_api_components.Work_manifest_dirspace_result in
                    Logs.info (fun m ->
                        m
                          "GITHUB_EVALUATOR : %s : RESULT_STORE : id=%a : dir=%s : workspace=%s : \
                           result=%s"
                          t.request_id
                          Uuidm.pp
                          t.work_manifest_id
                          result.Wmr.path
                          result.Wmr.workspace
                          (if result.Wmr.success then "SUCCESS" else "FAILURE"));
                    Pgsql_io.Prepared_stmt.execute
                      db.Db.db
                      Sql.insert_github_work_manifest_result
                      t.work_manifest_id
                      result.Wmr.path
                      result.Wmr.workspace
                      result.Wmr.success)
                  tf_operation.Rb.dirspaces)

      let store_result db t =
        let open Abb.Future.Infix_monad in
        store_result' db t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (#Pgsql_io.err as err) ->
            Prmths.Counter.inc_one Metrics.pgsql_errors_total;
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_io.pp_err err);
            Abb.Future.return (Error `Error)
        | Error (#Pgsql_pool.err as err) ->
            Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s : ERROR : %a" db.Db.request_id Pgsql_pool.pp_err err);
            Abb.Future.return (Error `Error)
        | Error `Error -> Abb.Future.return (Error `Error)

      let index_results results =
        let module R = Terrat_api_components.Work_manifest_index_result in
        let module Paths = Terrat_api_components.Work_manifest_index_paths in
        let paths = Json_schema.String_map.to_list (Paths.additional results.R.paths) in
        ( results.R.success,
          (CCList.flat_map (fun (_path, { Paths.Additional.failures; _ }) ->
               let failures =
                 Json_schema.String_map.to_list (Paths.Additional.Failures.additional failures)
               in
               CCList.map
                 (fun (path, { Paths.Additional.Failures.Additional.lnum; msg }) ->
                   (path, lnum, msg))
                 failures))
            paths )

      let noop t = ()
      let invalid_work_manifest_state _ _ = ()
      let work_manifest_not_found _ = ()

      let result_status results =
        let module Wmr = Terrat_api_components.Work_manifest_dirspace_result in
        let module R = Terrat_api_components_work_manifest_tf_operation_result in
        let module Hooks_output = Terrat_api_components.Hook_outputs in
        let success = results.R.overall.R.Overall.success in
        let pre_hooks_status =
          let module Run = Terrat_api_components.Workflow_output_run in
          let module Env = Terrat_api_components.Workflow_output_env in
          let module Checkout = Terrat_api_components.Workflow_output_checkout in
          let module Ce = Terrat_api_components.Workflow_output_cost_estimation in
          let module Oidc = Terrat_api_components.Workflow_output_oidc in
          results.R.overall.R.Overall.outputs.Hooks_output.pre
          |> CCList.for_all
               Hooks_output.Pre.Items.(
                 function
                 | Workflow_output_run Run.{ success; _ }
                 | Workflow_output_env Env.{ success; _ }
                 | Workflow_output_checkout Checkout.{ success; _ }
                 | Workflow_output_cost_estimation Ce.{ success; _ }
                 | Workflow_output_oidc Oidc.{ success; _ } -> success)
        in
        let post_hooks_status =
          let module Run = Terrat_api_components.Workflow_output_run in
          let module Env = Terrat_api_components.Workflow_output_env in
          let module Oidc = Terrat_api_components.Workflow_output_oidc in
          let module Drift_create_issue = Terrat_api_components.Workflow_output_drift_create_issue
          in
          results.R.overall.R.Overall.outputs.Hooks_output.post
          |> CCList.for_all
               Hooks_output.Post.Items.(
                 function
                 | Workflow_output_run Run.{ success; _ }
                 | Workflow_output_env Env.{ success; _ }
                 | Workflow_output_oidc Oidc.{ success; _ }
                 | Workflow_output_drift_create_issue Drift_create_issue.{ success; _ } -> success)
        in
        let dirspaces =
          CCList.map
            (fun Wmr.{ path; workspace; success; _ } ->
              ({ Terrat_change.Dirspace.dir = path; workspace }, success))
            results.R.dirspaces
        in
        {
          Terrat_evaluator2.Result_status.overall = success;
          pre_hooks = pre_hooks_status;
          post_hooks = post_hooks_status;
          dirspaces;
        }

      (* Publish results *)
      module Workflow_step_output = struct
        type t = {
          success : bool;
          key : string option;
          text : string;
          step_type : string;
          details : string option;
        }
      end

      let maybe_credential_error_strings =
        [
          "no valid credential";
          "Required token could not be found";
          "could not find default credentials";
        ]

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
                   Oidc.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ }
                 ->
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
                       {
                         step_type = type_;
                         text = plan;
                         key = Some "plan";
                         success;
                         details = None;
                       };
                   ]
               | Output.Workflow_output_run _
               | Output.Workflow_output_oidc _
               | Output.Workflow_output_plan _
               | Output.Workflow_output_env _
               | Output.Workflow_output_init Init.{ outputs = None; _ }
               | Output.Workflow_output_apply Apply.{ outputs = None; _ } -> [])

      let has_changes_of_workflow_outputs outputs =
        let module Output = Terrat_api_components_workflow_outputs.Items in
        let module Plan = Terrat_api_components_workflow_output_plan in
        let module Output_plan = Terrat_api_components_output_plan in
        (* Find the plan output, and then extract the has changes if it's there *)
        outputs
        |> CCList.find_opt (function
               | Output.Workflow_output_plan _ -> true
               | _ -> false)
        |> CCOption.flat_map (function
               | Output.Workflow_output_plan
                   Plan.
                     { outputs = Some (Plan.Outputs.Output_plan Output_plan.{ has_changes; _ }); _ }
                 -> Some has_changes
               | _ -> None)

      let create_run_output ~view request_id results work_manifest =
        let module Wm = Terrat_work_manifest2 in
        let module Wmr = Terrat_api_components.Work_manifest_dirspace_result in
        let module R = Terrat_api_components_work_manifest_tf_operation_result in
        let dirspaces =
          let module Cmp = struct
            type t = bool * bool * string * string [@@deriving ord]
          end in
          results.R.dirspaces
          |> CCList.sort
               (fun
                 Wmr.{ path = p1; workspace = w1; success = s1; outputs = outputs1; _ }
                 Wmr.{ path = p2; workspace = w2; success = s2; outputs = outputs2; _ }
               ->
                 (* Sort the results by dirspace and whether or not it has
                    changes.  We want those dirspaces that have no changes
                    last. *)
                 let has_changes1 =
                   CCOption.get_or ~default:true (has_changes_of_workflow_outputs outputs1)
                 in
                 let has_changes2 =
                   CCOption.get_or ~default:true (has_changes_of_workflow_outputs outputs2)
                 in
                 (* Negate has_changes because the order of [bool] is [false]
                    before [true]. *)
                 Cmp.compare (not has_changes1, s1, p1, w1) (not has_changes2, s2, p2, w2))
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
                     {
                       currency;
                       total_monthly_cost;
                       prev_monthly_cost;
                       diff_monthly_cost;
                       dirspaces;
                     }
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
                     ("compact_view", bool (view = `Compact));
                     ("compact_dirspaces", bool (CCList.length dirspaces > 5));
                     ( "results",
                       list
                         (CCList.map
                            (fun Wmr.{ path; workspace; success; outputs; _ } ->
                              let module Text = Terrat_api_components_output_text in
                              Map.of_list
                                (CCList.flatten
                                   [
                                     [
                                       ("dir", string path);
                                       ("workspace", string workspace);
                                       ("success", bool success);
                                       ( "outputs",
                                         kv_of_workflow_step (workflow_output_texts outputs) );
                                     ]
                                     @ CCOption.map_or
                                         ~default:[]
                                         (fun has_changes -> [ ("has_changes", bool has_changes) ])
                                         (has_changes_of_workflow_outputs outputs);
                                   ]))
                            dirspaces) );
                   ];
                   (match work_manifest.Wm.denied_dirspaces with
                   | [] -> []
                   | dirspaces ->
                       [
                         ( "denied_dirspaces",
                           list
                             (CCList.map
                                (fun {
                                       Wm.Deny.dirspace = { Terrat_change.Dirspace.dir; workspace };
                                       policy;
                                     } ->
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
                                dirspaces) );
                       ]);
                 ]))
        in
        let tmpl =
          match Wm.Unified_run_type.of_run_type work_manifest.Wm.run_type with
          | Wm.Unified_run_type.Plan -> Tmpl.plan_complete
          | Wm.Unified_run_type.Apply -> Tmpl.apply_complete
        in
        match Snabela.apply tmpl kv with
        | Ok body -> body
        | Error (#Snabela.err as err) ->
            Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Snabela.pp_err err);
            assert false

      let rec iterate_comment_posts ?(view = `Full) t results pull_request work_manifest =
        let module Wm = Terrat_work_manifest2 in
        let open Abbs_future_combinators.Infix_result_monad in
        let output = create_run_output ~view t.request_id results work_manifest in
        Metrics.Run_output_histogram.observe
          (Metrics.run_output_chars ~r:work_manifest.Wm.run_type ~c:(view = `Compact))
          (CCFloat.of_int (CCString.length output));
        let repo = pull_request.Pull_request.repo in
        create_client t.config pull_request.Pull_request.account
        >>= fun client ->
        let open Abb.Future.Infix_monad in
        Terrat_github.publish_comment
          ~owner:repo.Repo.owner
          ~repo:repo.Repo.name
          ~pull_number:pull_request.Pull_request.id
          ~body:output
          client.Client.client
        >>= function
        | Ok () -> Abb.Future.return (Ok ())
        | Error (#Terrat_github.publish_comment_err as err) -> (
            match
              (view, results.Terrat_api_components_work_manifest_tf_operation_result.dirspaces)
            with
            | _, [] -> assert false
            | `Full, _ ->
                Prmths.Counter.inc_one Metrics.github_errors_total;
                Logs.info (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : ITERATE_COMMENT_POST : %s"
                      t.request_id
                      (Terrat_github.show_publish_comment_err err));
                iterate_comment_posts ~view:`Compact t results pull_request work_manifest
            | `Compact, [ _ ] ->
                (* If we're in compact view but there is only one dirspace, then
                   that means there is no way to make the comment smaller. *)
                Prmths.Counter.inc_one Metrics.github_errors_total;
                Logs.info (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : ITERATE_COMMENT_POST : %s"
                      t.request_id
                      (Terrat_github.show_publish_comment_err err));
                Terrat_github.publish_comment
                  ~owner:repo.Repo.owner
                  ~repo:repo.Repo.name
                  ~pull_number:pull_request.Pull_request.id
                  ~body:Tmpl.comment_too_large
                  client.Client.client
            | `Compact, dirspaces ->
                Abbs_future_combinators.List_result.iter
                  ~f:(fun dirspace ->
                    Prmths.Counter.inc_one Metrics.github_errors_total;
                    Logs.info (fun m ->
                        m
                          "GITHUB_EVALUATOR : %s : ITERATE_COMMENT_POST : %s"
                          t.request_id
                          (Terrat_github.show_publish_comment_err err));
                    let results =
                      {
                        results with
                        Terrat_api_components_work_manifest_tf_operation_result.dirspaces =
                          [ dirspace ];
                      }
                    in
                    iterate_comment_posts ~view:`Full t results pull_request work_manifest)
                  dirspaces)

      let publish_result t result pull_request work_manifest =
        let open Abb.Future.Infix_monad in
        Abbs_time_it.run
          (fun time ->
            Logs.info (fun m ->
                m "GITHUB_EVALUATOR : %s : PUBLISH_RESULTS : time=%f" t.request_id time))
          (fun () -> iterate_comment_posts t result pull_request work_manifest)
        >>= function
        | Ok () -> Abb.Future.return (Ok ())
        | Error (#Terrat_github.publish_comment_err as err) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVALUATOR : %s: ERROR : %a"
                  t.request_id
                  Terrat_github.pp_publish_comment_err
                  err);
            Abb.Future.return (Error `Error)
        | Error `Error -> Abb.Future.return (Error `Error)
    end

    module Repo_config = struct
      type t = {
        config : Terrat_config.t;
        installation_id : int;
        pull_number : int;
        repo : Repo.t;
        request_id : string;
        storage : Terrat_storage.t;
        user : string;
      }

      type r = unit

      let account t = { Account.installation_id = t.installation_id; request_id = t.request_id }
      let config t = t.config
      let pull_number t = t.pull_number
      let repo t = t.repo
      let request_id t = t.request_id
      let user t = t.user

      let with_db t ~f =
        Pgsql_pool.with_conn t.storage ~f:(fun db -> f { Db.db; request_id = t.request_id })

      let noop _ = ()
    end

    module Unlock = struct
      type t = {
        access_token : string;
        config : Terrat_config.t;
        ids : Terrat_evaluator2.Unlock_id.t list;
        installation_id : int;
        pull_number : int;
        repo : Repo.t;
        request_id : string;
        storage : Terrat_storage.t;
        user : string;
      }

      type r = unit

      let noop _ = ()
      let account t = { Account.installation_id = t.installation_id; request_id = t.request_id }

      let client t =
        {
          Client.client = Terrat_github.create t.config (`Token t.access_token);
          config = t.config;
          request_id = t.request_id;
        }

      let create_access_control_ctx t client =
        {
          Access_control.client = client.Client.client;
          config = t.config;
          repo = t.repo;
          user = t.user;
        }

      let ids t = t.ids

      let publish_msg t =
        { Publish_msg.client = client t; pull_number = t.pull_number; repo = t.repo; user = t.user }

      let repo t = t.repo
      let request_id t = t.request_id

      let perform_unlock_pull_request t db pull_number =
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_io.Prepared_stmt.execute
          db
          (Sql.insert_pull_request_unlock ())
          (CCInt64.of_int t.repo.Repo.id)
          (CCInt64.of_int pull_number)
        >>= fun () -> clean_pull_request_plans ~repo_id:t.repo.Repo.id ~pull_number db

      let perform_unlock_drift t db =
        Pgsql_io.Prepared_stmt.execute
          db
          (Sql.insert_drift_unlock ())
          (CCInt64.of_int t.repo.Repo.id)

      let unlock' t = function
        | Terrat_evaluator2.Unlock_id.Pull_request pull_number ->
            Pgsql_pool.with_conn t.storage ~f:(fun db ->
                perform_unlock_pull_request t db pull_number)
        | Terrat_evaluator2.Unlock_id.Drift ->
            Pgsql_pool.with_conn t.storage ~f:(fun db -> perform_unlock_drift t db)

      let unlock t id =
        let open Abb.Future.Infix_monad in
        unlock' t id
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s: ERROR : %a" t.request_id Pgsql_io.pp_err err);
            Abb.Future.return (Error `Error)
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s: ERROR : %a" t.request_id Pgsql_pool.pp_err err);
            Abb.Future.return (Error `Error)

      let user t = t.user
    end

    module Drift = struct
      module Schedule = struct
        type t = {
          account : Account.t;
          repo : Repo.t;
          reconcile : bool;
          request_id : string;
          tag_query : Terrat_tag_query.t;
        }

        let account t = t.account
        let repo t = t.repo
        let reconcile t = t.reconcile
        let request_id t = t.request_id
        let tag_query t = t.tag_query
      end

      module Data = struct
        type t = {
          branch_name : Ref.t;
          branch_ref : Ref.t;
          index : Terrat_change_match.Index.t option;
          repo_config : Terrat_repo_config.Version_1.t;
          tree : string list;
        }

        let branch_name t = t.branch_name
        let branch_ref t = t.branch_ref
        let index t = t.index
        let repo_config t = t.repo_config
        let tree t = t.tree
      end

      type t = {
        config : Terrat_config.t;
        request_id : string;
        storage : Terrat_storage.t;
      }

      type r = unit

      let noop _ = ()

      let with_db t ~f =
        Pgsql_pool.with_conn t.storage ~f:(fun db -> f { Db.db; request_id = t.request_id })

      let query_missing_scheduled_runs t =
        let open Abb.Future.Infix_monad in
        Pgsql_pool.with_conn t.storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.fetch
              db
              (Sql.select_missing_drift_scheduled_runs ())
              ~f:(fun installation_id repository_id owner name reconcile tag_query ->
                {
                  Schedule.account =
                    {
                      Account.installation_id = CCInt64.to_int installation_id;
                      request_id = t.request_id;
                    };
                  repo = { Repo.id = CCInt64.to_int repository_id; owner; name };
                  reconcile;
                  request_id = t.request_id;
                  tag_query = CCOption.get_or ~default:Terrat_tag_query.any tag_query;
                }))
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s : DRIFT : %a" t.request_id Pgsql_pool.pp_err err);
            Abb.Future.return (Error `Error)
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s : DRIFT : %a" t.request_id Pgsql_io.pp_err err);
            Abb.Future.return (Error `Error)

      let fetch_data' t account repo =
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_github.get_installation_access_token t.config account.Account.installation_id
        >>= fun access_token ->
        let client = Terrat_github.create t.config (`Token access_token) in
        let client = { Client.client; request_id = t.request_id; config = t.config } in
        Terrat_github.fetch_repo ~owner:repo.Repo.owner ~repo:repo.Repo.name client.Client.client
        >>= fun repoository ->
        let module Rc = Terrat_repo_config.Version_1 in
        let module R = Githubc2_components.Full_repository in
        let default_branch = repoository.R.primary.R.Primary.default_branch in
        Abbs_future_combinators.Infix_result_app.(
          (fun repo_config tree branch -> (repo_config, tree, branch))
          <$> fetch_repo_config client repo default_branch
          <*> fetch_tree client repo default_branch
          <*> Terrat_github.fetch_branch
                ~owner:repo.Repo.owner
                ~repo:repo.Repo.name
                ~branch:default_branch
                client.Client.client)
        >>= function
        | ({ Rc.indexer = Some { Rc.Indexer.enabled = true; _ }; _ } as repo_config), tree, branch
          ->
            let module B = Githubc2_components.Branch_with_protection in
            let module C = Githubc2_components.Commit in
            let commit = branch.B.primary.B.Primary.commit in
            let hash = commit.C.primary.C.Primary.sha in
            Pgsql_pool.with_conn t.storage ~f:(fun db ->
                let db = { Db.db; request_id = t.request_id } in
                query_index db account hash)
            >>= fun index ->
            Abb.Future.return
              (Ok { Data.repo_config; tree; branch_name = default_branch; branch_ref = hash; index })
        | repo_config, tree, branch ->
            let module B = Githubc2_components.Branch_with_protection in
            let module C = Githubc2_components.Commit in
            let commit = branch.B.primary.B.Primary.commit in
            let hash = commit.C.primary.C.Primary.sha in
            Abb.Future.return
              (Ok
                 {
                   Data.repo_config;
                   tree;
                   branch_name = default_branch;
                   branch_ref = hash;
                   index = Some Terrat_change_match.Index.empty;
                 })

      let fetch_data t sched =
        let open Abb.Future.Infix_monad in
        fetch_data' t sched.Schedule.account sched.Schedule.repo
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (#Terrat_github.get_installation_access_token_err as err) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVALUATOR : %s: ERROR : %a"
                  t.request_id
                  Terrat_github.pp_get_installation_access_token_err
                  err);
            Abb.Future.return (Error `Error)
        | Error (#Terrat_github.fetch_repo_err as err) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVALUATOR : %s: ERROR : %a"
                  t.request_id
                  Terrat_github.pp_fetch_repo_err
                  err);
            Abb.Future.return (Error `Error)
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s: ERROR : %a" t.request_id Pgsql_io.pp_err err);
            Abb.Future.return (Error `Error)
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s: ERROR : %a" t.request_id Pgsql_pool.pp_err err);
            Abb.Future.return (Error `Error)
        | Error `Error -> Abb.Future.return (Error `Error)
        | Error (`Parse_err err) ->
            Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : PARSE_ERR : %s" t.request_id err);
            Abb.Future.return (Error `Error)
    end

    module Index = struct
      type t = {
        config : Terrat_config.t;
        installation_id : int;
        pull_number : int;
        repo : Repo.t;
        request_id : string;
        storage : Terrat_storage.t;
        user : string;
      }

      type r = unit

      let account t = { Account.installation_id = t.installation_id; request_id = t.request_id }
      let config t = t.config
      let pull_number t = t.pull_number
      let repo t = t.repo
      let request_id t = t.request_id
      let user t = t.user

      let with_db t ~f =
        Pgsql_pool.with_conn t.storage ~f:(fun db -> f { Db.db; request_id = t.request_id })

      let noop _ = ()
    end

    module Push = struct
      type t = {
        branch : string;
        config : Terrat_config.t;
        installation_id : int;
        repo : Repo.t;
        request_id : string;
        storage : Terrat_storage.t;
      }

      type r = unit

      let noop _ = ()
      let repo t = t.repo
      let request_id t = t.request_id
      let branch t = t.branch

      let enable_drift_schedule t schedule reconcile tag_query =
        Pgsql_pool.with_conn t.storage ~f:(fun db ->
            Pgsql_io.tx db ~f:(fun () ->
                Pgsql_io.Prepared_stmt.execute
                  db
                  Sql.upsert_drift_schedule
                  (CCInt64.of_int t.repo.Repo.id)
                  schedule
                  reconcile
                  tag_query))

      let disable_drift_schedule t =
        Pgsql_pool.with_conn t.storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.execute
              db
              Sql.delete_drift_schedule
              (CCInt64.of_int t.repo.Repo.id))

      let update_drift_config t =
        let module D = Terrat_repo_config.Drift in
        function
        | Some { D.enabled = true; schedule; reconcile; tag_query } -> (
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : DRIFT : ENABLE : repo=%s : schedule=%s : reconcile=%s : \
                   tag_query=%s"
                  t.request_id
                  (Repo.to_string t.repo)
                  schedule
                  (Bool.to_string reconcile)
                  (CCOption.get_or ~default:"" tag_query));
            match CCOption.map Terrat_tag_query.of_string tag_query with
            | Some (Ok tag_query) -> enable_drift_schedule t schedule reconcile (Some tag_query)
            | None -> enable_drift_schedule t schedule reconcile None
            | Some (Error (#Terrat_tag_query_ast.err as err)) ->
                Logs.info (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : DRIFT : ERROR : %a"
                      t.request_id
                      Terrat_tag_query_ast.pp_err
                      err);
                Abb.Future.return (Ok ()))
        | Some { D.enabled = false; _ } | None ->
            Logs.info (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : DRIFT : DISABLE : repo=%s"
                  t.request_id
                  (Repo.to_string t.repo));
            disable_drift_schedule t

      let update_drift_schedule' t =
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_github.get_installation_access_token t.config t.installation_id
        >>= fun access_token ->
        let client =
          {
            Client.client = Terrat_github.create t.config (`Token access_token);
            config = t.config;
            request_id = t.request_id;
          }
        in
        fetch_repo_config client t.repo t.branch
        >>= fun repo_config ->
        let module C = Terrat_repo_config.Version_1 in
        let drift_config = repo_config.C.drift in
        update_drift_config t drift_config

      let update_drift_schedule t =
        let open Abb.Future.Infix_monad in
        update_drift_schedule' t
        >>= function
        | Ok () -> Abb.Future.return (Ok ())
        | Error (#Terrat_github.get_installation_access_token_err as err) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVALUATOR : %s: ERROR : %a"
                  t.request_id
                  Terrat_github.pp_get_installation_access_token_err
                  err);
            Abb.Future.return (Error `Error)
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s: ERROR : %a" t.request_id Pgsql_io.pp_err err);
            Abb.Future.return (Error `Error)
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s: ERROR : %a" t.request_id Pgsql_pool.pp_err err);
            Abb.Future.return (Error `Error)
        | Error `Error -> Abb.Future.return (Error `Error)
        | Error (`Parse_err err) ->
            Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : PARSE_ERR : %s" t.request_id err);
            Abb.Future.return (Error `Error)

      let drift_of_t t = { Drift.config = t.config; request_id = t.request_id; storage = t.storage }
    end
  end

  module Runner = struct
    type t = {
      config : Terrat_config.t;
      request_id : string;
      storage : Terrat_storage.t;
    }

    type r = unit

    let get_installation_id =
      let module Wm = Terrat_work_manifest2 in
      function
      | {
          Wm.src = Wm.Kind.Pull_request { Pull_request.account = { Account.installation_id; _ }; _ };
          _;
        }
      | { Wm.src = Wm.Kind.Drift { Drift.account = { Account.installation_id; _ }; _ }; _ }
      | { Wm.src = Wm.Kind.Index { Index.account = { Account.installation_id; _ }; _ }; _ } ->
          installation_id

    let get_repo =
      let module Wm = Terrat_work_manifest2 in
      function
      | { Wm.src = Wm.Kind.Pull_request { Pull_request.repo; _ }; _ }
      | { Wm.src = Wm.Kind.Drift { Drift.repo; _ }; _ }
      | { Wm.src = Wm.Kind.Index { Index.repo; _ }; _ } -> repo

    let get_branch =
      let module Wm = Terrat_work_manifest2 in
      let module Prs = Terrat_pull_request.State in
      function
      | {
          Wm.src =
            Wm.Kind.Pull_request { Pull_request.branch_name; state = Prs.(Open _ | Closed); _ };
          _;
        } -> branch_name
      | {
          Wm.src = Wm.Kind.Pull_request { Pull_request.base_branch_name; state = Prs.Merged _; _ };
          _;
        } -> base_branch_name
      | { Wm.src = Wm.Kind.Drift { Drift.branch = branch_name; _ }; _ }
      | { Wm.src = Wm.Kind.Index { Index.branch = branch_name; _ }; _ } -> branch_name

    let make_run_telemetry config run_type repo =
      let module Wm = Terrat_work_manifest2 in
      Terrat_telemetry.Event.Run
        {
          github_app_id = Terrat_config.github_app_id config;
          run_type;
          owner = repo.Repo.owner;
          repo = repo.Repo.name;
        }

    let config t = t.config
    let request_id t = t.request_id
    let completed _ = ()

    let client t work_manifest =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_github.get_installation_access_token t.config (get_installation_id work_manifest)
        >>= fun access_token ->
        Abb.Future.return
          (Ok
             {
               Client.client = Terrat_github.create t.config (`Token access_token);
               config = t.config;
               request_id = t.request_id;
             })
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Terrat_github.get_installation_access_token_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s: ERROR : %a"
                t.request_id
                Terrat_github.pp_get_installation_access_token_err
                err);
          Abb.Future.return (Error `Error)

    let abort_work_manifest t client work_manifest cause =
      let module Wm = Terrat_work_manifest2 in
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_pool.with_conn t.storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.execute db Sql.abort_work_manifest work_manifest.Wm.id
          >>= fun () ->
          match work_manifest.Wm.src with
          | Wm.Kind.Pull_request { Pull_request.id = pull_number; repo; _ } ->
              let body =
                match cause with
                | `Failed_to_start -> Tmpl.failed_to_start_workflow
                | `Missing_workflow -> Tmpl.failed_to_find_workflow
              in
              Terrat_github.publish_comment
                ~owner:repo.Repo.owner
                ~repo:repo.Repo.name
                ~pull_number
                ~body
                client.Client.client
          | _ -> Abb.Future.return (Ok ()))

    let next_work_manifest t =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_pool.with_conn t.storage ~f:(fun db ->
            let db = { Db.db; request_id = t.request_id } in
            Pgsql_io.Prepared_stmt.fetch db.Db.db ~f:CCFun.id Sql.select_next_work_manifest
            >>= function
            | [] -> Abb.Future.return (Ok None)
            | [ id ] ->
                Abbs_time_it.run
                  (fun time ->
                    Logs.info (fun m ->
                        m
                          "GITHUB_EVALUATOR : %s : QUERY_WORK_MANIFEST : id=%a : time=%f"
                          t.request_id
                          Uuidm.pp
                          id
                          time))
                  (fun () -> query_work_manifest db id)
            | _ :: _ -> assert false)
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" t.request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s: ERROR : %a" t.request_id Pgsql_pool.pp_err err);
          Abb.Future.return (Error `Error)
      | Error `Error -> Abb.Future.return (Error `Error)

    let run_work_manifest t client work_manifest =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        let module Wm = Terrat_work_manifest2 in
        let repo = get_repo work_manifest in
        let branch = get_branch work_manifest in
        Terrat_github.load_workflow ~owner:repo.Repo.owner ~repo:repo.Repo.name client.Client.client
        >>= function
        | Some workflow_id -> (
            let open Abb.Future.Infix_monad in
            Terrat_github.call
              client.Client.client
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
                                            ( "work-token",
                                              `String (Uuidm.to_string work_manifest.Wm.id) );
                                            ( "api-base-url",
                                              `String (Terrat_config.api_base t.config ^ "/github")
                                            );
                                          ];
                                    };
                            };
                        additional = Json_schema.String_map.empty;
                      }
                  Parameters.(
                    make
                      ~owner:repo.Repo.owner
                      ~repo:repo.Repo.name
                      ~workflow_id:(Workflow_id.V0 workflow_id)))
            >>= function
            | Ok _ ->
                Terrat_telemetry.send
                  (Terrat_config.telemetry t.config)
                  (make_run_telemetry t.config work_manifest.Wm.run_type repo)
                >>= fun () -> Abb.Future.return (Ok ())
            | Error (`Missing_response resp as err)
              when CCString.mem ~sub:"No ref found for:" (Openapi.Response.value resp) ->
                (* If the ref has been deleted while we are looking up the
                   workflow, just ignore and move on. *)
                Logs.err (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : ERROR : REF_NOT_FOUND : %s : %s : %s : %a"
                      t.request_id
                      repo.Repo.owner
                      repo.Repo.name
                      branch
                      Githubc2_abb.pp_call_err
                      err);
                Abb.Future.return (Ok ())
            | Error (#Githubc2_abb.call_err as err) ->
                let open Abbs_future_combinators.Infix_result_monad in
                Logs.err (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : ERROR : COULD_NOT_RUN_WORKFLOW : %s : %s : %s : %a"
                      t.request_id
                      repo.Repo.owner
                      repo.Repo.name
                      branch
                      Githubc2_abb.pp_call_err
                      err);
                abort_work_manifest t client work_manifest `Failed_to_start
                >>= fun () -> Abb.Future.return (Error `Error))
        | None ->
            let open Abbs_future_combinators.Infix_result_monad in
            Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : MISSING_WORKFLOW" t.request_id);
            abort_work_manifest t client work_manifest `Missing_workflow
            >>= fun () -> Abb.Future.return (Error `Error)
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" t.request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s: ERROR : %a" t.request_id Pgsql_pool.pp_err err);
          Abb.Future.return (Error `Error)
      | Error (#Terrat_github.publish_comment_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s: ERROR : %a"
                t.request_id
                Terrat_github.pp_publish_comment_err
                err);
          Abb.Future.return (Error `Error)
      | Error (#Terrat_github.get_installation_access_token_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s: ERROR : %a"
                t.request_id
                Terrat_github.pp_get_installation_access_token_err
                err);
          Abb.Future.return (Error `Error)
      | Error `Error -> Abb.Future.return (Error `Error)
  end
end

module Evaluator = Terrat_evaluator2.Make (S)
module Ref = S.Ref
module Repo = S.Repo
module Pull_request = S.Pull_request
module Drift = S.Drift
module Index = S.Index

module Event = struct
  module Initiate = struct
    type t = S.Event.Initiate.t

    let make ~branch_ref ~config ~encryption_key ~request_id ~run_id ~storage ~work_manifest_id () =
      {
        S.Event.Initiate.branch_ref;
        config;
        encryption_key;
        request_id;
        run_id;
        storage;
        work_manifest_id;
      }

    let eval = Evaluator.Event.Initiate.eval
  end

  module Terraform = struct
    type t = S.Event.Terraform.t

    let make
        ~config
        ~installation_id
        ~operation
        ~pull_number
        ~repo
        ~request_id
        ~storage
        ~tag_query
        ~user
        () =
      {
        S.Event.Terraform.config;
        installation_id;
        operation;
        pull_number;
        repo;
        request_id;
        storage;
        tag_query;
        user;
      }

    let eval = Evaluator.Event.Terraform.eval
  end

  module Repo_config = struct
    type t = S.Event.Repo_config.t

    let make ~config ~installation_id ~pull_number ~repo ~request_id ~storage ~user () =
      { S.Event.Repo_config.config; installation_id; pull_number; repo; request_id; storage; user }

    let eval = Evaluator.Event.Repo_config.eval
  end

  module Index = struct
    type t = S.Event.Index.t

    let make ~config ~installation_id ~pull_number ~repo ~request_id ~storage ~user () =
      { S.Event.Index.config; installation_id; pull_number; repo; request_id; storage; user }

    let eval = Evaluator.Event.Index.eval
  end

  module Unlock = struct
    type t = S.Event.Unlock.t

    let make
        ~access_token
        ~config
        ~ids
        ~installation_id
        ~pull_number
        ~repo
        ~request_id
        ~storage
        ~user
        () =
      {
        S.Event.Unlock.access_token;
        config;
        ids;
        installation_id;
        pull_number;
        repo;
        request_id;
        storage;
        user;
      }

    let eval = Evaluator.Event.Unlock.eval
  end

  module Push = struct
    type t = S.Event.Push.t

    let make ~branch ~config ~installation_id ~repo ~request_id ~storage () =
      { S.Event.Push.branch; config; installation_id; repo; request_id; storage }

    let eval = Evaluator.Event.Push.eval
  end

  module Drift = struct
    type t = S.Event.Drift.t

    let make ~config ~request_id ~storage () = { S.Event.Drift.config; request_id; storage }
    let eval = Evaluator.Event.Drift.eval
  end

  module Plan_cleanup = struct
    type t = S.Event.Plan_cleanup.t

    let make ~request_id ~storage () = { S.Event.Plan_cleanup.request_id; storage }
    let eval = Evaluator.Event.Plan_cleanup.eval
  end

  module Plan_get = struct
    type t = S.Event.Plan_get.t

    let make ~config ~dir ~request_id ~storage ~work_manifest_id ~workspace () =
      { S.Event.Plan_get.config; dir; request_id; storage; work_manifest_id; workspace }

    let eval = Evaluator.Event.Plan_get.eval
  end

  module Plan_set = struct
    type t = S.Event.Plan_set.t

    let make ~config ~data ~dir ~has_changes ~request_id ~storage ~work_manifest_id ~workspace () =
      {
        S.Event.Plan_set.config;
        data;
        dir;
        has_changes;
        request_id;
        storage;
        work_manifest_id;
        workspace;
      }

    let eval = Evaluator.Event.Plan_set.eval
  end

  module Result = struct
    type t = S.Event.Result.t

    let make ~config ~request_id ~result ~storage ~work_manifest_id () =
      { S.Event.Result.config; request_id; result; storage; work_manifest_id }

    let eval = Evaluator.Event.Result.eval
  end
end

module Runner = struct
  type t = S.Runner.t

  let make ~config ~request_id ~storage () = { S.Runner.config; request_id; storage }
  let eval = Evaluator.Runner.eval
end
