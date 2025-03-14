let src = Logs.Src.create "telemetry"

module Logs = (val Logs.src_log src : Logs.LOG)
module Http = Abb_curl.Make (Abb)

let one_hour = 60.0 *. 60.0

let http_headers =
  Http.Headers.of_list [ ("content-length", "0"); ("user-agent", "Terrateam Telemetry 1.0") ]

module Event = struct
  type t =
    | Start of {
        app_type : string;
        app_id : string;
      }
    | Run of {
        app_type : string;
        app_id : string;
        step : Terrat_work_manifest3.Step.t;
        owner : string;
        repo : string;
      }
    | Ping of {
        app_type : string;
        app_id : string;
      }
end

let send' telemetry_config event =
  match telemetry_config with
  | Terrat_config.Telemetry.Disabled -> Abbs_future_combinators.unit
  | Terrat_config.Telemetry.Anonymous uri -> (
      match event with
      | Event.Start { app_type; app_id } ->
          let uri =
            Uri.with_path
              uri
              (Printf.sprintf "/event/start/%s/%s" app_type Digest.(to_hex (string app_id)))
          in
          Logs.info (fun m -> m "%a" Uri.pp uri);
          Logs.info (fun m -> m "ANONYMOUS : EVENT : START");
          (* For some reason, on dev ngrok this request hangs if it is HTTP2,
             but forcing it to HTTP/1.1 works. *)
          Abbs_future_combinators.ignore
            (Abbs_future_combinators.timeout
               ~timeout:(Abb.Sys.sleep 1.0)
               (Http.post
                  ~options:Http.Options.(with_opt (Http_version `Http1_1) default)
                  ~headers:http_headers
                  uri))
      | Event.Run { app_type; app_id; step; owner; repo } ->
          let uri =
            Uri.with_path
              uri
              (Printf.sprintf
                 "/event/run/%s/%s/%s/%s/%s"
                 app_type
                 Digest.(to_hex (string app_id))
                 (Terrat_work_manifest3.Step.to_string step)
                 Digest.(to_hex (string owner))
                 Digest.(to_hex (string repo)))
          in
          Logs.info (fun m -> m "ANONYMOUS : EVENT : RUN");
          (* For some reason, on dev ngrok this request hangs if it is HTTP2,
             but forcing it to HTTP/1.1 works. *)
          Abbs_future_combinators.ignore
            (Abbs_future_combinators.timeout
               ~timeout:(Abb.Sys.sleep 1.0)
               (Http.post
                  ~options:Http.Options.(with_opt (Http_version `Http1_1) default)
                  ~headers:http_headers
                  uri))
      | Event.Ping { app_type; app_id } ->
          let uri =
            Uri.with_path
              uri
              (Printf.sprintf "/event/ping/%s/%s" app_type Digest.(to_hex (string app_id)))
          in
          Logs.info (fun m -> m "ANONYMOUS : EVENT : PING");
          (* For some reason, on dev ngrok this request hangs if it is HTTP2,
             but forcing it to HTTP/1.1 works. *)
          Abbs_future_combinators.ignore
            (Abbs_future_combinators.timeout
               ~timeout:(Abb.Sys.sleep 1.0)
               (Http.post
                  ~options:Http.Options.(with_opt (Http_version `Http1_1) default)
                  ~headers:http_headers
                  uri)))

let send telemetry_config event =
  Abbs_future_combinators.ignore (Abb.Future.fork (send' telemetry_config event))

let rec start_ping_loop config =
  let open Abb.Future.Infix_monad in
  Abb.Sys.sleep one_hour
  >>= fun () ->
  (match Terrat_config.github config with
  | Some github ->
      send
        (Terrat_config.telemetry config)
        (Event.Ping { app_type = "github"; app_id = Terrat_config.Github.app_id github })
  | None -> Abb.Future.return ())
  >>= fun () -> start_ping_loop config
