exception Session_store_failed

module Sql = struct
  let load () =
    Pgsql_io.Typed_sql.(
      sql
      // (* avatar_url *) Ret.(option text)
      // (* email *) Ret.(option text)
      // (* id *) Ret.uuid
      // (* name *) Ret.(option text)
      /^ "select users.avatar_url, users.email, users.id, users.name  from user_sessions as us \
          inner join users on users.id = us.user_id where us.token = $token"
      /% Var.uuid "token")

  let store () =
    Pgsql_io.Typed_sql.(
      sql
      // (* token *) Ret.uuid
      /^ "insert into user_sessions (user_id, user_agent) values ($user_id, $user_agent) returning \
          token"
      /% Var.uuid "user_id"
      /% Var.text "user_agent")

  let delete =
    Pgsql_io.Typed_sql.(sql /^ "delete from user_sessions where token = $token" /% Var.uuid "token")
end

let key : Terrat_api_components.User.t Brtl_mw_session.Value.t Hmap.key =
  Brtl_mw_session.create_key ()

let cookie_name = "session"

let load storage id =
  match Uuidm.of_string id with
  | Some uuid -> (
      let load =
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.fetch
              db
              (Sql.load ())
              ~f:(fun avatar_url email id name ->
                Terrat_api_components.User.{ avatar_url; email; id = Uuidm.to_string id; name })
              uuid
            >>= function
            | [] -> Abb.Future.return (Ok None)
            | user :: _ -> Abb.Future.return (Ok (Some user)))
      in
      let open Abb.Future.Infix_monad in
      load
      >>= function
      | Ok r -> Abb.Future.return r
      | Error `Pgsql_pool_error ->
          Logs.err (fun m -> m "SESSION : ERROR : Pool error");
          Abb.Future.return None
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "SESSION : ERROR : Database");
          Logs.err (fun m -> m "%s" (Pgsql_io.show_err err));
          Abb.Future.return None)
  | None -> Abb.Future.return None

let store storage id_opt user ctx =
  match id_opt with
  | Some id ->
      (* If there already is an id, do nothing *)
      Abb.Future.return id
  | None -> (
      let open Abb.Future.Infix_monad in
      let user_agent =
        ctx
        |> Brtl_ctx.request
        |> Brtl_ctx.Request.headers
        |> CCFun.flip Cohttp.Header.get "user-agent"
        |> CCOption.get_or ~default:"Unknown"
      in
      let user_id = Terrat_api_components.User.(user.id) in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            (Sql.store ())
            ~f:CCFun.id
            (CCOption.get_exn_or "terrat_session_store" (Uuidm.of_string user_id))
            user_agent)
      >>= function
      | Ok [] -> assert false
      | Ok (token :: _) -> Abb.Future.return (Uuidm.to_string token)
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "Failure storing session %s" (Pgsql_io.show_err err));
          raise Session_store_failed
      | Error `Pgsql_pool_error ->
          Logs.err (fun m -> m "Failed to acquire a pool connection");
          raise Session_store_failed)

let create storage =
  let config =
    Brtl_mw_session.Config.
      {
        key;
        cookie_name;
        load = load storage;
        store = store storage;
        expiration = `Session;
        domain = None;
        path = Some "/";
      }
  in
  Brtl_mw_session.create config

let get_session ctx = Brtl_mw_session.get_session_value key ctx

(* let get_session_exn ctx = CCOption.get_exn_or "get_session" (get_session ctx) *)

let set_session t ctx = Brtl_mw_session.set_session_value key t ctx

let rem_session storage ctx =
  let f =
    match Brtl_mw_session.get_cookie_value cookie_name ctx with
    | Some token ->
        let open Abbs_future_combinators.Infix_result_monad in
        let token = CCOption.get_exn_or ("token: " ^ token) (Uuidm.of_string token) in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.execute db Sql.delete token)
        >>= fun () -> Abb.Future.return (Ok (Brtl_mw_session.rem_session_value key ctx))
    | None -> Abb.Future.return (Ok ctx)
  in
  let open Abb.Future.Infix_monad in
  f
  >>= function
  | Ok ctx -> Abb.Future.return (Ok ctx)
  | Error (#Pgsql_pool.err | #Pgsql_io.err) as err -> Abb.Future.return err

let create_user_session user ctx = set_session user ctx

let with_session ctx =
  match get_session ctx with
  | Some session -> Abb.Future.return (Ok session)
  | None -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))
