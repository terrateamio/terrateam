module Sql = struct
  let more_rows =
    Pgsql_io.Typed_sql.(
      sql // Ret.bigint /^ "select repository from github_dirspace_locking_migration limit 1")

  let perform_sql =
    {|
     with
     batch as (
         select * from github_dirspace_locking_migration limit 100 for update skip locked
     ),
     deleted as (
         delete from github_dirspace_locking_migration as mig
         using batch
         where batch.repository = mig.repository and batch.pull_number = mig.pull_number
         returning mig.repository, mig.pull_number
     )
     select update_github_pull_request_dirspace_locks(repository, pull_number) from deleted
     |}

  let perform = Pgsql_io.Typed_sql.(sql // Ret.text /^ perform_sql)
end

let rec run_batch storage update while_ =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.tx db ~f:(fun () ->
          while_ db
          >>= function
          | `Cont -> update db >>= fun () -> Abb.Future.return (Ok `Cont)
          | `Done -> Abb.Future.return (Ok `Done)))
  >>= function
  | `Cont -> run_batch storage update while_
  | `Done -> Abb.Future.return (Ok ())

let update' sql db =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch db ~f:(fun x -> x) sql >>= fun _ -> Abb.Future.return (Ok ())

let while' sql db =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch db sql ~f:CCFun.id
  >>= function
  | [] -> Abb.Future.return (Ok `Done)
  | _ :: _ -> Abb.Future.return (Ok `Cont)

let run (config, storage) = run_batch storage (update' Sql.perform) (while' Sql.more_rows)
