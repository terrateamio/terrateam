module Sql = struct
  let read fname = CCOpt.get_exn_or fname (Terrat_files_sql.read fname)

  let base64 = function
    | Some s :: rest -> (
        match Base64.decode (CCString.replace ~sub:"\n" ~by:"" s) with
        | Ok s -> Some (s, rest)
        | _ -> None)
    | _ -> None

  let upsert_terraform_plan =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "upsert_terraform_plan.sql"
      /% Var.uuid "change"
      /% Var.text "dir_path"
      /% Var.text "workspace"
      /% Var.(ud (text "data") Base64.encode_string))

  let select_terraform_plan =
    Pgsql_io.Typed_sql.(
      sql
      // (* data *) Ret.ud base64
      /^ read "select_terraform_plan.sql"
      /% Var.uuid "change"
      /% Var.text "dir_path"
      /% Var.text "workspace")
end

(* let post storage plan =
 *   Brtl_ep.run_result ~f:(fun ctx ->
 *       let open Abbs_future_combinators.Infix_result_monad in
 *       Terrat_work_manifest.with_work_manifest storage ctx
 *       >>= fun work_manifest ->
 *       let open Abb.Future.Infix_monad in
 *       let module P = Terrat_data.Request.Plan.Create in
 *       Pgsql_pool.with_conn storage ~f:(fun db ->
 *           Pgsql_io.Prepared_stmt.execute
 *             db
 *             Sql.upsert_terraform_plan
 *             (Terrat_work_manifest.change work_manifest)
 *             plan.P.dir_path
 *             plan.P.workspace
 *             (\* Decode it and it will get re-encoded, this is to protect against
 *                getting a bad input *\)
 *             (Base64.decode_exn plan.P.plan))
 *       >>= function
 *       | Ok ()   ->
 *           Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx))
 *       | Error _ ->
 *           Abb.Future.return
 *             (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
 * 
 * let get storage dir_path workspace =
 *   Brtl_ep.run_result ~f:(fun ctx ->
 *       let open Abbs_future_combinators.Infix_result_monad in
 *       Terrat_work_manifest.with_work_manifest storage ctx
 *       >>= fun work_manifest ->
 *       let open Abb.Future.Infix_monad in
 *       Pgsql_pool.with_conn storage ~f:(fun db ->
 *           Pgsql_io.Prepared_stmt.fetch
 *             db
 *             Sql.select_terraform_plan
 *             ~f:CCFun.id
 *             (Terrat_work_manifest.change work_manifest)
 *             dir_path
 *             workspace)
 *       >>= function
 *       | Ok (plan :: _)                 ->
 *           let headers = Cohttp.Header.of_list [ ("content-type", "application/octet-stream") ] in
 *           Abb.Future.return
 *             (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~headers ~status:`OK plan) ctx))
 *       | Ok []                          ->
 *           Abb.Future.return
 *             (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
 *       | Error (#Pgsql_pool.err as err) ->
 *           Logs.err (fun m -> m "PLAN : GET : %s" (Pgsql_pool.show_err err));
 *           Abb.Future.return
 *             (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
 *       | Error (#Pgsql_io.err as err)   ->
 *           Logs.err (fun m -> m "PLAN : GET : %s" (Pgsql_io.show_err err));
 *           Abb.Future.return
 *             (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))) *)
