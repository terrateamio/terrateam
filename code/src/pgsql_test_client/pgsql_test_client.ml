module Oth_abb = Oth_abb.Make (Abb)

let host = Sys.argv.(1)
let user = Sys.argv.(2)
let database = Sys.argv.(3)
let passwd = Sys.argv.(4)

module Sql = struct
  let drop_foo = Pgsql_io.Typed_sql.(sql /^ "drop table if exists foo")
end

let tls_config =
  let cfg = Otls.Tls_config.create () in
  Otls.Tls_config.insecure_noverifycert cfg;
  Otls.Tls_config.insecure_noverifyname cfg;
  cfg

let with_conn :
      'e.
      (Pgsql_io.t -> ('a, ([> Pgsql_io.create_err ] as 'e)) result Abb.Future.t) ->
      ('a, 'e) result Abb.Future.t =
 fun f ->
  let open Abb.Future.Infix_monad in
  Pgsql_io.create ~tls_config:(`Require tls_config) ~host ~user ~passwd database
  >>= function
  | Ok conn ->
      Abbs_future_combinators.with_finally
        (fun () ->
          Pgsql_io.Prepared_stmt.execute conn Sql.drop_foo
          >>= function
          | Ok () -> f conn
          | Error err ->
              Logs.err (fun m -> m "%s" (Pgsql_io.show_err err));
              assert false)
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
          Pgsql_io.Typed_sql.(
            sql /^ "INSERT INTO foo VALUES($name, $age)" /% Var.text "name" /% Var.integer "age")
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

let test_insert_row_null =
  Oth_abb.test ~desc:"Insert row with null" ~name:"insert_row_null" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo_null (name TEXT, age INTEGER)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(
            sql
            /^ "INSERT INTO foo_null VALUES($name, $age)"
            /% Var.text "name"
            /% Var.option (Var.integer "age"))
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
        Pgsql_io.Prepared_stmt.bind insert_stmt insert_rf "Testy McTestface" None
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
          Pgsql_io.Typed_sql.(
            sql /^ "INSERT INTO foo VALUES($name, $age)" /% Var.text "name" /% Var.integer "age")
        in
        let fetch_sql =
          Pgsql_io.Typed_sql.(
            sql
            // Ret.text
            /^ "SELECT DISTINCT name FROM foo WHERE name = $name AND age = $age"
            /% Var.text "name"
            /% Var.integer "age")
        in
        let make_rf sql = Pgsql_io.Row_func.ignore sql in
        let create_rf = make_rf create_sql in
        let insert_rf = make_rf insert_sql in
        let fetch_rf = Pgsql_io.Row_func.map fetch_sql ~f:(fun name -> name) in
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
      >>= function
      | Ok r ->
          assert (r = [ "Testy McTestface" ]);
          Abb.Future.return ()
      | Error #Pgsql_io.create_err -> assert false
      | Error #Pgsql_io.err -> assert false)

let test_fetch_all_rows =
  Oth_abb.test ~desc:"Fetch all rows" ~name:"fetch_rows" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "create table foo (name text primary key, age integer)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(
            sql
            /^ "insert into foo (name, age) values($name, $age)"
            /% Var.text "name"
            /% Var.smallint "age")
        in
        let fetch_sql =
          Pgsql_io.Typed_sql.(sql // Ret.text // Ret.integer /^ "SELECT name, age FROM foo")
        in
        let fetch_rf = Pgsql_io.Row_func.map fetch_sql ~f:(fun name age -> (name, age)) in
        Pgsql_io.Prepared_stmt.execute conn create_sql
        >>= fun () ->
        Pgsql_io.Prepared_stmt.execute conn insert_sql "Test" 26
        >>= fun () ->
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
      | Ok r ->
          assert (List.length r = 1);
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
          Pgsql_io.Typed_sql.(
            sql /^ "INSERT INTO foo VALUES($name, $age)" /% Var.text "name" /% Var.integer "age")
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

let test_multiple_tx_success =
  Oth_abb.test ~desc:"Multiple transaction success" ~name:"multiple_tx_success" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT, age INTEGER)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(
            sql /^ "INSERT INTO foo VALUES($name, $age)" /% Var.text "name" /% Var.integer "age")
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
        >>= fun () ->
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
      >>= function
      | Ok r ->
          assert (r = ());
          Abb.Future.return ()
      | Error #Pgsql_io.create_err -> assert false
      | Error #Pgsql_io.err -> assert false)

let test_with_cursor =
  Oth_abb.test ~desc:"With Cursor" ~name:"with_cursor" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "create table foo (name text primary key, age integer)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(
            sql
            /^ "insert into foo (name, age) values($name, $age)"
            /% Var.text "name"
            /% Var.smallint "age")
        in
        let fetch_sql =
          Pgsql_io.Typed_sql.(sql // Ret.text // Ret.integer /^ "SELECT name, age FROM foo")
        in
        let fetch_rf = Pgsql_io.Row_func.map fetch_sql ~f:(fun name age -> (name, age)) in
        Pgsql_io.Prepared_stmt.execute conn create_sql
        >>= fun () ->
        Pgsql_io.Prepared_stmt.execute conn insert_sql "Test" 26
        >>= fun () ->
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
      | Ok r ->
          assert (List.length r = 1);
          Abb.Future.return ()
      | Error err -> assert false)

let test_bad_bind_too_few_args =
  Oth_abb.test ~desc:"Bad Bind Too Few Arguments" ~name:"bad_bind_too_few" (fun () ->
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT, age INTEGER)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(sql /^ "INSERT INTO foo VALUES($name, $age)" /% Var.text "name")
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
        Pgsql_io.Prepared_stmt.bind insert_stmt insert_rf "Testy McTestface"
        >>= fun cursor ->
        Pgsql_io.Cursor.execute cursor
        >>= fun () ->
        Pgsql_io.Prepared_stmt.destroy create_stmt
        >>= fun () -> Pgsql_io.Prepared_stmt.destroy insert_stmt
      in
      let open Abb.Future.Infix_monad in
      with_conn f
      >>= function
      | Ok _ -> assert false
      | Error (#Pgsql_io.sql_parse_err as err) ->
          assert (err = `Unknown_variable "age");
          Abb.Future.return ()
      | Error #Pgsql_io.create_err -> assert false
      | Error #Pgsql_io.err -> assert false)

