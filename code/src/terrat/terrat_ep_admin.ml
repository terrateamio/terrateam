let admin_token_permission ctx admin_token =
  match Brtl_permissions.get_auth ctx with
  | Ok (Brtl_permissions.Auth.Bearer token) -> Abb.Future.return (CCString.equal token admin_token)
  | _ -> Abb.Future.return false

module Drift = struct
  module List = struct
    module Sql = struct
      let read fname =
        CCOption.get_exn_or
          fname
          (CCOption.map
             (fun s ->
               s
               |> CCString.split_on_char '\n'
               |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
               |> CCString.concat "\n")
             (Terrat_files_sql.read fname))

      let select_admin_drift_list () =
        Pgsql_io.Typed_sql.(
          sql
          // (* id *) Ret.uuid
          // (* owner *) Ret.text
          // (* name *) Ret.text
          // (* state *) Ret.text
          // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
          // (* created_at *) Ret.text
          // (* completed_at *) Ret.(option text)
          /^ read "select_github_admin_drift_list.sql")
    end

    let make_drift id owner name state run_type created_at completed_at =
      let open Terrat_api_admin.Drifts.Responses.OK.Results.Items in
      {
        id = Uuidm.to_string id;
        owner;
        name;
        state;
        run_type = Terrat_work_manifest.Unified_run_type.(to_string (of_run_type run_type));
        created_at;
        completed_at;
      }

    let get admin_token config storage ctx =
      Brtl_permissions.with_permissions [ admin_token_permission ] ctx admin_token (fun () ->
          let open Abb.Future.Infix_monad in
          Pgsql_pool.with_conn storage ~f:(fun db ->
              Pgsql_io.Prepared_stmt.fetch db (Sql.select_admin_drift_list ()) ~f:make_drift)
          >>= function
          | Ok results ->
              let response = Terrat_api_admin.Drifts.Responses.OK.{ results } in
              let body =
                response |> Terrat_api_admin.Drifts.Responses.OK.to_yojson |> Yojson.Safe.to_string
              in
              Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m ->
                  m "ADMIN : %s : DRIFTS : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
          | Error _ ->
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
  end
end
