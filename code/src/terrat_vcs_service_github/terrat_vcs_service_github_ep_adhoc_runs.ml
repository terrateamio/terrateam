let src = Logs.Src.create "vcs_service_github_ep_adhoc_runs"

module Logs = (val Logs.src_log src : Logs.LOG)

module type S = sig
  val enforce_installation_access :
    request_id:string ->
    Terrat_user.t ->
    int ->
    Pgsql_io.t ->
    (unit, [> `Forbidden ]) result Abb.Future.t
end

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map Pgsql_io.clean_string (Terrat_files_github_sql.read fname))

  let select_username () =
    Pgsql_io.Typed_sql.(
      sql // Ret.text /^ read "select_username_for_repo_delete.sql" /% Var.uuid "user_id")

  let select_repo_by_name () =
    Pgsql_io.Typed_sql.(
      sql
      // Ret.bigint
      // Ret.text
      // Ret.text
      /^ read "select_repo_by_name.sql"
      /% Var.bigint "installation_id"
      /% Var.text "name")

  let select_latest_adhoc_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      // Ret.uuid
      /^ read "select_latest_adhoc_work_manifest.sql"
      /% Var.bigint "repository_id"
      /% Var.text "run_type")
end

module Make (P : Terrat_vcs_provider2_github.S) (S : S) = struct
  module Evaluator2 = Terrat_vcs_event_evaluator2.Make (P)

  let parse_operation = function
    | "plan" -> Some `Plan
    | "apply" -> Some `Apply
    | _ -> None

  let parse_request_body body =
    try
      let json = Yojson.Safe.from_string body in
      let open Yojson.Safe.Util in
      let repo_name = json |> member "repo_name" |> to_string in
      let branch = json |> member "branch" |> to_string_option in
      let operation = json |> member "operation" |> to_string in
      let tag_query = json |> member "tag_query" |> to_string_option in
      Some (repo_name, branch, operation, tag_query)
    with _ -> None

  let lookup_username db user =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_io.Prepared_stmt.fetch db (Sql.select_username ()) ~f:CCFun.id (Terrat_user.id user)
    >>= function
    | username :: _ -> Abb.Future.return (Ok username)
    | [] -> Abb.Future.return (Error `Forbidden)

  let lookup_latest_adhoc_work_manifest db repository_id run_type =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_io.Prepared_stmt.fetch
      db
      (Sql.select_latest_adhoc_work_manifest ())
      ~f:CCFun.id
      (Int64.of_int repository_id)
      run_type
    >>= function
    | wm_id :: _ -> Abb.Future.return (Ok (Some wm_id))
    | [] -> Abb.Future.return (Ok None)

  let lookup_repo db installation_id repo_name =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_io.Prepared_stmt.fetch
      db
      (Sql.select_repo_by_name ())
      ~f:(fun id owner name -> P.Api.Repo.make ~id:(Int64.to_int id) ~owner ~name ())
      (Int64.of_int installation_id)
      repo_name
    >>= function
    | repo :: _ -> Abb.Future.return (Ok repo)
    | [] -> Abb.Future.return (Error `Repo_not_found_err)

  let post config storage exec installation_id =
    Brtl_ep.run_result_json ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        let request_id = Brtl_ctx.token ctx in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        let body = Brtl_ctx.body ctx in
        match parse_request_body body with
        | None ->
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "{}") ctx))
        | Some (repo_name, branch_opt, operation_str, tag_query_str) -> (
            match parse_operation operation_str with
            | None ->
                Abb.Future.return
                  (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "{}") ctx))
            | Some operation -> (
                let tag_query =
                  match tag_query_str with
                  | None -> Ok Terrat_tag_query.any
                  | Some s -> Terrat_tag_query.of_string s
                in
                match tag_query with
                | Error _ ->
                    Abb.Future.return
                      (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "{}") ctx))
                | Ok tag_query -> (
                    let branch = P.Api.Ref.of_string (CCOption.get_or ~default:"main" branch_opt) in
                    let account = P.Api.Account.make installation_id in
                    Pgsql_pool.with_conn storage ~f:(fun db ->
                        S.enforce_installation_access ~request_id user installation_id db
                        >>= function
                        | Error `Forbidden -> Abb.Future.return (Error `Forbidden)
                        | Ok () -> (
                            lookup_username db user
                            >>= function
                            | Error `Forbidden -> Abb.Future.return (Error `Forbidden)
                            | Error (#Pgsql_io.err as err) -> Abb.Future.return (Error err)
                            | Ok username -> (
                                lookup_repo db installation_id repo_name
                                >>= function
                                | Error `Repo_not_found_err ->
                                    Abb.Future.return (Error `Repo_not_found_err)
                                | Error (#Pgsql_io.err as err) -> Abb.Future.return (Error err)
                                | Ok repo -> (
                                    let vcs_user = P.Api.User.make username in
                                    let repo_id = P.Api.Repo.id repo in
                                    let run_type =
                                      match operation with
                                      | `Plan -> "plan"
                                      | `Apply -> "apply"
                                    in
                                    Evaluator2.adhoc_run
                                      ~request_id
                                      ~config
                                      ~storage
                                      ~exec
                                      ~account
                                      ~user:vcs_user
                                      ~repo
                                      ~branch
                                      ~operation
                                      ~tag_query
                                      ()
                                    >>= fun () ->
                                    lookup_latest_adhoc_work_manifest db repo_id run_type
                                    >>= function
                                    | Ok (Some wm_id) -> Abb.Future.return (Ok (Some wm_id))
                                    | Ok None -> Abb.Future.return (Ok None)
                                    | Error _ -> Abb.Future.return (Ok None)))))
                    >>= function
                    | Ok (Some wm_id) ->
                        let body =
                          Printf.sprintf {|{"work_manifest_id":"%s"}|} (Uuidm.to_string wm_id)
                        in
                        Abb.Future.return
                          (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Accepted body) ctx))
                    | Ok None ->
                        Abb.Future.return
                          (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Accepted "{}") ctx))
                    | Error `Forbidden ->
                        Abb.Future.return
                          (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
                    | Error `Repo_not_found_err ->
                        Abb.Future.return
                          (Ok
                             (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "{}") ctx))
                    | Error (#Pgsql_pool.err as err) ->
                        Logs.err (fun m -> m "%s : ADHOC_RUN : %a" request_id Pgsql_pool.pp_err err);
                        Abb.Future.return
                          (Ok
                             (Brtl_ctx.set_response
                                (Brtl_rspnc.create ~status:`Internal_server_error "")
                                ctx))
                    | Error (#Pgsql_io.err as err) ->
                        Logs.err (fun m -> m "%s : ADHOC_RUN : %a" request_id Pgsql_io.pp_err err);
                        Abb.Future.return
                          (Ok
                             (Brtl_ctx.set_response
                                (Brtl_rspnc.create ~status:`Internal_server_error "")
                                ctx))))))
end
