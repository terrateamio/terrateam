module Gw = Terrat_github_webhooks

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

  let insert_org =
    Pgsql_io.Typed_sql.(sql // (* id *) Ret.uuid /^ read "insert_org.sql" /% Var.text "name")

  let insert_github_installation =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_installation.sql"
      /% Var.bigint "id"
      /% Var.text "login"
      /% Var.uuid "org"
      /% Var.text "target_type")

  let select_github_installation =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.bigint
      /^ "select id from github_installations where id = $id"
      /% Var.bigint "id")

  let insert_github_installation_repository =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_installation_repository.sql"
      /% Var.bigint "id"
      /% Var.bigint "installation_id"
      /% Var.text "owner"
      /% Var.text "name")

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
      /^ "insert into github_dirspaces (base_sha, path, repository, sha, workspace) values \
          ($base_sha, $path, $repository, $sha, $workspace) on conflict (repository, sha, path, \
          workspace) do nothing"
      /% Var.text "base_sha"
      /% Var.text "path"
      /% Var.bigint "repository"
      /% Var.text "sha"
      /% Var.text "workspace")

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
          workflow_idx) values ($work_manifest, $path, $workspace, $workflow_idx)"
      /% Var.uuid "work_manifest"
      /% Var.text "path"
      /% Var.text "workspace"
      /% Var.(option (smallint "workflow_idx")))

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

  let insert_pull_request_unlock =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_pull_request_unlocks (repository, pull_number) values ($repository, \
          $pull_number)"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number")

  let fail_running_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.uuid
      // (* pull_number *) Ret.bigint
      // (* sha *) Ret.text
      // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
      /^ read "github_fail_running_work_manifest.sql"
      /% Var.text "owner"
      /% Var.text "name"
      /% Var.text "run_id")

  let select_missing_dirspace_applies_for_pull_request =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_missing_dirspace_applies_for_pull_request.sql"
      /% Var.text "owner"
      /% Var.text "name"
      /% Var.bigint "pull_number")

  let select_work_manifest_dirspaces =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ "select path, workspace from github_work_manifest_dirspaceflows where work_manifest = $id"
      /% Var.uuid "id")
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

  let action_failed =
    CCOption.get_exn_or
      "github_action_failed.tmpl"
      (Terrat_files_tmpl.read "github_action_failed.tmpl")

  let pull_request_not_appliable = read "github_pull_request_not_appliable.tmpl"
  let pull_request_not_mergeable = read "github_pull_request_not_mergeable.tmpl"
  let terrateam_comment_unknown_action = read "terrateam_comment_unknown_action.tmpl"
  let terrateam_comment_help = read "terrateam_comment_help.tmpl"
  let apply_no_matching_dirspaces = read "apply_no_matching_dirspaces.tmpl"
  let plan_no_matching_dirspaces = read "plan_no_matching_dirspaces.tmpl"
  let base_branch_not_default_branch = read "base_branch_not_default_branch.tmpl"
  let auto_apply_running = read "auto_apply_running.tmpl"
  let bad_glob = read "bad_glob.tmpl"

  let unlock_success =
    CCOption.get_exn_or "unlock_success.tmpl" (Terrat_files_tmpl.read "unlock_success.tmpl")
end

module Event = struct
  type t = {
    access_token : string;
    config : Terrat_config.t;
    installation_id : int;
    pull_number : int;
    repository : Gw.Repository.t;
    request_id : string;
    run_type : Terrat_work_manifest.Run_type.t;
    tag_query : Terrat_tag_set.t;
  }

  let make
      ~access_token
      ~config
      ~installation_id
      ~pull_number
      ~repository
      ~request_id
      ~run_type
      ~tag_query =
    Logs.info (fun m ->
        m
          "GITHUB_EVENT : %s : MAKE : %s : %s : %d : %s : %s"
          request_id
          repository.Gw.Repository.owner.Gw.User.login
          repository.Gw.Repository.name
          pull_number
          (Terrat_work_manifest.Run_type.to_string run_type)
          (Terrat_tag_set.to_string tag_query));
    {
      access_token;
      config;
      installation_id;
      pull_number;
      repository;
      request_id;
      run_type;
      tag_query;
    }

  let request_id t = t.request_id
  let tag_query t = t.tag_query
  let run_type t = t.run_type
  let default_branch t = t.repository.Gw.Repository.default_branch
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
            { Primary.filename; status = "renamed"; previous_filename = Some previous_filename; _ };
          _;
        } -> Terrat_change.Diff.Move { filename; previous_filename }
      | _ -> failwith "nyi1")

let fetch_diff ~request_id ~access_token ~owner ~repo ~base_sha head_sha =
  let open Abbs_future_combinators.Infix_result_monad in
  Terrat_github.compare_commits ~access_token ~owner ~repo (base_sha, head_sha)
  >>= fun resp ->
  let module Ghc_comp = Githubc2_components in
  let module Cc = Ghc_comp.Commit_comparison in
  match Openapi.Response.value resp with
  | `OK { Cc.primary = { Cc.Primary.files = Some files; _ }; _ } ->
      let diff = diff_of_github_diff files in
      Abb.Future.return (Ok diff)
  | otherwise -> Abb.Future.return (Error (`Bad_compare_response otherwise))

