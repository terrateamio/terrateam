let src = Logs.Src.create "vcs_service_github_ep_user"

module Logs = (val Logs.src_log src : Logs.LOG)

module Whoami = struct
  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map Pgsql_io.clean_string (Terrat_files_github_sql.read fname))

    let select_github_user () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* username *)
        Ret.text
        //
        (* email *)
        Ret.(option text)
        //
        (* name *)
        Ret.(option text)
        //
        (* avatar_url *)
        Ret.(option text)
        /^ read "select_github_user2_by_user_id.sql"
        /% Var.uuid "user_id")
  end

  let get config storage =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let run =
          Pgsql_pool.with_conn storage ~f:(fun db ->
              Pgsql_io.Prepared_stmt.fetch
                db
                (Sql.select_github_user ())
                ~f:(fun username _ _ avatar_url -> (username, avatar_url))
                (Terrat_user.id user))
          >>= fun res -> Abb.Future.return (Ok (CCOption.of_list res))
        in
        let open Abb.Future.Infix_monad in
        run
        >>= function
        | Ok None ->
            Logs.debug (fun m ->
                m
                  "%s : WHOAMI : user_id=%a : NOT_FOUND"
                  (Brtl_ctx.token ctx)
                  Uuidm.pp
                  (Terrat_user.id user));
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
        | Ok (Some (username, avatar_url)) ->
            let body =
              Terrat_api_components.Github_user.(
                { avatar_url; username } |> to_yojson |> Yojson.Safe.to_string)
            in
            Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m -> m "%s : WHOAMI : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m -> m "%s : WHOAMI : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end

module Installations = struct
  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map Pgsql_io.clean_string (Terrat_files_github_sql.read fname))

    let tier_features =
      let module P = struct
        type t = Terrat_tier.t [@@deriving yojson]
      end in
      CCFun.(
        CCOption.wrap Yojson.Safe.from_string
        %> CCOption.map P.of_yojson
        %> CCOption.flat_map CCResult.to_opt)

    let select_installations () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.bigint
        //
        (* login *)
        Ret.text
        //
        (* account status *)
        Ret.text
        //
        (* trial_ends_at *)
        Ret.(option text)
        //
        (* tier name *)
        Ret.text
        //
        (* tier features *)
        Ret.ud' tier_features
        /^ read "select_user_installations.sql"
        /% Var.(array (bigint "installation_ids")))

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
        /% Var.(uuid "user_id")
        /% Var.(array (bigint "installation_ids")))
  end

  let get' config storage user =
    let open Abbs_future_combinators.Infix_result_monad in
    Terrat_vcs_service_github_user.get_token config storage user
    >>= fun token ->
    Terrat_github.with_client
      (Terrat_vcs_service_github_provider.Api.Config.vcs_config config)
      (`Bearer token)
      Terrat_github.get_user_installations
    >>= fun installations ->
    Pgsql_pool.with_conn storage ~f:(fun db ->
        let module I = Githubc2_components.Installation in
        Pgsql_io.Prepared_stmt.fetch
          db
          ~f:(fun _ _ _ -> ())
          (Sql.upsert_user_installations ())
          (Terrat_user.id user)
          (CCList.map (fun { I.primary = { I.Primary.id; _ }; _ } -> Int64.of_int id) installations)
        >>= fun _ ->
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.select_installations ())
          ~f:(fun id name account_status trial_ends_at tier_name tier_features ->
            let module I = Terrat_api_components.Installation in
            let module T = Terrat_api_components.Tier in
            let { Terrat_tier.num_users_per_month; _ } = tier_features in
            let tier =
              {
                T.name = tier_name;
                features =
                  {
                    T.Features.num_users_per_month =
                      (if num_users_per_month = CCInt.max_int then None
                       else Some num_users_per_month);
                  };
              }
            in
            { I.id = CCInt64.to_string id; name; account_status; trial_ends_at; tier })
          (CCList.map (fun I.{ primary = Primary.{ id; _ }; _ } -> Int64.of_int id) installations))

  let get config storage =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        get' config storage user
        >>= function
        | Ok installations ->
            let body =
              Terrat_api_user.List_github_installations.Responses.OK.(
                { installations } |> to_yojson |> Yojson.Safe.to_string)
            in
            Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
        | Error (`Refresh_err _ as err) ->
            Logs.err (fun m ->
                m
                  "%s : GET : INSTALLATIONS : %a"
                  (Brtl_ctx.token ctx)
                  Terrat_vcs_service_github_user.pp_err
                  err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
        | Error `Bad_refresh_token ->
            Logs.err (fun m ->
                m "%s : GET : INSTALLATIONS : BAD_REFRESH_TOKEN" (Brtl_ctx.token ctx));
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "%s : GET : INSTALLATIONS : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "%s : GET : INSTALLATIONS : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Terrat_github.get_user_installations_err as err) ->
            Logs.err (fun m ->
                m
                  "%s : GET : INSTALLATIONS : %a"
                  (Brtl_ctx.token ctx)
                  Terrat_github.pp_get_user_installations_err
                  err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Terrat_vcs_service_github_user.err as err) ->
            Logs.err (fun m ->
                m
                  "%s : GET : INSTALLATIONS : %a"
                  (Brtl_ctx.token ctx)
                  Terrat_vcs_service_github_user.pp_err
                  err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end
