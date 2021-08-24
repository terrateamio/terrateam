module Sql = struct
  let read fname = CCOpt.get_exn_or fname (Terrat_files_github.read fname)

  let select_installation_env_vars =
    Pgsql_io.Typed_sql.(
      sql
      // (* name *) Ret.varchar
      // (* value *) Ret.varchar
      // (* modified_by *) Ret.varchar
      // (* modified_time *) Ret.varchar
      /^ read "select_installation_env_vars.sql"
      /% Var.bigint "installation_id")
end

let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

let fetch_env_vars storage installation_id =
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_installation_env_vars
        ~f:(fun name value modified_by modified_time ->
          Terrat_data_backend.Response.Env_var.{ name; value; modified_by; modified_time })
        installation_id)

let get storage ctx =
  let open Abb.Future.Infix_monad in
  let request = Brtl_ctx.request ctx in
  let headers = Brtl_ctx.Request.headers request in
  Terrat_verify_jwt.verify storage headers
  >>= function
  | Ok (_, _, _, iss) -> (
      fetch_env_vars storage iss
      >>= function
      | Ok secrets                     ->
          let body =
            Terrat_data_backend.Response.Env_var_list.
              { results = secrets; next = None; prev = None }
            |> Terrat_data_backend.Response.Env_var_list.to_yojson
            |> Yojson.Safe.to_string
          in
          Abb.Future.return
            (Brtl_ctx.set_response
               (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
               ctx)
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "BACKEND_ENV_VARS : GET : FAILED : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Error (#Pgsql_io.err as err)   ->
          Logs.err (fun m -> m "BACKEND_ENV_VARS : GET : FAILED : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
  | Error (#Terrat_verify_jwt.err as err) ->
      Logs.err (fun m -> m "BACKEND_ENV_VARS : GET : FAILED : %s" (Terrat_verify_jwt.show_err err));
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
