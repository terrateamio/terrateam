let src = Logs.Src.create "vcs_service_gitlab_ep_installations"

module Logs = (val Logs.src_log src : Logs.LOG)
module User = Terrat_vcs_service_gitlab_user

module Metrics = struct
  module Psql_query_time = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_linear ~start:0.0 ~interval:0.1 ~count:15
  end)

  let namespace = "terrat_vcs_service_gitlab"
  let subsystem = "ep_installations"

  let psql_query_time =
    let help = "Time for PostgreSQL query" in
    Psql_query_time.v_label ~help ~label_name:"q" ~namespace ~subsystem "psql_query_time"
end

let max_page_size = 100

let replace_where q = function
  | "" -> CCString.replace ~sub:"{{where}}" ~by:"" q
  | where -> CCString.replace ~sub:"{{where}}" ~by:("where " ^ where) q

let set_timeout timeout =
  Pgsql_io.Typed_sql.(sql /^ Printf.sprintf "set local statement_timeout = '%s'" timeout)

module List = struct
  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map Pgsql_io.clean_string (Terrat_files_gitlab_sql.read fname))

    let select_user_installations () =
      Pgsql_io.Typed_sql.(sql /^ read "select_user_installations.sql" /% Var.uuid "user_id")

    let upsert_user_installations () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* installation_id *)
        Ret.bigint
        //
        (* name *)
        Ret.text
        //
        (* state *)
        Ret.text
        /^ read "upsert_user_installations.sql"
        /% Var.uuid "user_id"
        /% Var.(array (bigint "installation_ids")))
  end

  let get' config storage user =
    let open Abbs_future_combinators.Infix_result_monad in
    let module Groups = Gitlabc_groups.GetApiV4Groups in
    let vcs_config = Terrat_vcs_service_gitlab_provider.Api.Config.vcs_config config in
    Pgsql_pool.with_conn storage ~f:(fun db -> User.Oauth.access_token ~config:vcs_config db user)
    >>= fun token ->
    let client =
      Openapic_abb.create
        ~base_url:(Terrat_config.Gitlab.api_base_url vcs_config)
        ~user_agent:"Terrateam"
        (`Bearer token)
    in
    Openapic_abb.collect_all
      ~page:Openapic_abb.Page.gitlab
      client
      Groups.(make (Parameters.make ~order_by:"name" ()))
    >>= fun groups ->
    let module G = Gitlabc_components_api_entities_group in
    let group_ids = CCList.map (fun { G.id; _ } -> CCInt64.of_int id) groups in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.upsert_user_installations ())
          ~f:(fun installation_id name state ->
            let module I = Terrat_api_components_installation in
            let module T = Terrat_api_components_tier in
            {
              I.id = CCInt64.to_string installation_id;
              name;
              account_status = state;
              tier = { T.features = { T.Features.num_users_per_month = None }; name = "Unknown" };
              trial_ends_at = None;
            })
          (Terrat_user.id user)
          group_ids)
    >>= fun installations -> Abb.Future.return (Ok installations)

  let get config storage =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        get' config storage user
        >>= function
        | Ok installations ->
            let module R = Terrat_api_gitlab_installations.List.Responses.OK in
            let body = { R.installations } |> R.to_yojson |> Yojson.Safe.to_string in
            Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
        | Error `Error ->
            Logs.err (fun m -> m "ERROR");
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#User.Oauth.access_token_err as err) ->
            Logs.err (fun m -> m "%a" User.Oauth.pp_access_token_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Openapic_abb.call_err as err) ->
            Logs.err (fun m -> m "%a" Openapic_abb.pp_call_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m -> m ": %a" Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end

module Webhook = struct
  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map Pgsql_io.clean_string (Terrat_files_gitlab_sql.read fname))

    let insert_or_select_installation =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* webhook secret *)
        Ret.text
        //
        (* state *)
        Ret.text
        /^ read "insert_or_select_installation.sql"
        /% Var.bigint "id"
        /% Var.text "name")
  end

  let affirm_is_admin client installation_id user_id =
    let open Abbs_future_combinators.Infix_result_monad in
    let module G = Gitlabc_groups_members.GetApiV4GroupsIdMembersAllUserId in
    Openapic_abb.call
      client
      G.(make (Parameters.make ~id:(CCInt.to_string installation_id) ~user_id))
    >>= fun resp ->
    let module M = Gitlabc_components.API_Entities_Member in
    match Openapi.Response.value resp with
    | `OK { M.access_level; _ } ->
        if access_level >= 50 then Abb.Future.return (Ok ())
        else Abb.Future.return (Error (`Access_level_err access_level))
    | `Not_found -> Abb.Future.return (Error `User_not_found_in_group_err)

  let fetch_group_name client installation_id =
    let open Abbs_future_combinators.Infix_result_monad in
    let module G = Gitlabc_groups.GetApiV4GroupsId in
    Openapic_abb.call client G.(make (Parameters.make ~id:(CCInt.to_string installation_id) ()))
    >>= fun resp ->
    let module Group = Gitlabc_components.API_Entities_GroupDetail in
    let (`OK { Group.name; _ }) = Openapi.Response.value resp in
    Abb.Future.return (Ok name)

  let get' config storage user installation_id webhook_url =
    let open Abbs_future_combinators.Infix_result_monad in
    let vcs_config = Terrat_vcs_service_gitlab_provider.Api.Config.vcs_config config in
    let client =
      Openapic_abb.create
        ~user_agent:"Terrateam"
        ~base_url:(Terrat_config.Gitlab.api_base_url vcs_config)
        (`Bearer (Terrat_config.Gitlab.access_token vcs_config))
    in
    Pgsql_pool.with_conn storage ~f:(fun db -> User.query_user_id db user)
    >>= fun user_id ->
    Abbs_future_combinators.Infix_result_app.(
      (fun name () -> name)
      <$> fetch_group_name client installation_id
      <*> affirm_is_admin client installation_id user_id)
    >>= fun name ->
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.insert_or_select_installation
          ~f:(fun webhook_secret state ->
            let module W = Terrat_api_components.Gitlab_webhook in
            { W.webhook_secret = Some webhook_secret; webhook_url; state })
          (CCInt64.of_int installation_id)
          name)
    >>= function
    | [] -> assert false
    | webhook_secret :: _ -> Abb.Future.return (Ok webhook_secret)

  let get config storage installation_id =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        let c = Terrat_vcs_service_gitlab_provider.Api.Config.config config in
        get'
          config
          storage
          user
          installation_id
          (Printf.sprintf "%s/v1/gitlab/events" (Terrat_config.api_base c))
        >>= function
        | Ok webhook ->
            let body =
              webhook |> Terrat_api_components.Gitlab_webhook.to_yojson |> Yojson.Safe.to_string
            in
            Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
        | Error `User_not_found_in_group_err ->
            Logs.err (fun m -> m "installation_id=%d : USER_NOT_FOUND_IN_GROUP" installation_id);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (`User_not_found_err user) ->
            Logs.err (fun m ->
                m
                  "installation_id=%d : USER_NOT_FOUND : user=%a"
                  installation_id
                  Terrat_user.pp
                  user);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (`Access_level_err access_level) ->
            Logs.err (fun m ->
                m "installation_id=%d : ACCESS_LEVEL : level=%d" installation_id access_level);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
        | Error (#Openapic_abb.call_err as err) ->
            Logs.err (fun m ->
                m "installation_id=%d : %a" installation_id Openapic_abb.pp_call_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m -> m "installation_id=%d : %a" installation_id Pgsql_io.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m -> m "installation_id=%d : %a" installation_id Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end

module List_repos = struct
  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map Pgsql_io.clean_string (Terrat_files_gitlab_sql.read fname))

    let select_installation_repos_page () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.bigint
        //
        (* installation_id *)
        Ret.bigint
        //
        (* name *)
        Ret.text
        //
        (* updated_at *)
        Ret.text
        //
        (* setup *)
        Ret.boolean
        /^ read "select_installation_repos_page.sql"
        /% Var.uuid "user_id"
        /% Var.bigint "installation_id"
        /% Var.(option (text "prev_name")))
  end

  let columns = Pgsql_pagination.Search.Col.[ create ~vname:"prev_name" ~cname:"name" ]

  module Page = struct
    type cursor = string

    type query = {
      user : Uuidm.t;
      storage : Terrat_storage.t;
      installation_id : int;
      dir : [ `Asc | `Desc ];
      limit : int;
    }

    type t = Terrat_api_components.Installation_repo.t Pgsql_pagination.t

    type err =
      [ Pgsql_pool.err
      | Pgsql_io.err
      ]

    let run_query ?cursor query f =
      let search =
        Pgsql_pagination.Search.(
          create ~page_size:(CCInt.min max_page_size query.limit) ~dir:query.dir columns)
      in
      Pgsql_pool.with_conn query.storage ~f:(fun db ->
          f
            search
            db
            (Sql.select_installation_repos_page ())
            ~f:(fun id installation_id name updated_at setup ->
              {
                Terrat_api_components.Installation_repo.id = CCInt64.to_string id;
                installation_id = CCInt64.to_string installation_id;
                name;
                updated_at;
                setup;
              })
            query.user
            (CCInt64.of_int query.installation_id)
            cursor)

    let next ?cursor query = run_query ?cursor query Pgsql_pagination.next
    let prev ?cursor query = run_query ?cursor query Pgsql_pagination.prev

    let to_yojson t =
      Terrat_api_installations.List_repos.Responses.OK.(
        { repositories = Pgsql_pagination.results t } |> to_yojson)

    let cursor_of_first t =
      let module R = Terrat_api_components.Installation_repo in
      match Pgsql_pagination.results t with
      | [] -> None
      | R.{ name; _ } :: _ -> Some [ name ]

    let cursor_of_last t =
      let module R = Terrat_api_components.Installation_repo in
      match CCList.rev (Pgsql_pagination.results t) with
      | [] -> None
      | R.{ name; _ } :: _ -> Some [ name ]

    let has_another_page t = Pgsql_pagination.has_next_page t

    let rspnc_of_err ~token = function
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "%s : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "%s : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get' config storage user installation_id page limit ctx =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        User.enforce_installation_access db user installation_id)
    >>= fun () ->
    let open Abb.Future.Infix_monad in
    let query = Page.{ user = Terrat_user.id user; storage; installation_id; limit; dir = `Asc } in
    Paginate.run ?page ~page_param:"page" query ctx >>= fun ctx -> Abb.Future.return (Ok ctx)

  let get config storage installation_id page limit =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        get' config storage user installation_id page limit ctx
        >>= function
        | Ok ctx -> Abb.Future.return (Ok ctx)
        | Error `Forbidden -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "INSTALLATION : %s : LIST_REPOS : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "INSTALLATION : %s : LIST_REPOS : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end
