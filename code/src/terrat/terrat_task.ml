module Sql = struct
  let insert_task () =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.uuid
      /^ "insert into tasks (name) values ($name) returning id"
      /% Var.text "name")

  let update_task () =
    Pgsql_io.Typed_sql.(
      sql /^ "update tasks set state = $state where id = $id" /% Var.uuid "id" /% Var.text "state")
end

type 'a t = {
  id : 'a;
  name : string;
}

type fresh = unit
type stored = Uuidm.t

let make ~name () = { id = (); name }
let id t = t.id

let store db t =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch db (Sql.insert_task ()) ~f:CCFun.id t.name
  >>= function
  | [] -> assert false
  | id :: _ -> Abb.Future.return (Ok { t with id })

let update_task db id state = Pgsql_io.Prepared_stmt.execute db (Sql.update_task ()) id state
let abort db t = update_task db t.id "aborted"

let run storage t f =
  Abbs_future_combinators.on_failure
    (fun () ->
      let open Abb.Future.Infix_monad in
      Pgsql_pool.with_conn storage ~f:(fun db -> update_task db t.id "running")
      >>= function
      | Ok () -> (
          f ()
          >>= function
          | Ok _ as r ->
              let open Abbs_future_combinators.Infix_result_monad in
              Pgsql_pool.with_conn storage ~f:(fun db -> update_task db t.id "completed")
              >>= fun () -> Abb.Future.return r
          | Error _ as err ->
              let open Abbs_future_combinators.Infix_result_monad in
              Pgsql_pool.with_conn storage ~f:(fun db -> update_task db t.id "failed")
              >>= fun () -> Abb.Future.return err)
      | Error _ as err ->
          let open Abbs_future_combinators.Infix_result_monad in
          Pgsql_pool.with_conn storage ~f:(fun db -> update_task db t.id "failed")
          >>= fun () -> Abb.Future.return err)
    ~failure:(fun () ->
      Abbs_future_combinators.ignore
        (Pgsql_pool.with_conn storage ~f:(fun db -> update_task db t.id "failed")))
