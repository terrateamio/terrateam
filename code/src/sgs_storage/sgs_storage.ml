type t = Pgsql_pool.t

module Metrics = struct
  let namespace = "sgs"
  let subsystem = "storage"

  let num_conns =
    let help = "Number of created connections" in
    Prmths.Gauge.v ~help ~namespace ~subsystem "num_conns"

  let num_idle_conns =
    let help = "Number of idle connections" in
    Prmths.Gauge.v ~help ~namespace ~subsystem "num_idle_conns"
end

let metrics { Pgsql_pool.Metrics.num_conns; idle_conns; queue_time = _ } =
  Prmths.Gauge.set Metrics.num_conns (CCFloat.of_int num_conns);
  Prmths.Gauge.set Metrics.num_idle_conns (CCFloat.of_int idle_conns);
  Abbs_fc.unit

let on_connect idle_tx_timeout conn =
  Abbs_fc.ignore
    (let open Abb.Future.Infix_monad in
     Pgsql_io.Prepared_stmt.execute
       conn
       Pgsql_io.Typed_sql.(
         sql /^ Mql_sql.set ~name:"idle_in_transaction_session_timeout" idle_tx_timeout)
     >>= function
     | Ok () -> Abb.Future.return ()
     | Error (#Pgsql_io.err as err) ->
         Logs.err (fun m -> m "%a" Pgsql_io.pp_err err);
         Abb.Future.return ())

let create config =
  let tls_config =
    let cfg = Otls.Tls_config.create () in
    Otls.Tls_config.insecure_noverifycert cfg;
    Otls.Tls_config.insecure_noverifyname cfg;
    cfg
  in
  Pgsql_pool.create
    ?port:(Sgs_config.db_port config)
    ~metrics
    ~idle_check:(Duration.of_sec 30)
      (* Connections live long enough for the per-connection prepared-statement
         cache to amortise; the app issues a small, finite set of distinct
         queries so the cached statements per backend stay bounded. *)
    ~max_uses:10000
    ~tls_config:(`Prefer tls_config)
    ~host:(Sgs_config.db_host config)
    ~user:(Sgs_config.db_user config)
    ~passwd:(Sgs_config.db_password config)
    ~max_conns:(Sgs_config.db_max_pool_size config)
    ~connect_timeout:(Sgs_config.db_connect_timeout config)
    ~on_connect:(on_connect (Sgs_config.db_idle_tx_timeout config))
    (Sgs_config.db config)
