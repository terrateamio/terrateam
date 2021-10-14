module Migrate = struct
  type t = Terrat_config.t * Terrat_storage.t

  type err =
    [ Pgsql_io.err
    | Pgsql_pool.err
    ]

  let create_migrations_table_sql =
    Pgsql_io.Typed_sql.(
      sql
      /^ "create table if not exists migrations (date timestamp default now(), "
      /^ "name varchar(256) not null, "
      /^ "primary key (date, name))")

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
    | None      -> failwith ("Could not load file: " ^ fname)

let migrations =
  [
    ("create-tables", run_file_sql "2021-08-28-initial-tables.sql");
    ("create-user-tables", run_file_sql "2021-09-19-add-users.sql");
    ("create-secrets-tables", run_file_sql "2021-09-21-add-secrets.sql");
    ( "add-github-user-installations-expire",
      run_file_sql "2021-09-23-add-github-user-installations-expire.sql" );
    ("add-installation-config", run_file_sql "2021-09-25-add-config.sql");
    ("add-more-installation-config", run_file_sql "2021-09-28-add-more-installation-config.sql");
    ("add-user-installation-admin", run_file_sql "2021-10-01-add-github-installation-admin.sql");
    ("rename-github-installation", run_file_sql "2021-10-01-rename-github-installation.sql");
    ("add-auto-merge-default", run_file_sql "2021-10-01-add-auto-merge-default.sql");
    ("add-avatar-url", run_file_sql "2021-10-03-add-avatar-url.sql");
    ("add-avatar-urls-to-users", Terrat_migrations_2021_10_03_add_avatar_url.run);
    ("remove-avatar-url-default", run_file_sql "2021-10-03-remove-avatar-url-default.sql");
    ("add-avatar-url-non-null", run_file_sql "2021-10-03-add-avatar-url-non-null.sql");
    ("merge-env-and-secrets", run_file_sql "2021-10-05-merge-env-and-secrets.sql");
    ( "add-env-vars-secret-null-constraint",
      run_file_sql "2021-10-05-add-env-vars-secret-add-null-constraint.sql" );
    ("add-terraform-versions", run_file_sql "2021-10-06-add-terraform-versions.sql");
    ("fix-autoplan-file-list", run_file_sql "2021-10-06-fix-autoplan-file-list.sql");
    ("insert-terraform-versions", run_file_sql "2021-10-06-insert-terraform-versions.sql");
    ( "add-updated-and-user-agent-to-session",
      run_file_sql "2021-10-09-add-updated-and-user-agent-to-sessions.sql" );
    ("add-user-prefs", run_file_sql "2021-10-11-add-user-prefs.sql");
    ("add-user-emails", Terrat_migrations_2021_10_11_add_user_prefs.run);
    ("add-file-support-env-vars", run_file_sql "2021-10-14-add-file-support-env-vars.sql");
  ]

let run config storage = Mig.run (config, storage) migrations