let test_array =
  Oth_abb.test ~desc:"Array" ~name:"array" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let sql =
          Pgsql_io.Typed_sql.(
            sql
            // Ret.text
            // Ret.integer
            // Ret.option Ret.integer
            /^ "select * from unnest ($name, $age, $other)"
            /% Var.str_array (Var.varchar "name")
            /% Var.array (Var.integer "age")
            /% Var.array (Var.option (Var.integer "other")))
        in
        let rf =
          Pgsql_io.Row_func.map sql ~f:(fun name age other ->
              (name, Int32.to_int age, CCOption.map Int32.to_int other))
        in
        Pgsql_io.Prepared_stmt.create conn sql
        >>= fun stmt ->
        Pgsql_io.Prepared_stmt.bind
          stmt
          rf
          [ "na\\\"me1"; "name2" ]
          [ Int32.of_int 4; Int32.of_int 5 ]
          [ None; Some (Int32.of_int 10) ]
        >>= fun cursor -> Pgsql_io.Cursor.with_cursor cursor ~f:Pgsql_io.Cursor.fetch
      in
      with_conn f
      >>= function
      | Ok r ->
          assert (r = [ ("na\\\"me1", 4, None); ("name2", 5, Some 10) ]);
          Abb.Future.return ()
      | Error #Pgsql_io.create_err -> assert false
      | Error #Pgsql_io.err -> assert false)

