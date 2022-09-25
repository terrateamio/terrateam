module Migrate = struct
  type t = Terrat_config.t * Terrat_storage.t

  type err =
    [ Pgsql_io.err
    | Pgsql_pool.err
    ]

  let create_migrations_table_sql =
    Pgsql_io.Typed_sql.(
      sql
      /^ "create table if not exists migrations (date timestamp default now(), name varchar(256) \
          primary key)")

  let add_migration_sql =
    Pgsql_io.Typed_sql.(sql /^ "insert into migrations (name) values($name)" /% Var.varchar "name")

  let get_migrations_sql =
    Pgsql_io.Typed_sql.(sql // Ret.varchar /^ "select name from migrations order by date asc")

  let get_migrations (_config, storage) =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.execute db create_migrations_table_sql
        >>= fun () -> Pgsql_io.Prepared_stmt.fetch db get_migrations_sql ~f:CCFun.id)

  let add_migration (_config, storage) name =
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.execute db add_migration_sql name)

  let start_migration _ name =
    Logs.info (fun m -> m "Performing migration for %s" name);
    Abb.Future.return ()

  let complete_migration _ name =
    Logs.info (fun m -> m "Completed migration for %s" name);
    Abb.Future.return ()

  let list_migrations _ ms =
    Logs.info (fun m -> m "Migrations to perform");
    CCList.iter (fun name -> Logs.info (fun m -> m "%s" name)) ms;
    Abb.Future.return ()
end

module Mig = Data_mig.Make (Migrate)

let run_file_sql fname (config, storage) =
  match Terrat_files_migrations.read fname with
  | Some file ->
      let stmts =
        file
        |> CCString.split ~by:";\n\n"
        |> CCList.filter CCFun.(CCString.trim %> CCString.is_empty %> not)
      in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              Abbs_future_combinators.List_result.iter
                ~f:(fun stmt ->
                  let open Pgsql_io in
                  Logs.info (fun m -> m "Performing SQL operation: %s" stmt);
                  let stmt_sql = Typed_sql.(sql /^ stmt) in
                  Prepared_stmt.execute db stmt_sql)
                stmts))
  | None -> failwith ("Could not load file: " ^ fname)

let migrations =
  [
    ("initial-tables", run_file_sql "2021-12-03-initial-tables.sql");
    ("add-github-installation", run_file_sql "2021-12-29-add-github-installation.sql");
    ("add-github-unlock", run_file_sql "2022-04-19-add-github-unlock.sql");
    ("add-github-merged-sha", run_file_sql "2022-04-26-add-merged-sha.sql");
    ("add-github-merged_at", run_file_sql "2022-04-26-add-merged_at.sql");
    ("drop-plan-text", run_file_sql "2022-05-01-remove-plan-text.sql");
    ("add-unsafe-apply", run_file_sql "2022-09-01-add-unsafe-apply.sql");
    ("add-access-denied", run_file_sql "2022-10-29-add-access-denied.sql");
  ]

let run config storage = Mig.run (config, storage) migrations
