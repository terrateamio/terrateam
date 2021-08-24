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
        Format.kfprintf k ppf ("[%s] %a @[" ^^ fmt ^^ "@]@.") time_str Logs.pp_header (level, h)
      in
      msgf @@ fun ?header ?tags fmt -> with_stamp header tags k ppf fmt
    in
    { Logs.report }

  let setup_log level =
    Logs.set_reporter (reporter Format.std_formatter);
    Logs.set_level level

  let logs = C.Term.(const setup_log $ Logs_cli.level ())

  let server_cmd f =
    let doc = "Run server." in
    let exits = C.Term.default_exits in
    C.Term.(const f $ logs, info "server" ~doc ~exits)

  let migrate_cmd f =
    let doc = "Perform migration" in
    let exits = C.Term.default_exits in
    C.Term.(const f $ logs, info "migrate" ~doc ~exits)

  let default_cmd =
    let doc = "terrateam" in
    let exits = C.Term.default_exits in
    C.Term.(ret (const (`Help (`Pager, None))), info "terrateam" ~doc ~exits)
end

let server () =
  match Terrat_config.create () with
    | Ok config -> (
        let run () =
          let open Abb.Future.Infix_monad in
          Terrat_storage.create config
          >>= fun storage ->
          Abbs_future_combinators.ignore
            (Abbs_future_combinators.first
               (Terrat_server.run config storage)
               (Terrat_backend_server.run config storage))
        in

        match Abb.Scheduler.run_with_state run with
          | `Det ()            -> ()
          | `Aborted           -> assert false
          | `Exn (exn, bt_opt) ->
              Logs.err (fun m -> m "%s" (Printexc.to_string exn));
              CCOpt.iter
                (fun bt -> Logs.err (fun m -> m "%s" (Printexc.raw_backtrace_to_string bt)))
                bt_opt;
              assert false)
    | Error err ->
        Logs.err (fun m -> m "CONFIG : ERROR : %s" (Terrat_config.show_err err));
        exit 1

let migrate () =
  match Terrat_config.create () with
    | Ok config                         -> (
        let run () =
          let open Abb.Future.Infix_monad in
          Terrat_storage.create config >>= fun storage -> Terrat_migrations.run config storage
        in
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
              CCOpt.iter
                (fun bt -> Logs.err (fun m -> m "%s" (Printexc.raw_backtrace_to_string bt)))
                bt_opt;
              assert false)
    | Error (#Terrat_config.err as err) ->
        Logs.err (fun m -> m "Config file failed to load %s" (Terrat_config.show_err err));
        exit 1

let cmds = Cmdline.[ server_cmd server; migrate_cmd migrate ]

let () =
  Mirage_crypto_rng_unix.initialize ();
  Cmdliner.Term.(exit @@ eval_choice Cmdline.default_cmd cmds)
