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
          Evaluator.run_work_manifest_initiate
            ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
            ~encryption_key
            work_manifest_id
            initiate
          >>= fun r -> Abb.Future.return (Ok r)

    let post config storage work_manifest_id initiate =
      let open Abb.Future.Infix_monad in
      Brtl_ep.run_json ~f:(fun ctx ->
          post' config storage work_manifest_id initiate ctx
          >>= function
          | Ok (Some response) ->
              let body =
                response
                |> Terrat_api_work_manifest.Initiate.Responses.OK.to_yojson
                |> Yojson.Safe.to_string
              in
              Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
          | Ok None ->
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m ->
                  m "%s : ACCESS_TOKEN : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m ->
                  m "%s : ACCESS_TOKEN : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
          | Error `Error ->
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
  end

  module Plans = struct
    let post config storage work_manifest_id plan ctx =
      let open Abb.Future.Infix_monad in
      let request_id = Brtl_ctx.token ctx in
      Evaluator.run_plan_store
        ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
        work_manifest_id
        plan
      >>= function
      | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
      | Error `Error ->
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)

    let get config storage work_manifest_id dir workspace =
      let open Abb.Future.Infix_monad in
      Brtl_ep.run_json ~f:(fun ctx ->
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
              Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK response) ctx)
          | Ok None ->
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
          | Error `Error ->
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
  end

  module Results = struct
    let put config storage work_manifest_id result =
      let open Abb.Future.Infix_monad in
      Brtl_ep.run_json ~f:(fun ctx ->
          let request_id = Brtl_ctx.token ctx in
          Evaluator.run_work_manifest_result
            ~ctx:(Evaluator.Ctx.make ~request_id ~config ~storage ())
            work_manifest_id
            result
          >>= fun r ->
          match r with
          | Ok () ->
              Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
          | Error `Error ->
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
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
      let open Abb.Future.Infix_monad in
      Brtl_ep.run_json ~f:(fun ctx ->
          Pgsql_pool.with_conn storage ~f:(fun db ->
              Pgsql_io.Prepared_stmt.fetch db Sql.select_workspaces ~f:CCFun.id work_manifest_id)
          >>= function
          | Ok [] ->
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
          | Ok (workspaces :: _) ->
              let body =
                Terrat_api_components.Work_manifest_workspaces.to_yojson workspaces
                |> Yojson.Safe.to_string
              in
              Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m ->
                  m "%s : WORKSPACES : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m -> m "%s : WORKSPACES : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
  end
end