module Evaluator = Terrat_event_evaluator.Make (struct
  module Event = Event

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
  end

  let list_existing_dirs event pull_request dirs =
    let open Abb.Future.Infix_monad in
    let client = Terrat_github.create (`Token event.Event.access_token) in
    Abbs_future_combinators.List_result.fold_left
      ~init:Terrat_event_evaluator.Dir_set.empty
      ~f:(fun acc d ->
        let open Abbs_future_combinators.Infix_result_monad in
        Githubc2_abb.call
          client
          Githubc2_repos.Get_content.(
            make
              (Parameters.make
                 ~owner:event.Event.repository.Gw.Repository.owner.Gw.User.login
                 ~repo:event.Event.repository.Gw.Repository.name
                 ~ref_:(Some pull_request.Terrat_pull_request.hash)
                 ~path:d
                 ()))
        >>= fun resp ->
        match Openapi.Response.value resp with
        | `OK _ | `Found | `Forbidden _ ->
            Abb.Future.return (Ok (Terrat_event_evaluator.Dir_set.add d acc))
        | `Not_found _ -> Abb.Future.return (Ok acc))
      (Terrat_event_evaluator.Dir_set.to_list dirs)
    >>= function
    | Ok existing_dirs -> Abb.Future.return (Ok existing_dirs)
    | Error (#Githubc2_abb.call_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : FAIL_LIST_EXISTING_DIRS : %s"
              (Event.request_id event)
              (Githubc2_abb.show_call_err err));
        Abb.Future.return (Error `Error)

  let store_dirspaceflows db event pull_request dirspaceflows =
    let run =
      Abbs_future_combinators.List_result.iter
        ~f:(fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; workspace }; _ } ->
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.insert_dirspace
            (Pull_request.base_hash pull_request)
            dir
            (CCInt64.of_int event.Event.repository.Gw.Repository.id)
            (Pull_request.hash pull_request)
            workspace)
        dirspaceflows
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
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
      (CCInt64.of_int event.Event.repository.Gw.Repository.id)
      pull_request.Pr.hash
      merged_sha
      merged_at
      state
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let store_new_work_manifest db event work_manifest =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      let module Wm = Terrat_work_manifest in
      let module Pr = Terrat_pull_request in
      let pull_request = work_manifest.Terrat_work_manifest.pull_request in
      let hash =
        match pull_request.Pr.state with
        | Pr.State.(Merged Merged.{ merged_hash; _ }) -> merged_hash
        | _ -> work_manifest.Wm.hash
      in
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : %s : STORE_WORK_MANIFEST : %s : %s : %Ld : %s : %s"
            (Event.request_id event)
            event.Event.repository.Gw.Repository.owner.Gw.User.login
            event.Event.repository.Gw.Repository.name
            pull_request.Pr.id
            work_manifest.Wm.base_hash
            hash);
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.insert_work_manifest
        ~f:(fun id state created_at -> (id, state, created_at))
        work_manifest.Wm.base_hash
        pull_request.Pr.id
        (CCInt64.of_int event.Event.repository.Gw.Repository.id)
        (Terrat_work_manifest.Run_type.to_string event.Event.run_type)
        hash
        (Terrat_tag_set.to_string work_manifest.Wm.tag_query)
      >>= function
      | [] -> assert false
      | (id, state, created_at) :: _ ->
          Abbs_future_combinators.List_result.iter
            ~f:
              (fun Terrat_change.
                     { Dirspaceflow.dirspace = { Dirspace.dir; workspace }; workflow_idx } ->
              Pgsql_io.Prepared_stmt.execute
                db
                Sql.insert_work_manifest_dirspaceflow
                id
                dir
                workspace
                workflow_idx)
            work_manifest.Wm.changes
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
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)
    | Error (#Githubc2_abb.call_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : ERROR : %s"
              (Event.request_id event)
              (Githubc2_abb.show_call_err err));
        Abb.Future.return (Error `Error)

  let fetch_repo_config event pull_request =
    let open Abb.Future.Infix_monad in
    Terrat_github.fetch_repo_config
      ~python:(Terrat_config.python_exec event.Event.config)
      ~access_token:event.Event.access_token
      ~owner:event.Event.repository.Gw.Repository.owner.Gw.User.login
      ~repo:event.Event.repository.Gw.Repository.name
      pull_request.Terrat_pull_request.hash
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
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : ERROR : %s"
              (Event.request_id event)
              (Terrat_github.show_fetch_repo_config_err err));
        Abb.Future.return
          (Error (`Repo_config_err "An unknown error occurred while reading the repo config."))

  let fetch_pull_request event =
    let owner = event.Event.repository.Gw.Repository.owner.Gw.User.login in
    let repo = event.Event.repository.Gw.Repository.name in
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.fetch_pull_request
        ~access_token:event.Event.access_token
        ~owner
        ~repo
        event.Event.pull_number
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
            ~request_id:event.Event.request_id
            ~access_token:event.Event.access_token
            ~owner
            ~repo
            ~base_sha
            hash
          >>= fun diff ->
          Logs.debug (fun m ->
              m
                "GITHUB_EVENT : %s : MERGEABLE : merged=%s : mergeable_state=%s"
                event.Event.request_id
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
                   id = CCInt64.of_int event.Event.pull_number;
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
      | `Not_found _ | `Internal_server_error _ | `Not_modified -> failwith "nyi2"
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error `Error -> Abb.Future.return (Error `Error)
    | Error (#Githubc2_abb.call_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : ERROR : %s : %s : %s"
              (Event.request_id event)
              owner
              repo
              (Githubc2_abb.show_call_err err));
        Abb.Future.return (Error `Error)
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : ERROR : %s : %s : %s"
              (Event.request_id event)
              owner
              repo
              (Terrat_github.show_get_installation_access_token_err err));
        Abb.Future.return (Error `Error)
    | Error (`Bad_compare_response (`OK cc)) ->
        Logs.info (fun m ->
            m
              "GITHUB_EVENT : %s : NO_FILES_CHANGED : %s : %s : %d"
              (Event.request_id event)
              owner
              repo
              event.Event.pull_number);
        Logs.info (fun m ->
            m
              "GITHUB_EVENT : %s : NO_FILES_CHANGED : %s : %s : %s"
              (Event.request_id event)
              owner
              repo
              (Githubc2_repos.Compare_commits.Responses.OK.show cc));
        Abb.Future.return (Error `Error)
    | Error (`Bad_compare_response (`Not_found not_found)) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : COMMITS_NOT_FOUND : %s : %s : %d : %s"
              (Event.request_id event)
              owner
              repo
              event.Event.pull_number
              (Githubc2_repos.Compare_commits.Responses.Not_found.show not_found));
        Abb.Future.return (Error `Error)
    | Error (`Bad_compare_response (`Internal_server_error err)) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : INTERNAL_SERVER_ERROR : %s : %s : %d : %s"
              (Event.request_id event)
              owner
              repo
              event.Event.pull_number
              (Githubc2_repos.Compare_commits.Responses.Internal_server_error.show err));
        Abb.Future.return (Error `Error)

  let query_pull_request_out_of_diff_applies db event pull_request =
    let run =
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_out_of_diff_applies
        ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
        (CCInt64.of_int event.Event.repository.Gw.Repository.id)
        pull_request.Terrat_pull_request.id
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let fetch_tree event pull_request =
    let open Abb.Future.Infix_monad in
    let owner = event.Event.repository.Gw.Repository.owner.Gw.User.login in
    let repo = event.Event.repository.Gw.Repository.name in
    Terrat_github.get_tree
      ~access_token:event.Event.access_token
      ~owner
      ~repo
      ~sha:pull_request.Terrat_pull_request.hash
      ()
    >>= function
    | Ok files -> Abb.Future.return (Ok files)
    | Error (#Terrat_github.get_tree_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : ERROR : %s"
              (Event.request_id event)
              (Terrat_github.show_get_tree_err err));
        Abb.Future.return (Error `Error)

  let fetch_commit_checks event pull_request =
    let open Abb.Future.Infix_monad in
    let owner = event.Event.repository.Gw.Repository.owner.Gw.User.login in
    let repo = event.Event.repository.Gw.Repository.name in
    Abbs_time_it.run
      (fun t ->
        Logs.info (fun m ->
            m "GITHUB_EVENT : %s : LIST_COMMIT_CHECKS : %f" (Event.request_id event) t))
      (fun () ->
        Terrat_github_commit_check.list
          ~access_token:event.Event.access_token
          ~owner
          ~repo
          ~ref_:pull_request.Terrat_pull_request.hash
          ())
    >>= function
    | Ok _ as res -> Abb.Future.return res
    | Error (#Terrat_github_commit_check.list_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : FETCH_COMMIT_CHECKS : %s"
              (Event.request_id event)
              (Terrat_github_commit_check.show_list_err err));
        Abb.Future.return (Error `Error)

  let fetch_pull_request_reviews event pull_request =
    let open Abb.Future.Infix_monad in
    let owner = event.Event.repository.Gw.Repository.owner.Gw.User.login in
    let repo = event.Event.repository.Gw.Repository.name in
    let pull_number = CCInt64.to_int pull_request.Terrat_pull_request.id in
    Terrat_github.Pull_request_reviews.list
      ~access_token:event.Event.access_token
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
                (fun Prr.{ primary = Primary.{ node_id; state; _ }; _ } ->
                  Terrat_pull_request_review.
                    {
                      id = node_id;
                      status =
                        (match state with
                        | "APPROVED" -> Status.Approved
                        | _ -> Status.Unknown);
                    })
                reviews))
    | Error (#Terrat_github.Pull_request_reviews.list_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : ERROR : %s"
              (Event.request_id event)
              (Terrat_github.Pull_request_reviews.show_list_err err));
        Abb.Future.return (Error `Error)

  let query_conflicting_work_manifests_in_repo db event =
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
              pull_request;
              run_id;
              run_type = CCOption.get_exn_or ("run type " ^ run_type) (Run_type.of_string run_type);
              state;
              tag_query = Terrat_tag_set.of_string tag_query;
            })
        (CCInt64.of_int event.Event.repository.Gw.Repository.id)
        (CCInt64.of_int event.Event.pull_number)
        event.Event.run_type
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok wms -> Abb.Future.return (Ok wms)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let create_commit_checks event pull_request checks =
    let open Abb.Future.Infix_monad in
    Terrat_github_commit_check.create
      ~access_token:event.Event.access_token
      ~owner:event.Event.repository.Gw.Repository.owner.Gw.User.login
      ~repo:event.Event.repository.Gw.Repository.name
      ~ref_:pull_request.Terrat_pull_request.hash
      checks
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Githubc2_abb.call_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : ERROR : %s"
              (Event.request_id event)
              (Githubc2_abb.show_call_err err));
        Abb.Future.return (Error `Error)

  let get_commit_check_details_url event pull_request =
    Printf.sprintf
      "https://github.com/%s/%s/actions"
      event.Event.repository.Gw.Repository.owner.Gw.User.login
      event.Event.repository.Gw.Repository.name

  let query_unapplied_dirspaces db event pull_request =
    let module Pr = Terrat_pull_request in
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db
      Sql.select_missing_dirspace_applies_for_pull_request
      ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
      event.Event.repository.Gw.Repository.owner.Gw.User.login
      event.Event.repository.Gw.Repository.name
      pull_request.Pr.id
    >>= function
    | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let query_dirspaces_without_valid_plans db event pull_request dirspaces =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db
      ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
      Sql.select_dirspaces_without_valid_plans
      (CCInt64.of_int event.Event.repository.Gw.Repository.id)
      pull_request.Terrat_pull_request.id
      (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
      (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
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
      (CCInt64.of_int event.Event.repository.Gw.Repository.id)
      pull_request.Terrat_pull_request.id
      (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
      (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
    >>= function
    | Ok res -> Abb.Future.return (Ok (Terrat_event_evaluator.Dirspace_map.of_list res))
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let publish_comment msg_type event body =
    let open Abb.Future.Infix_monad in
    Terrat_github.publish_comment
      ~access_token:event.Event.access_token
      ~owner:event.Event.repository.Gw.Repository.owner.Gw.User.login
      ~repo:event.Event.repository.Gw.Repository.name
      ~pull_number:event.Event.pull_number
      body
    >>= function
    | Ok () -> Abb.Future.return ()
    | Error (#Terrat_github.publish_comment_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : %s : ERROR : %s"
              (Event.request_id event)
              msg_type
              (Terrat_github.show_publish_comment_err err));
        Abb.Future.return ()

  let apply_template_and_publish msg_type template kv event =
    match Snabela.apply template kv with
    | Ok body -> publish_comment msg_type event body
    | Error (#Snabela.err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : TEMPLATE_ERROR : %s"
              (Event.request_id event)
              (Snabela.show_err err));
        Abb.Future.return ()

  let publish_msg event = function
    | Terrat_event_evaluator.Msg.Missing_plans dirspaces ->
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
                  "GITHUB_EVENT : %s : MISSING_PLANS : %s : %s"
                  (Event.request_id event)
                  dir
                  workspace))
          dirspaces;
        apply_template_and_publish "MISSING_PLANS" Tmpl.missing_plans kv event
    | Terrat_event_evaluator.Msg.Dirspaces_owned_by_other_pull_request prs ->
        let prs = Terrat_event_evaluator.Dirspace_map.to_list prs in
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
                  "GITHUB_EVENT : %s : DIRSPACES_OWNED_BY_OTHER_PR : %s : %s : %Ld"
                  (Event.request_id event)
                  dir
                  workspace
                  id))
          prs;
        apply_template_and_publish
          "DIRSPACES_OWNED_BY_OTHER_PRS"
          Tmpl.dirspaces_owned_by_other_pull_requests
          kv
          event
    | Terrat_event_evaluator.Msg.Conflicting_work_manifests wms ->
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
                                pull_request = Terrat_pull_request.{ id; _ };
                                _;
                              } ->
                         Map.of_list
                           [
                             ("pull_number", string (CCInt64.to_string id));
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
    | Terrat_event_evaluator.Msg.Repo_config_parse_failure err ->
        let kv = Snabela.Kv.(Map.of_list [ ("msg", string err) ]) in
        apply_template_and_publish
          "REPO_CONFIG_PARSE_FAILURE"
          Tmpl.repo_config_parse_failure
          kv
          event
    | Terrat_event_evaluator.Msg.Repo_config_failure err ->
        let kv = Snabela.Kv.(Map.of_list [ ("msg", string err) ]) in
        apply_template_and_publish
          "REPO_CONFIG_GENERIC_FAILURE"
          Tmpl.repo_config_generic_failure
          kv
          event
    | Terrat_event_evaluator.Msg.Pull_request_not_appliable (_, apply_requirements) ->
        let module Ar = Terrat_event_evaluator.Msg.Apply_requirements in
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
    | Terrat_event_evaluator.Msg.Pull_request_not_mergeable _ ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish
          "PULL_REQUEST_NOT_MERGEABLE"
          Tmpl.pull_request_not_mergeable
          kv
          event
    | Terrat_event_evaluator.Msg.Apply_no_matching_dirspaces ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish
          "APPLY_NO_MATCHING_DIRSPACES"
          Tmpl.apply_no_matching_dirspaces
          kv
          event
    | Terrat_event_evaluator.Msg.Plan_no_matching_dirspaces ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish
          "PLAN_NO_MATCHING_DIRSPACES"
          Tmpl.plan_no_matching_dirspaces
          kv
          event
    | Terrat_event_evaluator.Msg.Base_branch_not_default_branch _ ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish
          "BASE_BRANCH_NOT_DEFAULT_BRANCH"
          Tmpl.base_branch_not_default_branch
          kv
          event
    | Terrat_event_evaluator.Msg.Autoapply_running ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish "AUTO_APPLY_RUNNING" Tmpl.auto_apply_running kv event
    | Terrat_event_evaluator.Msg.Bad_glob s ->
        let kv = Snabela.Kv.(Map.of_list [ ("glob", string s) ]) in
        apply_template_and_publish "BAD_GLOB" Tmpl.bad_glob kv event
end)

