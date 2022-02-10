module Gh = Githubc_v3
module Org_admin = CCMap.Make (CCInt)

module Sql = struct
  let read fname = CCOpt.get_exn_or fname (Terrat_files_github.read fname)

  let select_access_tokens =
    Pgsql_io.Typed_sql.(
      sql
      // (* token *) Ret.varchar
      // (* refresh_token *) Ret.varchar
      // (* expiration *) Ret.varchar
      // (* refresh_expiration *) Ret.varchar
      /^ read "select_access_tokens.sql"
      /% Var.varchar "user_id")

  let update_github_users =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "update_github_users.sql"
      /% Var.varchar "user_id"
      /% Var.varchar "token"
      /% Var.(option (varchar "refresh_token"))
      /% Var.(option (timestamptz "expiration"))
      /% Var.(option (timestamptz "refresh_expiration")))

  let insert_github_user_installation =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_user_installation.sql"
      /% Var.varchar "user_id"
      /% Var.bigint "installation_id"
      /% Var.timestamptz "expiration"
      /% Var.boolean "admin")

  let select_user_installations =
    Pgsql_io.Typed_sql.(
      sql
      // (* login *) Ret.varchar
      // (* installation_id *) Ret.bigint
      // (* admin *) Ret.boolean
      /^ read "select_user_installations.sql"
      /% Var.varchar "user_id")
end

let installation_expiration = 30.0

type get_access_token_err =
  [ Pgsql_pool.err
  | Pgsql_io.err
  | `Refresh_token_err of Gh.call_err
  | `Renew_refresh_token
  ]
[@@deriving show]

