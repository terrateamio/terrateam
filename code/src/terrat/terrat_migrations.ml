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

let add_encryption_key (config, storage) =
  let key = Mirage_crypto_rng.generate 64 in
  let insert_encryption_key =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into encryption_keys (rank, data) values(0, decode($data, 'base64'))"
      /% Var.(ud (text "data") CCFun.(Cstruct.to_string %> Base64.encode_exn)))
  in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.execute db insert_encryption_key key)

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
    ("add-drift", run_file_sql "2023-01-30-add-drift-tables.sql");
    ("add-drift-unlock", run_file_sql "2023-02-14-add-drift-unlock.sql");
    ("add-encryption-keys-table", run_file_sql "2023-02-22-add-encryption-keys.sql");
    ("add-encryption-key", add_encryption_key);
    ("add-github-account-status", run_file_sql "2023-05-15-add-github-account-status.sql");
    ("add-lock-policy", run_file_sql "2023-05-17-add-lock-policy.sql");
    ("add-lock-policy-none", run_file_sql "2023-05-20-add-lock-policy-none.sql");
    ("remove-github-repo-constraint", run_file_sql "2023-08-02-remove-github-repo-constraint.sql");
    ( "add-base-sha-to-github-dirspaces-pkey",
      run_file_sql "2023-11-09-add-base-sha-to-github-dirspaces-pkey.sql" );
    ("refactor-users", run_file_sql "2023-09-25-refactor-users.sql");
    ("refactor-user-sessions", run_file_sql "2023-09-25-refactor-user-sessions.sql");
    ( "refactor-user-sessions-user-agent",
      run_file_sql "2023-09-25-refactor-user-sessions-user-agent.sql" );
    ("remove-github-users-id", run_file_sql "2023-09-25-remove-github-users-id.sql");
    ( "make-user-session-token-autogen",
      run_file_sql "2023-09-26-make-user-session-token-autogen.sql" );
    ("add-pull-request-title", run_file_sql "2023-10-10-add-pull-request-title.sql");
    ( "add-user-track-on-work-manifest",
      run_file_sql "2023-11-15-add-user-track-on-work-manifest.sql" );
    ("add-user-track-on-pull-request", run_file_sql "2023-11-15-add-user-track-on-pull-request.sql");
    ("add-user-installations-table", run_file_sql "2023-11-18-add-user-installations-table.sql");
    ("add-tasks-table", run_file_sql "2023-12-18-add-tasks-table.sql");
    ( "add-json-dirspaces-to-work-manifests",
      run_file_sql "2024-01-02-add-json-dirspaces-to-work-manifests.sql" );
    ("add-work-manifest-run-kind", run_file_sql "2024-02-02-add-work-manifest-run-kind.sql");
    ("add-github-code-index-table", run_file_sql "2024-02-05-add-code-index-table.sql");
    ("add-index-work-manifests", run_file_sql "2024-02-07-add-index-work-manifest-table.sql");
    ("add-code-index-created_at", run_file_sql "2024-02-14-add-code-index-created_at.sql");
    ("add-drift-schedule-updated_at", run_file_sql "2024-03-02-add-drift-schedule-updated_at.sql");
    ("add-drift-tag-query", run_file_sql "2024-03-06-add-drift-tag-query.sql");
    ("add-repo-setup-flag", run_file_sql "2024-03-28-add-repo-setup-flag.sql");
    ("add-work-manifest-environment", run_file_sql "2024-04-22-add-work-manifest-environment.sql");
    ("add-work-manifest-steps", run_file_sql "2024-08-02-add-work-manifest-steps.sql");
    ("add-flow-states", run_file_sql "2024-08-11-add-flow-states.sql");
    ("add-config-builder", run_file_sql "2024-09-15-add-config-builder-tables.sql");
    ("add-step-output-table", run_file_sql "2024-10-11-add-step-output-table.sql");
  ]

let run config storage = Mig.run (config, storage) migrations
