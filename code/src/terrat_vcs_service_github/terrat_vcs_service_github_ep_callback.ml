let src = Logs.Src.create "vcs_service_github_ep_callback"

module Logs = (val Logs.src_log src : Logs.LOG)

module Http = Abb_curl.Make (Abb)

module Webhook = struct
  type config = {
    enabled : bool;
    endpoint : string;
    secret : string;
  }

  let config_from_env () =
    let enabled =
      match Sys.getenv_opt "TERRATEAM_WEBHOOKS_ENABLED" with
      | Some "true" -> true
      | Some "1" -> true
      | _ -> false
    in
    let endpoint =
      CCOption.get_or ~default:"" (Sys.getenv_opt "TERRATEAM_WEBHOOKS_ENDPOINT")
    in
    let secret =
      CCOption.get_or ~default:"" (Sys.getenv_opt "TERRATEAM_WEBHOOKS_SECRET")
    in
    { enabled; endpoint; secret }

  let send_signup_event username email name avatar_url =
    let cfg = config_from_env () in
    if not cfg.enabled || cfg.endpoint = "" then
      Abb.Future.return (Ok ())
    else
      let timestamp = 
        let open Unix in
        let t = gettimeofday () in
        let tm = gmtime t in
        Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ"
          (tm.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday
          tm.tm_hour tm.tm_min tm.tm_sec
      in
      let body = 
        `Assoc [
          ("event_type", `String "github_user_signup");
          ("username", `String username);
          ("email", `String (CCOption.get_or ~default:"" email));
          ("name", `String (CCOption.get_or ~default:"" name));
          ("avatar_url", `String (CCOption.get_or ~default:"" avatar_url));
          ("timestamp", `String timestamp);
        ]
        |> Yojson.Safe.to_string
      in
      let headers = 
        [
          ("Content-Type", "application/json");
          ("User-Agent", "Terrateam/1.0");
          ("Authorization", Printf.sprintf "Bearer %s" cfg.secret);
        ]
      in
      (* Append the specific path for signup webhooks *)
      let endpoint_url = Printf.sprintf "%s/github-signup" cfg.endpoint in
      let uri = Uri.of_string endpoint_url in
      let open Abb.Future.Infix_monad in
      Http.post ~headers ~body uri
      >>= function
      | Ok (resp, _body) when Http.Status.is_success (Http.Response.status resp) ->
          Logs.info (fun m -> m "Signup webhook sent successfully for user %s" username);
          Abb.Future.return (Ok ())
      | Ok (resp, _body) ->
          let status_code = Http.Status.to_code (Http.Response.status resp) in
          Logs.warn (fun m -> 
            m "Failed to send signup webhook for user %s: HTTP %d" username status_code);
          Abb.Future.return (Ok ())  (* Don't fail the main operation *)
      | Error err ->
          Logs.warn (fun m -> 
            m "Failed to send signup webhook for user %s: %s" username (Http.Error.show err));
          Abb.Future.return (Ok ())  (* Don't fail the main operation *)
end

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

  let insert_github_user_email () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_user_emails (username, email, is_primary) values($username, $email, \
          $is_primary) on conflict (username, email) do update set is_primary = EXCLUDED.is_primary"
      /% Var.text "username"
      /% Var.text "email"
      /% Var.bool "is_primary")

  let select_user_installations_by_username () =
    Pgsql_io.Typed_sql.(
      sql
      // Ret.text
      /^ "select gi.id from github_installations gi \
          inner join github_user_installations2 gui on gui.installation_id = gi.id \
          inner join github_users2 gu on gu.user_id = gui.user_id \
          where gu.username = $username and gi.state = 'installed'"
      /% Var.text "username")
end

let perform_auth request_id config storage code =
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
  let c =
    Terrat_github.create
      (Terrat_vcs_service_github_provider.Api.Config.vcs_config config)
      (`Bearer access_token)
  in
  Githubc2_abb.call
    c
    Githubc2_users.List_emails_for_authenticated_user.(make (Parameters.make ~per_page:100 ()))
  >>= fun user_emails ->
  let emails =
    match Openapi.Response.value user_emails with
    | `OK emails ->
        CCList.map
          (fun Githubc2_components.Email.{ primary = Primary.{ email; primary; _ }; _ } -> 
            (email, primary))
          emails
    | _ -> []
  in
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
  Logs.info (fun m -> m "%s : CALLBACK : username=%s" request_id username);
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
                  >>= fun () ->
                  Abbs_future_combinators.List_result.iter
                    ~f:(fun (email, is_primary) ->
                      Pgsql_io.Prepared_stmt.execute
                        db
                        (Sql.insert_github_user_email ())
                        username
                        email
                        is_primary)
                    emails
                  >>= fun () ->
                  (* Check if user has any installations *)
                  Pgsql_io.Prepared_stmt.fetch
                    db
                    (Sql.select_user_installations_by_username ())
                    ~f:CCFun.id
                    username
                  >>= fun installations ->
                  (match installations with
                  | [] ->
                      (* No installations - this is a new signup, send webhook *)
                      Logs.info (fun m -> m "New user signup detected: %s (no installations)" username);
                      Webhook.send_signup_event username email name avatar_url
                  | _ ->
                      (* User has installations, no webhook needed *)
                      Abb.Future.return (Ok ()))
                  >>= fun _ -> Abb.Future.return (Ok (Terrat_user.make ~id:user_id ())))
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
              >>= fun () ->
              Abbs_future_combinators.List_result.iter
                ~f:(fun (email, is_primary) ->
                  Pgsql_io.Prepared_stmt.execute db (Sql.insert_github_user_email ()) username email is_primary)
                emails
              >>= fun () ->
              (* Check if user has any installations *)
              Pgsql_io.Prepared_stmt.fetch
                db
                (Sql.select_user_installations_by_username ())
                ~f:CCFun.id
                username
              >>= fun installations ->
              (match installations with
              | [] ->
                  (* No installations - this is a new signup, send webhook *)
                  Logs.info (fun m -> m "New user signup detected: %s (no installations)" username);
                  Webhook.send_signup_event username email name avatar_url
              | _ ->
                  (* User has installations, no webhook needed *)
                  Abb.Future.return (Ok ()))
              >>= fun _ -> Abb.Future.return (Ok (Terrat_user.make ~id:user_id ()))))

let get config storage code installation_id_opt =
  let open Abb.Future.Infix_monad in
  Brtl_ep.run ~content_type:"text/plain" ~f:(fun ctx ->
      perform_auth (Brtl_ctx.token ctx) config storage code
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
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
