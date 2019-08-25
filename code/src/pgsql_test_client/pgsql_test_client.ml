module Oth_abb = Oth_abb.Make (Abb)

let host = Sys.argv.(1)

let user = Sys.argv.(2)

let database = Sys.argv.(3)

let tls_config =
  let cfg = Otls.Tls_config.create () in
  Otls.Tls_config.insecure_noverifycert cfg;
  Otls.Tls_config.insecure_noverifyname cfg;
  cfg

let with_conn f =
  let open Abb.Future.Infix_monad in
  Pgsql_io.create ~tls_config:(`Require tls_config) ~host ~user database
  >>= function
  | Ok conn          ->
      Abbs_future_combinators.with_finally
        (fun () ->
          f conn
          >>= function
          | Ok r    -> Abb.Future.return (Ok r)
          | Error _ -> Abb.Future.return (Error ()))
        ~finally:(fun () -> Abbs_future_combinators.ignore (Pgsql_io.destroy conn))
  | Error (_ as err) ->
      Logs.err (fun m -> m "%s" (Pgsql_io.show_create_err err));
      Abb.Future.return (Error ())

let test_create_table =
  Oth_abb.test ~desc:"Create table" ~name:"create_table" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let sql =
          Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT, age INTEGER)")
        in
        let rf =
          Pgsql_io.Row_func.make
            sql
            ~init:()
            ~f:(fun () -> ())
            ~fin:(fun () -> Abb.Future.return (Ok ()))
        in
        Pgsql_io.Prepared_stmt.create conn sql
        >>= fun stmt ->
        ( Pgsql_io.Prepared_stmt.execute stmt rf
          : ('a, Pgsql_io.Prepared_stmt.exec_err) result Abb.Future.t
          :> ('a, [> Pgsql_io.Prepared_stmt.exec_err | Pgsql_io.Prepared_stmt.create_err ]) result
             Abb.Future.t )
        >>= fun () -> Pgsql_io.Prepared_stmt.destroy stmt
      in
      with_conn f
      >>= fun r ->
      assert (r = Ok ());
      Abb.Future.return ())

let test_insert_row =
  Oth_abb.test ~desc:"Insert row" ~name:"insert_row" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT, age INTEGER)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(sql /^ "INSERT INTO foo VALUES($1, $2)" /% Var.text /% Var.integer)
        in
        let create_rf =
          Pgsql_io.Row_func.make
            create_sql
            ~init:()
            ~f:(fun () -> ())
            ~fin:(fun () -> Abb.Future.return (Ok ()))
        in
        let insert_rf =
          Pgsql_io.Row_func.make
            insert_sql
            ~init:()
            ~f:(fun () -> ())
            ~fin:(fun () -> Abb.Future.return (Ok ()))
        in
        Pgsql_io.Prepared_stmt.create conn create_sql
        >>= fun create_stmt ->
        Pgsql_io.Prepared_stmt.create conn insert_sql
        >>= fun insert_stmt ->
        ( Pgsql_io.Prepared_stmt.execute create_stmt create_rf
          : ('a, Pgsql_io.Prepared_stmt.exec_err) result Abb.Future.t
          :> ('a, [> Pgsql_io.Prepared_stmt.exec_err | Pgsql_io.Prepared_stmt.create_err ]) result
             Abb.Future.t )
        >>= fun () ->
        ( Pgsql_io.Prepared_stmt.execute insert_stmt insert_rf "Testy McTestface" (Int32.of_int 36)
          : ('a, Pgsql_io.Prepared_stmt.exec_err) result Abb.Future.t
          :> ('a, [> Pgsql_io.Prepared_stmt.exec_err | Pgsql_io.Prepared_stmt.create_err ]) result
             Abb.Future.t )
        >>= fun () ->
        Pgsql_io.Prepared_stmt.destroy create_stmt
        >>= fun () -> Pgsql_io.Prepared_stmt.destroy insert_stmt
      in
      with_conn f
      >>= fun r ->
      assert (r = Ok ());
      Abb.Future.return ())

let test_fetch_row =
  Oth_abb.test ~desc:"Fetch row" ~name:"fetch_row" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT, age INTEGER)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(sql /^ "INSERT INTO foo VALUES($1, $2)" /% Var.text /% Var.integer)
        in
        let fetch_sql =
          Pgsql_io.Typed_sql.(
            sql
            // Ret.text
            /^ "SELECT DISTINCT name FROM foo WHERE name = $1 AND age = $2"
            /% Var.text
            /% Var.integer)
        in
        let make_rf sql =
          Pgsql_io.Row_func.make
            sql
            ~init:()
            ~f:(fun () -> ())
            ~fin:(fun () -> Abb.Future.return (Ok ()))
        in
        let create_rf = make_rf create_sql in
        let insert_rf = make_rf insert_sql in
        let fetch_rf =
          Pgsql_io.Row_func.make
            fetch_sql
            ~init:[]
            ~f:(fun acc name -> name :: acc)
            ~fin:(fun acc -> Abb.Future.return (Ok acc))
        in
        Pgsql_io.Prepared_stmt.create conn create_sql
        >>= fun create_stmt ->
        Pgsql_io.Prepared_stmt.create conn insert_sql
        >>= fun insert_stmt ->
        Pgsql_io.Prepared_stmt.create conn fetch_sql
        >>= fun fetch_stmt ->
        ( Pgsql_io.Prepared_stmt.execute create_stmt create_rf
          : ('a, Pgsql_io.Prepared_stmt.exec_err) result Abb.Future.t
          :> ('a, [> Pgsql_io.Prepared_stmt.exec_err | Pgsql_io.Prepared_stmt.create_err ]) result
             Abb.Future.t )
        >>= fun () ->
        ( Pgsql_io.Prepared_stmt.execute insert_stmt insert_rf "Testy McTestface" (Int32.of_int 36)
          : ('a, Pgsql_io.Prepared_stmt.exec_err) result Abb.Future.t
          :> ('a, [> Pgsql_io.Prepared_stmt.exec_err | Pgsql_io.Prepared_stmt.create_err ]) result
             Abb.Future.t )
        >>= fun () ->
        ( Pgsql_io.Prepared_stmt.execute fetch_stmt fetch_rf "Testy McTestface" (Int32.of_int 36)
          : (string list, Pgsql_io.Prepared_stmt.exec_err) result Abb.Future.t
          :> ( string list,
               [> Pgsql_io.Prepared_stmt.exec_err | Pgsql_io.Prepared_stmt.create_err ] )
             result
             Abb.Future.t )
        >>= fun acc ->
        Pgsql_io.Prepared_stmt.destroy create_stmt
        >>= fun () ->
        Pgsql_io.Prepared_stmt.destroy insert_stmt
        >>= fun () ->
        Pgsql_io.Prepared_stmt.destroy fetch_stmt >>= fun () -> Abb.Future.return (Ok acc)
      in
      with_conn f
      >>= fun r ->
      assert (r = Ok [ "Testy McTestface" ]);
      Abb.Future.return ())

let test_tx_success =
  Oth_abb.test ~desc:"Transaction success" ~name:"tx_success" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT, age INTEGER)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(sql /^ "INSERT INTO foo VALUES($1, $2)" /% Var.text /% Var.integer)
        in
        let make_rf sql =
          Pgsql_io.Row_func.make
            sql
            ~init:()
            ~f:(fun () -> ())
            ~fin:(fun () -> Abb.Future.return (Ok ()))
        in
        let create_rf = make_rf create_sql in
        let insert_rf = make_rf insert_sql in
        Pgsql_io.tx conn ~f:(fun () ->
            Pgsql_io.Prepared_stmt.create conn create_sql
            >>= fun create_stmt ->
            Pgsql_io.Prepared_stmt.create conn insert_sql
            >>= fun insert_stmt ->
            print_endline "here";
            ( Pgsql_io.Prepared_stmt.execute create_stmt create_rf
              : ('a, Pgsql_io.Prepared_stmt.exec_err) result Abb.Future.t
              :> ( 'a,
                   [> Pgsql_io.Prepared_stmt.exec_err | Pgsql_io.Prepared_stmt.create_err ] )
                 result
                 Abb.Future.t )
            >>= fun () ->
            print_endline "there";
            ( Pgsql_io.Prepared_stmt.execute
                insert_stmt
                insert_rf
                "Testy McTestface"
                (Int32.of_int 36)
              : ('a, Pgsql_io.Prepared_stmt.exec_err) result Abb.Future.t
              :> ( 'a,
                   [> Pgsql_io.Prepared_stmt.exec_err | Pgsql_io.Prepared_stmt.create_err ] )
                 result
                 Abb.Future.t ))
      in
      with_conn f
      >>= fun r ->
      assert (r = Ok ());
      Abb.Future.return ())

let test =
  Oth_abb.(
    to_sync_test (serial [ test_create_table; test_insert_row; test_fetch_row; test_tx_success ]))

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
      Format.kfprintf k ppf ("[%s]%a @[" ^^ fmt ^^ "@]@.") time_str Logs.pp_header (level, h)
    in
    msgf @@ fun ?header ?tags fmt -> with_stamp header tags k ppf fmt
  in
  { Logs.report }

let () =
  Random.self_init ();
  Logs.set_reporter (reporter Format.std_formatter);
  Logs.set_level ~all:true (Some Logs.Debug);
  Oth.run test
