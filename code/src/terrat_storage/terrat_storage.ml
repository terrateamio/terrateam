let src = Logs.Src.create "storage"

module Logs = (val Logs.src_log src : Logs.LOG)

module Queue_time_histogram = Prmths.Histogram (struct
  let spec = Prmths.Histogram_spec.of_list [ 0.01; 0.1; 0.25; 0.5; 1.0; 2.5; 5.0; 7.5; 10.0; 15.0 ]
end)

module Metrics = struct
  let namespace = "terrat"
  let subsystem = "storage"

  let num_conns =
    let help = "Number of created connections" in
    Prmths.Gauge.v ~help ~namespace ~subsystem "num_conns"

  let num_idle_conns =
    let help = "Number of idle connections" in
    Prmths.Gauge.v ~help ~namespace ~subsystem "num_idle_conns"

  let queue_time =
    let help = "Time spent waiting for a connection from the pool" in
    Queue_time_histogram.v ~help ~namespace ~subsystem "queue_time"
end

type t = Pgsql_pool.t

let metrics Pgsql_pool.Metrics.{ num_conns; idle_conns; queue_time } =
  Prmths.Gauge.set Metrics.num_conns (CCFloat.of_int num_conns);
  Prmths.Gauge.set Metrics.num_idle_conns (CCFloat.of_int idle_conns);
  CCOption.iter (Queue_time_histogram.observe Metrics.queue_time) queue_time;
  Abbs_future_combinators.unit

let on_connect idle_tx_timeout conn =
  Abbs_future_combinators.ignore
    (let open Abb.Future.Infix_monad in
     Pgsql_io.Prepared_stmt.execute
       conn
       Pgsql_io.Typed_sql.(
         sql /^ Printf.sprintf "set idle_in_transaction_session_timeout='%s'" idle_tx_timeout)
     >>= function
     | Ok () -> Abb.Future.return ()
     | Error (#Pgsql_io.err as err) ->
         Logs.err (fun m -> m "%a" Pgsql_io.pp_err err);
         Abb.Future.return ())

let create config =
  let open Abb.Future.Infix_monad in
  let tls_config =
    let cfg = Otls.Tls_config.create () in
    Otls.Tls_config.insecure_noverifycert cfg;
    Otls.Tls_config.insecure_noverifyname cfg;
    cfg
  in
  Pgsql_pool.create
    ~metrics
    ~idle_check:(Duration.of_sec 0)
    ~tls_config:(`Prefer tls_config)
    ~host:(Terrat_config.db_host config)
    ~user:(Terrat_config.db_user config)
    ~passwd:(Terrat_config.db_password config)
    ?port:(Some (Terrat_config.db_port config))
    ~max_conns:(Terrat_config.db_max_pool_size config)
    ~connect_timeout:(Terrat_config.db_connect_timeout config)
    ~on_connect:(on_connect (Terrat_config.db_idle_tx_timeout config))
    (Terrat_config.db config)
  >>= fun storage ->
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.execute
        db
        Pgsql_io.Typed_sql.(sql /^ "create extension if not exists pgcrypto"))
  >>= function
  | Ok () -> Abb.Future.return storage
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "%a" Pgsql_io.pp_err err);
      raise (Failure "could not create storage")
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "%a" Pgsql_pool.pp_err err);
      raise (Failure "could not create storage")
