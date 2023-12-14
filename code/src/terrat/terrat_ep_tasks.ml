module Sql = struct
  let select_task () =
    Pgsql_io.Typed_sql.(
      sql
      // (* name *) Ret.text
      // (* state *) Ret.text
      // (* updated_at *) Ret.text
      /^ "select name, state, to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') from tasks \
          where id = $id"
      /% Var.uuid "id")
end

let get storage task_id =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun _ ->
      let open Abb.Future.Infix_monad in
      let id = Uuidm.to_string task_id in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            (Sql.select_task ())
            ~f:(fun name state updated_at ->
              Terrat_api_components.Task.{ id; name; state; updated_at })
            task_id)
      >>= function
      | Ok (task :: _) ->
          let body = Terrat_api_components.Task.to_yojson task |> Yojson.Safe.to_string in
          Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
      | Ok [] ->
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "TASK : %s : GET : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "TASK : %s : GET : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
