type t = Pgsql_pool.t

let create config =
  let tls_config =
    let cfg = Otls.Tls_config.create () in
    Otls.Tls_config.insecure_noverifycert cfg;
    Otls.Tls_config.insecure_noverifyname cfg;
    cfg
  in
  Pgsql_pool.create
    ~tls_config:(`Require tls_config)
    ~host:(Terrat_config.db_host config)
    ~user:(Terrat_config.db_user config)
    ~passwd:(Terrat_config.db_password config)
    ~max_conns:100
    ~connect_timeout:10.0
    (Terrat_config.db config)
