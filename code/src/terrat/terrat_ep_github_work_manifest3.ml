module Make
    (Terratc : Terratc_intf.S
                 with type Github.Client.t = Terrat_github_evaluator3.S.Client.t
                  and type Github.Account.t = Terrat_github_evaluator3.S.Account.t
                  and type Github.Repo.t = Terrat_github_evaluator3.S.Repo.t
                  and type Github.Remote_repo.t = Terrat_github_evaluator3.S.Remote_repo.t
                  and type Github.Ref.t = Terrat_github_evaluator3.S.Ref.t) =
struct
  module Github_evaluator = Terrat_github_evaluator3.Make (Terratc)

  let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

  module Sql = struct
    let select_encryption_key () =
      (* The hex conversion is so that there are no issues with escaping
         the string *)
      Pgsql_io.Typed_sql.(
        sql
        // (* data *) Ret.ud' CCFun.(Cstruct.of_hex %> CCOption.return)
        /^ "select encode(data, 'hex') from encryption_keys order by rank limit 1")
  end

  module Initiate = struct
    module I = Terrat_api_components_work_manifest_initiate

    let post' config storage work_manifest_id initiate ctx =
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch db (Sql.select_encryption_key ()) ~f:CCFun.id)
      >>= function
      | [] -> assert false
      | encryption_key :: _ ->
          let request_id = Brtl_ctx.token ctx in
          Github_evaluator.work_manifest_initiate
            ~ctx:(Terrat_evaluator3.Ctx.make ~request_id ~config ~storage ())
            ~encryption_key
            work_manifest_id
            initiate
          >>= fun r -> Abb.Future.return (Ok r)

    let post config storage work_manifest_id initiate ctx =
      let open Abb.Future.Infix_monad in
      post' config storage work_manifest_id initiate ctx
      >>= function
      | Ok (Some response) ->
          let body =
            response
            |> Terrat_api_work_manifest.Initiate.Responses.OK.to_yojson
            |> Yojson.Safe.to_string
          in
          Abb.Future.return
            (Brtl_ctx.set_response
               (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
               ctx)
      | Ok None ->
          Abb.Future.return
            (Brtl_ctx.set_response
               (Brtl_rspnc.create ~headers:response_headers ~status:`Not_found "")
               ctx)
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m ->
              m
                "EP_GITHUB_WORK_MANIFEST : %s : ACCESS_TOKEN : %a"
                (Brtl_ctx.token ctx)
                Pgsql_pool.pp_err
                err);
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m ->
              m
                "EP_GITHUB_WORK_MANIFEST : %s : ACCESS_TOKEN : %a"
                (Brtl_ctx.token ctx)
                Pgsql_io.pp_err
                err);
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Error `Error ->
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  end

  module Plans = struct
    let post config storage work_manifest_id plan ctx =
      let open Abb.Future.Infix_monad in
      let request_id = Brtl_ctx.token ctx in
      Github_evaluator.plan_store
        ~ctx:(Terrat_evaluator3.Ctx.make ~request_id ~config ~storage ())
        work_manifest_id
        plan
      >>= function
      | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
      | Error `Error ->
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)

    let get config storage work_manifest_id dir workspace ctx =
      let open Abb.Future.Infix_monad in
      let request_id = Brtl_ctx.token ctx in
      Github_evaluator.plan_fetch
        ~ctx:(Terrat_evaluator3.Ctx.make ~request_id ~config ~storage ())
        work_manifest_id
        { Terrat_dirspace.dir; workspace }
      >>= function
      | Ok (Some data) ->
          let response =
            Terrat_api_work_manifest.Plan_get.Responses.OK.({ data } |> to_yojson)
            |> Yojson.Safe.to_string
          in
          Abb.Future.return
            (Brtl_ctx.set_response
               (Brtl_rspnc.create ~headers:response_headers ~status:`OK response)
               ctx)
      | Ok None ->
          Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
      | Error `Error ->
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  end

  module Results = struct
    let put config storage work_manifest_id result ctx =
      let open Abb.Future.Infix_monad in
      let request_id = Brtl_ctx.token ctx in
      Github_evaluator.work_manifest_result
        ~ctx:(Terrat_evaluator3.Ctx.make ~request_id ~config ~storage ())
        work_manifest_id
        result
      >>= fun r ->
      match r with
      | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
      | Error `Error ->
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  end

  module Access_token = struct
    module Cache = Abb_cache.Expiring.Make (struct
      type k = int64 [@@deriving eq]
      type v = string
      type err = Terrat_github.get_installation_access_token_err
      type args = unit -> (v, err) result Abb.Future.t

      let fetch f = f ()
    end)

    (*  Cache it for slightly less time than it lives *)
    let cache =
      Cache.create
        {
          Abb_cache.Expiring.on_hit = CCFun.const ();
          on_miss = CCFun.const ();
          duration = Duration.of_sec 50;
          size = 100;
        }

    module Sql = struct
      let select_encryption_key () =
        Pgsql_io.Typed_sql.(
          sql
          // (* data *) Ret.ud' CCFun.(Cstruct.of_hex %> CCOption.return)
          /^ "select encode(data, 'hex') from encryption_keys order by rank limit 1")

      let select_running_work_manifest () =
        Pgsql_io.Typed_sql.(
          sql
          // (* id *) Ret.uuid
          /^ "select id from github_work_manifests where id = $id and state = 'running'"
          /% Var.uuid "id")

      let select_installation_id () =
        Pgsql_io.Typed_sql.(
          sql
          // (* id *) Ret.bigint
          /^ "select gir.installation_id from github_work_manifests as gwm inner join \
              github_installation_repositories as gir on gwm.repository = gir.id where gwm.id = \
              $id"
          /% Var.uuid "id")
    end

    let access_permission storage ctx work_manifest_id =
      match Brtl_permissions.get_auth ctx with
      | Ok (Brtl_permissions.Auth.Bearer token) -> (
          let run =
            let open Abbs_future_combinators.Infix_result_monad in
            Pgsql_pool.with_conn storage ~f:(fun db ->
                Pgsql_io.Prepared_stmt.fetch
                  db
                  (Sql.select_running_work_manifest ())
                  ~f:CCFun.id
                  work_manifest_id
                >>= function
                | _ :: _ -> (
                    (* The work manifest is running, so check the signature *)
                    Pgsql_io.Prepared_stmt.fetch db (Sql.select_encryption_key ()) ~f:CCFun.id
                    >>= function
                    | key :: _ ->
                        let token_decoded = Base64.decode_exn token in
                        let signature =
                          Cstruct.to_string
                            (Mirage_crypto.Hash.SHA256.hmac
                               ~key
                               (Cstruct.of_string (Uuidm.to_string work_manifest_id)))
                        in
                        Abb.Future.return (Ok (CCString.equal token_decoded signature))
                    | [] -> assert false)
                | [] -> Abb.Future.return (Ok false))
          in
          let open Abb.Future.Infix_monad in
          run
          >>= function
          | Ok ret -> Abb.Future.return ret
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m ->
                  m
                    "EP_WORK_MANIFEST : %s : ACCESS_TOKEN : %a"
                    (Brtl_ctx.token ctx)
                    Pgsql_pool.pp_err
                    err);
              Abb.Future.return false
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m ->
                  m
                    "EP_WORK_MANIFEST : %s : ACCESS_TOKEN : %a"
                    (Brtl_ctx.token ctx)
                    Pgsql_io.pp_err
                    err);
              Abb.Future.return false)
      | _ -> Abb.Future.return false

    let github_permissions =
      Githubc2_components.App_permissions.(
        make
          Primary.
            {
              actions = None;
              administration = None;
              checks = None;
              contents = Some "read";
              deployments = None;
              environments = None;
              issues = Some "write";
              members = None;
              metadata = None;
              organization_administration = None;
              organization_announcement_banners = None;
              organization_custom_roles = None;
              organization_hooks = None;
              organization_packages = None;
              organization_personal_access_token_requests = None;
              organization_personal_access_tokens = None;
              organization_plan = None;
              organization_projects = None;
              organization_secrets = None;
              organization_self_hosted_runners = None;
              organization_user_blocking = None;
              packages = None;
              pages = None;
              pull_requests = Some "write";
              repository_hooks = None;
              repository_projects = None;
              secret_scanning_alerts = None;
              secrets = None;
              security_events = None;
              single_file = None;
              statuses = Some "write";
              team_discussions = None;
              vulnerability_alerts = None;
              workflows = None;
            })

    let post config storage work_manifest_id ctx =
      Brtl_permissions.with_permissions
        [ access_permission storage ]
        ctx
        work_manifest_id
        (fun () ->
          let open Abb.Future.Infix_monad in
          Pgsql_pool.with_conn storage ~f:(fun db ->
              Pgsql_io.Prepared_stmt.fetch
                db
                (Sql.select_installation_id ())
                ~f:CCFun.id
                work_manifest_id)
          >>= function
          | Ok (installation_id :: _) -> (
              Cache.fetch cache installation_id (fun () ->
                  Terrat_github.get_installation_access_token
                    ~permissions:github_permissions
                    config
                    (CCInt64.to_int installation_id))
              >>= function
              | Ok access_token ->
                  let body =
                    Terrat_api_work_manifest.Get_access_token.Responses.OK.(
                      to_yojson { access_token })
                    |> Yojson.Safe.to_string
                  in
                  Abb.Future.return
                    (Brtl_ctx.set_response
                       (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
                       ctx)
              | Error (#Terrat_github.get_installation_access_token_err as err) ->
                  Logs.err (fun m ->
                      m
                        "EP_GITHUB_WORK_MANIFEST : %s : ACCESS_TOKEN : %a"
                        (Brtl_ctx.token ctx)
                        Terrat_github.pp_get_installation_access_token_err
                        err);
                  Abb.Future.return
                    (Brtl_ctx.set_response
                       (Brtl_rspnc.create ~status:`Internal_server_error "")
                       ctx))
          | Ok [] ->
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m ->
                  m
                    "EP_GITHUB_WORK_MANIFEST : %s : ACCESS_TOKEN : %a"
                    (Brtl_ctx.token ctx)
                    Pgsql_pool.pp_err
                    err);
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m ->
                  m
                    "EP_GITHUB_WORK_MANIFEST : %s : ACCESS_TOKEN : %a"
                    (Brtl_ctx.token ctx)
                    Pgsql_io.pp_err
                    err);
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
  end
end
