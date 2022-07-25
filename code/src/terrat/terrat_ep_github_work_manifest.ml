module String_map = CCMap.Make (CCString)
module Dirspace_map = CCMap.Make (Terrat_change.Dirspace)

let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

let maybe_credential_error_strings =
  [
    "no valid credential"; "Required token could not be found"; "could not find default credentials";
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

  let base64 = function
    | Some s :: rest -> (
        match Base64.decode (CCString.replace ~sub:"\n" ~by:"" s) with
        | Ok s -> Some (s, rest)
        | _ -> None)
    | _ -> None

  let run_type = function
    | Some s :: rest ->
        let open CCOption in
        Terrat_work_manifest.Run_type.of_string s >>= fun run_type -> Some (run_type, rest)
    | _ -> None

  let tag_query = function
    | Some s :: rest -> Some (Terrat_tag_set.of_string s, rest)
    | _ -> None

  let initiate_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      // (* bash_hash *) Ret.text
      // (* completed_at *) Ret.(option text)
      // (* created_at *) Ret.text
      // (* hash *) Ret.text
      // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
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
      // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
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

  let abort_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_work_manifests set state = 'aborted', completed_at = now() where id = $id \
          and state in ('queued', 'running')"
      /% Var.uuid "id")

  let select_work_manifest_dirspaces =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      // (* workflow_idx *) Ret.(option integer)
      /^ "select path, workspace, workflow_idx from github_work_manifest_dirspaceflows where \
          work_manifest = $id"
      /% Var.uuid "id")

  let upsert_terraform_plan =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "upsert_terraform_plan.sql"
      /% Var.uuid "work_manifest"
      /% Var.text "path"
      /% Var.text "workspace"
      /% Var.(ud (text "data") Base64.encode_string))

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
      /^ "update github_work_manifests set state = 'completed', completed_at = now() where id = $id"
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

  let select_recent_plan =
    Pgsql_io.Typed_sql.(
      sql
      // (* data *) Ret.ud base64
      /^ read "select_github_recent_plan.sql"
      /% Var.uuid "id"
      /% Var.text "dir"
      /% Var.text "workspace")

  let select_github_parameters_from_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      // (* installation_id *) Ret.bigint
      // (* owner *) Ret.text
      // (* name *) Ret.text
      // (* branch *) Ret.text
      // (* sha *) Ret.text
      // (* pull_number *) Ret.bigint
      // (* run_type *) Ret.ud run_type
      // (* run_id *) Ret.(option text)
      /^ read "select_github_parameters_from_work_manifest.sql"
      /% Var.uuid "id")

  let select_missing_dirspace_applies_for_pull_request =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_missing_dirspace_applies_for_pull_request.sql"
      /% Var.text "owner"
      /% Var.text "name"
      /% Var.bigint "pull_number")
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
  end

  let read fname =
    fname
    |> Terrat_files_tmpl.read
    |> CCOption.get_exn_or fname
    |> Snabela.Template.of_utf8_string
    |> CCResult.get_exn
    |> fun tmpl -> Snabela.of_template tmpl Transformers.[ money; plan_diff ]

  let plan_complete = read "github_plan_complete.tmpl"
  let apply_complete = read "github_apply_complete.tmpl"

  let work_manifest_already_run =
    "github_work_manifest_already_run.tmpl"
    |> Terrat_files_tmpl.read
    |> CCOption.get_exn_or "github_work_manifest_already_run.tmpl"
end

