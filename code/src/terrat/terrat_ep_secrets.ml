module Gh = Githubc_v3
module Encrypter = Mirage_crypto_pk.Rsa.OAEP (Mirage_crypto.Hash.SHA256)

module Sql = struct
  let read fname = CCOpt.get_exn_or fname (Terrat_files_github.read fname)

  let select_installation_pub_key =
    Pgsql_io.Typed_sql.(
      sql // (* pub key *) Ret.varchar /^ read "select_installation_pub_key.sql" /% Var.bigint "id")

  let insert_installation_secret =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_installation_secret.sql"
      /% Var.bigint "installation_id"
      /% Var.varchar "name"
      /% Var.varchar "value"
      /% Var.boolean "is_file"
      /% Var.varchar "modified_by")

  let delete_secret =
    Pgsql_io.Typed_sql.(
      sql
      /^ "delete from installation_env_vars where installation_id = $installation_id and name = \
          $name and secret"
      /% Var.bigint "installation_id"
      /% Var.varchar "name")

  let select_installation_secrets =
    Pgsql_io.Typed_sql.(
      sql
      // (* name *) Ret.varchar
      // (* is_file *) Ret.boolean
      // (* modified_by *) Ret.varchar
      // (* modified_time *) Ret.varchar
      /^ read "select_installation_secrets_pagination.sql"
      /% Var.varchar "user_id"
      /% Var.bigint "installation_id"
      /% Var.option (Var.varchar "prev_name"))
end

module Pagination = Brtl_pagination.Make (struct
  type elt = Terrat_data.Response.Secret.t

  type t = elt Pgsql_pagination.t

  let compare x y =
    CCString.compare x.Terrat_data.Response.Secret.name y.Terrat_data.Response.Secret.name

  let to_paginate v = [ v.Terrat_data.Response.Secret.name ]

  let has_another_page = Pgsql_pagination.has_next_page

  let items = Pgsql_pagination.results
end)

let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

let validate_name name =
  if
    CCString.length name > 0
    && (match name.[0] with
         | '0' .. '9' -> false
         | _          -> true)
    && CCString.for_all
         (function
           | 'A' .. 'Z' | 'a' .. 'z' | '_' | '0' .. '9' -> true
           | _ -> false)
         name
  then
    Ok ()
  else
    Error `Invalid_secret_name

let encrypt_and_store storage installation_id user_id secret =
  let module S = Terrat_data.Request.Secret in
  let open Abbs_future_combinators.Infix_result_monad in
  Abb.Future.return (validate_name secret.S.name)
  >>= fun () ->
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.tx db ~f:(fun () ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_installation_pub_key
            ~f:CCFun.id
            installation_id
          >>= function
          | pub_key_pem :: _ -> (
              match X509.Public_key.decode_pem (Cstruct.of_string pub_key_pem) with
                | Ok (`RSA pub_key) ->
                    let value_encrypted =
                      Base64.encode_string
                        (Cstruct.to_string
                           (Encrypter.encrypt ~key:pub_key (Cstruct.of_string secret.S.value)))
                    in
                    Pgsql_io.Prepared_stmt.execute
                      db
                      Sql.insert_installation_secret
                      installation_id
                      secret.S.name
                      value_encrypted
                      secret.S.is_file
                      user_id
                | _                 -> assert false)
          | _                -> Abb.Future.return (Error `Missing_installation_error)))

let perform_get storage installation_id user_id limit prev_name pagination =
  let search =
    Pgsql_pagination.Search.(
      create ~page_size:limit ~dir:`Asc [ Col.create ~vname:"prev_name" ~cname:"name" ])
  in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      pagination
        search
        db
        Sql.select_installation_secrets
        ~f:(fun name is_file modified_by modified_time ->
          Terrat_data.Response.Secret.{ name; is_file; modified_by; modified_time })
        user_id
        installation_id
        prev_name)

let dispatch_get storage installation_id user_id limit = function
  | (`Next, prev_name) ->
      perform_get storage installation_id user_id limit prev_name Pgsql_pagination.next
  | (`Prev, prev_name) ->
      perform_get storage installation_id user_id limit prev_name Pgsql_pagination.prev

