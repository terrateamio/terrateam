let src = Logs.Src.create "ep_access_control"

module Logs = (val Logs.src_log src : Logs.LOG)

let ensure_has_access_token_id user ctx =
  match Terrat_user.access_token_id user with
  | Some access_token_id -> Abbs_fc.return_ok access_token_id
  | None -> Abbs_fc.return_err (Brtl_ctx.set_response `Forbidden ctx)

module Refresh = struct
  module Sql = struct
    let select_capabilities_sql =
      Mql_sql.read "select capabilities from access_tokens where id = $access_token_id"

    let select_capabilities () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* capabilities *)
        Ret.(
          option (u json CCFun.([%of_yojson: Terrat_user.Capability.t list] %> CCOption.of_result)))
        /^ select_capabilities_sql
        /% Var.uuid "access_token_id")
  end

  let post _config storage =
    Brtl_ep.run_result_json ~f:(fun ctx ->
        let open Abbs_fc.Infix_result_monad in
        Terrat_session.with_session ~caps:[ Terrat_user.Capability.Access_token_refresh ] ctx
        >>= fun user ->
        ensure_has_access_token_id user ctx
        >>= fun access_token_id ->
        let run =
          Pgsql_pool.with_conn storage ~f:(fun db ->
              Pgsql_io.Prepared_stmt.fetch
                db
                (Sql.select_capabilities ())
                ~f:CCFun.id
                access_token_id
              >>= function
              | [] ->
                  Abbs_fc.return_ok
                    (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx)
              | capabilities :: _ ->
                  let user = Terrat_user.make ~id:(Terrat_user.id user) ?capabilities () in
                  Terrat_user.Token.to_token ~expiration:(Duration.of_min 1) db user
                  >>| fun token ->
                  Brtl_ctx.set_response
                    (Brtl_rspnc.create
                       ~status:`OK
                       (Yojson.Safe.to_string
                       @@ Terrat_api_access_token.Refresh.Responses.OK.(to_yojson { token })))
                    ctx)
        in
        let open Abb.Future.Infix_monad in
        run
        >>= function
        | Ok _ as r -> Abb.Future.return r
        | Error (#Terrat_user.Token.to_token_err as err) ->
            Logs.err (fun m ->
                m
                  "%s : REFRESH : user=%a : %a"
                  (Brtl_ctx.token ctx)
                  Uuidm.pp
                  (Terrat_user.id user)
                  Terrat_user.Token.pp_to_token_err
                  err);
            Abbs_fc.return_err (Brtl_ctx.set_response `Internal_server_error ctx)
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m
                  "%s : REFRESH : user=%a : %a"
                  (Brtl_ctx.token ctx)
                  Uuidm.pp
                  (Terrat_user.id user)
                  Pgsql_pool.pp_err
                  err);
            Abbs_fc.return_err (Brtl_ctx.set_response `Internal_server_error ctx))
end