let test_insert_execute =
  Oth_abb.test ~desc:"Insert row execute" ~name:"insert_row_execute" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT, age INTEGER)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(
            sql /^ "INSERT INTO foo VALUES($name, $age)" /% Var.text "name" /% Var.integer "age")
        in
        Pgsql_io.Prepared_stmt.execute conn create_sql
        >>= fun () ->
        Pgsql_io.Prepared_stmt.execute conn insert_sql "Testy McTestface" (Int32.of_int 36)
      in
      with_conn f
      >>= fun r ->
      assert (r = Ok ());
      Abb.Future.return ())

let test_stmt_fetch =
  Oth_abb.test ~desc:"Statement_fetch" ~name:"Statement fetch" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "create table foo (name text primary key, age integer)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(
            sql
            /^ "insert into foo (name, age) values($name, $age)"
            /% Var.text "name"
            /% Var.smallint "age")
        in
        let fetch_sql =
          Pgsql_io.Typed_sql.(sql // Ret.text // Ret.integer /^ "SELECT name, age FROM foo")
        in
        Pgsql_io.Prepared_stmt.execute conn create_sql
        >>= fun () ->
        Pgsql_io.Prepared_stmt.execute conn insert_sql "Test" 26
        >>= fun () ->
        Pgsql_io.Prepared_stmt.fetch conn fetch_sql ~f:(fun name age -> (name, age))
        >>= fun acc -> Abb.Future.return (Ok acc)
      in
      with_conn f
      >>= function
      | Ok r ->
          assert (List.length r = 1);
          Abb.Future.return ()
      | Error err -> assert false)

let test_integrity_fail =
  Oth_abb.test ~desc:"Integrity fail" ~name:"integrity_fail" (fun () ->
      let open Abb.Future.Infix_monad in
      let f in_tx trigger conn =
        let create_sql =
          Pgsql_io.Typed_sql.(
            sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT PRIMARY KEY, age INTEGER)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(
            sql /^ "INSERT INTO foo VALUES($name, $age)" /% Var.text "name" /% Var.integer "age")
        in
        Pgsql_io.tx conn ~f:(fun () ->
            let open Abbs_future_combinators.Infix_result_monad in
            Abbs_future_combinators.to_result (Abb.Future.Promise.set in_tx ())
            >>= fun () ->
            Abbs_future_combinators.to_result trigger
            >>= fun () ->
            Pgsql_io.Prepared_stmt.execute conn create_sql
            >>= fun () ->
            Pgsql_io.Prepared_stmt.execute conn insert_sql "Testy McTestface" (Int32.of_int 36))
      in
      let check_err r1 r2 =
        match (r1, r2) with
        | _, Error (`Integrity_err _) | Error (`Integrity_err _), _ -> Ok ()
        | _ -> Error ()
      in
      let in_tx_left = Abb.Future.Promise.create () in
      let in_tx_right = Abb.Future.Promise.create () in
      let trigger_tx = Abb.Future.Promise.create () in
      let trigger_tx_fut = Abb.Future.Promise.future trigger_tx in
      Abb.Future.fork
        Abb.Future.Infix_app.(
          check_err
          <$> with_conn (f in_tx_left trigger_tx_fut)
          <*> with_conn (f in_tx_right trigger_tx_fut))
      >>= fun test ->
      Abb.Future.Infix_app.(
        (fun () () -> ())
        <$> Abb.Future.Promise.future in_tx_left
        <*> Abb.Future.Promise.future in_tx_right)
      >>= fun () ->
      Abb.Future.Promise.set trigger_tx ()
      >>= fun () ->
      test
      >>= fun r ->
      assert (r = Ok ());
      Abb.Future.return ())

