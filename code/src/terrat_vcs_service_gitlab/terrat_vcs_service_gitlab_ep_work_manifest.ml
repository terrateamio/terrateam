let src = Logs.Src.create "vcs_service_gitlab_ep_work_manifest"

module Logs = (val Logs.src_log src : Logs.LOG)

module Make (P : Terrat_vcs_provider2_gitlab.S) = struct
  module Evaluator = Terrat_vcs_event_evaluator.Make (P)

  module Sql = struct
    let select_encryption_key () =
      (* The hex conversion is so that there are no issues with escaping
     the string *)
      Pgsql_io.Typed_sql.(
        sql
        //
        (* data *)
        Ret.ud' CCFun.(Cstruct.of_hex %> CCOption.return)
        /^ "select encode(data, 'hex') from encryption_keys order by rank limit 1")

    let select_running_work_manifest () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.uuid
        /^ "select id from work_manifests where id = $id and state in ('queued', 'running')"
        /% Var.uuid "id")
  end

  let enforce_work_manifest_access access_token_id work_manifest_id storage ctx =
    let open Abb.Future.Infix_monad in
    match access_token_id with
    | Some access_token_id when Uuidm.equal access_token_id work_manifest_id -> (
        Pgsql_pool.with_conn storage ~f:(fun db ->
            Pgsql_io.Prepared_stmt.fetch
              db
              (Sql.select_running_work_manifest ())
              ~f:CCFun.id
              work_manifest_id)
        >>= function
        | Ok [] -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))
        | Ok (_ :: _) -> Abb.Future.return (Ok ())
        | Error (#Pgsql_pool.err | #Pgsql_io.err) ->
            Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx)))
    | Some _ | None -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))

  module Initiate = struct
    module I = Terrat_api_components_work_manifest_initiate

    let post' config storage work_manifest_id initiate ctx =
      let open Abbs_future_combinators.Infix_result_monad in
      (* TODO: Remove. We do not require this anymore *)
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch db (Sql.select_encryption_key ()) ~f:CCFun.id)
      >>= function
      | [] -> assert false
      | encryption_key :: _ ->
          let request_id = Brtl_ctx.token ctx in
          Evaluator.run_work_manifest_initiate
            ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
            ~encryption_key
            work_manifest_id
            initiate
          >>= fun r -> Abb.Future.return (Ok r)

    let post config storage work_manifest_id initiate =
      let open Abbs_future_combinators.Infix_result_monad in
      Brtl_ep.run_result_json ~f:(fun ctx ->
          (* Initiate isn't called with any auth other than knowing what work
             manifest it's calling more, so enforce that they have access to the
             work manifest, pretending we got a token with the work manifest as
             the access token. *)
          enforce_work_manifest_access (Some work_manifest_id) work_manifest_id storage ctx
          >>= fun () ->
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
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
          | Ok None ->
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx))
          | Error `Forbidden ->
              Logs.err (fun m -> m "%s : ACCESS_TOKEN : FORBIDDEN" (Brtl_ctx.token ctx));
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m ->
                  m "%s : ACCESS_TOKEN : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m ->
                  m "%s : ACCESS_TOKEN : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error `Error ->
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
  end

  module Plans = struct
    let post config storage work_manifest_id plan =
      let open Abb.Future.Infix_monad in
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          (* TODO: Uncomment once all runs are on new work manifest access tokens *)
          (* Terrat_session.with_session ctx *)
          (* >>= fun user -> *)
          (* enforce_work_manifest_access *)
          (*   (Terrat_user.access_token_id user) *)
          (*   work_manifest_id *)
          (*   storage *)
          (*   ctx *)
          (* >>= fun () -> *)
          enforce_work_manifest_access (Some work_manifest_id) work_manifest_id storage ctx
          >>= fun () ->
          let open Abb.Future.Infix_monad in
          let request_id = Brtl_ctx.token ctx in
          Evaluator.run_plan_store
            ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
            work_manifest_id
            plan
          >>= function
          | Ok () ->
              Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx))
          | Error `Error ->
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))

    let get config storage work_manifest_id dir workspace =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          (* TODO: Uncomment once all runs are on new work manifest access tokens *)
          (* Terrat_session.with_session ctx *)
          (* >>= fun user -> *)
          (* enforce_work_manifest_access *)
          (*   (Terrat_user.access_token_id user) *)
          (*   work_manifest_id *)
          (*   storage *)
          (*   ctx *)
          (* >>= fun () -> *)
          enforce_work_manifest_access (Some work_manifest_id) work_manifest_id storage ctx
          >>= fun () ->
          let open Abb.Future.Infix_monad in
          let request_id = Brtl_ctx.token ctx in
          Evaluator.run_plan_fetch
            ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
            work_manifest_id
            { Terrat_dirspace.dir; workspace }
          >>= function
          | Ok (Some data) ->
              let response =
                Terrat_api_work_manifest.Plan_get.Responses.OK.({ data } |> to_yojson)
                |> Yojson.Safe.to_string
              in
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK response) ctx))
          | Ok None ->
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx))
          | Error `Error ->
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
  end

  module Results = struct
    let put config storage work_manifest_id result =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          (* TODO: Uncomment once all runs are on new work manifest access tokens *)
          (* Terrat_session.with_session ctx *)
          (* >>= fun user -> *)
          (* enforce_work_manifest_access *)
          (*   (Terrat_user.access_token_id user) *)
          (*   work_manifest_id *)
          (*   storage *)
          (*   ctx *)
          (* >>= fun () -> *)
          enforce_work_manifest_access (Some work_manifest_id) work_manifest_id storage ctx
          >>= fun () ->
          let open Abb.Future.Infix_monad in
          let request_id = Brtl_ctx.token ctx in
          Evaluator.run_work_manifest_result
            ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
            work_manifest_id
            result
          >>= fun r ->
          match r with
          | Ok () ->
              Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx))
          | Error `Error ->
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
  end

  module Workspaces = struct
    module Sql = struct
      let dirspaces =
        let module P = struct
          type t = Terrat_api_components.Work_manifest_workspaces.t [@@deriving yojson]
        end in
        CCFun.(
          CCOption.wrap Yojson.Safe.from_string
          %> CCOption.map P.of_yojson
          %> CCOption.flat_map CCResult.to_opt)

      let select_workspaces =
        Pgsql_io.Typed_sql.(
          sql
          //
          (* dirspaces *)
          Ret.(ud' dirspaces)
          /^ "select dirspaces from work_manifests where id = $id and state in ('queued', \
              'running')"
          /% Var.uuid "id")
    end

    let get config storage work_manifest_id =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          (* TODO: Uncomment once all runs are on new work manifest access tokens *)
          (* Terrat_session.with_session ctx *)
          (* >>= fun user -> *)
          (* enforce_work_manifest_access *)
          (*   (Terrat_user.access_token_id user) *)
          (*   work_manifest_id *)
          (*   storage *)
          (*   ctx *)
          (* >>= fun () -> *)
          enforce_work_manifest_access (Some work_manifest_id) work_manifest_id storage ctx
          >>= fun () ->
          let open Abb.Future.Infix_monad in
          Pgsql_pool.with_conn storage ~f:(fun db ->
              Pgsql_io.Prepared_stmt.fetch db Sql.select_workspaces ~f:CCFun.id work_manifest_id)
          >>= function
          | Ok [] ->
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx))
          | Ok (workspaces :: _) ->
              let body =
                Terrat_api_components.Work_manifest_workspaces.to_yojson workspaces
                |> Yojson.Safe.to_string
              in
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m ->
                  m "%s : WORKSPACES : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m -> m "%s : WORKSPACES : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
  end
end
