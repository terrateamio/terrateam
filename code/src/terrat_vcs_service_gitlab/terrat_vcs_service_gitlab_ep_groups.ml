module Oauth = Terrat_vcs_service_gitlab_user.Oauth

let src = Logs.Src.create "vcs_service_gitlab_ep_groups"

module Logs = (val Logs.src_log src : Logs.LOG)

module List = struct
  let get' config storage user =
    let open Abbs_future_combinators.Infix_result_monad in
    let vcs_config = Terrat_vcs_service_gitlab_provider.Api.Config.vcs_config config in
    Pgsql_pool.with_conn storage ~f:(fun db -> Oauth.access_token ~config:vcs_config db user)
    >>= fun token ->
    let client =
      Openapic_abb.create
        ~base_url:(Terrat_config.Gitlab.api_base_url vcs_config)
        ~user_agent:"Terrateam"
        (`Bearer token)
    in
    let module Groups = Gitlabc_groups.GetApiV4Groups in
    Openapic_abb.collect_all
      ~page:Openapic_abb.Page.gitlab
      client
      Groups.(make (Parameters.make ~order_by:"name" ()))
    >>= fun groups ->
    let module G = Gitlabc_components_api_entities_group in
    let module R = Terrat_api_components_gitlab_group in
    Abb.Future.return (Ok (CCList.map (fun { G.id; full_name = name; _ } -> { R.id; name }) groups))

  let get config storage =
    Brtl_ep.run_result_json ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        Logs.info (fun m ->
            m "%s : GROUPS : LIST : user=%a" (Brtl_ctx.token ctx) Uuidm.pp (Terrat_user.id user));
        let open Abb.Future.Infix_monad in
        get' config storage user
        >>= function
        | Ok groups ->
            let body =
              groups
              |> Terrat_api_gitlab_groups.List.Responses.OK.to_yojson
              |> Yojson.Safe.to_string
            in
            Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
        | Error `Error ->
            Logs.err (fun m -> m "user=%a" Terrat_user.pp user);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Oauth.access_token_err as err) ->
            Logs.err (fun m -> m "user=%a : %a" Terrat_user.pp user Oauth.pp_access_token_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Openapic_abb.call_err as err) ->
            Logs.err (fun m -> m "user=%a : %a" Terrat_user.pp user Openapic_abb.pp_call_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m -> m "user=%a : %a" Terrat_user.pp user Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end

module Is_member = struct
  module U = Gitlabc_components.API_Entities_UserPublic

  let get' user_id config group_id =
    let module Glg = Gitlabc_groups_members.GetApiV4GroupsIdMembersAllUserId in
    let vcs_config = Terrat_vcs_service_gitlab_provider.Api.Config.vcs_config config in
    let open Abbs_future_combinators.Infix_result_monad in
    let client =
      Openapic_abb.create
        ~user_agent:"Terrateam"
        ~base_url:(Terrat_config.Gitlab.api_base_url vcs_config)
        (`Bearer (Terrat_config.Gitlab.access_token vcs_config))
    in
    Openapic_abb.call client Glg.(make (Parameters.make ~id:(CCInt.to_string group_id) ~user_id))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK _ -> Abb.Future.return (Ok true)
    | _ -> Abb.Future.return (Ok false)

  let get { U.id; _ } config storage group_id =
    Brtl_ep.run_result_json ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        Logs.info (fun m ->
            m
              "%s : GROUPS : IS_MEMBER : user=%a"
              (Brtl_ctx.token ctx)
              Uuidm.pp
              (Terrat_user.id user));
        let open Abb.Future.Infix_monad in
        get' id config group_id
        >>= function
        | Ok result ->
            let body =
              Terrat_api_gitlab_groups.Is_member.Responses.(
                { OK.result } |> OK.to_yojson |> Yojson.Safe.to_string)
            in
            Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
        | Error (#Openapic_abb.call_err as err) ->
            Logs.err (fun m -> m "group_id=%d : %a" group_id Openapic_abb.pp_call_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end