let get config storage github_schema installation_id limit page =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user_id ->
      let open Abb.Future.Infix_monad in
      Terrat_github.verify_user_installation_access
        config
        storage
        github_schema
        installation_id
        user_id
      >>= function
      | Ok () -> (
          let limit = CCInt.min 100 limit in
          let page =
            match page with
              | Some ("n", name) -> (`Next, Some name)
              | Some ("p", name) -> (`Prev, Some name)
              | Some _ | None    -> (`Next, None)
          in
          dispatch_get storage installation_id user_id limit page
          >>= function
          | Ok secrets                     ->
              let uri = Brtl_ctx.uri ctx in
              let pagination = CCOpt.get_exn_or "pagination" (Pagination.make secrets uri) in
              let next = CCOpt.map Uri.to_string (Pagination.to_next pagination) in
              let prev = CCOpt.map Uri.to_string (Pagination.to_prev pagination) in
              let body =
                Terrat_data.Response.Secret_list.
                  { results = Pagination.items pagination; next; prev }
                |> Terrat_data.Response.Secret_list.to_yojson
                |> Yojson.Safe.to_string
              in
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response
                      (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
                      ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m -> m "SECRETS : LIST : ERROR : DB : %s" (Pgsql_pool.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error (#Pgsql_io.err as err)   ->
              Logs.err (fun m -> m "SECRETS : LIST : ERROR : DB : %s" (Pgsql_io.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          )
      | Error `Forbidden ->
          Logs.info (fun m -> m "SECRETS : LIST : FORBIDDEN : %s : %Ld" user_id installation_id);
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "SECRETS : LIST : ERROR : DB : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "SECRETS : LIST : ERROR : DB : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Gh.call_err as err) ->
          Logs.err (fun m -> m "SECRETS : LIST : ERROR : GITHUB : %s" (Gh.show_call_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Terrat_github.get_access_token_err as err) ->
          Logs.err (fun m ->
              m "SECRETS : LIST : ERROR : GITHUB : %s" (Terrat_github.show_get_access_token_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))

let put config storage github_schema installation_id secret =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user_id ->
      let open Abb.Future.Infix_monad in
      Terrat_github.verify_admin_installation_access
        config
        storage
        github_schema
        installation_id
        user_id
      >>= function
      | Ok () -> (
          encrypt_and_store storage installation_id user_id secret
          >>= function
          | Ok ()                             ->
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Created "") ctx))
          | Error `Invalid_secret_name        ->
              Logs.err (fun m ->
                  m
                    "SECRETS : PUT: ERROR : INVALID_NAME : %s"
                    secret.Terrat_data.Request.Secret.name);
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx))
          | Error (#Pgsql_pool.err as err)    ->
              Logs.err (fun m -> m "SECRETS : PUT : ERROR : DB : %s" (Pgsql_pool.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error (#Pgsql_io.err as err)      ->
              Logs.err (fun m -> m "SECRETS : PUT : ERROR : DB : %s" (Pgsql_io.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error `Missing_installation_error ->
              Logs.info (fun m -> m "SECRETS : PUT : ERROR : MISSING_INSTALLATION");
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)))
      | Error `Forbidden ->
          Logs.info (fun m -> m "SECRETS : PUT : FORBIDDEN : %s : %Ld" user_id installation_id);
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "SECRETS : PUT : ERROR : DB : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "SECRETS : PUT : ERROR : DB : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Gh.call_err as err) ->
          Logs.err (fun m -> m "SECRETS : PUT : ERROR : GITHUB : %s" (Gh.show_call_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Terrat_github.get_access_token_err as err) ->
          Logs.err (fun m ->
              m "SECRETS : PUT : ERROR : GITHUB : %s" (Terrat_github.show_get_access_token_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))

let delete config storage github_schema installation_id name =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user_id ->
      let open Abb.Future.Infix_monad in
      Terrat_github.verify_admin_installation_access
        config
        storage
        github_schema
        installation_id
        user_id
      >>= function
      | Ok () -> (
          Pgsql_pool.with_conn storage ~f:(fun db ->
              Pgsql_io.Prepared_stmt.execute db Sql.delete_secret installation_id name)
          >>= function
          | Ok ()                          ->
              Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m -> m "SECRETS : DELETE : ERROR : DB : %s" (Pgsql_pool.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error (#Pgsql_io.err as err)   ->
              Logs.err (fun m -> m "SECRETS : DELETE : ERROR : DB : %s" (Pgsql_io.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          )
      | Error `Forbidden ->
          Logs.info (fun m -> m "SECRETS : DELETE : FORBIDDEN : %s : %Ld" user_id installation_id);
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "SECRETS : DELETE : ERROR : DB : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "SECRETS : DELETE : ERROR : DB : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Gh.call_err as err) ->
          Logs.err (fun m -> m "SECRETS : DELETE : ERROR : GITHUB : %s" (Gh.show_call_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Terrat_github.get_access_token_err as err) ->
          Logs.err (fun m ->
              m
                "SECRETS : DELETE : ERROR : GITHUB : %s"
                (Terrat_github.show_get_access_token_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))