type verify_user_installation_access_err =
  [ get_access_token_err
  | Gh.call_err
  | `Forbidden
  ]
[@@deriving show]

type get_user_installations_err =
  [ get_access_token_err
  | Githubc_v3.call_err
  ]
[@@deriving show]

let create schema auth = Gh.create ~user_agent:"Terrateam" schema auth

let get_access_token storage client_id client_secret user_id =
  let open Abb.Future.Infix_monad in
  Abb.Sys.time ()
  >>= fun now ->
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_access_tokens
        ~f:(fun token refresh_token expiration refresh_expiration ->
          (token, refresh_token, expiration, refresh_expiration))
        user_id)
  >>= function
  | Ok ((token, _, expiration, _) :: _) when now < ISO8601.Permissive.datetime expiration ->
      Abb.Future.return (Ok token)
  | Ok ((_, refresh_token, _, refresh_expiration) :: _)
    when now < ISO8601.Permissive.datetime refresh_expiration -> (
      let open Abb.Future.Infix_monad in
      Logs.debug (fun m -> m "ACCESS_TOKEN : REFRESH : %s" user_id);
      Gh.oauth_refresh ~user_agent:"Terrateam" ~client_id ~client_secret ~refresh_token
      >>= function
      | Ok oauth_access_token -> (
          let token = Gh.Response.Oauth_access_token.access_token oauth_access_token in
          let expiration =
            CCOpt.map
              (fun exp -> ISO8601.Permissive.string_of_datetime (now +. CCFloat.of_int exp))
              (Gh.Response.Oauth_access_token.expires_in oauth_access_token)
          in
          let refresh_expiration =
            CCOpt.map
              (fun exp -> ISO8601.Permissive.string_of_datetime (now +. CCFloat.of_int exp))
              (Gh.Response.Oauth_access_token.refresh_token_expires_in oauth_access_token)
          in
          Pgsql_pool.with_conn storage ~f:(fun db ->
              Pgsql_io.Prepared_stmt.execute
                db
                Sql.update_github_users
                user_id
                token
                (Gh.Response.Oauth_access_token.refresh_token oauth_access_token)
                expiration
                refresh_expiration)
          >>= function
          | Ok () -> Abb.Future.return (Ok token)
          | Error ((#Pgsql_pool.err | #Pgsql_io.err) as err) -> Abb.Future.return (Error err))
      | Error (#Gh.call_err as err) -> Abb.Future.return (Error (`Refresh_token_err err)))
  | Ok (_ :: _ | []) -> Abb.Future.return (Error `Renew_refresh_token)
  | Error ((#Pgsql_pool.err | #Pgsql_io.err) as err) -> Abb.Future.return (Error err)

let get_user_installations config storage github_schema user_id =
  let f' =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_user_installations
          ~f:(fun login installation_id admin -> (login, installation_id, admin))
          user_id)
    >>= function
    | [] ->
        get_access_token
          storage
          (Terrat_config.github_app_client_id config)
          (Terrat_config.github_app_client_secret config)
          user_id
        >>= fun token ->
        create github_schema (`Token token)
        >>= fun gh ->
        (* TODO: collect all of the installations.  This currently isn't done
           because Github pagination API is slightly different for this API
           because the data is in an inner object rather than being the entire
           results like in the other APIs so [Githubc_v3.collect_all] doesn't
           "just work" *)
        Gh.call gh (Gh.user_installations ~per_page:100 gh)
        >>= fun installations ->
        let installations = Gh.Response.value installations in
        Gh.collect_all gh (Gh.user_org_membership gh)
        >>= fun org_memberships ->
        (* Filter out any org that is not active.  We do not want people with
           pending memberships to get access. *)
        let org_memberships =
          CCList.filter
            (fun org_membership -> Gh.Response.Org_membership.state org_membership = "active")
            org_memberships
        in
        let org_admin =
          Org_admin.of_list
            (CCList.map
               (fun org_membership ->
                 let admin = Gh.Response.Org_membership.role org_membership = "admin" in
                 let id = Gh.Response.(Org_simple.id (Org_membership.org org_membership)) in
                 (id, admin))
               org_memberships)
        in
        Abbs_future_combinators.to_result (Abb.Sys.time ())
        >>= fun now ->
        let expiration = now +. installation_expiration in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.tx db ~f:(fun () ->
                Abbs_future_combinators.List_result.map
                  ~f:(fun installation ->
                    let name = Gh.Response.(User.login (Installation.account installation)) in
                    let installation_id = Gh.Response.Installation.id installation in
                    let org_id = Gh.Response.(User.id (Installation.account installation)) in
                    let org_type = Gh.Response.(User.type_ (Installation.account installation)) in
                    let is_admin =
                      org_type = "User" || Org_admin.get_or ~default:false org_id org_admin
                    in
                    Pgsql_io.Prepared_stmt.execute
                      db
                      Sql.insert_github_user_installation
                      user_id
                      installation_id
                      (ISO8601.Permissive.string_of_datetime expiration)
                      is_admin
                    >>= fun () ->
                    Abb.Future.return
                      (Ok
                         Terrat_data.Response.Installation.
                           { name; id = CCInt64.to_string installation_id; admin = is_admin }))
                  (Gh.Response.Installations.installations installations)))
    | installations ->
        Abb.Future.return
          (Ok
             (CCList.map
                (fun (name, id, admin) ->
                  Terrat_data.Response.Installation.{ name; id = CCInt64.to_string id; admin })
                installations))
  in
  let open Abb.Future.Infix_monad in
  f'
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error #get_user_installations_err as err -> Abb.Future.return err

let verify_user_installation_access config storage github_schema installation_id user_id =
  let f' =
    let open Abbs_future_combinators.Infix_result_monad in
    get_user_installations config storage github_schema user_id
    >>= fun installations ->
    let installation_id = CCInt64.to_string installation_id in
    if
      CCList.exists
        (fun inst -> CCString.equal installation_id inst.Terrat_data.Response.Installation.id)
        installations
    then Abb.Future.return (Ok ())
    else Abb.Future.return (Error `Forbidden)
  in
  let open Abb.Future.Infix_monad in
  f'
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#verify_user_installation_access_err as err) -> Abb.Future.return (Error err)

let verify_admin_installation_access config storage github_schema installation_id user_id =
  let f' =
    let open Abbs_future_combinators.Infix_result_monad in
    get_user_installations config storage github_schema user_id
    >>= fun installations ->
    let installation_id = CCInt64.to_string installation_id in
    if
      CCList.exists
        (function
          | Terrat_data.Response.Installation.{ id; admin = true; _ } ->
              CCString.equal installation_id id
          | _ -> false)
        installations
    then Abb.Future.return (Ok ())
    else Abb.Future.return (Error `Forbidden)
  in
  let open Abb.Future.Infix_monad in
  f'
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#verify_user_installation_access_err as err) -> Abb.Future.return (Error err)