let test_integrity_recover =
  Oth_abb.test ~desc:"Integrity error recover" ~name:"integrity_recover" (fun () ->
      let open Abb.Future.Infix_monad in
      let f in_tx trigger conn =
        let create_sql =
          Pgsql_io.Typed_sql.(
            sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT PRIMARY KEY, age INTEGER)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(
            sql /^ "INSERT INTO foo VALUES($name, $age)" /% Var.text "name" /% Var.integer "age")
        in
        Pgsql_io.tx conn ~f:(fun () ->
            let open Abbs_future_combinators.Infix_result_monad in
            Abbs_future_combinators.to_result (Abb.Future.Promise.set in_tx ())
            >>= fun () ->
            Abbs_future_combinators.to_result trigger
            >>= fun () ->
            Pgsql_io.Prepared_stmt.execute conn create_sql
            >>= fun () ->
            Pgsql_io.Prepared_stmt.execute conn insert_sql "Testy McTestface" (Int32.of_int 36))
        >>= function
        | Ok () -> Abb.Future.return (Ok `Ok)
        | Error (`Integrity_err _) ->
            let open Abbs_future_combinators.Infix_result_monad in
            Pgsql_io.Prepared_stmt.execute conn insert_sql "Testy RecoverFace" (Int32.of_int 36)
            >>= fun () -> Abb.Future.return (Ok `Integrity)
        | Error _ as err -> Abb.Future.return err
      in
      let check_err r1 r2 =
        match (r1, r2) with
        | _, Ok `Integrity | Ok `Integrity, _ -> Ok ()
        | _, Error (#Pgsql_io.err as err) | Error (#Pgsql_io.err as err), _ ->
            failwith (Pgsql_io.show_err err)
        | _, _ -> failwith "missing integrity failure"
      in
      let in_tx_left = Abb.Future.Promise.create () in
      let in_tx_right = Abb.Future.Promise.create () in
      let trigger_tx = Abb.Future.Promise.create () in
      let trigger_tx_fut = Abb.Future.Promise.future trigger_tx in
      Abb.Future.fork
        Abb.Future.Infix_app.(
          check_err
          <$> with_conn (f in_tx_left trigger_tx_fut)
          <*> with_conn (f in_tx_right trigger_tx_fut))
      >>= fun test ->
      Abb.Future.Infix_app.(
        (fun () () -> ())
        <$> Abb.Future.Promise.future in_tx_left
        <*> Abb.Future.Promise.future in_tx_right)
      >>= fun () ->
      Abb.Future.Promise.set trigger_tx ()
      >>= fun () ->
      test
      >>= fun r ->
      assert (r = Ok ());
      Abb.Future.return ())

let test_rollback =
  Oth_abb.test ~desc:"Rollback" ~name:"rollback" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let create_sql =
          Pgsql_io.Typed_sql.(
            sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT PRIMARY KEY, age INTEGER)")
        in
        let insert_sql =
          Pgsql_io.Typed_sql.(
            sql /^ "INSERT INTO foo VALUES($name, $age)" /% Var.text "name" /% Var.integer "age")
        in
        let select_sql =
          Pgsql_io.Typed_sql.(
            sql // (* name *) Ret.varchar // (* age *) Ret.integer /^ "SELECT * FROM foo")
        in
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_io.Prepared_stmt.execute conn create_sql
        >>= fun () ->
        let open Abb.Future.Infix_monad in
        Pgsql_io.tx conn ~f:(fun () ->
            let open Abbs_future_combinators.Infix_result_monad in
            Pgsql_io.Prepared_stmt.execute conn insert_sql "Testy McTestface" (Int32.of_int 36)
            >>= fun () -> Abb.Future.return (Error `Foo))
        >>= fun _ ->
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_io.tx conn ~f:(fun () ->
            Pgsql_io.Prepared_stmt.fetch conn select_sql ~f:(fun name age -> (name, age)))
        >>= fun r ->
        assert (r = []);
        Abb.Future.return (Ok ())
      in
      with_conn f
      >>= fun r ->
      assert (r = Ok ());
      Abb.Future.return ())

