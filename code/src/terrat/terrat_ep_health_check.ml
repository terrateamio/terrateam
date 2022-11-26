module Metrics = struct
  module DefaultHistogram = Prmths.DefaultHistogram

  let namespace = "terrat"
  let subsystem = "ep_health_check"

  let duration_seconds =
    let help = "Number of seconds to perform health check" in
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

  let pgsql_pool_errors_total = Terrat_metrics.errors_total ~m:"ep_health_check" ~t:"pgsql_pool"
  let pgsql_errors_total = Terrat_metrics.errors_total ~m:"ep_health_check" ~t:"pgsql"
end

let get' storage ctx =
  let open Abb.Future.Infix_monad in
  Pgsql_pool.with_conn storage ~f:(fun db -> Abbs_future_combinators.to_result (Pgsql_io.ping db))
  >>= function
  | Ok true ->
      Prmths.Counter.inc_one (Metrics.responses_total "success");
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
  | Ok false ->
      Prmths.Counter.inc_one (Metrics.responses_total "ping_fail");
      Prmths.Counter.inc_one Metrics.pgsql_errors_total;
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "HEALTH : ERROR : %s" (Pgsql_pool.show_err err));
      Prmths.Counter.inc_one (Metrics.responses_total "pgsql_pool_fail");
      Prmths.Counter.inc_one Metrics.pgsql_pool_errors_total;
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)

let get storage ctx =
  Prmths.Counter.inc_one Metrics.requests_total;
  Metrics.DefaultHistogram.time Metrics.duration_seconds (fun () ->
      Prmths.Gauge.track_inprogress Metrics.requests_concurrent (fun () -> get' storage ctx))
