module Http = Cohttp_abb.Make (Abb)

module Sql = struct
  let verify_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.uuid
      /^ "select id from github_work_manifests where state = 'running' and id = $id"
      /% Var.uuid "id")
end

let tls_config =
  let cfg = Otls.Tls_config.create () in
  Otls.Tls_config.insecure_noverifycert cfg;
  Otls.Tls_config.insecure_noverifyname cfg;
  cfg

let header_replace k v h = Cohttp.Header.replace h k v

let post config storage path ctx =
  let open Abb.Future.Infix_monad in
  let request = Brtl_ctx.request ctx in
  match Cohttp.Header.get (Brtl_ctx.Request.headers request) "x-api-key" with
  | Some work_manifest_id -> (
      (match Uuidm.of_string work_manifest_id with
      | Some work_manifest_id ->
          Pgsql_pool.with_conn storage ~f:(fun db ->
              Pgsql_io.Prepared_stmt.fetch db Sql.verify_work_manifest ~f:CCFun.id work_manifest_id)
      | None -> Abb.Future.return (Error `Bad_work_manifest))
      >>= function
      | Ok (_ :: _) -> (
          let infracost_uri = Terrat_config.infracost_pricing_api_endpoint config in
          let uri = Uri.with_path infracost_uri (Uri.path infracost_uri ^ "/" ^ path) in
          let body = Brtl_ctx.body ctx in
          let headers =
            request
            |> Brtl_ctx.Request.headers
            |> CCFun.flip Cohttp.Header.remove "host"
            |> header_replace "x-api-key" (Terrat_config.infracost_api_key config)
          in
          Logs.info (fun m -> m "INFRACOST: URI : %s" (Uri.to_string uri));
          Http.Client.call ~tls_config ~headers ~body:(Http.Body.of_string body) `POST uri
          >>= function
          | Ok (resp, body) when Cohttp.Response.status resp = `OK ->
              Abb.Future.return
                (Brtl_ctx.set_response
                   (Brtl_rspnc.create ~headers:(Cohttp.Response.headers resp) ~status:`OK body)
                   ctx)
          | Ok (resp, _) ->
              Logs.err (fun m -> m "INFRACOST : ERROR : %a" Cohttp.Response.pp_hum resp);
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error body) ctx)
          | Error (#Cohttp_abb.request_err as err) ->
              Logs.err (fun m -> m "INFRACOST : ERROR : %s" (Cohttp_abb.show_request_err err));
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "INFRACOST : ERROR : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "INFRACOST : ERROR : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Ok [] ->
          Logs.err (fun m -> m "INFRACOST : ERROR : MISSING_WORK_MANIFEST");
          Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
      | Error `Bad_work_manifest ->
          Logs.err (fun m -> m "INFRACOST : ERROR : BAD_WORK_MANIFEST");
          Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx))
  | None ->
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