let test_bad_state =
  Oth_abb.test ~desc:"Conn in bad state" ~name:"bad_state" (fun () ->
      let open Abb.Future.Infix_monad in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        let create_sql =
          Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT, age INTEGER)")
        in
        let insert_bad_sql =
          Pgsql_io.Typed_sql.(
            sql
            /^ "INSERT INTO foo (name, age) VALUES($name, age)"
            /% Var.text "name"
            /% Var.integer "age")
        in
        let insert_good_sql =
          Pgsql_io.Typed_sql.(
            sql
            /^ "INSERT INTO foo (name, age) VALUES($name, $age)"
            /% Var.text "name"
            /% Var.integer "age")
        in
        Pgsql_io.Prepared_stmt.execute conn create_sql
        >>= fun () ->
        let open Abb.Future.Infix_monad in
        Pgsql_io.Prepared_stmt.execute conn insert_bad_sql "Testy McTestface" (Int32.of_int 36)
        >>= function
        | Error _ ->
            Pgsql_io.Prepared_stmt.execute conn insert_good_sql "Testy McTestface" (Int32.of_int 36)
        | Ok _ -> assert false
      in
      with_conn f
      >>= function
      | Ok () -> Abb.Future.return ()
      | Error (#Pgsql_io.err as err) ->
          print_endline (Pgsql_io.show_err err);
          assert false
      | Error _ -> assert false)

let test_concurrent_exn_raise =
  Oth_abb.test ~name:"Concurrent Exn Raise" (fun () ->
      let create_sql =
        Pgsql_io.Typed_sql.(sql /^ "CREATE TABLE IF NOT EXISTS foo (name TEXT, age INTEGER)")
      in
      let insert_good_sql =
        Pgsql_io.Typed_sql.(
          sql
          /^ "INSERT INTO foo (name, age) VALUES($name, $age)"
          /% Var.text "name"
          /% Var.integer "age")
      in
      let f conn =
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_io.Prepared_stmt.execute conn create_sql
        >>= fun () ->
        let open Abb.Future.Infix_monad in
        let in_tx = Abb.Future.Promise.create () in
        Abb.Future.await
          Abb.Future.Infix_app.(
            (fun _ res ->
              match res with
              | Ok () -> ()
              | Error (#Pgsql_io.err as err) ->
                  print_endline (Pgsql_io.show_err err);
                  assert false
              | Error _ -> assert false)
            <$> (let open Abb.Future.Infix_monad in
                Abb.Future.Promise.future in_tx
                >>= fun () -> Abb.Sys.sleep 0.0 >>= fun () -> raise (Failure "crash"))
            <*> Pgsql_io.tx conn ~f:(fun () ->
                    let open Abbs_future_combinators.Infix_result_monad in
                    Abbs_future_combinators.to_result (Abb.Future.Promise.set in_tx ())
                    >>= fun () ->
                    Pgsql_io.Prepared_stmt.execute conn insert_good_sql "foo bar" 12l
                    >>= fun () -> Pgsql_io.Prepared_stmt.execute conn insert_good_sql "foo" 12l))
        >>= function
        | `Det () -> assert false
        | `Exn (_, _) ->
            Pgsql_io.(
              tx conn ~f:(fun () -> Prepared_stmt.execute conn insert_good_sql "foo baz" 13l))
        | `Aborted -> assert false
      in
      let open Abb.Future.Infix_monad in
      with_conn f
      >>= function
      | Ok () -> Abb.Future.return ()
      | Error (#Pgsql_io.err as err) ->
          print_endline (Pgsql_io.show_err err);
          assert false
      | Error _ -> assert false)

let test =
  Oth_abb.(
    to_sync_test
      (serial
         [
           test_create_table;
           test_insert_row;
           test_insert_row_null;
           test_fetch_row;
           test_fetch_all_rows;
           test_tx_success;
           test_multiple_tx_success;
           test_with_cursor;
           test_bad_bind_too_few_args;
           test_array;
           test_insert_execute;
           test_stmt_fetch;
           test_integrity_fail;
           test_integrity_recover;
           test_rollback;
           test_bad_state;
           test_concurrent_exn_raise;
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
