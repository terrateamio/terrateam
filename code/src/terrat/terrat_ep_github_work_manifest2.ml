module String_map = CCMap.Make (CCString)
module Dirspace_map = CCMap.Make (Terrat_change.Dirspace)

module Metrics = struct
  let namespace = "terrat"
  let subsystem = "ep_github_work_manifest"

  module Run_output_histogram = Prmths.Histogram (struct
    let spec =
      Prmths.Histogram_spec.of_list [ 500.0; 1000.0; 2500.0; 10000.0; 20000.0; 35000.0; 65000.0 ]
  end)

  module Plan_histogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_list [ 1000.0; 10000.0; 100000.0; 1000000.0; 1000000.0 ]
  end)

  module Work_manifest_run_time_histogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_exponential 20.0 1.5 10
  end)

  let plan_chars =
    let help = "Size of plans" in
    Plan_histogram.v ~help ~namespace ~subsystem "plan_chars"
end

module Sql = struct
  let select_encryption_key () =
    (* The hex conversion is so that there are no issues with escaping
       the string *)
    Pgsql_io.Typed_sql.(
      sql
      // (* data *) Ret.ud' CCFun.(Cstruct.of_hex %> CCOption.return)
      /^ "select encode(data, 'hex') from encryption_keys order by rank limit 1")
end

let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

module Initiate = struct
  module I = Terrat_api_components_work_manifest_initiate

  let post' config storage work_manifest_id { I.run_id; sha = branch_ref } ctx =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.Prepared_stmt.fetch db (Sql.select_encryption_key ()) ~f:CCFun.id)
    >>= function
    | [] -> assert false
    | encryption_key :: _ ->
        let request_id = Brtl_ctx.token ctx in
        Terrat_github_evaluator2.Event.Initiate.(
          eval
            (make
               ~branch_ref:(Terrat_github_evaluator2.Ref.of_string branch_ref)
               ~config
               ~encryption_key
               ~request_id
               ~run_id
               ~storage
               ~work_manifest_id
               ()))
        >>= fun r ->
        Terrat_github_evaluator2.Runner.(eval (make ~config ~request_id ~storage ()))
        >>= fun () -> Abb.Future.return (Ok r)

  let post config storage work_manifest_id initiate ctx =
    let open Abb.Future.Infix_monad in
    post' config storage work_manifest_id initiate ctx
    >>= function
    | Ok response ->
        let body =
          response
          |> Terrat_api_work_manifest.Initiate.Responses.OK.to_yojson
          |> Yojson.Safe.to_string
        in
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~headers:response_headers ~status:`OK body) ctx)
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
  module Pc = Terrat_api_components.Plan_create

  let post config storage work_manifest_id { Pc.path; workspace; plan_data; has_changes } ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    let plan = Base64.decode_exn plan_data in
    Metrics.Plan_histogram.observe Metrics.plan_chars (CCFloat.of_int (CCString.length plan));
    Terrat_github_evaluator2.Event.Plan_set.(
      eval
        (make
           ~config
           ~data:plan
           ~dir:path
           ~has_changes
           ~request_id
           ~storage
           ~work_manifest_id
           ~workspace
           ()))
    >>= function
    | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
    | Error `Error ->
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)

  let get config storage work_manifest_id dir workspace ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    Terrat_github_evaluator2.Event.Plan_get.(
      eval (make ~config ~dir ~request_id ~storage ~work_manifest_id ~workspace ()))
    >>= function
    | Ok (Some data) ->
        let response =
          Terrat_api_work_manifest.Plan_get.Responses.OK.(
            { data = Base64.encode_exn data } |> to_yojson)
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
    Terrat_github_evaluator2.Event.Result.(
      eval (make ~config ~request_id ~result ~storage ~work_manifest_id ()))
    >>= fun r ->
    Terrat_github_evaluator2.Runner.(eval (make ~config ~request_id ~storage ()))
    >>= fun _ ->
    match r with
    | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
    | Error `Error ->
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
end

module Access_token = struct
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
            github_installation_repositories as gir on gwm.repository = gir.id where gwm.id = $id"
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
            Terrat_github.get_installation_access_token
              ~permissions:github_permissions
              config
              (CCInt64.to_int installation_id)
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
                  (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
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