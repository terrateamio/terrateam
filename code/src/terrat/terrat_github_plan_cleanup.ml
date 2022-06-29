module Sql = struct
  let read fname =
    CCOpt.get_exn_or
      fname
      (CCOpt.map
         (fun s ->
           s
           |> CCString.split_on_char '\n'
           |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
           |> CCString.concat "\n")
         (Terrat_files_sql.read fname))

  let delete_old_plans = Pgsql_io.Typed_sql.(sql /^ read "delete_github_old_terraform_plans.sql")

  let delete_plan =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "delete_github_terraform_plan.sql"
      /% Var.uuid "id"
      /% Var.text "dir"
      /% Var.text "workspace")

  let delete_pull_request_plans =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "delete_github_pull_request_plans.sql"
      /% Var.text "owner"
      /% Var.text "repo"
      /% Var.bigint "pull_number")
end

let one_day = 60.0 *. 60.0 *. 24.0

let rec start storage =
  let open Abb.Future.Infix_monad in
  Pgsql_pool.with_conn storage ~f:(fun db -> Pgsql_io.Prepared_stmt.execute db Sql.delete_old_plans)
  >>= function
  | Ok () ->
      Logs.info (fun m -> m "GITHUB_PLAN_CLEANUP : SUCCESS");
      Abb.Sys.sleep one_day >>= fun () -> start storage
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "GITHUB_PLAN_CLEANUP : ERROR : %s" (Pgsql_pool.show_err err));
      Abb.Sys.sleep one_day >>= fun () -> start storage
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "GITHUB_PLAN_CLEANUP : ERROR : %s" (Pgsql_io.show_err err));
      Abb.Sys.sleep one_day >>= fun () -> start storage

let clean ~work_manifest ~dir ~workspace db =
  let open Abb.Future.Infix_monad in
  Pgsql_io.Prepared_stmt.execute db Sql.delete_plan work_manifest dir workspace
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#Pgsql_io.err as err) -> Abb.Future.return (Error err)

let clean_pull_request ~owner ~repo ~pull_number db =
  let open Abb.Future.Infix_monad in
  Pgsql_io.Prepared_stmt.execute
    db
    Sql.delete_pull_request_plans
    owner
    repo
    (CCInt64.of_int pull_number)
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#Pgsql_io.err as err) -> Abb.Future.return (Error err)
