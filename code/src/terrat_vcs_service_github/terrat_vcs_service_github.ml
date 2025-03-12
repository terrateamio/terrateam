module type ROUTES = sig
  val routes :
    Terrat_config.t ->
    Terrat_storage.t ->
    (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
end

module Make (Provider : Terrat_vcs_provider2_github.S) (Routes : ROUTES) = struct
  module Evaluator = Terrat_vcs_event_evaluator.Make (Provider)
  module Events = Terrat_vcs_service_github_ep_events3.Make (Provider)
  module Work_manifest = Terrat_vcs_service_github_ep_work_manifest.Make (Provider)

  module Routes = struct
    module Rt = struct
      let api () = Brtl_rtng.Route.(rel / "api")
      let api_v1 () = Brtl_rtng.Route.(api () / "v1")
      let github_client_id () = Brtl_rtng.Route.(api_v1 () / "github" / "client_id")
      let work_manifest_root base = Brtl_rtng.Route.(base () / "work-manifests")
      let work_manifest base = Brtl_rtng.Route.(work_manifest_root base /% Path.ud Uuidm.of_string)

      let work_manifest_initiate base =
        Brtl_rtng.Route.(
          work_manifest base
          / "initiate"
          /* Body.decode ~json:Terrat_api_work_manifest.Initiate.Request_body.of_yojson ())

      let work_manifest_plan base =
        Brtl_rtng.Route.(
          work_manifest base
          / "plans"
          /* Body.decode ~json:Terrat_api_work_manifest.Plan_create.Request_body.of_yojson ())

      let work_manifest_results base =
        Brtl_rtng.Route.(
          work_manifest base
          /* Body.decode ~json:Terrat_api_work_manifest.Results.Request_body.of_yojson ())

      let work_manifest_access_token base = Brtl_rtng.Route.(work_manifest base / "access-token")
      let github () = Brtl_rtng.Route.(api () / "github")
      let github_v1 () = Brtl_rtng.Route.(github () / "v1")
      let github_events () = Brtl_rtng.Route.(github_v1 () / "events")
      let github_work_manifest_plan () = work_manifest_plan github_v1
      let github_work_manifest_initiate () = work_manifest_initiate github_v1
      let github_work_manifest_results () = work_manifest_results github_v1
      let github_work_manifest_access_token () = work_manifest_access_token github_v1

      let github_get_work_manifest_plan () =
        Brtl_rtng.Route.(
          work_manifest github_v1 / "plans" /? Query.string "path" /? Query.string "workspace")

      let github_callback () =
        Brtl_rtng.Route.(
          github_v1 ()
          / "callback"
          /? Query.string "code"
          /? Query.(option (ud "installation_id" (CCOption.wrap Int64.of_string))))
    end

    let routes config storage =
      Routes.routes config storage
      @ Brtl_rtng.Route.
          [
            (* Work manifests *)
            (`POST, Rt.github_work_manifest_plan () --> Work_manifest.Plans.post config storage);
            (`GET, Rt.github_get_work_manifest_plan () --> Work_manifest.Plans.get config storage);
            (`PUT, Rt.github_work_manifest_results () --> Work_manifest.Results.put config storage);
            ( `POST,
              Rt.github_work_manifest_initiate () --> Work_manifest.Initiate.post config storage );
            ( `POST,
              Rt.github_work_manifest_access_token ()
              --> Work_manifest.Access_token.post config storage );
            (* Github *)
            (`POST, Rt.github_events () --> Events.post config storage);
            ( `GET,
              Rt.github_callback () --> Terrat_vcs_service_github_ep_callback.get config storage );
            ( `GET,
              Rt.github_client_id () --> Terrat_vcs_service_github_ep_client_id.get config storage
            );
          ]
  end

  module Service = struct
    let one_hour = Duration.to_f (Duration.of_hour 1)

    type t = {
      config : Terrat_config.t;
      storage : Terrat_storage.t;
      drift : unit Abb.Future.t;
      flow_state_cleanup : unit Abb.Future.t;
      plan_cleanup : unit Abb.Future.t;
      repo_config_cleanup : unit Abb.Future.t;
    }

    let rec drift config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_scheduled_drift
           (Terrat_vcs_event_evaluator.Ctx.make
              ~config
              ~storage
              ~request_id:(Ouuid.to_string (Ouuid.v4 ()))
              ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> drift config storage

    let rec flow_state_cleanup config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_flow_state_cleanup
           (Terrat_vcs_event_evaluator.Ctx.make
              ~config
              ~storage
              ~request_id:(Ouuid.to_string (Ouuid.v4 ()))
              ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> flow_state_cleanup config storage

    let rec plan_cleanup config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_plan_cleanup
           (Terrat_vcs_event_evaluator.Ctx.make
              ~config
              ~storage
              ~request_id:(Ouuid.to_string (Ouuid.v4 ()))
              ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> plan_cleanup config storage

    let rec repo_config_cleanup config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_repo_config_cleanup
           (Terrat_vcs_event_evaluator.Ctx.make
              ~config
              ~storage
              ~request_id:(Ouuid.to_string (Ouuid.v4 ()))
              ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> repo_config_cleanup config storage

    let start config storage =
      let open Abb.Future.Infix_monad in
      Abb.Future.Infix_app.(
        (fun drift flow_state_cleanup plan_cleanup repo_config_cleanup ->
          (drift, flow_state_cleanup, plan_cleanup, repo_config_cleanup))
        <$> Abb.Future.fork (drift config storage)
        <*> Abb.Future.fork (flow_state_cleanup config storage)
        <*> Abb.Future.fork (plan_cleanup config storage)
        <*> Abb.Future.fork (repo_config_cleanup config storage))
      >>= fun (drift, flow_state_cleanup, plan_cleanup, repo_config_cleanup) ->
      Abb.Future.return
        { config; storage; drift; flow_state_cleanup; plan_cleanup; repo_config_cleanup }

    let stop t =
      let open Abb.Future.Infix_monad in
      Abb.Future.abort t.drift
      >>= fun () ->
      Abb.Future.abort t.flow_state_cleanup
      >>= fun () ->
      Abb.Future.abort t.plan_cleanup
      >>= fun () -> Abb.Future.abort t.repo_config_cleanup >>= fun () -> Abb.Future.return ()

    let routes t = Routes.routes t.config t.storage
  end
end
