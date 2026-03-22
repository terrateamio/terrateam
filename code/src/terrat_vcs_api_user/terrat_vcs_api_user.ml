module type S = sig
  val vcs : string
  val read_sql : string -> string option
end

module Make
    (P : Terrat_vcs_provider2.S with type Api.Account.Id.t = int and type Api.User.Id.t = string)
    (S : S) =
struct
  let src = Logs.Src.create ("vcs_api_user_" ^ S.vcs)

  module Logs = (val Logs.src_log src : Logs.LOG)

  let read fname = CCOption.get_exn_or fname (CCOption.map Pgsql_io.clean_string (S.read_sql fname))

  module Sql = struct
    let insert_api_user () =
      Pgsql_io.Typed_sql.(
        sql
        // Ret.uuid
        /^ read "insert_api_user.sql"
        /% Var.bigint "installation_id"
        /% Var.text "name"
        /% Var.uuid "created_by")

    let select_api_users () =
      Pgsql_io.Typed_sql.(
        sql
        // Ret.uuid
        // Ret.text
        // Ret.text
        /^ read "select_api_users.sql"
        /% Var.bigint "installation_id")

    let delete_api_user () =
      Pgsql_io.Typed_sql.(
        sql /^ read "delete_api_user.sql" /% Var.uuid "api_user_id" /% Var.bigint "installation_id")

    let delete_user_installation () =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "delete_api_user_installation.sql"
        /% Var.uuid "user_id"
        /% Var.bigint "installation_id")

    let delete_access_tokens () =
      Pgsql_io.Typed_sql.(
        sql /^ "delete from access_tokens where user_id = $user_id" /% Var.uuid "user_id")

    let select_installation_login () =
      Pgsql_io.Typed_sql.(
        sql
        // Ret.text
        // Ret.text
        /^ read "select_installation_login.sql"
        /% Var.bigint "installation_id")

    let select_username () =
      Pgsql_io.Typed_sql.(
        sql // Ret.text /^ read "select_username_for_repo_delete.sql" /% Var.uuid "user_id")

    let insert_user_installation () =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "insert_user_installation.sql"
        /% Var.uuid "user_id"
        /% Var.bigint "installation_id")

    let insert_access_token () =
      Pgsql_io.Typed_sql.(
        sql
        // Ret.uuid
        /^ "insert into access_tokens (capabilities, name, user_id) values ($capabilities, $name, \
            $user_id) returning id"
        /% Var.(ud (json "capabilities") [%to_yojson: Terrat_user.Capability.t list])
        /% Var.text "name"
        /% Var.uuid "user_id")
  end

  let lookup_username db user =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_io.Prepared_stmt.fetch db (Sql.select_username ()) ~f:CCFun.id (Terrat_user.id user)
    >>= function
    | username :: _ -> Abb.Future.return (Ok username)
    | [] -> Abb.Future.return (Error `Forbidden)

  let enforce_org_admin ~request_id ~org username client =
    let open Abbs_future_combinators.Infix_result_monad in
    let vcs_user = P.Api.User.make username in
    P.Api.get_org_role ~request_id ~org vcs_user client
    >>= function
    | Some `Admin -> Abb.Future.return (Ok ())
    | Some `User | None -> Abb.Future.return (Error `Forbidden)

  let get_installation_info db installation_id =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_io.Prepared_stmt.fetch
      db
      (Sql.select_installation_login ())
      ~f:(fun login target_type -> (login, target_type))
      (CCInt64.of_int installation_id)
    >>= function
    | (login, target_type) :: _ -> Abb.Future.return (Ok (login, target_type))
    | [] -> Abb.Future.return (Error `Not_found)

  let enforce_admin ~request_id config installation_id user db =
    let open Abbs_future_combinators.Infix_result_monad in
    get_installation_info db installation_id
    >>= fun (org, target_type) ->
    (* Personal accounts (target_type = "User") are always allowed *)
    if CCString.equal target_type "User" then Abb.Future.return (Ok ())
    else
      lookup_username db user
      >>= fun username ->
      let account = P.Api.Account.make installation_id in
      P.Api.create_client ~request_id config account db
      >>= fun client -> enforce_org_admin ~request_id ~org username client

  module List = struct
    let run config storage installation_id _limit =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          let request_id = Brtl_ctx.token ctx in
          Terrat_session.with_session ctx
          >>= fun user ->
          let open Abb.Future.Infix_monad in
          Pgsql_pool.with_conn storage ~f:(fun db ->
              P.enforce_installation_access ~request_id user installation_id db
              >>= function
              | Ok () -> (
                  enforce_admin ~request_id config installation_id user db
                  >>= function
                  | Ok () ->
                      Pgsql_io.Prepared_stmt.fetch
                        db
                        (Sql.select_api_users ())
                        ~f:(fun id name created_at ->
                          let module I = Terrat_api_components.Api_user_item in
                          { I.id = Uuidm.to_string id; name; created_at })
                        (CCInt64.of_int installation_id)
                  | Error `Forbidden -> Abb.Future.return (Error `Forbidden)
                  | Error `Not_found -> Abb.Future.return (Error `Not_found)
                  | Error `Error -> Abb.Future.return (Error `Error)
                  | Error (#Pgsql_io.err as err) -> Abb.Future.return (Error err))
              | Error `Forbidden -> Abb.Future.return (Error `Forbidden))
          >>= function
          | Ok results ->
              let module Pg = Terrat_api_components.Api_user_page in
              let body = { Pg.results } |> Pg.to_yojson |> Yojson.Safe.to_string in
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
          | Error `Forbidden ->
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
          | Error `Not_found ->
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx))
          | Error `Error ->
              Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m -> m "%s : LIST : DB_ERROR : %a" request_id Pgsql_io.pp_err err);
              Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m -> m "%s : LIST : POOL_ERROR : %a" request_id Pgsql_pool.pp_err err);
              Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx)))
  end

  module Create = struct
    let run config storage installation_id body =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          let request_id = Brtl_ctx.token ctx in
          Terrat_session.with_session ctx
          >>= fun user ->
          let open Abb.Future.Infix_monad in
          let module C = Terrat_api_components.Api_user_create in
          let { C.name } = body in
          let inst_id = CCInt64.of_int installation_id in
          Pgsql_pool.with_conn storage ~f:(fun db ->
              P.enforce_installation_access ~request_id user installation_id db
              >>= function
              | Ok () -> (
                  enforce_admin ~request_id config installation_id user db
                  >>= function
                  | Ok () -> (
                      let open Abbs_future_combinators.Infix_result_monad in
                      Pgsql_io.Prepared_stmt.fetch
                        db
                        (Sql.insert_api_user ())
                        ~f:CCFun.id
                        inst_id
                        name
                        (Terrat_user.id user)
                      >>= function
                      | [] -> assert false
                      | api_user_id :: _ -> (
                          Pgsql_io.Prepared_stmt.execute
                            db
                            (Sql.insert_user_installation ())
                            api_user_id
                            inst_id
                          >>= fun () ->
                          let module Cap = Terrat_user.Capability in
                          let capabilities =
                            [
                              Cap.Installation_id (Int64.to_string inst_id);
                              Cap.Vcs S.vcs;
                              Cap.Kv_store_read;
                              Cap.Drift_initiate;
                            ]
                          in
                          Pgsql_io.Prepared_stmt.fetch
                            db
                            (Sql.insert_access_token ())
                            ~f:CCFun.id
                            capabilities
                            name
                            api_user_id
                          >>= function
                          | [] -> assert false
                          | access_token_id :: _ ->
                              let api_user =
                                Terrat_user.make
                                  ~access_token_id
                                  ~capabilities:[ Cap.Access_token_refresh ]
                                  ~id:api_user_id
                                  ()
                              in
                              Terrat_user.Token.to_token db api_user
                              >>= fun refresh_token ->
                              Abb.Future.return (Ok (api_user_id, refresh_token))))
                  | Error `Forbidden -> Abb.Future.return (Error `Forbidden)
                  | Error `Not_found -> Abb.Future.return (Error `Not_found)
                  | Error `Error -> Abb.Future.return (Error `Error)
                  | Error (#Pgsql_io.err as err) -> Abb.Future.return (Error err))
              | Error `Forbidden -> Abb.Future.return (Error `Forbidden))
          >>= function
          | Ok (api_user_id, refresh_token) ->
              let module Au = Terrat_api_components.Api_user in
              let body =
                { Au.id = Uuidm.to_string api_user_id; refresh_token }
                |> Au.to_yojson
                |> Yojson.Safe.to_string
              in
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
          | Error `Forbidden ->
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
          | Error `Not_found ->
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx))
          | Error `Error ->
              Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
          | Error (#Terrat_user.Token.to_token_err as err) ->
              Logs.err (fun m ->
                  m
                    "%s : CREATE : TOKEN_ERROR : %a"
                    request_id
                    Terrat_user.Token.pp_to_token_err
                    err);
              Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m -> m "%s : CREATE : POOL_ERROR : %a" request_id Pgsql_pool.pp_err err);
              Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx)))
  end

  module Delete = struct
    let run config storage installation_id api_user_id =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          let request_id = Brtl_ctx.token ctx in
          Terrat_session.with_session ctx
          >>= fun user ->
          let open Abb.Future.Infix_monad in
          let inst_id = CCInt64.of_int installation_id in
          Pgsql_pool.with_conn storage ~f:(fun db ->
              P.enforce_installation_access ~request_id user installation_id db
              >>= function
              | Ok () -> (
                  enforce_admin ~request_id config installation_id user db
                  >>= function
                  | Ok () ->
                      let open Abbs_future_combinators.Infix_result_monad in
                      Pgsql_io.Prepared_stmt.execute
                        db
                        (Sql.delete_user_installation ())
                        api_user_id
                        inst_id
                      >>= fun () ->
                      Pgsql_io.Prepared_stmt.execute db (Sql.delete_access_tokens ()) api_user_id
                      >>= fun () ->
                      Pgsql_io.Prepared_stmt.execute db (Sql.delete_api_user ()) api_user_id inst_id
                  | Error `Forbidden -> Abb.Future.return (Error `Forbidden)
                  | Error `Not_found -> Abb.Future.return (Error `Not_found)
                  | Error `Error -> Abb.Future.return (Error `Error)
                  | Error (#Pgsql_io.err as err) -> Abb.Future.return (Error err))
              | Error `Forbidden -> Abb.Future.return (Error `Forbidden))
          >>= function
          | Ok () ->
              Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx))
          | Error `Forbidden ->
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
          | Error `Not_found ->
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx))
          | Error `Error ->
              Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m -> m "%s : DELETE : DB_ERROR : %a" request_id Pgsql_io.pp_err err);
              Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m -> m "%s : DELETE : POOL_ERROR : %a" request_id Pgsql_pool.pp_err err);
              Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx)))
  end

  module Rt = struct
    let api () =
      Brtl_rtng.Route.(rel / "api" / "v1" / S.vcs / "installations" /% Path.int / "api-users")

    let delete () = Brtl_rtng.Route.(api () /? Query.ud "id" Uuidm.of_string)
    let list () = Brtl_rtng.Route.(api () /? Query.(option_default 100 (int "limit")))

    let create () =
      Brtl_rtng.Route.(
        api () /* Body.decode ~json:Terrat_api_components.Api_user_create.of_yojson ())
  end

  let routes config storage =
    Brtl_rtng.Route.
      [
        (`GET, Rt.list () --> List.run config storage);
        (`POST, Rt.create () --> Create.run config storage);
        (`DELETE, Rt.delete () --> Delete.run config storage);
      ]
end
