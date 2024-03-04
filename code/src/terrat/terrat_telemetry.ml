module Http = Cohttp_abb.Make (Abb)

let tls_config =
  let cfg = Otls.Tls_config.create () in
  Otls.Tls_config.insecure_noverifycert cfg;
  Otls.Tls_config.insecure_noverifyname cfg;
  cfg

let one_hour = 60.0 *. 60.0

let http_headers =
  Cohttp.Header.of_list [ ("content-length", "0"); ("user-agent", "Terrateam Telemetry 1.0") ]

module Event = struct
  type t =
    | Start of { github_app_id : string }
    | Run of {
        github_app_id : string;
        run_type : Terrat_work_manifest2.Run_type.t;
        owner : string;
        repo : string;
      }
    | Ping of { github_app_id : string }
end

let send' telemetry_config event =
  match telemetry_config with
  | Terrat_config.Telemetry.Disabled -> Abbs_future_combinators.unit
  | Terrat_config.Telemetry.Anonymous uri -> (
      match event with
      | Event.Start { github_app_id } ->
          let uri =
            Uri.with_path
              uri
              (Printf.sprintf "/event/start/%s" Digest.(to_hex (string github_app_id)))
          in
          Logs.info (fun m -> m "%a" Uri.pp uri);
          Logs.info (fun m -> m "TELEMETRY : ANONYMOUS : EVENT : START");
          Abbs_future_combinators.ignore
            (Http.Client.call ~headers:http_headers ~tls_config `POST uri)
      | Event.Run { github_app_id; run_type; owner; repo } ->
          let uri =
            Uri.with_path
              uri
              (Printf.sprintf
                 "/event/run/%s/%s/%s/%s"
                 Digest.(to_hex (string github_app_id))
                 (Terrat_work_manifest2.Run_type.to_string run_type)
                 Digest.(to_hex (string owner))
                 Digest.(to_hex (string repo)))
          in
          Logs.info (fun m -> m "TELEMETRY : ANONYMOUS : EVENT : RUN");
          Abbs_future_combinators.ignore
            (Http.Client.call ~headers:http_headers ~tls_config `POST uri)
      | Event.Ping { github_app_id } ->
          let uri =
            Uri.with_path
              uri
              (Printf.sprintf "/event/ping/%s" Digest.(to_hex (string github_app_id)))
          in
          Logs.info (fun m -> m "TELEMETRY : ANONYMOUS : EVENT : PING");
          Abbs_future_combinators.ignore
            (Http.Client.call ~headers:http_headers ~tls_config `POST uri))

let send telemetry_config event =
  Abbs_future_combinators.ignore (Abb.Future.fork (send' telemetry_config event))

let rec start_ping_loop config =
  let open Abb.Future.Infix_monad in
  Abb.Sys.sleep one_hour
  >>= fun () ->
  send
    (Terrat_config.telemetry config)
    (Event.Ping { github_app_id = Terrat_config.github_app_id config })
  >>= fun () -> start_ping_loop config
