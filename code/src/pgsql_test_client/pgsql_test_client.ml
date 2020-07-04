module Oth_abb = Oth_abb.Make (Abb)

let host = Sys.argv.(1)

let user = Sys.argv.(2)

let database = Sys.argv.(3)

let tls_config =
  let cfg = Otls.Tls_config.create () in
  Otls.Tls_config.insecure_noverifycert cfg;
  Otls.Tls_config.insecure_noverifyname cfg;
  cfg

let with_conn :
      'e. (Pgsql_io.t -> ('a, ([> Pgsql_io.create_err ] as 'e)) result Abb.Future.t) ->
      ('a, 'e) result Abb.Future.t =
 fun f ->
  let open Abb.Future.Infix_monad in
  Pgsql_io.create ~tls_config:(`Require tls_config) ~host ~user database
  >>= function
  | Ok conn   ->
      Abbs_future_combinators.with_finally
        (fun () -> f conn)
        ~finally:(fun () -> Abbs_future_combinators.ignore (Pgsql_io.destroy conn))
  | Error err ->
      Logs.err (fun m -> m "%s" (Pgsql_io.show_create_err err));
      failwith "nyi"

let test_create_table =
  Oth_abb.test ~desc:"Create table" ~name:"create_table" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let sql =
          Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT, age INTEGER)")
        in
        let rf = Pgsql_io.Row_func.ignore sql in
        Pgsql_io.Prepared_stmt.create conn sql
        >>= fun stmt ->
        Pgsql_io.Prepared_stmt.bind stmt rf
        >>= fun cursor ->
        Pgsql_io.Cursor.execute cursor >>= fun () -> Pgsql_io.Prepared_stmt.destroy stmt
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
        let create_rf = Pgsql_io.Row_func.ignore create_sql in
        let insert_rf = Pgsql_io.Row_func.ignore insert_sql in
        Pgsql_io.Prepared_stmt.create conn create_sql
        >>= fun create_stmt ->
        Pgsql_io.Prepared_stmt.bind create_stmt create_rf
        >>= fun cursor ->
        Pgsql_io.Cursor.execute cursor
        >>= fun () ->
        Pgsql_io.Prepared_stmt.create conn insert_sql
        >>= fun insert_stmt ->
        Pgsql_io.Prepared_stmt.bind insert_stmt insert_rf "Testy McTestface" (Int32.of_int 36)
        >>= fun cursor ->
        Pgsql_io.Cursor.execute cursor
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
        let make_rf sql = Pgsql_io.Row_func.ignore sql in
        let create_rf = make_rf create_sql in
        let insert_rf = make_rf insert_sql in
        let fetch_rf = Pgsql_io.Row_func.map fetch_sql (fun acc name -> name :: acc) in
        Pgsql_io.Prepared_stmt.create conn create_sql
        >>= fun create_stmt ->
        Pgsql_io.Prepared_stmt.bind create_stmt create_rf
        >>= fun cursor ->
        Pgsql_io.Cursor.execute cursor
        >>= fun () ->
        Pgsql_io.Prepared_stmt.create conn insert_sql
        >>= fun insert_stmt ->
        Pgsql_io.Prepared_stmt.bind insert_stmt insert_rf "Testy McTestface" (Int32.of_int 36)
        >>= fun cursor ->
        Pgsql_io.Cursor.execute cursor
        >>= fun () ->
        Pgsql_io.Prepared_stmt.create conn fetch_sql
        >>= fun fetch_stmt ->
        Pgsql_io.Prepared_stmt.bind fetch_stmt fetch_rf "Testy McTestface" (Int32.of_int 36)
        >>= fun cursor ->
        Pgsql_io.Cursor.fetch cursor
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

let test_fetch_all_rows =
  Oth_abb.test ~desc:"Fetch all rows" ~name:"fetch_rows" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let fetch_sql =
          Pgsql_io.Typed_sql.(sql // Ret.text // Ret.integer /^ "SELECT name, age FROM foo")
        in
        let fetch_rf = Pgsql_io.Row_func.map fetch_sql (fun acc name age -> (name, age) :: acc) in
        Pgsql_io.Prepared_stmt.create conn fetch_sql
        >>= fun fetch_stmt ->
        Pgsql_io.Prepared_stmt.bind fetch_stmt fetch_rf
        >>= fun cursor ->
        Pgsql_io.Cursor.fetch cursor
        >>= fun acc ->
        Pgsql_io.Prepared_stmt.destroy fetch_stmt >>= fun () -> Abb.Future.return (Ok acc)
      in
      with_conn f
      >>= function
      | Ok r      ->
          assert (List.length r >= 1);
          Abb.Future.return ()
      | Error err -> assert false)

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
        let create_rf = Pgsql_io.Row_func.ignore create_sql in
        let insert_rf = Pgsql_io.Row_func.ignore insert_sql in
        Pgsql_io.(
          tx conn ~f:(fun () ->
              Prepared_stmt.create conn create_sql
              >>= fun create_stmt ->
              Prepared_stmt.bind create_stmt create_rf
              >>= fun cursor ->
              Cursor.execute cursor
              >>= fun () ->
              Prepared_stmt.create conn insert_sql
              >>= fun insert_stmt ->
              Prepared_stmt.bind insert_stmt insert_rf "Testy McTestface" (Int32.of_int 36)
              >>= fun cursor -> Cursor.execute cursor))
      in
      with_conn f
      >>= fun r ->
      assert (r = Ok ());
      Abb.Future.return ())

let test_with_cursor =
  Oth_abb.test ~desc:"With Cursor" ~name:"with_cursor" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let fetch_sql =
          Pgsql_io.Typed_sql.(sql // Ret.text // Ret.integer /^ "SELECT name, age FROM foo")
        in
        let fetch_rf = Pgsql_io.Row_func.map fetch_sql (fun acc name age -> (name, age) :: acc) in
        Pgsql_io.Prepared_stmt.create conn fetch_sql
        >>= fun fetch_stmt ->
        Pgsql_io.Prepared_stmt.bind fetch_stmt fetch_rf
        >>= fun cursor ->
        Pgsql_io.Cursor.with_cursor cursor ~f:Pgsql_io.Cursor.fetch
        >>= fun acc ->
        Pgsql_io.Prepared_stmt.destroy fetch_stmt >>= fun () -> Abb.Future.return (Ok acc)
      in
      with_conn f
      >>= function
      | Ok r      ->
          assert (List.length r >= 1);
          Abb.Future.return ()
      | Error err -> assert false)

let test_bad_bind_too_few_args =
  Oth_abb.test ~desc:"Bad Bind Too Few Arguments" ~name:"bad_bind_too_few" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT, age INTEGER)")
        in
        let insert_sql = Pgsql_io.Typed_sql.(sql /^ "INSERT INTO foo VALUES($1, $2)" /% Var.text) in
        let create_rf = Pgsql_io.Row_func.ignore create_sql in
        let insert_rf = Pgsql_io.Row_func.ignore insert_sql in
        Pgsql_io.Prepared_stmt.create conn create_sql
        >>= fun create_stmt ->
        Pgsql_io.Prepared_stmt.bind create_stmt create_rf
        >>= fun cursor ->
        Pgsql_io.Cursor.execute cursor
        >>= fun () ->
        Pgsql_io.Prepared_stmt.create conn insert_sql
        >>= fun insert_stmt ->
        Pgsql_io.Prepared_stmt.bind insert_stmt insert_rf "Testy McTestface"
        >>= fun cursor ->
        Pgsql_io.Cursor.execute cursor
        >>= fun () ->
        Pgsql_io.Prepared_stmt.destroy create_stmt
        >>= fun () -> Pgsql_io.Prepared_stmt.destroy insert_stmt
      in
      with_conn f
      >>= function
      | Ok _ -> assert false
      | Error (`Unmatching_frame (Pgsql_codec.Frame.Backend.ErrorResponse { msgs })) ->
          assert (CCList.Assoc.get_exn ~eq:Char.equal 'S' msgs = "ERROR");
          assert (CCList.Assoc.get_exn ~eq:Char.equal 'V' msgs = "ERROR");
          assert (CCList.Assoc.get_exn ~eq:Char.equal 'C' msgs = "08P01");
          Abb.Future.return ()
      | Error (`Unmatching_frame _)
      | Error (`Msgs _)
      | Error `E_no_space
      | Error (`Parse_error _)
      | Error `E_address_family_not_supported
      | Error `E_address_not_available
      | Error `Connection_failed
      | Error (`Unexpected _)
      | Error `E_bad_file
      | Error `E_connection_reset
      | Error `E_address_in_use
      | Error `E_invalid
      | Error `E_host_unreachable
      | Error `E_io
      | Error `E_is_connected
      | Error `E_network_unreachable
      | Error `E_access
      | Error `E_connection_refused -> assert false)

let test =
  Oth_abb.(
    to_sync_test
      (serial
         [
           test_create_table;
           test_insert_row;
           test_fetch_row;
           test_fetch_all_rows;
           test_tx_success;
           test_with_cursor;
           test_bad_bind_too_few_args;
         ]))

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
