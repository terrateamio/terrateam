let src = Logs.Src.create "infracost"

module Logs = (val Logs.src_log src : Logs.LOG)
module Http = Cohttp_abb.Make (Abb)

module Metrics = struct
  module DefaultHistogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_list [ 0.005; 0.5; 1.0; 5.0; 10.0; 15.0; 20.0 ]
  end)

  let namespace = "terrat"
  let subsystem = "ep_infracost"

  let duration_seconds =
    let help = "Number of seconds to eval an infracost request" in
    DefaultHistogram.v ~help ~namespace ~subsystem "duration_seconds"

  let requests_total =
    let help = "Total number of requests" in
    Prmths.Counter.v ~help ~namespace ~subsystem "requests_total"

  let responses_total =
    let help = "Total number of responses" in
    Prmths.Counter.v_label ~label_name:"result" ~help ~namespace ~subsystem "responses_total"

  let requests_concurrent =
    let help = "Number of concurrent requests" in
    Prmths.Gauge.v ~help ~namespace ~subsystem "requests_concurrent"

  let pgsql_pool_errors_total = Terrat_metrics.errors_total ~m:"ep_infracost" ~t:"pgsql_pool"
  let pgsql_errors_total = Terrat_metrics.errors_total ~m:"ep_infracost" ~t:"pgsql"
  let http_errors_total = Terrat_metrics.errors_total ~m:"ep_infracost" ~t:"http"
  let timeout_errors_total = Terrat_metrics.errors_total ~m:"ep_infracost" ~t:"timeout"
  let infracost_errors_total = Terrat_metrics.errors_total ~m:"ep_infracost" ~t:"infracost"
end

module Sql = struct
  let verify_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      /^ "select id from github_work_manifests where state = 'running' and id = $id"
      /% Var.uuid "id")
end

let header_replace k v h = Cohttp.Header.replace h k v

let post' config storage api_key infracost_uri path ctx =
  let open Abb.Future.Infix_monad in
  let request = Brtl_ctx.request ctx in
  let request_id = Brtl_ctx.token ctx in
  match Cohttp.Header.get (Brtl_ctx.Request.headers request) "x-api-key" with
  | Some work_manifest_id -> (
      (match Uuidm.of_string work_manifest_id with
      | Some work_manifest_id ->
          Pgsql_pool.with_conn storage ~f:(fun db ->
              Pgsql_io.Prepared_stmt.fetch db Sql.verify_work_manifest ~f:CCFun.id work_manifest_id)
      | None -> Abb.Future.return (Error `Bad_work_manifest))
      >>= function
      | Ok (_ :: _) -> (
          let uri = Uri.with_path infracost_uri (Uri.path infracost_uri ^ "/" ^ path) in
          let body = Brtl_ctx.body ctx in
          let headers =
            request
            |> Brtl_ctx.Request.headers
            |> CCFun.flip Cohttp.Header.remove "host"
            |> header_replace "x-api-key" api_key
          in
          Logs.debug (fun m ->
              m "%s : work_manifest=%s : URI : %s" request_id work_manifest_id (Uri.to_string uri));
          Abbs_future_combinators.timeout
            ~timeout:(Abb.Sys.sleep 30.0)
            (Http.Client.post ~headers ~body uri)
          >>= function
          | `Ok (Ok (resp, body)) when Cohttp.Response.status resp = `OK ->
              Logs.debug (fun m -> m "%s : work_manifest=%s : SUCCESS" request_id work_manifest_id);
              Prmths.Counter.inc_one (Metrics.responses_total "success");
              Abb.Future.return
                (Brtl_ctx.set_response
                   (Brtl_rspnc.create ~headers:(Cohttp.Response.headers resp) ~status:`OK body)
                   ctx)
          | `Ok (Ok (resp, _)) ->
              Logs.err (fun m ->
                  m
                    "%s : work_manifest=%s : ERROR : %a"
                    request_id
                    work_manifest_id
                    Cohttp.Response.pp_hum
                    resp);
              Prmths.Counter.inc_one Metrics.infracost_errors_total;
              Prmths.Counter.inc_one (Metrics.responses_total "error");
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error body) ctx)
          | `Ok (Error (#Cohttp_abb.request_err as err)) ->
              Logs.err (fun m ->
                  m
                    "%s : work_manifest=%s : ERROR : %s"
                    request_id
                    work_manifest_id
                    (Cohttp_abb.show_request_err err));
              Prmths.Counter.inc_one Metrics.http_errors_total;
              Prmths.Counter.inc_one (Metrics.responses_total "error");
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
          | `Timeout ->
              Logs.err (fun m ->
                  m "%s : work_manifest=%s : ERROR : TIMEOUT" request_id work_manifest_id);
              Prmths.Counter.inc_one Metrics.timeout_errors_total;
              Prmths.Counter.inc_one (Metrics.responses_total "timeout");
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_pool.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
          Logs.err (fun m ->
              m
                "%s : work_manifest=%s : ERROR : %a"
                request_id
                work_manifest_id
                Pgsql_pool.pp_err
                err);
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m ->
              m "%s : work_manifest=%s : ERROR : %a" request_id work_manifest_id Pgsql_io.pp_err err);
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Ok [] ->
          Logs.warn (fun m ->
              m "%s : work_manifest=%s : ERROR : MISSING_WORK_MANIFEST" request_id work_manifest_id);
          Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
      | Error `Bad_work_manifest ->
          Logs.err (fun m ->
              m "%s : work_manifest=%s : ERROR : BAD_WORK_MANIFEST" request_id work_manifest_id);
          Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx))
  | None ->
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)

let post config storage path ctx =
  let request_id = Brtl_ctx.token ctx in
  match Terrat_config.infracost config with
  | Some { Terrat_config.Infracost.endpoint = infracost_uri; api_key } ->
      Logs.info (fun m -> m "%s : START" request_id);
      Prmths.Counter.inc_one Metrics.requests_total;
      Metrics.DefaultHistogram.time Metrics.duration_seconds (fun () ->
          Prmths.Gauge.track_inprogress Metrics.requests_concurrent (fun () ->
              Abbs_future_combinators.with_finally
                (fun () -> post' config storage api_key infracost_uri path ctx)
                ~finally:(fun () ->
                  Logs.info (fun m -> m "%s : FINISH" request_id);
                  Abbs_future_combinators.unit)))
  | None ->
      Logs.info (fun m -> m "%s : DISABLED" request_id);
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