let publish_comment token owner repo pull_number body =
  let client = Terrat_github.create (`Token token) in
  Githubc2_abb.call
    client
    Githubc2_issues.Create_comment.(
      make
        ~body:Request_body.(make Primary.{ body })
        Parameters.(make ~issue_number:pull_number ~owner ~repo))

module T = struct
  type t = {
    config : Terrat_config.t;
    access_token : string;
    owner : string;
    name : string;
    pull_number : int;
    hash : string;
    request_id : string;
    run_id : string;
    work_manifest : Uuidm.t;
  }
end

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

module Evaluator = Terrat_work_manifest_evaluator.Make (struct
  type t = T.t

  module Pull_request = Pull_request

  let request_id t = t.T.request_id

  let maybe_update_commit_status t installation_id owner repo_name run_type dirspaces hash =
    function
    | Terrat_work_manifest.State.Running ->
        let unified_run_type =
          Terrat_work_manifest.(
            run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
        in
        Abbs_future_combinators.ignore
          (Abb.Future.fork
             (let open Abbs_future_combinators.Infix_result_monad in
             Terrat_github.get_installation_access_token t.T.config (CCInt64.to_int installation_id)
             >>= fun access_token ->
             let target_url =
               Printf.sprintf "https://github.com/%s/%s/actions/runs/%s" owner repo_name t.T.run_id
             in
             let commit_statuses =
               let module T = Terrat_github.Commit_status.Create.T in
               let aggregate =
                 T.make
                   ~target_url
                   ~description:"Running"
                   ~context:(Printf.sprintf "terrateam %s" unified_run_type)
                   ~state:"pending"
                   ()
               in
               let dirspaces =
                 CCList.map
                   (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; workspace }; _ } ->
                     T.make
                       ~target_url
                       ~description:"Running"
                       ~context:(Printf.sprintf "terrateam %s %s %s" unified_run_type dir workspace)
                       ~state:"pending"
                       ())
                   dirspaces
               in
               aggregate :: dirspaces
             in
             Terrat_github.Commit_status.create
               ~access_token
               ~owner
               ~repo:repo_name
               ~sha:hash
               commit_statuses))
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
      t.T.work_manifest
      t.T.run_id
      t.T.hash
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
          t.T.work_manifest
          t.T.run_id
          t.T.hash
        >>= function
        | wm :: _ -> Abb.Future.return (Ok (Some wm))
        | [] -> Abb.Future.return (Ok None))

  let initiate_work_manifest db t =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Logs.info (fun m ->
          m
            "GITHUB_WORK_MANIFEST : %s : INITIATE : %s : %s : %s"
            t.T.request_id
            (Uuidm.to_string t.T.work_manifest)
            t.T.run_id
            t.T.hash);
      initiate_work_manifest' db t
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
            Terrat_work_manifest.
              {
                base_hash;
                changes = ();
                completed_at;
                created_at;
                hash;
                id = t.T.work_manifest;
                pull_request = Pull_request.{ repo_id; pull_number; base_branch };
                run_id = Some t.T.run_id;
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
            t.T.work_manifest
          >>= fun dirspaces ->
          let open Abb.Future.Infix_monad in
          maybe_update_commit_status t installation_id owner repo_name run_type dirspaces hash state
          >>= fun () ->
          Abb.Future.return
            (Ok (Some Terrat_work_manifest.{ partial_work_manifest with changes = dirspaces }))
      | None ->
          Logs.info (fun m ->
              m
                "GITHUB_WORK_MANIFEST : %s : ABORT_WORK_MANIFEST : %s"
                t.T.request_id
                (Uuidm.to_string t.T.work_manifest));
          Pgsql_io.Prepared_stmt.execute db Sql.abort_work_manifest t.T.work_manifest
          >>= fun () -> Abb.Future.return (Ok None)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_WORK_MANIFEST : %s : ERROR : %s" t.T.request_id (Pgsql_io.show_err err));
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
        Logs.err (fun m ->
            m "GITHUB_WORK_MANIFEST : %s : ERROR : %s" t.T.request_id (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let query_dirspaces_owned_by_other_pull_requests db t pull_request dirspaces =
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
            } ))
      pull_request.Pull_request.repo_id
      pull_request.Pull_request.pull_number
      (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
      (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
    >>= function
    | Ok res -> Abb.Future.return (Ok (Terrat_event_evaluator.Dirspace_map.of_list res))
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_WORK_MANIFEST : %s : ERROR : %s" t.T.request_id (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)
end)

module Initiate = struct
  module Work_manifest_initiate = Terrat_api_components.Work_manifest_initiate

  let comment_work_manifest_already_run t =
    let open Abbs_future_combinators.Infix_result_monad in
    Logs.err (fun m ->
        m
          "GITHUB_WORK_MANIFEST : %s : WORK_MANIFEST_ALREADY_RUNNING : work_manifest=%s : owner=%s \
           : name=%s : pull_number=%d"
          t.T.request_id
          (Uuidm.to_string t.T.work_manifest)
          t.T.owner
          t.T.name
          t.T.pull_number);
    publish_comment
      t.T.access_token
      t.T.owner
      t.T.name
      t.T.pull_number
      Tmpl.work_manifest_already_run
    >>= fun _ -> Abb.Future.return (Ok ())

  let handle_post request_id config storage t =
    let open Abbs_future_combinators.Infix_result_monad in
    Evaluator.run storage t
    >>= function
    | Some work_manifest -> (
        let module Wm = Terrat_work_manifest in
        let changed_dirspaces =
          CCList.map
            (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; workspace }; workflow_idx } ->
              (* TODO: Provide correct rank *)
              Terrat_api_components.Work_manifest_dir.
                { path = dir; workspace; workflow = workflow_idx; rank = 0 })
            work_manifest.Wm.changes
        in
        match work_manifest.Wm.run_type with
        | Wm.Run_type.Plan | Wm.Run_type.Autoplan ->
            let open Abbs_future_combinators.Infix_result_monad in
            Terrat_github.fetch_repo_config
              ~python:(Terrat_config.python_exec config)
              ~access_token:t.T.access_token
              ~owner:t.T.owner
              ~repo:t.T.name
              t.T.hash
            >>= fun repo_config ->
            Terrat_github.get_tree
              ~access_token:t.T.access_token
              ~owner:t.T.owner
              ~repo:t.T.name
              ~sha:t.T.hash
              ()
            >>= fun files ->
            let dirspaces =
              CCList.map
                (fun Terrat_change_matcher.
                       {
                         dirspaceflow =
                           Terrat_change.
                             { Dirspaceflow.dirspace = { Dirspace.dir; workspace }; workflow_idx };
                         _;
                       } ->
                  Terrat_api_components.Work_manifest_dir.
                    { path = dir; workspace; workflow = workflow_idx; rank = 0 })
                (Terrat_change_matcher.match_diff
                   repo_config
                   (CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) files))
            in
            let ret =
              Terrat_api_components.(
                Work_manifest.Work_manifest_plan
                  Work_manifest_plan.
                    {
                      type_ = "plan";
                      base_ref = work_manifest.Wm.pull_request.Pull_request.base_branch;
                      changed_dirspaces;
                      dirspaces;
                    })
            in
            Abb.Future.return (Ok ret)
        | Wm.Run_type.Apply | Wm.Run_type.Autoapply ->
            let ret =
              Terrat_api_components.(
                Work_manifest.Work_manifest_apply
                  Work_manifest_apply.
                    {
                      type_ = "apply";
                      base_ref = work_manifest.Wm.pull_request.Pull_request.base_branch;
                      changed_dirspaces;
                    })
            in
            Abb.Future.return (Ok ret))
    | None -> Abb.Future.return (Error `Work_manifest_not_found)

  let pre_handle_post request_id config storage work_manifest_id run_id sha =
    let open Abb.Future.Infix_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.select_github_parameters_from_work_manifest ())
          ~f:(fun installation_id owner name branch _sha pull_number _run_type _run_id ->
            (installation_id, owner, name, branch, pull_number))
          work_manifest_id)
    >>= function
    | Ok ((installation_id, owner, name, branch, pull_number) :: _) ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_github.get_installation_access_token config (CCInt64.to_int installation_id)
        >>= fun access_token ->
        Abb.Future.return
          (Ok
             T.
               {
                 config;
                 access_token;
                 owner;
                 name;
                 pull_number = CCInt64.to_int pull_number;
                 hash = sha;
                 request_id;
                 run_id;
                 work_manifest = work_manifest_id;
               })
    | Ok [] -> Abb.Future.return (Error `Work_manifest_not_found)
    | Error (#Pgsql_pool.err as err) -> Abb.Future.return (Error err)
    | Error (#Pgsql_io.err as err) -> Abb.Future.return (Error err)

  let post config storage work_manifest_id { Work_manifest_initiate.run_id; sha } ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    pre_handle_post request_id config storage work_manifest_id run_id sha
    >>= function
    | Ok t -> (
        handle_post request_id config storage t
        >>= function
        | Ok response ->
            let body =
              response
              |> Terrat_api_work_manifest.Initiate.Responses.OK.to_yojson
              |> Yojson.Safe.to_string
            in
            Abb.Future.return
              (Brtl_ctx.set_response
                 (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
                 ctx)
        | Error (`Work_manifest_already_run Terrat_work_manifest.{ id; pull_request; _ }) -> (
            comment_work_manifest_already_run t
            >>= function
            | Ok () ->
                Abb.Future.return
                  (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
            | Error (#Githubc2_abb.call_err as err) ->
                Logs.err (fun m ->
                    m
                      "GITHUB_WORK_MANIFEST : %s : ERROR : %s"
                      request_id
                      (Githubc2_abb.show_call_err err));
                Abb.Future.return
                  (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Terrat_github.fetch_repo_config_err as err) ->
            Logs.err (fun m ->
                m
                  "GITHUB_WORK_MANIFEST : %s : ERROR : %s"
                  request_id
                  (Terrat_github.show_fetch_repo_config_err err));
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (#Terrat_github.get_tree_err as err) ->
            Logs.err (fun m ->
                m
                  "GITHUB_WORK_MANIFEST : %s : ERROR : %s"
                  request_id
                  (Terrat_github.show_get_tree_err err));
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (#Terrat_work_manifest_evaluator.err as err) ->
            Logs.err (fun m ->
                m "GITHUB_WORK_MANIFEST : %s : ERROR : %s" request_id (Evaluator.show_err err));
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
    | Error (#Pgsql_pool.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_WORK_MANIFEST : %s : ERROR : %s" request_id (Pgsql_pool.show_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_WORK_MANIFEST : %s : ERROR : %s" request_id (Pgsql_io.show_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_WORK_MANIFEST : %s : ERROR : %s"
              request_id
              (Terrat_github.show_get_installation_access_token_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | Error `Work_manifest_not_found ->
        Logs.err (fun m ->
            m
              "GITHUB_WORK_MANIFEST : %s : WORK_MANIFEST_NOT_FOUND : %s"
              request_id
              (Uuidm.to_string work_manifest_id));
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
end

module Plans = struct
  module Pc = Terrat_api_components.Plan_create

  let post config storage work_manifest_id { Pc.path; workspace; plan_data } ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    let id = Uuidm.to_string work_manifest_id in
    Logs.info (fun m -> m "WORK_MANIFEST : %s : PLAN : %s : %s : %s" request_id id path workspace);
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.execute
          db
          Sql.upsert_terraform_plan
          work_manifest_id
          path
          workspace
          (* Decode it and it will get re-encoded before putting it into (before
             applying the prepared statement, we don't want to worry about
             properly escaping the string).  This is decoded here just to ensure
             that we only accept valid base64 encoded data. *)
          (Base64.decode_exn plan_data))
    >>= function
    | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
    | Error (#Pgsql_pool.err as err) ->
        Logs.err (fun m ->
            m "WORK_MANIFEST : %s : PLAN : %s : ERROR : %s" request_id id (Pgsql_pool.show_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "WORK_MANIFEST : %s : PLAN : %s : ERROR : %s" request_id id (Pgsql_io.show_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)

  let delete_plan request_id db work_manifest dir workspace =
    let open Abb.Future.Infix_monad in
    Terrat_github_plan_cleanup.clean ~work_manifest ~dir ~workspace db
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "WORK_MANIFEST : %s : DELETE_PLAN : ERROR : %s" request_id (Pgsql_io.show_err err));
        Abb.Future.return (Ok ())

  let get config storage work_manifest_id path workspace ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    let id = Uuidm.to_string work_manifest_id in
    Logs.info (fun m ->
        m "WORK_MANIFEST : %s : PLAN_GET : %s : %s : %s" request_id id path workspace);
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
    | Ok [] ->
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
    | Ok (data :: _) ->
        let response =
          Terrat_api_work_manifest.Plan_get.Responses.OK.(
            { data = Base64.encode_exn data } |> to_yojson)
          |> Yojson.Safe.to_string
        in
        Abb.Future.return
          (Brtl_ctx.set_response
             (Brtl_rspnc.create ~headers:response_headers ~status:`OK response)
             ctx)
    | Error (#Pgsql_pool.err as err) ->
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : PLAN_GET : %s : ERROR : %s"
              request_id
              id
              (Pgsql_pool.show_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : PLAN_GET : %s : ERROR : %s"
              request_id
              id
              (Pgsql_io.show_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
end

module Results = struct
  let complete_check access_token owner repo branch run_id run_type sha results =
    let module Wmr = Terrat_api_components.Work_manifest_result in
    let module R = Terrat_api_work_manifest.Results.Request_body in
    let unified_run_type =
      Terrat_work_manifest.(run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
    in
    let success = results.R.overall.R.Overall.success in
    let description = if success then "Completed" else "Failed" in
    let state = if success then "success" else "failure" in
    let target_url = Printf.sprintf "https://github.com/%s/%s/actions/runs/%s" owner repo run_id in
    let commit_statuses =
      let module T = Terrat_github.Commit_status.Create.T in
      let aggregate =
        T.make
          ~target_url
          ~description
          ~context:(Printf.sprintf "terrateam %s" unified_run_type)
          ~state
          ()
      in
      let dirspaces =
        CCList.map
          (fun Wmr.{ path; workspace; success; _ } ->
            let state = if success then "success" else "failure" in
            let description = if success then "Completed" else "Failed" in
            T.make
              ~target_url
              ~description
              ~context:(Printf.sprintf "terrateam %s %s %s" unified_run_type path workspace)
              ~state
              ())
          results.R.dirspaces
      in
      aggregate :: dirspaces
    in
    Terrat_github.Commit_status.create ~access_token ~owner ~repo ~sha commit_statuses

  let create_run_output run_type results =
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
      |> CCList.exists (fun Wmr.{ output; _ } ->
             let other_outputs =
               output.Wmr.Output.additional
               |> Json_schema.String_map.to_seq
               |> CCSeq.map (fun (_, v) -> v)
             in
             let strings =
               CCSeq.(
                 append
                   (of_list
                      (CCOption.get_or ~default:[] Wmr.Output.(output.primary.Primary.errors)))
                   other_outputs)
             in
             CCSeq.exists
               (fun s ->
                 CCList.exists
                   (fun sub -> CCString.find ~sub s <> -1)
                   maybe_credential_error_strings)
               strings)
    in
    let cost_estimation =
      dirspaces
      |> CCList.map (fun Wmr.{ path; workspace; output; _ } ->
             CCOption.map
               (fun infracost -> (path, workspace, infracost))
               Wmr.Output.(output.primary.Primary.cost_estimation))
      |> CCOption.sequence_l
      |> CCOption.map (fun costs ->
             let module Ce = Terrat_api_components_cost_estimation in
             let diff_monthly_cost =
               CCListLabels.fold_left
                 ~init:0.0
                 ~f:(fun acc_diff_monthly_cost (_, _, Ce.{ diff_monthly_cost; _ }) ->
                   acc_diff_monthly_cost +. diff_monthly_cost)
                 costs
             in
             let total_cost_estimation =
               let open CCOption.Infix in
               results.R.overall.R.Overall.output
               >>= fun output ->
               R.Overall.Output.(output.primary.Primary.cost_estimation)
               >>= fun cost_estimation ->
               Terrat_api_components.Total_cost_estimation.(
                 Some (cost_estimation.total_monthly_cost, cost_estimation.currency))
             in
             Snabela.Kv.(
               Map.of_list
                 (CCList.flatten
                    [
                      CCOption.map_or
                        ~default:
                          [
                            ("prev_monthly_cost", string "???");
                            ("total_monthly_cost", string "???");
                            ("diff_monthly_cost", string "???");
                            ("currency", string "???");
                          ]
                        (fun (total_monthly_cost, currency) ->
                          [
                            ("prev_monthly_cost", float (total_monthly_cost -. diff_monthly_cost));
                            ("total_monthly_cost", float total_monthly_cost);
                            ("diff_monthly_cost", float diff_monthly_cost);
                            ("currency", string currency);
                          ])
                        total_cost_estimation;
                      [
                        ( "dirspaces",
                          list
                            (CCList.map
                               (fun ( path,
                                      workspace,
                                      Ce.
                                        {
                                          prev_monthly_cost;
                                          total_monthly_cost;
                                          diff_monthly_cost;
                                          currency;
                                        } ) ->
                                 Map.of_list
                                   [
                                     ("dir", string path);
                                     ("workspace", string workspace);
                                     ("prev_monthly_cost", float prev_monthly_cost);
                                     ("total_monthly_cost", float total_monthly_cost);
                                     ("diff_monthly_cost", float diff_monthly_cost);
                                     ("currency", string currency);
                                   ])
                               costs) );
                      ];
                    ])))
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
                 ( "output",
                   list
                     [
                       Map.of_list
                         (CCList.flatten
                            [
                              CCOption.map_or
                                ~default:[]
                                (fun errors ->
                                  [
                                    ( "errors",
                                      list
                                        (CCList.map
                                           (fun line -> Map.of_list [ ("line", string line) ])
                                           errors) );
                                  ])
                                (let open CCOption.Infix in
                                results.R.overall.R.Overall.output
                                >>= fun output -> R.Overall.Output.(output.primary.Primary.errors));
                            ]);
                     ] );
                 ( "results",
                   list
                     (CCList.map
                        (fun Wmr.{ path; workspace; success; output } ->
                          Map.of_list
                            [
                              ("dir", string path);
                              ("workspace", string workspace);
                              ("success", bool success);
                              ( "output",
                                list
                                  [
                                    Map.of_list
                                      (CCList.flatten
                                         [
                                           (match Wmr.Output.(output.primary.Primary.errors) with
                                           | Some errors ->
                                               [
                                                 ( "errors",
                                                   list
                                                     (CCList.map
                                                        (fun line ->
                                                          Map.of_list [ ("line", string line) ])
                                                        errors) );
                                               ]
                                           | None -> []);
                                           CCList.map
                                             (fun (k, v) -> (k, string v))
                                             (Json_schema.String_map.to_list
                                                output.Wmr.Output.additional);
                                         ]);
                                  ] );
                            ])
                        dirspaces) );
               ];
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
        Logs.err (fun m -> m "WORK_MANIFEST : ERROR : %s" (Snabela.show_err err));
        assert false

  let publish_results
      request_id
      config
      installation_id
      owner
      repo
      branch
      pull_number
      run_type
      results
      run_id
      sha =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      let output = create_run_output run_type results in
      Terrat_github.get_installation_access_token config installation_id
      >>= fun token ->
      publish_comment token owner repo pull_number output
      >>= fun _ -> complete_check token owner repo branch run_id run_type sha results
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok () -> Abb.Future.return ()
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : ERROR : %s"
              request_id
              (Terrat_github.show_get_installation_access_token_err err));
        Abb.Future.return ()

  let automerge_config = function
    | Terrat_repo_config.(Version_1.{ automerge = Some _ as automerge; _ }) -> automerge
    | _ -> None

  let merge_pull_request request_id access_token owner repo pull_number =
    let open Abbs_future_combinators.Infix_result_monad in
    let client = Terrat_github.create (`Token access_token) in
    Logs.info (fun m ->
        m
          "WORK_MANIFEST : %s : MERGE_PULL_REQUEST : %s : %s : %Ld"
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
              "WORK_MANIFEST : %s : MERGE_METHOD_NOT_ALLOWED : %s : %s : %Ld"
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
          "WORK_MANIFEST : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %Ld"
          request_id
          owner
          repo
          pull_number);
    Terrat_github.fetch_pull_request ~access_token ~owner ~repo (CCInt64.to_int pull_number)
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK
        Githubc2_components.Pull_request.
          { primary = Primary.{ head = Head.{ primary = Primary.{ ref_ = branch; _ }; _ }; _ }; _ }
      -> (
        Logs.info (fun m ->
            m
              "WORK_MANIFEST : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %Ld : %s"
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
                  "WORK_MANIFEST : %s : DELETE_PULL_REQUEST_BRANCH : ERROR : %s : %s : %Ld : %s"
                  request_id
                  owner
                  repo
                  pull_number
                  (Githubc2_git.Delete_ref.Responses.Unprocessable_entity.show err));
            Abb.Future.return (Ok ()))
    | `Not_found _ | `Internal_server_error _ | `Not_modified -> failwith "nyi"

  let perform_automerge request_id config storage installation_id owner repo sha pull_number =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Logs.info (fun m ->
          m
            "WORK_MANIFEST : %s : AUTOMERGE : SELECT_MISSING_DIRSPACE_APPLIES : %s : %s : %Ld : %s"
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
                "WORK_MANIFEST : %s : ALL_DIRSPACES_APPLIED : %s : %s : %Ld : %s"
                request_id
                owner
                repo
                pull_number
                sha);
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
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
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
              request_id
              owner
              repo
              pull_number
              sha
              (Pgsql_pool.show_err err));
        Abb.Future.return ()
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
              request_id
              owner
              repo
              pull_number
              sha
              (Pgsql_io.show_err err));
        Abb.Future.return ()
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
              request_id
              owner
              repo
              pull_number
              sha
              (Terrat_github.show_get_installation_access_token_err err));
        Abb.Future.return ()
    | Error (#Terrat_github.fetch_repo_config_err as err) ->
        Logs.err (fun m ->
            m
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
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
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
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
              "WORK_MANIFEST : %s : AUTOMERGE : ERROR : %s : %s : %Ld : %s : %s"
              request_id
              owner
              repo
              pull_number
              sha
              (Githubc2_pulls.Merge.Responses.Method_not_allowed.show err));
        Abb.Future.return ()

  let put config storage work_manifest_id results ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    let id = Uuidm.to_string work_manifest_id in
    Logs.info (fun m ->
        m
          "WORK_MANIFEST : %s : RESULT : %s : %s"
          request_id
          id
          (if Terrat_api_work_manifest.Results.Request_body.(results.overall.Overall.success) then
           "SUCCESS"
          else "FAILURE"));
    Pgsql_pool.with_conn storage ~f:(fun db ->
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_io.tx db ~f:(fun () ->
            Abbs_future_combinators.List_result.iter
              ~f:(fun result ->
                let module Wmr = Terrat_api_components.Work_manifest_result in
                Logs.info (fun m ->
                    m
                      "WORK_MANIFEST : %s : RESULT_STORE : %s : %s : %s : %s"
                      request_id
                      id
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
              results.Terrat_api_work_manifest.Results.Request_body.dirspaces
            >>= fun () ->
            Pgsql_io.Prepared_stmt.execute db Sql.complete_work_manifest work_manifest_id
            >>= fun () ->
            Pgsql_io.Prepared_stmt.fetch
              db
              (Sql.select_github_parameters_from_work_manifest ())
              ~f:(fun installation_id owner name branch sha pull_number run_type run_id ->
                (installation_id, owner, name, branch, sha, pull_number, run_type, run_id))
              work_manifest_id
            >>= function
            | values :: _ -> Abb.Future.return (Ok values)
            | [] -> assert false))
    >>= function
    | Ok (installation_id, owner, repo, branch, sha, pull_number, run_type, run_id) ->
        Abb.Future.Infix_app.(
          (fun () () -> ())
          <$> publish_results
                request_id
                config
                (CCInt64.to_int installation_id)
                owner
                repo
                branch
                (CCInt64.to_int pull_number)
                run_type
                results
                (CCOption.get_exn_or "run_id is None" run_id)
                sha
          <*>
          match Terrat_work_manifest.Unified_run_type.of_run_type run_type with
          | Terrat_work_manifest.Unified_run_type.Apply ->
              perform_automerge
                request_id
                config
                storage
                (CCInt64.to_int installation_id)
                owner
                repo
                sha
                pull_number
          | Terrat_work_manifest.Unified_run_type.Plan -> Abb.Future.return ())
        >>= fun () ->
        Abb.Future.fork (Terrat_github_runner.run ~request_id config storage)
        >>= fun _ ->
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
    | Error (#Pgsql_pool.err as err) ->
        Logs.err (fun m -> m "WORK_MANIFEST : PLAN : %s : ERROR : %s" id (Pgsql_pool.show_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m -> m "WORK_MANIFEST : PLAN : %s : ERROR : %s" id (Pgsql_io.show_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
    | Error (#Githubc2_abb.call_err as err) ->
        Logs.err (fun m -> m "WORK_MANIFEST : ERROR : %s" (Githubc2_abb.show_call_err err));
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
end
