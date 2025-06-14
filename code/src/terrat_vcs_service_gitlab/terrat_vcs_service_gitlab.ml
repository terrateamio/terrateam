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
  module Routes = struct
    module Rt = struct
      let api () = Brtl_rtng.Route.(rel / "api")
      let api_v1 () = Brtl_rtng.Route.(api () / "v1")
      let gitlab () = Brtl_rtng.Route.(api () / "gitlab")
      let gitlab_v1 () = Brtl_rtng.Route.(api_v1 () / "gitlab")
      let gitlab_whoami () = Brtl_rtng.Route.(gitlab_v1 () / "whoami")

      let gitlab_callback () =
        Brtl_rtng.Route.(gitlab_v1 () / "callback" /? Query.string "code" /? Query.string "state")

      let gitlab_groups () = Brtl_rtng.Route.(gitlab_v1 () / "groups")
    end

    let routes config storage =
      Routes.routes config storage
      @ Brtl_rtng.Route.
          [
            ( `GET,
              Rt.gitlab_groups () --> Terrat_vcs_service_gitlab_ep_groups.List.get config storage );
            ( `GET,
              Rt.gitlab_callback () --> Terrat_vcs_service_gitlab_ep_callback.get config storage );
            ( `GET,
              Rt.gitlab_whoami () --> Terrat_vcs_service_gitlab_ep_user.Whoami.get config storage );
          ]
  end

  module Service = struct
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

    type t = {
      config : Provider.Api.Config.t;
      storage : Terrat_storage.t;
      whoami : Gitlabc_components.API_Entities_UserPublic.t;
    }

    type vcs_config = Provider.Api.Config.vcs_config

    let name _ = "gitlab"

    let start config vcs_config storage =
      let open Abb.Future.Infix_monad in
      let config = Provider.Api.Config.make ~config ~vcs_config () in
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
          Abb.Future.return (Ok { config; storage; whoami })
      | Error (#Openapic_abb.call_err as err) ->
          Logs.err (fun m -> m "Failed to fetch user: %a" Openapic_abb.pp_call_err err);
          Abb.Future.return (Error `Error)

    let stop t = raise (Failure "nyi")
    let routes t = Routes.routes t.config t.storage

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
