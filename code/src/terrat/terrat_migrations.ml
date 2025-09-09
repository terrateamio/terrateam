module Migrate = struct
  type t = Terrat_config.t * Terrat_storage.t * Pgsql_io.t

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

  (* Ensure that only one migration can be run at a time by blocking the whole
     table for update. *)
  let get_migrations_sql =
    Pgsql_io.Typed_sql.(
      sql // Ret.varchar /^ "select name from migrations order by date asc for update")

  let get_migrations (_config, _storage, db) =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_io.Prepared_stmt.execute db create_migrations_table_sql
    >>= fun () -> Pgsql_io.Prepared_stmt.fetch db get_migrations_sql ~f:CCFun.id

  let add_migration (_config, _storage, db) name =
    Pgsql_io.Prepared_stmt.execute db add_migration_sql name

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

let run_file_sql ?(tx = true) fname (config, storage, db) =
  let tx =
    if tx then fun ~f -> f db else fun ~f -> Pgsql_pool.with_conn storage ~f:(fun db -> f db)
  in
  match Terrat_files_migrations.read fname with
  | Some file ->
      let stmts =
        file
        |> CCString.split ~by:";\n\n"
        |> CCList.filter CCFun.(CCString.trim %> CCString.is_empty %> not)
      in
      tx ~f:(fun db ->
          Abbs_future_combinators.List_result.iter
            ~f:(fun stmt ->
              let open Pgsql_io in
              Logs.info (fun m -> m "Performing SQL operation: %s" stmt);
              let stmt_sql = Typed_sql.(sql /^ Pgsql_io.clean_string stmt) in
              Prepared_stmt.execute db stmt_sql)
            stmts)
  | None -> failwith ("Could not load file: " ^ fname)

let add_encryption_key (config, storage, _db) =
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
    ("remake-step-output-table", run_file_sql "2024-11-22-remake-step-output-table.sql");
    ("add-has_changes-to-plans", run_file_sql "2024-12-07-add-has_changes-to-plans.sql");
    ("add-trial-columns", run_file_sql "2025-01-14-add-trial-columns.sql");
    ("add-multiple-drift-schedules", run_file_sql "2025-02-15-add-multiple-drift-schedules.sql");
    ("add-gatekeeping", run_file_sql "2025-03-30-add-gatekeeping.sql");
    ("add-tiers", run_file_sql "2025-04-05-add-tiers.sql");
    ("add-users2-tables", run_file_sql "2025-04-07-refactor-user-tables.sql");
    ("add-tree-builder", run_file_sql "2025-04-11-add-tree-builder.sql");
    ("refactor-rename-core-tables", run_file_sql "2025-04-21-refactor-rename-core-tables.sql");
    ( "refactor-remove-core-table-views",
      run_file_sql "2025-04-21-refactor-delete-core-table-views.sql" );
    ("add-work-manifest-runs-on", run_file_sql "2025-04-29-add-work-manifest-runs-on.sql");
    ( "refactor-prep-github-vcs-mapping",
      run_file_sql "2025-04-28-refactor-prep-for-github-vcs-mapping.sql" );
    ( "refactor-fill-in-missing-github-maps",
      run_file_sql "2025-05-01-refactor-fill-in-missing-github-maps.sql" );
    ("add-repo-tree-id-column", run_file_sql "2025-05-13-add-repo-tree-id-column.sql");
    ("refactor-fill-in-missing-core-ids", Terrat_migrations_ex_150.fill_in_all);
    ( "refactor-remove-null-constraints-on-core-tables",
      run_file_sql "2025-05-19-refactor-remove-null-constraints.sql" );
    ("refactor-add-pkey-indexes", run_file_sql ~tx:false "2025-05-19-refactor-add-pkey-indexes.sql");
    ( "refactor-add-core-table-constraints",
      run_file_sql "2025-05-21-refactor-add-core-table-constraints.sql" );
    ("refactor-swap-primary-keys", run_file_sql "2025-05-01-refactor-swap-primary-keys.sql");
    ( "refactor-drop-legacy-github-columns",
      run_file_sql "2025-05-02-refactor-remove-old-columns.sql" );
    ("fix-slow-applied-dirspace-query", run_file_sql "2025-05-25-fix-slow-queries.sql");
    ("add-gitlab-user-tables", run_file_sql "2025-06-09-add-gitlab-user-tables.sql");
    ("add-gitlab-installations", run_file_sql "2025-06-16-add-gitlab-installations.sql");
    ( "add-pull-request-complete-column",
      run_file_sql "2025-06-30-add-pull-request-complete-column.sql" );
    ( "add-pull-request-query-indices",
      run_file_sql ~tx:false "2025-07-01-add-pull-request-query-indices.sql" );
    ( "refactor-github-dirspace-locking-phase-1",
      run_file_sql "2025-07-07-refactor-github-dirspace-locking-phase-1.sql" );
    ( "refactor-github-dirspace-locking-phase-2",
      run_file_sql "2025-07-07-refactor-github-dirspace-locking-phase-2.sql" );
    ("refactor-github-dirspace-locking-phase-3.1", Terrat_migrations_ex_568.run_github);
    ( "refactor-gihtub-dirspace-locking-phase-3.2",
      run_file_sql "2025-07-09-refactor-github-dirspace-locking-phase-3.sql" );
    ( "refactor-gitlab-dirspace-locking-phase-1",
      run_file_sql "2025-07-14-refactor-gitlab-dirspace-locking-phase-1.sql" );
    ("refactor-gitlab-dirspace-locking-phase-2", Terrat_migrations_ex_568.run_gitlab);
    ( "refactor-gitlab-dirspace-locking-phase-3",
      run_file_sql "2025-07-14-refactor-gitlab-dirspace-locking-phase-3.sql" );
    ( "fix-make-gitlab-tables-closer-to-github",
      run_file_sql "2025-07-15-fix-make-gitlab-tables-match-github-closer.sql" );
    ( "refactor-manage-github-maps-via-triggers",
      run_file_sql "2025-07-22-refactor-manage-github-maps-via-triggers.sql" );
    ("fix-gitlab-installation-state", run_file_sql "2025-07-21-fix-gitlab-installation-state.sql");
    ("add-github-emails-table", run_file_sql "2025-08-19-add-emails-table.sql");
    ("add-comment-tracking", run_file_sql "2025-08-20-add-comment-tracking.sql");
    ( "fix-missing-repository-mappings",
      run_file_sql "2025-08-21-fix-missing-repository-mappings.sql" );
    ("refactor-gates-primary-key", run_file_sql "2025-09-04-refactor-gates-primary-key.sql");
    ("add-primary-email-field", run_file_sql "2025-09-09-add-primary-email-field.sql");
    ("fix-drift-unlock-abort-wm", run_file_sql "2025-09-09-fix-drift-unlock.sql");
  ]

let run config storage =
  let open Abb.Future.Infix_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.tx db ~f:(fun () -> Mig.run (config, storage, db) migrations))
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error (#Migrate.err as err) -> Abb.Future.return (Error (`Migration_err err))
  | Error (#Mig.err as err) -> Abb.Future.return (Error err)
