module Terratc = Terratc_ee.Make (struct
  module Github = Terrat_vcs_github.S
end)

module Server = Terrat_server.Make (Terratc)

module Cmdline = struct
  module C = Cmdliner

  let reporter ppf =
    let report src level ~over k msgf =
      let k _ =
        over ();
        k ()
      in
      let with_stamp h tags k ppf fmt =
        (* TODO: Make this use the proper Abb time *)
        let time = Unix.gettimeofday () in
        let time_str = ISO8601.Permissive.string_of_datetime time in
        Format.kfprintf
          k
          ppf
          ("[%s] %a [%s] @[" ^^ fmt ^^ "@]@.")
          time_str
          Logs.pp_header
          (level, h)
          (Logs.Src.name src)
      in
      msgf @@ fun ?header ?tags fmt -> with_stamp header tags k ppf fmt
    in
    { Logs.report }

  let setup_log level dns_logging http_logging =
    Logs.set_reporter (reporter Format.std_formatter);
    Logs.set_level level;
    CCList.iter
      (fun src ->
        if
          (not dns_logging)
          && CCList.mem
               ~eq:CCString.equal
               (Logs.Src.name src)
               [ "happy-eyeballs"; "dns_client"; "dns_cache"; "abb.dns" ]
          || (not http_logging)
             && CCList.mem
                  ~eq:CCString.equal
                  (Logs.Src.name src)
                  [ "cohttp_abb"; "cohttp_abb.io"; "abb_curl"; "abb_curl_easy" ]
        then
          (* Increase these loggers because they are too verbose *)
          Logs.Src.set_level src (Some Logs.Error))
      (Logs.Src.list ())

  let dns_logging =
    let env =
      let doc = "Enable DNS logging" in
      C.Cmd.Env.info ~doc "TERRAT_DNS_LOGGING"
    in
    let doc = "Log DNS operations." in
    C.Arg.(value & flag & info [ "dns-logging" ] ~env ~doc)

  let http_logging =
    let env =
      let doc = "Enable HTTP logging" in
      C.Cmd.Env.info ~doc "TERRAT_HTTP_LOGGING"
    in
    let doc = "Log HTTP operations." in
    C.Arg.(value & flag & info [ "http-logging" ] ~env ~doc)

  let logs = C.Term.(const setup_log $ Logs_cli.level () $ dns_logging $ http_logging)

  let app_id =
    let doc = "App ID." in
    C.Arg.(required & opt (some string) None & info [ "app-id" ] ~doc)

  let pem =
    let doc = "PEM file path." in
    C.Arg.(required & opt (some file) None & info [ "pem" ] ~doc)

  let inst_id =
    let doc = "Installation ID." in
    C.Arg.(required & opt (some string) None & info [ "inst-id" ] ~doc)

  let generate_auth_token_cmd f =
    let doc = "Generate an auth token." in
    let exits = C.Cmd.Exit.defaults in
    C.Cmd.v (C.Cmd.info "gen-auth-token" ~doc ~exits) C.Term.(const f $ app_id $ pem $ inst_id)

  let server_cmd f =
    let doc = "Run server." in
    let exits = C.Cmd.Exit.defaults in
    C.Cmd.v (C.Cmd.info "server" ~doc ~exits) C.Term.(const f $ logs)

  let migrate_cmd f =
    let doc = "Perform migration" in
    let exits = C.Cmd.Exit.defaults in
    C.Cmd.v (C.Cmd.info "migrate" ~doc ~exits) C.Term.(const f $ logs)

  let default_cmd = C.Term.(ret (const (`Help (`Pager, None))))
end

