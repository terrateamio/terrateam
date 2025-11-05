module type S = sig
  module Installation_id : Terrat_vcs_api.ID

  val namespace_prefix : string
  val route_root : unit -> ('a, 'a) Brtl_rtng.Route.t

  val enforce_installation_access :
    request_id:string ->
    Terrat_user.t ->
    Installation_id.t ->
    Pgsql_io.t ->
    (unit, [> `Forbidden ]) result Abb.Future.t
end

module Make (P : Terrat_vcs_provider2.S) (S : S with type Installation_id.t = P.Api.Account.Id.t) =
struct
  let src = Logs.Src.create ("vcs_kv_store_" ^ S.namespace_prefix)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Cap = Terrat_user.Capability

  let enforce_installation_access storage user installation_id ctx =
    let open Abb.Future.Infix_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        S.enforce_installation_access ~request_id:(Brtl_ctx.token ctx) user installation_id db)
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error `Forbidden -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))
    | Error (#Pgsql_pool.err as err) ->
        Logs.err (fun m -> m "%s : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
        Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))

  let make_key installation_id key =
    (S.namespace_prefix ^ ":" ^ P.Api.Account.Id.to_string installation_id, key)

  let ror r =
    {
      Terrat_api_components_kv_record.committed = Terrat_kv_store.Record.committed r;
      created_at = Terrat_kv_store.Record.created_at r;
      idx = Terrat_kv_store.Record.idx r;
      data = Terrat_kv_store.Record.data r;
      key = snd @@ Terrat_kv_store.Record.key r;
      size = Terrat_kv_store.Record.size r;
      version = Terrat_kv_store.Record.version r;
    }

  let rec is_syntax_err = function
    | [] -> false
    | Pgsql_codec.Frame.Backend.ErrorResponse { msgs } :: fs ->
        if CCList.exists (fun (_, msg) -> CCString.find ~sub:"syntax error" msg <> -1) msgs then
          true
        else is_syntax_err fs
    | _ :: fs -> is_syntax_err fs

  let kv_run ctx storage r f =
    let open Abb.Future.Infix_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        f db
        >>= function
        | Ok _ as r -> Abb.Future.return r
        | Error #Terrat_kv_store.err as err -> Abb.Future.return err)
    >>= function
    | Ok res -> Abb.Future.return (Ok (r res))
    | Error (#Pgsql_pool.err as err) ->
        Logs.info (fun m -> m "%s : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
        Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
    | Error (`Unmatching_frame fs) when is_syntax_err fs ->
        Logs.info (fun m -> m "%s : PARSE FAILURE" (Brtl_ctx.token ctx));
        Abb.Future.return
          (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx))
    | Error (#Terrat_kv_store.err as err) ->
        Logs.info (fun m -> m "%s : %a" (Brtl_ctx.token ctx) Terrat_kv_store.pp_err err);
        Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))

  module Get = struct
    let run config storage installation_id key committed idx select =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ~caps:[ Cap.Kv_store_read ] ctx
          >>= fun user ->
          enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let key = make_key installation_id key in
          kv_run
            ctx
            storage
            (function
              | Some r ->
                  Brtl_ctx.set_response
                    (Brtl_rspnc.create
                       ~status:`OK
                       (Yojson.Safe.to_string @@ Terrat_api_components_kv_record.to_yojson @@ ror r))
                    ctx
              | None -> Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
            (Terrat_kv_store.get ?select ?idx ?committed ~key))
  end

  module Set = struct
    let run config storage installation_id key body =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ~caps:[ Cap.Kv_store_write ] ctx
          >>= fun user ->
          enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let key = make_key installation_id key in
          let { Terrat_api_components_kv_set.committed; data; idx } = body in
          kv_run
            ctx
            storage
            (fun r ->
              Brtl_ctx.set_response
                (Brtl_rspnc.create
                   ~status:`OK
                   (Yojson.Safe.to_string
                   @@ Terrat_api_components_kv_record.to_yojson
                   (* We remove data from the returned response for bandwidth
                      reasons.  We replace it with Null, which is valid
                      JSON. Gotta save those bytes *)
                   @@ (fun r -> { r with Terrat_api_components_kv_record.data = `Null })
                   @@ ror r))
                ctx)
            (Terrat_kv_store.set ?idx ?committed ~key data))
  end

  module Cas = struct
    let run config storage installation_id key body =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ~caps:[ Cap.Kv_store_read; Cap.Kv_store_write ] ctx
          >>= fun user ->
          enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let key = make_key installation_id key in
          let { Terrat_api_components_kv_cas.committed; data; idx; version } = body in
          kv_run
            ctx
            storage
            (function
              | Some r ->
                  Brtl_ctx.set_response
                    (Brtl_rspnc.create
                       ~status:`OK
                       (Yojson.Safe.to_string
                       @@ Terrat_api_components_kv_record.to_yojson
                       (* We remove data from the returned response for
                          bandwidth reasons.  We replace it with Null, which is
                          valid JSON. Gotta save those bytes *)
                       @@ (fun r -> { r with Terrat_api_components_kv_record.data = `Null })
                       @@ ror r))
                    ctx
              | None -> Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
            (Terrat_kv_store.cas ?idx ?committed ?version ~key data))
  end

  module Delete = struct
    let run config storage installation_id key idx version =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ~caps:[ Cap.Kv_store_read; Cap.Kv_store_write ] ctx
          >>= fun user ->
          enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let key = make_key installation_id key in
          kv_run
            ctx
            storage
            (fun r ->
              Brtl_ctx.set_response
                (Brtl_rspnc.create
                   ~status:`OK
                   (Yojson.Safe.to_string
                   @@ Terrat_api_components_kv_delete.(to_yojson { result = r })))
                ctx)
            (Terrat_kv_store.delete ?idx ?version ~key))
  end

  module Count = struct
    let run config storage installation_id key committed =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ~caps:[ Cap.Kv_store_read ] ctx
          >>= fun user ->
          enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let key = make_key installation_id key in
          kv_run
            ctx
            storage
            (function
              | Some { Kv_store_intf.Count.count; max_idx } ->
                  Brtl_ctx.set_response
                    (Brtl_rspnc.create
                       ~status:`OK
                       (Yojson.Safe.to_string
                       @@ Terrat_api_components_kv_count.(to_yojson { count; max_idx })))
                    ctx
              | None -> Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
            (Terrat_kv_store.count ?committed ~key))
  end

  module Size = struct
    let run config storage installation_id key idx committed =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ~caps:[ Cap.Kv_store_read ] ctx
          >>= fun user ->
          enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let key = make_key installation_id key in
          kv_run
            ctx
            storage
            (function
              | Some size ->
                  Brtl_ctx.set_response
                    (Brtl_rspnc.create
                       ~status:`OK
                       (Yojson.Safe.to_string @@ Terrat_api_components_kv_size.(to_yojson { size })))
                    ctx
              | None -> Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
            (Terrat_kv_store.size ?idx ?committed ~key))
  end

  module Iter = struct
    let run config storage installation_id key select idx inclusive committed prefix limit =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ~caps:[ Cap.Kv_store_read ] ctx
          >>= fun user ->
          enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let key = make_key installation_id key in
          kv_run
            ctx
            storage
            (fun results ->
              let module R = Terrat_api_components_kv_record_list in
              Brtl_ctx.set_response
                (Brtl_rspnc.create
                   ~status:`OK
                   (Yojson.Safe.to_string @@ R.to_yojson @@ { R.results = CCList.map ror results }))
                ctx)
            (Terrat_kv_store.iter ?select ?idx ?inclusive ?committed ?prefix ?limit ~key))
  end

  module Commit = struct
    let run config storage installation_id commit =
      Brtl_ep.run_result_json ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ~caps:[ Cap.Kv_store_write ] ctx
          >>= fun user ->
          enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let module C = Terrat_api_components_kv_commit in
          let module R = Terrat_api_components_kv_commit_result in
          let { C.keys } = commit in
          let keys =
            CCList.map (fun { C.Keys.Items.key; idx } -> (make_key installation_id key, idx)) keys
          in
          kv_run
            ctx
            storage
            (fun r ->
              Brtl_ctx.set_response
                (Brtl_rspnc.create
                   ~status:`OK
                   (Yojson.Safe.to_string
                   @@ R.to_yojson
                   @@ { R.keys = CCList.map (fun ((_, key), idx) -> { R.Keys.Items.key; idx }) r }))
                ctx)
            (Terrat_kv_store.commit ~keys))
  end

  module Rt = struct
    let kv_rt () = Brtl_rtng.Route.(S.route_root () / "kv" /% Path.ud S.Installation_id.of_string)

    let kv_get_rt () =
      Brtl_rtng.Route.(
        kv_rt ()
        / "key"
        /% Path.any
        /? Query.option (Query.bool "committed")
        /? Query.option (Query.int "idx")
        /? Query.option
             (Query.ud_array "select" (fun paths ->
                  let paths = CCList.filter (( <> ) "") paths in
                  let paths =
                    CCResult.map_l
                      (fun path ->
                        match CCString.Split.left ~by:"=" path with
                        | Some (k, path) -> Ok (k, path)
                        | None -> Error ())
                      paths
                  in
                  CCOption.of_result paths)))

    let kv_set_rt () =
      Brtl_rtng.Route.(
        kv_rt () / "key" /% Path.any /* Body.decode ~json:Terrat_api_components.Kv_set.of_yojson ())

    let kv_cas_rt () =
      Brtl_rtng.Route.(
        kv_rt ()
        / "cas"
        / "key"
        /% Path.any
        /* Body.decode ~json:Terrat_api_components.Kv_cas.of_yojson ())

    let kv_delete_rt () =
      Brtl_rtng.Route.(
        kv_rt () / "key" /% Path.any /? Query.(option (int "idx")) /? Query.(option (int "version")))

    let kv_count_rt () =
      Brtl_rtng.Route.(
        kv_rt () / "count" / "key" /% Path.string /? Query.(option (bool "committed")))

    let kv_size_rt () =
      Brtl_rtng.Route.(
        kv_rt ()
        / "size"
        / "key"
        /% Path.any
        /? Query.(option (int "idx"))
        /? Query.(option (bool "committed")))

    let kv_iter_rt () =
      Brtl_rtng.Route.(
        kv_rt ()
        / "iter"
        /% Path.any
        /? Query.option
             (Query.ud_array "select" (fun paths ->
                  let paths = CCList.filter (( <> ) "") paths in
                  let paths =
                    CCResult.map_l
                      (fun path ->
                        match CCString.Split.left ~by:"=" path with
                        | Some (k, path) -> Ok (k, path)
                        | None -> Error ())
                      paths
                  in
                  CCOption.of_result paths))
        /? Query.(option (int "idx"))
        /? Query.(option (bool "inclusive"))
        /? Query.(option (bool "committed"))
        /? Query.(option (bool "prefix"))
        /? Query.(option (int "limit")))

    let kv_commit_rt () =
      Brtl_rtng.Route.(
        kv_rt () / "commit" /* Body.decode ~json:Terrat_api_components.Kv_commit.of_yojson ())
  end

  let routes config storage =
    Brtl_rtng.Route.
      [
        (`GET, Rt.kv_get_rt () --> Get.run config storage);
        (`PUT, Rt.kv_set_rt () --> Set.run config storage);
        (`PUT, Rt.kv_cas_rt () --> Cas.run config storage);
        (`DELETE, Rt.kv_delete_rt () --> Delete.run config storage);
        (`GET, Rt.kv_count_rt () --> Count.run config storage);
        (`GET, Rt.kv_size_rt () --> Size.run config storage);
        (`GET, Rt.kv_iter_rt () --> Iter.run config storage);
        (`POST, Rt.kv_commit_rt () --> Commit.run config storage);
      ]
end