let run_event_evaluator storage event =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.insert_github_installation_repository
        (CCInt64.of_int event.Event.repository.Gw.Repository.id)
        (CCInt64.of_int event.Event.installation_id)
        event.Event.repository.Gw.Repository.owner.Gw.User.login
        event.Event.repository.Gw.Repository.name)
  >>= fun () ->
  let open Abb.Future.Infix_monad in
  Abb.Future.fork
    (Abbs_time_it.run
       (fun t ->
         Logs.info (fun m -> m "GITHUB_EVENT : %s : EVALUATE_EVENT : %f" event.Event.request_id t))
       (fun () -> Evaluator.run storage event)
    >>= fun () ->
    Abbs_time_it.run
      (fun t ->
        Logs.info (fun m -> m "GITHUB_EVENT : %s : GITHUB_RUNNER : %f" event.Event.request_id t))
      (fun () ->
        Terrat_github_runner.run ~request_id:(Event.request_id event) event.Event.config storage))
  >>= fun _ -> Abb.Future.return (Ok ())

let perform_unlock_pr request_id config storage installation_id repository pull_number =
  let open Abbs_future_combinators.Infix_result_monad in
  Logs.info (fun m ->
      m
        "GITHUB_EVENT : %s : UNLOCK : %s : %s  : %d"
        request_id
        repository.Gw.Repository.owner.Gw.User.login
        repository.Gw.Repository.name
        pull_number);
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.insert_pull_request_unlock
        (CCInt64.of_int repository.Gw.Repository.id)
        (CCInt64.of_int pull_number)
      >>= fun () ->
      Terrat_github_plan_cleanup.clean_pull_request
        ~owner:repository.Gw.Repository.owner.Gw.User.login
        ~repo:repository.Gw.Repository.name
        ~pull_number
        db)
  >>= fun () ->
  Terrat_github.get_installation_access_token config installation_id
  >>= fun token ->
  let open Abb.Future.Infix_monad in
  Terrat_github.publish_comment
    ~access_token:token
    ~owner:repository.Gw.Repository.owner.Gw.User.login
    ~repo:repository.Gw.Repository.name
    ~pull_number
    Tmpl.unlock_success
  >>= function
  | Ok () ->
      Abb.Future.fork (Terrat_github_runner.run ~request_id config storage)
      >>= fun _ -> Abb.Future.return (Ok ())
  | Error (#Terrat_github.publish_comment_err as err) ->
      Logs.err (fun m ->
          m
            "GITHUB_EVENT : %s : PUBLISH_COMMENT_ERROR : %s"
            request_id
            (Terrat_github.show_publish_comment_err err));
      Abb.Future.return (Ok ())

let process_installation request_id config storage = function
  | Gw.Installation_event.Installation_created created ->
      let open Abbs_future_combinators.Infix_result_monad in
      let installation = created.Gw.Installation_created.installation in
      Logs.info (fun m ->
          m
            "INSTALLATION : CREATE :  %d : %s"
            installation.Gw.Installation.id
            created.Gw.Installation_created.installation.Gw.Installation.account.Gw.User.login);
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_github_installation
            ~f:CCFun.id
            (CCInt64.of_int installation.Gw.Installation.id)
          >>= function
          | [] -> (
              Pgsql_io.Prepared_stmt.fetch
                db
                Sql.insert_org
                ~f:CCFun.id
                installation.Gw.Installation.account.Gw.User.login
              >>= function
              | org_id :: _ ->
                  Pgsql_io.Prepared_stmt.execute
                    db
                    Sql.insert_github_installation
                    (Int64.of_int installation.Gw.Installation.id)
                    installation.Gw.Installation.account.Gw.User.login
                    org_id
                    installation.Gw.Installation.account.Gw.User.type_
              | [] -> assert false)
          | _ :: _ -> Abb.Future.return (Ok ()))
  | Gw.Installation_event.Installation_deleted _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : INSTALLATION_DELETED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Installation_event.Installation_new_permissions_accepted installation_event ->
      let installation = installation_event.Gw.Installation_new_permissions_accepted.installation in
      Logs.info (fun m ->
          m
            "INSTALLATION : ACCEPTED_PERMISSIONS : %d : %s"
            installation.Gw.Installation.id
            installation.Gw.Installation.account.Gw.User.login);
      Abb.Future.return (Ok ())
  | Gw.Installation_event.Installation_suspend _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : INSTALLATION_SUSPENDED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Installation_event.Installation_unsuspend _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : INSTALLATION_UNSUSPENDED" request_id);
      Abb.Future.return (Ok ())

