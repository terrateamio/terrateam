let src = Logs.Src.create "vcs_service_gitlab"

module Logs = (val Logs.src_log src : Logs.LOG)

module type ROUTES = sig
  type config

  val routes :
    config ->
    Terrat_storage.t ->
    (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
end

module Make
    (Provider :
      Terrat_vcs_provider2_gitlab.S
        with type Api.Config.t = Terrat_vcs_service_gitlab_provider.Api.Config.t)
    (Routes : ROUTES with type config = Provider.Api.Config.t) =
struct
  module Evaluator = Terrat_vcs_event_evaluator.Make (Provider)
  module Ep_events = Terrat_vcs_service_gitlab_ep_events.Make (Provider)
  module Work_manifest = Terrat_vcs_service_gitlab_ep_work_manifest.Make (Provider)

  type t = {
    config : Provider.Api.Config.t;
    drift : unit Abb.Future.t;
    flow_state_cleanup : unit Abb.Future.t;
    plan_cleanup : unit Abb.Future.t;
    repo_config_cleanup : unit Abb.Future.t;
    storage : Terrat_storage.t;
    whoami : Gitlabc_components.API_Entities_UserPublic.t;
  }

  module Routes = struct
    module Rt = struct
      let api () = Brtl_rtng.Route.(rel / "api")
      let api_v1 () = Brtl_rtng.Route.(api () / "v1")
      let gitlab_v1 () = Brtl_rtng.Route.(api_v1 () / "gitlab")
      let gitlab_whoami () = Brtl_rtng.Route.(gitlab_v1 () / "whoami")
      let gitlab_whoareyou () = Brtl_rtng.Route.(gitlab_v1 () / "whoareyou")
      let gitlab_events () = Brtl_rtng.Route.(gitlab_v1 () / "events")

      (* Pipeline api base *)
      let gitlab_pipeline () = Brtl_rtng.Route.(api () / "gitlab")
      let gitlab_pipeline_v1 () = Brtl_rtng.Route.(gitlab_pipeline () / "v1")

      (* Work manifests *)
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

      let work_manifest_workspaces base = Brtl_rtng.Route.(work_manifest base / "workspaces")

      let work_manifest_results base =
        Brtl_rtng.Route.(
          work_manifest base
          /* Body.decode ~json:Terrat_api_work_manifest.Results.Request_body.of_yojson ())

      (* This is the other group of URLs, which are [/api/gitlab/v1] *)
      let gitlab_work_manifest_plan () = work_manifest_plan gitlab_pipeline_v1
      let gitlab_work_manifest_workspaces () = work_manifest_workspaces gitlab_pipeline_v1
      let gitlab_work_manifest_initiate () = work_manifest_initiate gitlab_pipeline_v1
      let gitlab_work_manifest_results () = work_manifest_results gitlab_pipeline_v1

      let gitlab_get_work_manifest_plan () =
        Brtl_rtng.Route.(
          work_manifest gitlab_pipeline_v1
          / "plans"
          /? Query.string "path"
          /? Query.string "workspace")

      let gitlab_callback () =
        Brtl_rtng.Route.(gitlab_v1 () / "callback" /? Query.string "code" /? Query.string "state")

      let gitlab_groups () = Brtl_rtng.Route.(gitlab_v1 () / "groups")

      let gitlab_groups_is_bot_member () =
        Brtl_rtng.Route.(gitlab_v1 () / "groups" /% Path.int / "is-member")

      let gitlab_installations () = Brtl_rtng.Route.(gitlab_v1 () / "installations")

      let gitlab_installations_webhook () =
        Brtl_rtng.Route.(gitlab_installations () /% Path.int / "webhook")

      (* Installations *)
      let gitlab_installations_repos () =
        Brtl_rtng.Route.(
          gitlab_installations ()
          /% Path.int
          / "repos"
          /? Query.(option (ud_array "page" Brtl_ep_paginate.Param.(of_param Typ.string)))
          /? Query.(option_default 20 (int "limit")))

      let gitlab_installation_dirspaces () =
        Brtl_rtng.Route.(
          gitlab_installations ()
          /% Path.int
          / "dirspaces"
          /? Query.(option (string "q"))
          /? Query.(option (string "tz"))
          /? Query.(
               option
                 (ud_array
                    "page"
                    Brtl_ep_paginate.Param.(
                      of_param Typ.(tuple4 (string, string, string, ud' Uuidm.of_string)))))
          /? Query.(option_default 20 (Query.int "limit")))

      let gitlab_installation_work_manifests () =
        Brtl_rtng.Route.(
          gitlab_installations ()
          /% Path.int
          / "work-manifests"
          /? Query.(option (string "q"))
          /? Query.(option (string "tz"))
          /? Query.(
               option
                 (ud_array
                    "page"
                    Brtl_ep_paginate.Param.(of_param Typ.(tuple (string, ud' Uuidm.of_string)))))
          /? Query.(option_default 20 (Query.int "limit")))

      let gitlab_installation_work_manifest_outputs () =
        Brtl_rtng.Route.(
          gitlab_installations ()
          /% Path.int
          / "work-manifests"
          /% Path.ud Uuidm.of_string
          / "outputs"
          /? Query.(option (string "q"))
          /? Query.(option (string "tz"))
          /? Query.(option (ud_array "page" Brtl_ep_paginate.Param.(of_param Typ.int)))
          /? Query.(option_default 20 (Query.int "limit"))
          /? Query.(option_default false (Query.bool "lite")))
    end

    let routes t =
      let config = t.config in
      let storage = t.storage in
      Routes.routes config storage
      @ Brtl_rtng.Route.
          [
            (* Installations *)
            ( `GET,
              Rt.gitlab_installation_dirspaces ()
              --> Terrat_vcs_service_gitlab_ep_installations.List_dirspaces.get config storage );
            ( `GET,
              Rt.gitlab_installations_repos ()
              --> Terrat_vcs_service_gitlab_ep_installations.List_repos.get config storage );
            ( `GET,
              Rt.gitlab_installation_work_manifests ()
              --> Terrat_vcs_service_gitlab_ep_installations.List_work_manifests.get config storage
            );
            ( `GET,
              Rt.gitlab_installation_work_manifest_outputs ()
              --> Terrat_vcs_service_gitlab_ep_installations.List_work_manifest_outputs.get
                    config
                    storage );
            (* Work manifests *)
            (`POST, Rt.gitlab_work_manifest_plan () --> Work_manifest.Plans.post config storage);
            (`GET, Rt.gitlab_get_work_manifest_plan () --> Work_manifest.Plans.get config storage);
            (`PUT, Rt.gitlab_work_manifest_results () --> Work_manifest.Results.put config storage);
            ( `POST,
              Rt.gitlab_work_manifest_initiate () --> Work_manifest.Initiate.post config storage );
            ( `GET,
              Rt.gitlab_work_manifest_workspaces () --> Work_manifest.Workspaces.get config storage
            );
            (`POST, Rt.gitlab_events () --> Ep_events.post config storage);
            ( `GET,
              Rt.gitlab_installations ()
              --> Terrat_vcs_service_gitlab_ep_installations.List.get config storage );
            ( `GET,
              Rt.gitlab_installations_webhook ()
              --> Terrat_vcs_service_gitlab_ep_installations.Webhook.get config storage );
            ( `GET,
              Rt.gitlab_groups_is_bot_member ()
              --> Terrat_vcs_service_gitlab_ep_groups.Is_member.get t.whoami config storage );
            ( `GET,
              Rt.gitlab_groups () --> Terrat_vcs_service_gitlab_ep_groups.List.get config storage );
            ( `GET,
              Rt.gitlab_callback () --> Terrat_vcs_service_gitlab_ep_callback.get config storage );
            ( `GET,
              Rt.gitlab_whoami () --> Terrat_vcs_service_gitlab_ep_user.Whoami.get config storage );
            ( `GET,
              Rt.gitlab_whoareyou ()
              --> Terrat_vcs_service_gitlab_ep_user.Whoareyou.get t.whoami config storage );
          ]
  end

  module Service = struct
    type nonrec t = t

    module Sql = struct
      let read fname =
        CCOption.get_exn_or
          fname
          (CCOption.map Pgsql_io.clean_string (Terrat_files_gitlab_sql.read fname))

      let select_gitlab_user2_exists =
        Pgsql_io.Typed_sql.(
          sql
          //
          (* created_at *)
          Ret.text
          /^ read "select_gitlab_user2_exists.sql"
          /% Var.uuid "user_id")
    end

    type vcs_config = Provider.Api.Config.vcs_config

    let one_hour = Duration.to_f (Duration.of_hour 1)

    let rec drift config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_scheduled_drift
           (Evaluator.Ctx.make ~config ~storage ~request_id:(Ouuid.to_string (Ouuid.v4 ())) ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> drift config storage

    let rec flow_state_cleanup config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_flow_state_cleanup
           (Evaluator.Ctx.make ~config ~storage ~request_id:(Ouuid.to_string (Ouuid.v4 ())) ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> flow_state_cleanup config storage

    let rec plan_cleanup config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_plan_cleanup
           (Evaluator.Ctx.make ~config ~storage ~request_id:(Ouuid.to_string (Ouuid.v4 ())) ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> plan_cleanup config storage

    let rec repo_config_cleanup config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_repo_config_cleanup
           (Evaluator.Ctx.make ~config ~storage ~request_id:(Ouuid.to_string (Ouuid.v4 ())) ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> repo_config_cleanup config storage

    let name _ = "gitlab"

    let start config vcs_config storage =
      let open Abb.Future.Infix_monad in
      let config = Provider.Api.Config.make ~config ~vcs_config () in
      Abb.Future.Infix_app.(
        (fun drift flow_state_cleanup plan_cleanup repo_config_cleanup ->
          (drift, flow_state_cleanup, plan_cleanup, repo_config_cleanup))
        <$> Abb.Future.fork (drift config storage)
        <*> Abb.Future.fork (flow_state_cleanup config storage)
        <*> Abb.Future.fork (plan_cleanup config storage)
        <*> Abb.Future.fork (repo_config_cleanup config storage))
      >>= fun (drift, flow_state_cleanup, plan_cleanup, repo_config_cleanup) ->
      let access_token = Terrat_config.Gitlab.access_token vcs_config in
      let client =
        Openapic_abb.create
          ~user_agent:"Terrateam"
          ~base_url:(Terrat_config.Gitlab.api_base_url vcs_config)
          (`Bearer access_token)
      in
      Openapic_abb.call client Gitlabc_user.GetApiV3User.(make ())
      >>= function
      | Ok resp ->
          let module U = Gitlabc_components.API_Entities_UserPublic in
          let (`OK whoami) = Openapi.Response.value resp in
          Logs.info (fun m -> m "START : username=%s" whoami.U.username);
          Abb.Future.return
            (Ok
               {
                 config;
                 drift;
                 flow_state_cleanup;
                 plan_cleanup;
                 repo_config_cleanup;
                 storage;
                 whoami;
               })
      | Error (#Openapic_abb.call_err as err) ->
          Logs.err (fun m -> m "Failed to fetch user: %a" Openapic_abb.pp_call_err err);
          Abb.Future.return (Error `Error)

    let stop t = raise (Failure "nyi")
    let routes t = Routes.routes t

    let get_user t user_id =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_pool.with_conn t.storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.fetch db Sql.select_gitlab_user2_exists ~f:CCFun.id user_id
            >>= function
            | [] -> Abb.Future.return (Ok None)
            | _ :: _ -> Abb.Future.return (Ok (Some (Terrat_user.make ~id:user_id ()))))
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "GET_USER : user_id=%a : %a" Uuidm.pp user_id Pgsql_pool.pp_err err);
          Abb.Future.return (Error `Error)
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GET_USER : user_id=%a : %a" Uuidm.pp user_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)
  end
end
