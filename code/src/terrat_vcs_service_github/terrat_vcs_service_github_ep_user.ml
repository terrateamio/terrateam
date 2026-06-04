let src = Logs.Src.create "vcs_service_github_ep_user"

module Logs = (val Logs.src_log src : Logs.LOG)

module Whoami = struct
  module Sql = struct
    let read s = Pgsql_io.clean_string s

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
        /^ read [%blob "sql/select_github_user2_by_user_id.sql"]
        /% Var.uuid "user_id")
  end

  let get _config storage =
    Brtl_ep.run_result_json ~f:(fun ctx ->
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
    let read s = Pgsql_io.clean_string s

    let tier_features =
      let module P = struct
        type t = Terrat_tier.t [@@deriving yojson]
      end in
      CCFun.(P.of_yojson %> CCResult.to_opt)

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
        (*created_at *)
        Ret.text
        //
        (* trial_ends_at *)
        Ret.(option text)
        //
        (* tier name *)
        Ret.text
        //
        (* tier features *)
        Ret.u Ret.json tier_features
        /^ read [%blob "sql/select_user_installations.sql"]
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
        /^ read [%blob "sql/upsert_user_installations.sql"]
        /% Var.(uuid "user_id")
        /% Var.(array (bigint "installation_ids")))
  end

  (* Render a GitHub installation as a compact, log-friendly summary. The installation [id] is the
     value matched against the local github_installations table, so it is the key datum when
     diagnosing why an installation that GitHub returns does not surface for a user. *)
  let summarize_installation installation =
    let module I = Githubc2_components.Installation in
    let module Su = Githubc2_components.Simple_user in
    let module En = Githubc2_components.Enterprise in
    let { I.primary = { I.Primary.id; target_type; account; _ }; _ } = installation in
    let login =
      match account with
      | Some (I.Primary.Account.Simple_user { Su.primary = { Su.Primary.login; _ }; _ }) -> login
      | Some (I.Primary.Account.Enterprise { En.primary = { En.Primary.slug; _ }; _ }) -> slug
      | None -> "<no-account>"
    in
    Printf.sprintf "id=%d type=%s login=%s" id target_type login

  let get' ~request_id config storage user =
    let open Abbs_future_combinators.Infix_result_monad in
    let module I = Githubc2_components.Installation in
    let user_id = Terrat_user.id user in
    Logs.info (fun m -> m "%s : INSTALLATIONS : user=%a : start" request_id Uuidm.pp user_id);
    Terrat_vcs_service_github_user.get_token config storage user
    >>= fun token ->
    Terrat_github.with_client
      (Terrat_vcs_service_github_provider.Api.Config.vcs_config config)
      (`Bearer token)
      Terrat_github.get_user_installations
    >>= fun installations ->
    (* What GitHub reports for this user's token. GET /user/installations only returns installations
       the user can reach through repositories they can access, so an org member with no access to a
       covered repository legitimately sees an empty list here even though the app is installed. *)
    Logs.info (fun m ->
        m
          "%s : INSTALLATIONS : user=%a : github_returned=%d : [%s]"
          request_id
          Uuidm.pp
          user_id
          (CCList.length installations)
          (String.concat ", " (CCList.map summarize_installation installations)));
    if CCList.is_empty installations then
      Logs.warn (fun m ->
          m
            "%s : INSTALLATIONS : user=%a : github returned zero installations - the user's OAuth \
             token cannot see any installation of this GitHub App. This is expected when the user \
             cannot access (through their organization membership) any repository the app is \
             installed on; verify the user has access to at least one covered repository and that \
             SAML SSO is authorized for their token."
            request_id
            Uuidm.pp
            user_id);
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.fetch
          db
          ~f:(fun _ _ _ -> ())
          (Sql.upsert_user_installations ())
          user_id
          (CCList.map (fun { I.primary = { I.Primary.id; _ }; _ } -> Int64.of_int id) installations)
        >>= fun _ ->
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.select_installations ())
          ~f:(fun id name account_status created_at trial_ends_at tier_name tier_features ->
            let module Ai = Terrat_api_components.Installation in
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
            { Ai.id = CCInt64.to_string id; name; account_status; created_at; trial_ends_at; tier })
          (CCList.map (fun { I.primary = { I.Primary.id; _ }; _ } -> Int64.of_int id) installations))
    >>= fun installations_result ->
    let module Ai = Terrat_api_components.Installation in
    (* What the user actually receives: GitHub's installations intersected with the local
       github_installations table. If this is shorter than github_returned, the missing ids have no
       installation row recorded locally. *)
    Logs.info (fun m ->
        m
          "%s : INSTALLATIONS : user=%a : db_matched=%d : [%s]"
          request_id
          Uuidm.pp
          user_id
          (CCList.length installations_result)
          (String.concat
             ", "
             (CCList.map
                (fun { Ai.id; name; _ } -> Printf.sprintf "id=%s login=%s" id name)
                installations_result)));
    let matched_ids = CCList.map (fun { Ai.id; _ } -> id) installations_result in
    let missing_from_db =
      CCList.filter_map
        (fun { I.primary = { I.Primary.id; _ }; _ } ->
          let id = string_of_int id in
          if CCList.mem ~eq:CCString.equal id matched_ids then None else Some id)
        installations
    in
    if not (CCList.is_empty missing_from_db) then
      Logs.warn (fun m ->
          m
            "%s : INSTALLATIONS : user=%a : missing_from_db=%d : ids=[%s] - these installations \
             were returned by GitHub but have no row in the github_installations table, so they \
             are dropped from the user's list (e.g. the install webhook was never received for \
             this account)."
            request_id
            Uuidm.pp
            user_id
            (CCList.length missing_from_db)
            (String.concat ", " missing_from_db));
    Abb.Future.return (Ok installations_result)

  let get config storage =
    Brtl_ep.run_result_json ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        get' ~request_id:(Brtl_ctx.token ctx) config storage user
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
                  "%s : GET : INSTALLATIONS : user=%a : %a"
                  (Brtl_ctx.token ctx)
                  Uuidm.pp
                  (Terrat_user.id user)
                  Terrat_vcs_service_github_user.pp_err
                  err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
        | Error `Bad_refresh_token ->
            Logs.err (fun m ->
                m
                  "%s : GET : INSTALLATIONS : user=%a : BAD_REFRESH_TOKEN"
                  (Brtl_ctx.token ctx)
                  Uuidm.pp
                  (Terrat_user.id user));
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m
                  "%s : GET : INSTALLATIONS : user=%a : %a"
                  (Brtl_ctx.token ctx)
                  Uuidm.pp
                  (Terrat_user.id user)
                  Pgsql_pool.pp_err
                  err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m
                  "%s : GET : INSTALLATIONS : user=%a : %a"
                  (Brtl_ctx.token ctx)
                  Uuidm.pp
                  (Terrat_user.id user)
                  Pgsql_io.pp_err
                  err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Terrat_github.get_user_installations_err as err) ->
            Logs.err (fun m ->
                m
                  "%s : GET : INSTALLATIONS : user=%a : %a"
                  (Brtl_ctx.token ctx)
                  Uuidm.pp
                  (Terrat_user.id user)
                  Terrat_github.pp_get_user_installations_err
                  err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Terrat_vcs_service_github_user.err as err) ->
            Logs.err (fun m ->
                m
                  "%s : GET : INSTALLATIONS : user=%a : %a"
                  (Brtl_ctx.token ctx)
                  Uuidm.pp
                  (Terrat_user.id user)
                  Terrat_vcs_service_github_user.pp_err
                  err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end