let server () =
  match Terrat_config.create () with
  | Ok config -> (
      let run () =
        let open Abb.Future.Infix_monad in
        Terrat_storage.create config >>= fun storage -> Server.run config storage
      in
      print_endline (Terrat_config.show config);
      match Abb.Scheduler.run_with_state run with
      | `Det () -> ()
      | `Aborted -> assert false
      | `Exn (exn, bt_opt) ->
          Logs.err (fun m -> m "%s" (Printexc.to_string exn));
          CCOption.iter
            (fun bt -> Logs.err (fun m -> m "%s" (Printexc.raw_backtrace_to_string bt)))
            bt_opt;
          assert false)
  | Error err ->
      Logs.err (fun m -> m "CONFIG : ERROR : %s" (Terrat_config.show_err err));
      exit 1

let migrate () =
  match Terrat_config.create () with
  | Ok config -> (
      let run () =
        let open Abb.Future.Infix_monad in
        Terrat_storage.create config >>= fun storage -> Terrat_migrations.run config storage
      in
      print_endline (Terrat_config.show config);
      match Abb.Scheduler.run_with_state run with
      | `Det (Ok ()) -> Logs.info (fun m -> m "Migration complete")
      | `Det (Error (`Migration_err (#Pgsql_io.err as err))) ->
          Logs.err (fun m -> m "Migration failed");
          Logs.err (fun m -> m "%s" (Pgsql_io.show_err err));
          exit 1
      | `Det (Error (`Migration_err (#Pgsql_pool.err as err))) ->
          Logs.err (fun m -> m "Migration failed");
          Logs.err (fun m -> m "%s" (Pgsql_pool.show_err err));
          exit 1
      | `Det (Error `Consistency_err) ->
          Logs.err (fun m -> m "Migration failed - inconsistent migrations");
          exit 1
      | `Aborted -> assert false
      | `Exn (exn, bt_opt) ->
          Logs.err (fun m -> m "%s" (Printexc.to_string exn));
          CCOption.iter
            (fun bt -> Logs.err (fun m -> m "%s" (Printexc.raw_backtrace_to_string bt)))
            bt_opt;
          assert false)
  | Error (#Terrat_config.err as err) ->
      Logs.err (fun m -> m "Config file failed to load %s" (Terrat_config.show_err err));
      exit 1

let generate_auth_token app_id pem inst_id =
  let run () =
    match Terrat_config.create () with
    | Ok config -> (
        let open Abb.Future.Infix_monad in
        print_endline (Terrat_config.show config);
        Abb.Sys.time ()
        >>= fun time ->
        let pem =
          match
            X509.Private_key.decode_pem (Cstruct.of_string (CCIO.with_in pem CCIO.read_all))
          with
          | Ok (`RSA v) -> v
          | Ok _ -> failwith "Expected RSA"
          | Error (`Msg s) -> failwith ("Error: " ^ s)
        in
        let payload =
          let module P = Jwt.Payload in
          let module C = Jwt.Claim in
          P.empty
          |> P.add_claim C.iss (`String app_id)
          |> P.add_claim C.iat (`Int (Float.to_int (time -. 60.0)))
          |> P.add_claim C.exp (`Int (Float.to_int (time +. (60.0 *. 10.0))))
        in
        let signer = Jwt.Signer.(RS256 (Priv_key.of_priv_key pem)) in
        let header = Jwt.Header.create (Jwt.Signer.to_string signer) in
        let jwt = Jwt.of_header_and_payload signer header payload in
        let token = Jwt.token jwt in
        let open Abbs_future_combinators.Infix_result_monad in
        let client = Terrat_github.create config (`Bearer token) in
        Githubc2_abb.call
          client
          Githubc2_apps.Create_installation_access_token.(
            make (Parameters.make ~installation_id:(CCInt.of_string_exn inst_id)))
        >>= fun resp ->
        match Openapi.Response.value resp with
        | `Created token ->
            let installation_token = Githubc2_components.Installation_token.value token in
            print_endline installation_token.Githubc2_components.Installation_token.Primary.token;
            Abb.Future.return (Ok ())
        | (`Unauthorized _ | `Forbidden _ | `Not_found _ | `Unprocessable_entity _) as err ->
            failwith (Terrat_github.show_get_installation_access_token_err err))
    | _ -> assert false
  in
  match Abb.Scheduler.run_with_state run with
  | `Det (Ok ()) -> ()
  | `Det (Error _) -> failwith "err"
  | `Aborted -> assert false
  | `Exn (exn, bt_opt) ->
      Printf.eprintf "%s\n" (Printexc.to_string exn);
      CCOption.iter (fun bt -> Printf.eprintf "%s\n" (Printexc.raw_backtrace_to_string bt)) bt_opt;
      assert false

let cmds =
  Cmdline.[ server_cmd server; migrate_cmd migrate; generate_auth_token_cmd generate_auth_token ]

let () =
  Mirage_crypto_rng_unix.initialize (module Mirage_crypto_rng.Fortuna);
  let info = Cmdliner.Cmd.info "terrat" in
  exit @@ Cmdliner.Cmd.eval @@ Cmdliner.Cmd.group ~default:Cmdline.default_cmd info cmds