let process_pull_request_event request_id config storage = function
  | Gw.Pull_request_event.Pull_request_opened
      {
        Gw.Pull_request_opened.installation = Some { Gw.Installation_lite.id = installation_id; _ };
        pull_request =
          Gw.Pull_request_opened.Pull_request_.T.
            { primary = Primary.{ number = pull_number; _ }; _ };
        repository;
        sender;
        _;
      }
  | Gw.Pull_request_event.Pull_request_synchronize
      {
        Gw.Pull_request_synchronize.installation =
          Some { Gw.Installation_lite.id = installation_id; _ };
        repository;
        pull_request = Gw.Pull_request.{ number = pull_number; _ };
        sender;
        _;
      }
  | Gw.Pull_request_event.Pull_request_reopened
      {
        Gw.Pull_request_reopened.installation =
          Some { Gw.Installation_lite.id = installation_id; _ };
        repository;
        pull_request =
          Gw.Pull_request_reopened.Pull_request_.T.
            { primary = Primary.{ number = pull_number; _ }; _ };
        sender;
        _;
      } ->
      let open Abbs_future_combinators.Infix_result_monad in
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : %s : PULL_REQUEST_EVENT : owner=%s : repo=%s : sender=%s"
            request_id
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            sender.Gw.User.login);
      Terrat_github.get_installation_access_token config installation_id
      >>= fun access_token ->
      let event =
        Event.make
          ~access_token
          ~config
          ~installation_id
          ~pull_number
          ~repository
          ~request_id
          ~run_type:Terrat_work_manifest.Run_type.Autoplan
          ~tag_query:(Terrat_tag_set.of_list [])
      in
      run_event_evaluator storage event
  | Gw.Pull_request_event.Pull_request_opened _ -> failwith "Invalid pull_request_open event"
  | Gw.Pull_request_event.Pull_request_synchronize _ ->
      failwith "Invalid pull_request_synchronize event"
  | Gw.Pull_request_event.Pull_request_reopened _ -> failwith "Invalid pull_request_reopened event"
  | Gw.Pull_request_event.Pull_request_closed
      {
        Gw.Pull_request_closed.installation = Some { Gw.Installation_lite.id = installation_id; _ };
        pull_request =
          Gw.Pull_request_closed.Pull_request_.T.
            { primary = Primary.{ number = pull_number; _ }; _ };
        repository;
        _;
      } ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.get_installation_access_token config installation_id
      >>= fun access_token ->
      let event =
        Event.make
          ~access_token
          ~config
          ~installation_id
          ~pull_number
          ~repository
          ~request_id
          ~run_type:Terrat_work_manifest.Run_type.Autoapply
          ~tag_query:(Terrat_tag_set.of_list [])
      in
      run_event_evaluator storage event
  | Gw.Pull_request_event.Pull_request_closed _ -> failwith "Invalid pull_request_closed event"
  | Gw.Pull_request_event.Pull_request_assigned _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_ASSIGNED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_auto_merge_disabled _ ->
      Logs.debug (fun m ->
          m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_AUTO_MERGE_DISABLED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_auto_merge_enabled _ ->
      Logs.debug (fun m ->
          m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_AUTO_MERGE_ENABLED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_converted_to_draft _ ->
      Logs.debug (fun m ->
          m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_CONVERTED_TO_DRAFT" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_edited _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_EDITED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_labeled _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_LABELED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_locked _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_LOCKED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_milestoned _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_MILESTONED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_ready_for_review _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_READY_FOR_REVIEW" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_review_request_removed _ ->
      Logs.debug (fun m ->
          m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_REVIEW_REQUEST_REMOVED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_review_requested _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_REVIEW_REQUESTED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_unassigned _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_UNASSIGNED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_unlabeled _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_UNLABELED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Pull_request_event.Pull_request_unlocked _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PULL_REQUEST_UNLOCKED" request_id);
      Abb.Future.return (Ok ())

let process_issue_comment request_id config storage = function
  | Gw.Issue_comment_event.Issue_comment_created
      {
        Gw.Issue_comment_created.installation =
          Some { Gw.Installation_lite.id = installation_id; _ };
        repository;
        comment;
        issue =
          Gw.Issue_comment_created.Issue_.T.
            { primary = Primary.{ number = pull_number; pull_request = Some _; _ }; _ };
        sender;
        _;
      } -> (
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : %s : COMMENT_CREATED_EVENT : owner=%s : repo=%s : sender=%s"
            request_id
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            sender.Gw.User.login);
      match Terrat_comment.parse comment.Gw.Issue_comment.body with
      | Ok Terrat_comment.Unlock ->
          perform_unlock_pr request_id config storage installation_id repository pull_number
      | Ok (Terrat_comment.Plan { tag_query }) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m -> m "GITHUB_EVENT : %s : REACT_TO_COMMENT : %f" request_id t))
            (fun () ->
              Terrat_github.react_to_comment
                ~access_token
                ~owner:repository.Gw.Repository.owner.Gw.User.login
                ~repo:repository.Gw.Repository.name
                ~comment_id:comment.Gw.Issue_comment.id
                ())
          >>= fun () ->
          let event =
            Event.make
              ~access_token
              ~config
              ~installation_id
              ~pull_number
              ~repository
              ~request_id
              ~run_type:Terrat_work_manifest.Run_type.Plan
              ~tag_query
          in
          run_event_evaluator storage event
      | Ok (Terrat_comment.Apply { tag_query }) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m -> m "GITHUB_EVENT : %s : REACT_TO_COMMENT : %f" request_id t))
            (fun () ->
              Terrat_github.react_to_comment
                ~access_token
                ~owner:repository.Gw.Repository.owner.Gw.User.login
                ~repo:repository.Gw.Repository.name
                ~comment_id:comment.Gw.Issue_comment.id
                ())
          >>= fun () ->
          let event =
            Event.make
              ~access_token
              ~config
              ~installation_id
              ~pull_number
              ~repository
              ~request_id
              ~run_type:Terrat_work_manifest.Run_type.Apply
              ~tag_query
          in
          run_event_evaluator storage event
      | Ok (Terrat_comment.Unsafe_apply { tag_query }) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Abbs_time_it.run
            (fun t ->
              Logs.info (fun m -> m "GITHUB_EVENT : %s : REACT_TO_COMMENT : %f" request_id t))
            (fun () ->
              Terrat_github.react_to_comment
                ~access_token
                ~owner:repository.Gw.Repository.owner.Gw.User.login
                ~repo:repository.Gw.Repository.name
                ~comment_id:comment.Gw.Issue_comment.id
                ())
          >>= fun () ->
          let event =
            Event.make
              ~access_token
              ~config
              ~installation_id
              ~pull_number
              ~repository
              ~request_id
              ~run_type:Terrat_work_manifest.Run_type.Unsafe_apply
              ~tag_query
          in
          run_event_evaluator storage event
      | Ok Terrat_comment.Help -> (
          let kv = Snabela.Kv.Map.of_list [] in
          match Snabela.apply Tmpl.terrateam_comment_help kv with
          | Ok body ->
              let open Abbs_future_combinators.Infix_result_monad in
              Terrat_github.get_installation_access_token config installation_id
              >>= fun access_token ->
              Terrat_github.publish_comment
                ~access_token
                ~owner:repository.Gw.Repository.owner.Gw.User.login
                ~repo:repository.Gw.Repository.name
                ~pull_number
                body
          | Error (#Snabela.err as err) ->
              Logs.err (fun m ->
                  m "GITHUB_EVENT : %s : TMPL_ERROR : HELP : %s" request_id (Snabela.show_err err));
              Abb.Future.return (Ok ()))
      | Ok (Terrat_comment.Feedback msg) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Logs.info (fun m ->
              m
                "GITHUB_EVENT : %s : FEEDBACK : owner=%s : repo=%s : pull_number=%d : user=%s : %s"
                request_id
                repository.Gw.Repository.owner.Gw.User.login
                repository.Gw.Repository.name
                pull_number
                comment.Gw.Issue_comment.user.Gw.User.login
                msg);
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Terrat_github.react_to_comment
            ~content:"heart"
            ~access_token
            ~owner:repository.Gw.Repository.owner.Gw.User.login
            ~repo:repository.Gw.Repository.name
            ~comment_id:comment.Gw.Issue_comment.id
            ()
          >>= fun () -> Abb.Future.return (Ok ())
      | Error `Not_terrateam -> Abb.Future.return (Ok ())
      | Error (`Unknown_action action) -> (
          let kv = Snabela.Kv.Map.of_list [] in
          match Snabela.apply Tmpl.terrateam_comment_unknown_action kv with
          | Ok body ->
              let open Abbs_future_combinators.Infix_result_monad in
              Logs.info (fun m ->
                  m "GITHUB_EVENT : %s : COMMENT_ERROR : UNKNOWN_ACTION : %s" request_id action);
              Terrat_github.get_installation_access_token config installation_id
              >>= fun access_token ->
              Terrat_github.publish_comment
                ~access_token
                ~owner:repository.Gw.Repository.owner.Gw.User.login
                ~repo:repository.Gw.Repository.name
                ~pull_number
                body
          | Error (#Snabela.err as err) ->
              Logs.err (fun m ->
                  m
                    "GITHUB_EVENT : %s : TMPL_ERROR : UNKNOWN_ACTION : %s"
                    request_id
                    (Snabela.show_err err));
              Abb.Future.return (Ok ())))
  | Gw.Issue_comment_event.Issue_comment_created _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : ISSUE_COMMENT_CREATED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Issue_comment_event.Issue_comment_deleted _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : ISSUE_COMMENT_DELETED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Issue_comment_event.Issue_comment_edited _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : ISSUE_COMMENT_EDITED" request_id);
      Abb.Future.return (Ok ())
  | Gw.Issue_comment_event.Issue_any _ ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : ISSUE" request_id);
      Abb.Future.return (Ok ())

