module type S = sig
  val vcs : string
end

module Make (P : Terrat_vcs_provider2.S with type Api.Account.Id.t = int) (S : S) = struct
  let src = Logs.Src.create ("vcs_drift_initiate_" ^ S.vcs)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Evaluator2 = Terrat_vcs_event_evaluator2.Make (P)

  let post config storage exec installation_id name repo =
    Brtl_ep.run_result_json ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        let request_id = Brtl_ctx.token ctx in
        Terrat_session.with_session ~caps:[ Terrat_user.Capability.Drift_initiate ] ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            P.enforce_installation_access ~request_id user installation_id db)
        >>= function
        | Ok () ->
            Logs.info (fun m ->
                m
                  "%s : DRIFT_INITIATE : installation_id=%d%s%s"
                  request_id
                  installation_id
                  (CCOption.map_or ~default:"" (fun n -> " : name=" ^ n) name)
                  (CCOption.map_or ~default:"" (fun r -> " : repo=" ^ r) repo));
            Abbs_future_combinators.ignore
              (Abb.Future.fork
                 (Evaluator2.run_missing_drift_schedules
                    ?name
                    ~force:true
                    ?repo
                    ~config
                    ~storage
                    ~exec
                    ()))
            >>= fun () ->
            Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "{}") ctx))
        | Error `Forbidden ->
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "%s : DRIFT_INITIATE : POOL_ERROR : %a" request_id Pgsql_pool.pp_err err);
            Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx)))

  module Rt = struct
    let drift () =
      Brtl_rtng.Route.(
        rel
        / "api"
        / "v1"
        / S.vcs
        / "installations"
        /% Path.int
        / "drift"
        /? Query.(option (string "name"))
        /? Query.(option (string "repo")))
  end

  let routes config storage exec =
    Brtl_rtng.Route.[ (`POST, Rt.drift () --> post config storage exec) ]
end
