let create_pgcrypto_sql = Mql_sql.read "create extension if not exists pgcrypto"
let set_statement_timeout_sql = Mql_sql.read "set statement_timeout='300s'"
let src = Logs.Src.create "storage"

module Logs = (val Logs.src_log src : Logs.LOG)
module Fc = Abbs_fc

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
  Abbs_fc.unit

let on_connect ?(settings = []) idle_tx_timeout lock_timeout conn =
  Abbs_fc.ignore
    (let go () =
       let open Fc.Infix_result_monad in
       Pgsql_io.Prepared_stmt.execute
         conn
         Pgsql_io.Typed_sql.(
           sql /^ Mql_sql.set ~name:"idle_in_transaction_session_timeout" idle_tx_timeout)
       >>= fun () ->
       Pgsql_io.Prepared_stmt.execute
         conn
         Pgsql_io.Typed_sql.(sql /^ Mql_sql.set ~name:"lock_timeout" lock_timeout)
       >>= fun () ->
       Pgsql_io.Prepared_stmt.execute conn Pgsql_io.Typed_sql.(sql /^ set_statement_timeout_sql)
       >>= fun () ->
       Fc.List_result.iter
         ~f:(fun setting -> Pgsql_io.Prepared_stmt.execute conn Pgsql_io.Typed_sql.(sql /^ setting))
         settings
     in
     let open Abb.Future.Infix_monad in
     go ()
     >>= function
     | Ok () -> Abb.Future.return ()
     | Error (#Pgsql_io.err as err) ->
         Logs.err (fun m -> m "%a" Pgsql_io.pp_err err);
         Abb.Future.return ())

let tls_config () =
  let cfg = Otls.Tls_config.create () in
  Otls.Tls_config.insecure_noverifycert cfg;
  Otls.Tls_config.insecure_noverifyname cfg;
  cfg

let create_pool ?tls_config ?settings ~host ~user ~passwd ~port config db =
  Pgsql_pool.create
    ~metrics
    ~idle_check:(Duration.of_sec 0)
    ?tls_config
    ~host
    ~user
    ~passwd
    ~port
    ~max_conns:(Terrat_config.db_max_pool_size config)
    ~connect_timeout:(Terrat_config.db_connect_timeout config)
    ~on_connect:
      (on_connect
         ?settings
         (Terrat_config.db_idle_tx_timeout config)
         (Terrat_config.db_lock_timeout config))
    db

let try_create config =
  let open Abb.Future.Infix_monad in
  create_pool
    ~tls_config:(`Prefer (tls_config ()))
    ~host:(Terrat_config.db_host config)
    ~user:(Terrat_config.db_user config)
    ~passwd:(Terrat_config.db_password config)
    ~port:(Terrat_config.db_port config)
    config
    (Terrat_config.db config)
  >>= fun storage ->
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.execute db Pgsql_io.Typed_sql.(sql /^ create_pgcrypto_sql))
  >>= function
  | Ok () -> Abb.Future.return (Ok storage)
  | Error _ as err -> Pgsql_pool.destroy storage >>| fun () -> err

let create config =
  let open Abb.Future.Infix_monad in
  try_create config
  >>= function
  | Ok storage -> Abb.Future.return storage
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "%a" Pgsql_io.pp_err err);
      raise (Failure "could not create storage")
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "%a" Pgsql_pool.pp_err err);
      raise (Failure "could not create storage")

(* Every filter of the price query is a parameter that can be NULL, so a generic
   plan cannot read the index on (service, region) and scans the whole price
   book. The statements are prepared once for each connection and run up to 1000
   times for each batch, which is where the planner would change to a generic
   plan. *)
let pricing_settings = [ Mql_sql.read "set plan_cache_mode='force_custom_plan'" ]

let create_pricing config { Terrat_config.Infracost.db; host; password; port; sslmode; user } =
  create_pool
    ~settings:pricing_settings
    ?tls_config:
      (match sslmode with
      | Terrat_config.Infracost.Disable -> None
      | Terrat_config.Infracost.Prefer -> Some (`Prefer (tls_config ()))
      | Terrat_config.Infracost.Require -> Some (`Require (tls_config ())))
    ~host
    ~user
    ~passwd:password
    ~port
    config
    db
