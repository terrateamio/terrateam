module Int64_map = CCMap.Make (CCInt64)

module Sql = struct
  let read fname =
    CCOpt.get_exn_or
      fname
      (CCOpt.map
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
      // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
      /^ read "select_github_action_parameters.sql"
      /% Var.uuid "work_manifest")

  let abort_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_work_manifests set state = 'aborted', completed_at = now() where id = $id \
          and state in ('queued', 'running')"
      /% Var.uuid "id")

  let select_work_manifest_dirspaces =
    Pgsql_io.Typed_sql.(
      sql
      // (* dir *) Ret.text
      // (* workspace *) Ret.text
      /^ "select path, workspace from github_work_manifest_dirspaceflows where work_manifest = $id"
      /% Var.uuid "id")
end

module Tmpl = struct
  let read fname = CCOpt.get_exn_or fname (Terrat_files_tmpl.read fname)
  let failed_to_start_workflow = read "github_failed_to_start_workflow.tmpl"
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

let start_check access_token owner repo sha run_type dirspaces =
  let unified_run_type =
    Terrat_work_manifest.(run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
  in
  let target_url = Printf.sprintf "https://github.com/%s/%s/actions" owner repo in
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
        (fun Terrat_change.Dirspace.{ dir; workspace } ->
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
  Terrat_github.Commit_status.create ~access_token ~owner ~repo ~sha commit_statuses

let abort_work_manifest
    ~access_token
    ~db
    ~owner
    ~repo
    ~sha
    ~pull_number
    ~run_type
    ~dirspaces
    work_manifest_id =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_io.Prepared_stmt.execute db Sql.abort_work_manifest work_manifest_id
  >>= fun () ->
  Terrat_github.publish_comment
    ~access_token
    ~owner
    ~repo
    ~pull_number:(CCInt64.to_int pull_number)
    Tmpl.failed_to_start_workflow
  >>= fun () ->
  let unified_run_type =
    Terrat_work_manifest.(run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
  in
  let target_url = Printf.sprintf "https://github.com/%s/%s/actions" owner repo in
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
  Terrat_github.Commit_status.create ~access_token ~owner ~repo ~sha commit_statuses

let rec run' request_id access_token_cache config db =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_io.tx db ~f:(fun () ->
      Pgsql_io.Prepared_stmt.fetch db ~f:CCFun.id Sql.select_next_work_manifest
      >>= function
      | [] -> Abb.Future.return (Ok `Done)
      | [ id ] -> (
          Logs.info (fun m -> m "GITHUB_RUNNER : %s : RUNNING : %s" request_id (Uuidm.to_string id));
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
                  let open Abb.Future.Infix_monad in
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
                                                  ("work-token", Uuidm.to_string id);
                                                  ( "api-base-url",
                                                    Terrat_config.api_base config ^ "/github" );
                                                ];
                                          };
                                  };
                              additional = Json_schema.String_map.empty;
                            }
                        Parameters.(make ~owner ~repo ~workflow_id:(Workflow_id.V0 workflow_id)))
                  >>= function
                  | Ok _ ->
                      let open Abbs_future_combinators.Infix_result_monad in
                      start_check access_token owner repo sha run_type dirspaces
                      >>= fun () ->
                      (* TODO: Handle failing because workflow is not present in branch *)
                      Abb.Future.return (Ok (`Cont access_token_cache))
                  | Error _ ->
                      Logs.err (fun m ->
                          m
                            "GITHUB_RUNNER : %s : ERROR : COULD_NOT_RUN_WORKFLOW : %s : %s : %s"
                            request_id
                            owner
                            repo
                            branch);
                      abort_work_manifest
                        ~access_token
                        ~db
                        ~owner
                        ~repo
                        ~sha
                        ~pull_number
                        ~run_type
                        ~dirspaces
                        id
                      >>= fun _ -> Abb.Future.return (Ok (`Cont access_token_cache)))
              | _ ->
                  Logs.err (fun m -> m "GITHUB_RUNNER : %s : ERROR : MISSING_WORKFLOW" request_id);
                  Abb.Future.return (Ok (`Cont access_token_cache))))
      | _ :: _ ->
          (* Should only ever be one result *)
          assert false)
  >>= function
  | `Done -> Abb.Future.return (Ok ())
  | `Cont access_token_cache -> run' request_id access_token_cache config db

let run ~request_id config storage =
  let open Abb.Future.Infix_monad in
  Pgsql_pool.with_conn storage ~f:(fun db -> run' request_id Int64_map.empty config db)
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#err as err) ->
      Logs.err (fun m -> m "GITHUB_RUNNER : ERROR : %s" (show_err err));
      Abb.Future.return (Error err)
