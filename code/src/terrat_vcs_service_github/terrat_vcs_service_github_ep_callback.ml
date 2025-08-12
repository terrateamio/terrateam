let src = Logs.Src.create "vcs_service_github_ep_callback"

module Logs = (val Logs.src_log src : Logs.LOG)

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map Pgsql_io.clean_string (Terrat_files_github_sql.read fname))

  let insert_user2 () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      /^ read "insert_user2.sql")

  let select_github_user2 () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* user_id *)
      Ret.uuid
      //
      (* email *)
      Ret.(option text)
      //
      (* name *)
      Ret.(option text)
      //
      (* avatar_url *)
      Ret.text
      /^ read "select_github_user2.sql"
      /% Var.text "username")

  let insert_github_user2 () =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_user2.sql"
      /% Var.(option (text "avatar_url"))
      /% Var.(option (text "email"))
      /% Var.(option (timestamptz "expiration"))
      /% Var.(option (text "name"))
      /% Var.(option (timestamptz "refresh_expiration"))
      /% Var.(option (text "refresh_token"))
      /% Var.text "token"
      /% Var.uuid "user_id"
      /% Var.text "username")
end

let perform_auth config storage code =
  let module Oauth = Terrat_github.Oauth.Response in
  let open Abbs_future_combinators.Infix_result_monad in
  Terrat_github.Oauth.authorize
    ~config:(Terrat_vcs_service_github_provider.Api.Config.vcs_config config)
    code
  >>= fun oauth ->
  let access_token = oauth.Oauth.access_token in
  Terrat_github.user
    ~config:(Terrat_vcs_service_github_provider.Api.Config.vcs_config config)
    ~access_token
    ()
  >>= fun current_user ->
  Abbs_future_combinators.to_result (Abb.Sys.time ())
  >>= fun now ->
  let username, avatar_url, name, email =
    let module Gar = Githubc2_users.Get_authenticated.Responses.OK in
    let module Pr = Githubc2_components.Private_user in
    let module Pu = Githubc2_components.Public_user in
    match current_user with
    | Gar.Private_user Pr.{ primary = Primary.{ avatar_url; name; email; login; _ }; _ }
    | Gar.Public_user Pu.{ avatar_url; name; email; login; _ } -> (login, avatar_url, name, email)
  in
  let expiration =
    CCOption.map
      (fun exp -> ISO8601.Permissive.string_of_datetime (now +. CCFloat.of_int exp))
      oauth.Oauth.expires_in
  in
  let refresh_expiration =
    CCOption.map
      (fun exp -> ISO8601.Permissive.string_of_datetime (now +. CCFloat.of_int exp))
      oauth.Oauth.refresh_token_expires_in
  in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.tx db ~f:(fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            (Sql.select_github_user2 ())
            ~f:(fun user_id email name avatar_url -> (user_id, email, name, avatar_url))
            username
          >>= function
          | [] -> (
              Pgsql_io.Prepared_stmt.fetch db (Sql.insert_user2 ()) ~f:CCFun.id
              >>= function
              | [] -> assert false
              | user_id :: _ ->
                  Pgsql_io.Prepared_stmt.execute
                    db
                    (Sql.insert_github_user2 ())
                    (Some avatar_url)
                    email
                    expiration
                    name
                    refresh_expiration
                    oauth.Oauth.refresh_token
                    oauth.Oauth.access_token
                    user_id
                    username
                  >>= fun () -> Abb.Future.return (Ok (Terrat_user.make ~id:user_id ())))
          | (user_id, _email, _name, _avatar_url) :: _ ->
              Pgsql_io.Prepared_stmt.execute
                db
                (Sql.insert_github_user2 ())
                (Some avatar_url)
                email
                expiration
                name
                refresh_expiration
                oauth.Oauth.refresh_token
                oauth.Oauth.access_token
                user_id
                username
              >>= fun () -> Abb.Future.return (Ok (Terrat_user.make ~id:user_id ()))))

let get config storage code installation_id_opt ctx =
  let open Abb.Future.Infix_monad in
  perform_auth config storage code
  >>= function
  | Ok user ->
      let ctx = Terrat_session.create_user_session user ctx in
      let uri =
        ctx
        |> Brtl_ctx.uri_base
        |> CCFun.flip Uri.with_path "/"
        |> CCFun.flip
             Uri.with_query
             (CCOption.map_or
                ~default:[]
                (fun installation_id ->
                  [ ("installation_id", [ Int64.to_string installation_id ]) ])
                installation_id_opt)
        |> Uri.to_string
      in
      let headers = Cohttp.Header.of_list [ ("location", uri) ] in
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~headers ~status:`See_other "") ctx)
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "FAIL : %s" (Pgsql_pool.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "FAIL : %s" (Pgsql_io.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Terrat_github.user_err as err) ->
      Logs.err (fun m -> m "FAIL : %s" (Terrat_github.show_user_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Terrat_github.Oauth.authorize_err as err) ->
      Logs.err (fun m -> m "FAIL : %a" Terrat_github.Oauth.pp_authorize_err err);
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