let process_workflow_job_failure storage access_token run_id repository =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      (* Including the repository here just in case run id's are recycled,
         we will limit ourselves to jobs in the correct repository.  Worst
         case is doing something in another customer's repository *)
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.fail_running_work_manifest
        ~f:(fun id pull_number sha run_type -> (id, pull_number, sha, run_type))
        repository.Gw.Repository.owner.Gw.User.login
        repository.Gw.Repository.name
        run_id
      >>= function
      | [] -> Abb.Future.return (Ok None)
      | ((work_manifest_id, pull_number, sha, run_type) as r) :: _ ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_work_manifest_dirspaces
            ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
            work_manifest_id
          >>= fun dirspaces -> Abb.Future.return (Ok (Some (r, dirspaces))))
  >>= function
  | Some ((work_manifest_id, pull_number, sha, run_type), dirspaces) ->
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : WORKFLOW_JOB_FAIL : %s : %s : %Ld"
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            pull_number);
      (* We successfully failed something *)
      Terrat_github.publish_comment
        ~access_token
        ~owner:repository.Gw.Repository.owner.Gw.User.login
        ~repo:repository.Gw.Repository.name
        ~pull_number:(CCInt64.to_int pull_number)
        Tmpl.action_failed
      >>= fun () ->
      let unified_run_type =
        Terrat_work_manifest.(
          run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
      in
      let target_url =
        Printf.sprintf
          "https://github.com/%s/%s/actions/runs/%s"
          repository.Gw.Repository.owner.Gw.User.login
          repository.Gw.Repository.name
          run_id
      in
      let commit_statuses =
        let module T = Terrat_github.Commit_status.Create.T in
        let aggregate =
          T.make
            ~target_url
            ~description:"Failed"
            ~context:(Printf.sprintf "terrateam %s" unified_run_type)
            ~state:"failure"
            ()
        in
        let dirspaces =
          CCList.map
            (fun Terrat_change.Dirspace.{ dir; workspace } ->
              T.make
                ~target_url
                ~description:"Failed"
                ~context:(Printf.sprintf "terrateam %s %s %s" unified_run_type dir workspace)
                ~state:"failure"
                ())
            dirspaces
        in
        aggregate :: dirspaces
      in
      let open Abb.Future.Infix_monad in
      Abb.Future.fork
        (Abbs_time_it.run
           (fun t ->
             Logs.info (fun m ->
                 m "GITHUB_EVENT : WORKFLOW_JOB_FAIL_COMMIT_STATUS : %s : %f" run_id t))
           (fun () ->
             Terrat_github.Commit_status.create
               ~access_token
               ~owner:repository.Gw.Repository.owner.Gw.User.login
               ~repo:repository.Gw.Repository.name
               ~sha
               commit_statuses))
      >>= fun _ -> Abb.Future.return (Ok ())
  | None ->
      (* Nothing to fail *)
      Logs.warn (fun m ->
          m
            "GITHUB_EVENT : WORKFLOW_JOB_FAIL : NO_MATCHES : %s : %s : %s"
            run_id
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name);
      Abb.Future.return (Ok ())

let process_workflow_job request_id config storage = function
  | Gw.Workflow_job_event.Workflow_job_completed
      Gw.Workflow_job_completed.
        {
          installation = Some Gw.Installation_lite.{ id = installation_id; _ };
          repository;
          workflow_job =
            Workflow_job_.T.{ primary = Primary.{ run_id; conclusion = Some "failure"; _ }; _ };
          _;
        } ->
      (* We only handle failures specially because only on failure is it possible
         that the action did not communicate back the result to the service. *)
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.get_installation_access_token config installation_id
      >>= fun access_token ->
      process_workflow_job_failure storage access_token (CCInt.to_string run_id) repository
  | Gw.Workflow_job_event.Workflow_job_completed _
  | Gw.Workflow_job_event.Workflow_job_in_progress _
  | Gw.Workflow_job_event.Workflow_job_queued _ -> Abb.Future.return (Ok ())

let handle_error ctx = function
  | #Pgsql_pool.err as err ->
      Logs.err (fun m ->
          m "GITHUB_EVENT : %s : ERROR : %s" (Brtl_ctx.token ctx) (Pgsql_pool.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | #Pgsql_io.err as err ->
      Logs.err (fun m ->
          m "GITHUB_EVENT : %s : ERROR : %s" (Brtl_ctx.token ctx) (Pgsql_io.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | #Terrat_github.get_installation_access_token_err as err ->
      Logs.err (fun m ->
          m
            "GITHUB_EVENT : %s : ERROR : %s"
            (Brtl_ctx.token ctx)
            (Terrat_github.show_get_installation_access_token_err err));
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
  | #Terrat_github.publish_comment_err as err ->
      Logs.err (fun m ->
          m
            "GITHUB_EVENT : %s : ERROR : %s"
            (Brtl_ctx.token ctx)
            (Terrat_github.show_publish_comment_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | `Repo_config_err err ->
      Logs.err (fun m -> m "GITHUB_EVENT : %s : ERROR : REPO_CONFIG : %s" (Brtl_ctx.token ctx) err);
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
  | #Abb_process.check_output_err as err ->
      Logs.err (fun m ->
          m
            "GITHUB_EVENT : %s : ERROR : %s"
            (Brtl_ctx.token ctx)
            (Abb_process.show_check_output_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)

let process_event_handler config storage ctx f =
  let open Abb.Future.Infix_monad in
  f ()
  >>= function
  | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
  | Error err -> handle_error ctx err

let post config storage ctx =
  let request = Brtl_ctx.request ctx in
  let headers = Brtl_ctx.Request.headers request in
  let body = Brtl_ctx.body ctx in
  match
    Terrat_github_webhooks_decoder.run
      ?secret:(Terrat_config.github_webhook_secret config)
      headers
      body
  with
  | Ok (Gw.Event.Installation_event installation_event) ->
      process_event_handler config storage ctx (fun () ->
          process_installation (Brtl_ctx.token ctx) config storage installation_event)
  | Ok (Gw.Event.Pull_request_event pull_request_event) ->
      process_event_handler config storage ctx (fun () ->
          process_pull_request_event (Brtl_ctx.token ctx) config storage pull_request_event)
  | Ok (Gw.Event.Issue_comment_event event) ->
      process_event_handler config storage ctx (fun () ->
          process_issue_comment (Brtl_ctx.token ctx) config storage event)
  | Ok (Gw.Event.Workflow_job_event event) ->
      process_event_handler config storage ctx (fun () ->
          process_workflow_job (Brtl_ctx.token ctx) config storage event)
  | Ok (Gw.Event.Push_event _) ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : PUSH_EVENT" (Brtl_ctx.token ctx));
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
  | Ok (Gw.Event.Workflow_run_event _) ->
      Logs.debug (fun m -> m "GITHUB_EVENT : %s : NOOP : WORKFLOW_RUN_EVENT" (Brtl_ctx.token ctx));
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
  | Ok (Gw.Event.Installation_repositories_event _) | Ok (Gw.Event.Workflow_dispatch_event _) ->
      Logs.debug (fun m ->
          m "GITHUB_EVENT : %s : NOOP : INSTALLATION_REPOSITORIES_EVENT" (Brtl_ctx.token ctx));
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
  | Error (#Terrat_github_webhooks_decoder.err as err) ->
      Logs.warn (fun m ->
          m
            "GITHUB_EVENT : %s : UNKNOWN_EVENT : %s"
            (Brtl_ctx.token ctx)
            (Terrat_github_webhooks_decoder.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
