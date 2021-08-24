let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

module Sql = struct
  let read fname = CCOpt.get_exn_or fname (Terrat_files_terraform.read fname)

  let select_default_terraform_version =
    Pgsql_io.Typed_sql.(
      sql // (* version *) Ret.varchar /^ read "select_default_terraform_version.sql")

  let select_terraform_versions =
    Pgsql_io.Typed_sql.(sql // (* version *) Ret.varchar /^ read "select_terraform_versions.sql")
end

let perform_get storage =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.tx db ~f:(fun () ->
          Pgsql_io.Prepared_stmt.fetch db Sql.select_default_terraform_version ~f:CCFun.id
          >>= function
          | default_version :: _ ->
              Pgsql_io.Prepared_stmt.fetch db Sql.select_terraform_versions ~f:CCFun.id
              >>= fun versions ->
              Abb.Future.return
                (Ok Terrat_data.Response.Terraform_versions.{ default_version; versions })
          | []                   -> assert false))

let get storage ctx =
  let open Abb.Future.Infix_monad in
  perform_get storage
  >>= function
  | Ok versions                    ->
      let body =
        versions |> Terrat_data.Response.Terraform_versions.to_yojson |> Yojson.Safe.to_string
      in
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~headers:response_headers ~status:`OK body) ctx)
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "TERRAFORM VERSIONS : GET : ERROR : %s" (Pgsql_pool.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Pgsql_io.err as err)   ->
      Logs.err (fun m -> m "TERRAFORM VERSIONS : GET : ERROR : %s" (Pgsql_io.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
