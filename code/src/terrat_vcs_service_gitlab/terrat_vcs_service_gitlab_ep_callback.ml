let src = Logs.Src.create "vcs_service_gitlab_ep_callback"

module Logs = (val Logs.src_log src : Logs.LOG)

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map Pgsql_io.clean_string (Terrat_files_gitlab_sql.read fname))

  let insert_user2 () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      /^ read "insert_user2.sql")

  let select_gitlab_user () =
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
      /^ read "select_gitlab_user2.sql"
      /% Var.text "username")

  let insert_gitlab_user () =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_gitlab_user2.sql"
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

module Oauth = struct
  module Http = Abb_curl.Make (Abb)

  type authorize_err =
    [ `Authorize_err of string
    | Http.request_err
    ]
  [@@deriving show]

  type refresh_err =
    [ `Refresh_err of string
    | `Bad_refresh_token
    | Http.request_err
    ]
  [@@deriving show]

  module Response = struct
    type t = {
      access_token : string;
      scope : string;
      token_type : string;
      refresh_token : string option; [@default None]
      refresh_token_expires_in : int option; [@default None]
      expires_in : int option; [@default None]
    }
    [@@deriving of_yojson { strict = false }, show]
  end

  module Response_err = struct
    type t = {
      error : string;
      error_description : string;
    }
    [@@deriving of_yojson { strict = false }, show]
  end

  let authorize ~config server_api_base code =
    let open Abb.Future.Infix_monad in
    let headers =
      Http.Headers.of_list
        [
          ("user-agent", "Terrateam");
          ("content-type", "application/json");
          ("accept", "application/json");
        ]
    in
    let uri =
      Uri.of_string
        (Printf.sprintf "%s/oauth/token" (Uri.to_string (Terrat_config.Gitlab.web_base_url config)))
    in
    let body =
      Yojson.Safe.to_string
        (`Assoc
           [
             ("client_id", `String (Terrat_config.Gitlab.app_id config));
             ("client_secret", `String (Terrat_config.Gitlab.app_secret config));
             ("code", `String code);
             ("grant_type", `String "authorization_code");
             ("redirect_uri", `String (Printf.sprintf "%s/v1/gitlab/callback" server_api_base));
           ])
    in
    Http.post ~headers ~body uri
    >>| function
    | Ok (resp, body) when Http.Status.is_success (Http.Response.status resp) -> (
        match Response.of_yojson (Yojson.Safe.from_string body) with
        | Ok value -> Ok value
        | Error _ -> Error (`Authorize_err body))
    | Ok (resp, body) -> Error (`Authorize_err body)
    | Error err -> Error err

  let refresh ~config refresh_token =
    let open Abb.Future.Infix_monad in
    let headers =
      Http.Headers.of_list
        [
          ("user-agent", "Terrateam");
          ("accept", "application/json");
          ("content-type", "application/json");
        ]
    in
    let uri =
      Uri.of_string
        (Printf.sprintf "%s/oauth/token" (Uri.to_string (Terrat_config.Gitlab.web_base_url config)))
    in
    let body =
      Yojson.Safe.to_string
        (`Assoc
           [
             ("client_id", `String (Terrat_config.Gitlab.app_id config));
             ("client_secret", `String (Terrat_config.Gitlab.app_secret config));
             ("grant_type", `String "refresh_token");
             ("refresh_token", `String refresh_token);
           ])
    in
    Http.post ~headers ~body uri
    >>| function
    | Ok (resp, body) when Http.Status.is_success (Http.Response.status resp) -> (
        match Response.of_yojson (Yojson.Safe.from_string body) with
        | Ok value -> Ok value
        | Error _ -> (
            match Response_err.of_yojson (Yojson.Safe.from_string body) with
            | Ok { Response_err.error = "bad_refresh_token"; _ } -> Error `Bad_refresh_token
            | _ -> Error (`Refresh_err body)))
    | Ok (resp, body) -> Error (`Refresh_err body)
    | Error err -> Error err
end

let perform_auth config storage code =
  let open Abbs_future_combinators.Infix_result_monad in
  let c = Terrat_vcs_service_gitlab_provider.Api.Config.config config in
  let vcs_config = Terrat_vcs_service_gitlab_provider.Api.Config.vcs_config config in
  Oauth.authorize ~config:vcs_config (Terrat_config.api_base c) code
  >>= fun oauth ->
  let access_token = oauth.Oauth.Response.access_token in
  let client =
    Openapic_abb.create
      ~user_agent:"Terrateam"
      ~base_url:(Terrat_config.Gitlab.api_base_url vcs_config)
      (`Bearer access_token)
  in
  Openapic_abb.call client (Gitlabc_user.GetApiV3User.make ())
  >>= fun resp ->
  let module U = Gitlabc_components_api_entities_userpublic in
  let (`OK { U.avatar_url; email; name; username; _ }) = Openapi.Response.value resp in
  Abbs_future_combinators.to_result (Abb.Sys.time ())
  >>= fun now ->
  let expiration =
    CCOption.map
      (fun exp -> ISO8601.Permissive.string_of_datetime (now +. CCFloat.of_int exp))
      oauth.Oauth.Response.expires_in
  in
  let refresh_expiration =
    CCOption.map
      (fun exp -> ISO8601.Permissive.string_of_datetime (now +. CCFloat.of_int exp))
      oauth.Oauth.Response.refresh_token_expires_in
  in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.tx db ~f:(fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            (Sql.select_gitlab_user ())
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
                    (Sql.insert_gitlab_user ())
                    avatar_url
                    email
                    expiration
                    name
                    refresh_expiration
                    oauth.Oauth.Response.refresh_token
                    oauth.Oauth.Response.access_token
                    user_id
                    username
                  >>= fun () -> Abb.Future.return (Ok (Terrat_user.make ~id:user_id ())))
          | (user_id, _email, _name, _avatar_url) :: _ ->
              Pgsql_io.Prepared_stmt.execute
                db
                (Sql.insert_gitlab_user ())
                avatar_url
                email
                expiration
                name
                refresh_expiration
                oauth.Oauth.Response.refresh_token
                oauth.Oauth.Response.access_token
                user_id
                username
              >>= fun () -> Abb.Future.return (Ok (Terrat_user.make ~id:user_id ()))))

let get config storage code state ctx =
  let open Abb.Future.Infix_monad in
  perform_auth config storage code
  >>= function
  | Ok user ->
      let ctx = Terrat_session.create_user_session user ctx in
      let uri = ctx |> Brtl_ctx.uri_base |> CCFun.flip Uri.with_path "/" |> Uri.to_string in
      let headers = Cohttp.Header.of_list [ ("location", uri) ] in
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~headers ~status:`See_other "") ctx)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "FAIL : %a" Openapic_abb.pp_call_err err);
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Oauth.authorize_err as err) ->
      Logs.err (fun m -> m "FAIL : %a" Oauth.pp_authorize_err err);
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "FAIL : %a" Pgsql_pool.pp_err err);
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "FAIL : %a" Pgsql_io.pp_err err);
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
