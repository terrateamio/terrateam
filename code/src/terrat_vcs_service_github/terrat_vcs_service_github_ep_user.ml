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

    let select_installations_for_diag () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.bigint
        //
        (* login *)
        Ret.text
        /^ read [%blob "sql/select_installations_for_diag.sql"])
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

  (* App-side cross-check. For each org Terrateam has an installation for, ask the APP (installation
     token) whether it considers [login] a member. If the app confirms an active membership in an org
     whose installation the user's OWN token did not return, that is an airtight GitHub-side
     regression to report. "app-cannot-read-org-members" instead means the app lacks the org
     Members:read permission, which is itself a leading suspect for empty user installations. *)
  let log_app_token_cross_check ~request_id ~user_id config storage ~login =
    let vcs_config = Terrat_vcs_service_github_provider.Api.Config.vcs_config config in
    let open Abb.Future.Infix_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.select_installations_for_diag ())
          ~f:(fun id org_login -> (id, org_login)))
    >>= function
    | Error (#Pgsql_pool.err as err) ->
        Logs.warn (fun m ->
            m
              "%s : DIAG : user=%a : cross-check could not read local installations : %a"
              request_id
              Uuidm.pp
              user_id
              Pgsql_pool.pp_err
              err);
        Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.warn (fun m ->
            m
              "%s : DIAG : user=%a : cross-check could not read local installations : %a"
              request_id
              Uuidm.pp
              user_id
              Pgsql_io.pp_err
              err);
        Abb.Future.return (Ok ())
    | Ok installations ->
        Logs.info (fun m ->
            m
              "%s : DIAG : user=%a : cross_check_login=%s : asking the app token about this user's \
               membership in %d local installation(s)"
              request_id
              Uuidm.pp
              user_id
              login
              (CCList.length installations));
        Abbs_future_combinators.List_result.iter
          ~f:(fun (installation_id, org_login) ->
            Terrat_github.get_installation_access_token vcs_config (CCInt64.to_int installation_id)
            >>= function
            | Error err ->
                Logs.warn (fun m ->
                    m
                      "%s : DIAG : user=%a : cross-check could not mint app token for org=%s \
                       installation_id=%Ld : %a"
                      request_id
                      Uuidm.pp
                      user_id
                      org_login
                      installation_id
                      Terrat_github.pp_get_installation_access_token_err
                      err);
                Abb.Future.return (Ok ())
            | Ok inst_token -> (
                Terrat_github.with_client
                  vcs_config
                  (`Bearer inst_token)
                  (Terrat_github.get_org_membership_diag ~org:org_login ~user:login)
                >>= function
                | Ok desc ->
                    Logs.info (fun m ->
                        m
                          "%s : DIAG : user=%a : app_sees org=%s installation_id=%Ld : %s"
                          request_id
                          Uuidm.pp
                          user_id
                          org_login
                          installation_id
                          desc);
                    Abb.Future.return (Ok ())
                | Error err ->
                    Logs.warn (fun m ->
                        m
                          "%s : DIAG : user=%a : app membership check failed org=%s \
                           installation_id=%Ld : %a"
                          request_id
                          Uuidm.pp
                          user_id
                          org_login
                          installation_id
                          Terrat_github.pp_get_org_membership_diag_err
                          err);
                    Abb.Future.return (Ok ())))
          installations
        >>= fun _ -> Abb.Future.return (Ok ())

  (* Best-effort visibility probe. When GitHub returns no installations for a user's valid token we
     ask that same token what else it can see - the authenticated identity, the orgs it can list,
     and the user's org memberships (role + active/pending state). Comparing these against a working
     user pinpoints where access is lost on GitHub's side. Every sub-call swallows its own errors
     and only logs, so this never affects the response. *)
  let log_github_visibility_diagnostics ~request_id ~user_id config storage token =
    let vcs_config = Terrat_vcs_service_github_provider.Api.Config.vcs_config config in
    let open Abb.Future.Infix_monad in
    Terrat_github.user ~config:vcs_config ~access_token:token ()
    >>= (fun res ->
    match res with
    | Ok current_user ->
        let module Gar = Githubc2_users.Get_authenticated.Responses.OK in
        let module Pr = Githubc2_components.Private_user in
        let module Pu = Githubc2_components.Public_user in
        let login =
          match current_user with
          | Gar.Private_user { Pr.primary = { Pr.Primary.login; _ }; _ }
          | Gar.Public_user { Pu.login; _ } -> login
        in
        Logs.info (fun m ->
            m "%s : DIAG : user=%a : token_login=%s" request_id Uuidm.pp user_id login);
        Abb.Future.return (Some login)
    | Error err ->
        Logs.warn (fun m ->
            m
              "%s : DIAG : user=%a : identity lookup failed : %a"
              request_id
              Uuidm.pp
              user_id
              Terrat_github.pp_user_err
              err);
        Abb.Future.return None)
    >>= fun login_opt ->
    Terrat_github.with_client vcs_config (`Bearer token) Terrat_github.get_user_orgs
    >>= (fun res ->
    (match res with
    | Ok orgs ->
        let module O = Githubc2_components.Organization_simple in
        Logs.info (fun m ->
            m
              "%s : DIAG : user=%a : user_orgs_visible=%d : [%s]"
              request_id
              Uuidm.pp
              user_id
              (CCList.length orgs)
              (String.concat
                 ", "
                 (CCList.map (fun { O.primary = { O.Primary.login; _ }; _ } -> login) orgs)))
    | Error err ->
        Logs.warn (fun m ->
            m
              "%s : DIAG : user=%a : user_orgs lookup failed (a 403 here means the token cannot \
               read this user's org list at all - app org Members:read permission or org \
               SSO/third-party approval) : %a"
              request_id
              Uuidm.pp
              user_id
              Terrat_github.pp_get_user_orgs_err
              err));
    Abb.Future.return ())
    >>= fun () ->
    Terrat_github.with_client vcs_config (`Bearer token) Terrat_github.get_user_org_memberships
    >>= fun res ->
    (match res with
    | Ok memberships ->
        let module Om = Githubc2_components.Org_membership in
        let module O = Githubc2_components.Organization_simple in
        let show_membership
            {
              Om.primary =
                {
                  Om.Primary.organization = { O.primary = { O.Primary.login; _ }; _ };
                  role;
                  state;
                  _;
                };
              _;
            } =
          let role =
            match role with
            | `Admin -> "admin"
            | `Billing_manager -> "billing_manager"
            | `Member -> "member"
          in
          let state =
            match state with
            | `Active -> "active"
            | `Pending -> "pending"
          in
          Printf.sprintf "%s(role=%s,state=%s)" login role state
        in
        Logs.info (fun m ->
            m
              "%s : DIAG : user=%a : user_org_memberships=%d : [%s]"
              request_id
              Uuidm.pp
              user_id
              (CCList.length memberships)
              (String.concat ", " (CCList.map show_membership memberships)))
    | Error err ->
        Logs.warn (fun m ->
            m
              "%s : DIAG : user=%a : org memberships lookup failed : %a"
              request_id
              Uuidm.pp
              user_id
              Terrat_github.pp_get_user_org_memberships_err
              err));
    match login_opt with
    | None -> Abb.Future.return (Ok ())
    | Some login -> log_app_token_cross_check ~request_id ~user_id config storage ~login

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
    >>= fun (installations, total_count) ->
    (* github_returned is what the user actually gets; total_count is GitHub's own count of
       installations it considers accessible to this token (if they disagree, GitHub is filtering
       the page). GET /user/installations only surfaces installations the user can reach through a
       repository they can access. *)
    Logs.info (fun m ->
        m
          "%s : INSTALLATIONS : user=%a : github_returned=%d : total_count=%d : [%s]"
          request_id
          Uuidm.pp
          user_id
          (CCList.length installations)
          total_count
          (String.concat ", " (CCList.map summarize_installation installations)));
    (if CCList.is_empty installations then (
       Logs.warn (fun m ->
           m
             "%s : INSTALLATIONS : user=%a : github_returned=0 - GitHub returned an empty \
              installation list for this user's valid token (this is the demo-mode trigger). \
              Emitting visibility diagnostics below to localize where access is lost."
             request_id
             Uuidm.pp
             user_id);
       log_github_visibility_diagnostics ~request_id ~user_id config storage token)
     else Abb.Future.return (Ok ()))
    >>= fun () ->
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
