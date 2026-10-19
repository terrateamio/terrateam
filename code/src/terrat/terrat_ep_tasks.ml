module Sql = struct
  let select_task_sql =
    Mql_sql.read
      "select name, state, to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') from tasks where \
       id = $id and user_id = $user_id"

  let select_task () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* name *)
      Ret.text
      //
      (* state *)
      Ret.u Ret.text (fun s ->
          CCResult.to_opt (Terrat_api_components.Task.State.of_yojson (`String s)))
      //
      (* updated_at *)
      Ret.text
      /^ select_task_sql
      /% Var.uuid "id"
      /% Var.uuid "user_id")
end

let get storage task_id =
  Brtl_ep.run_result_json ~f:(fun ctx ->
      let open Abbs_fc.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user ->
      let open Abb.Future.Infix_monad in
      let id = Uuidm.to_string task_id in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            (Sql.select_task ())
            ~f:(fun name state updated_at ->
              { Terrat_api_components.Task.id; name; state; updated_at })
            task_id
            (Terrat_user.id user))
      >>= function
      | Ok (task :: _) ->
          let body = Terrat_api_components.Task.to_yojson task |> Yojson.Safe.to_string in
          Abbs_fc.return_ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
      | Ok [] ->
          Abbs_fc.return_ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "TASK : %s : GET : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
          Abbs_fc.return_ok
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "TASK : %s : GET : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
          Abbs_fc.return_ok
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
