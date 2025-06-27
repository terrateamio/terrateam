let src = Logs.Src.create "terrat_ep_tenv"

module Logs = (val Logs.src_log src : Logs.LOG)

module Metrics = struct
  let namespace = "terrat"
  let subsystem = "ep_tenv"

  let cache_fn_call_count =
    let help = "Count of cache calls by function with hit or miss or evict" in
    let family =
      Prmths.Counter.v_labels
        ~label_names:[ "lifetime"; "fn"; "type" ]
        ~help
        ~namespace
        ~subsystem
        "cache_fn_call_count"
    in
    fun ~l ~fn t -> Prmths.Counter.labels family [ l; fn; t ]
end

module Http = Abb_curl.Make (Abb)
module Cache = Abb_cache.Make (Abb)

module Sql = struct
  let validate_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      /^ "select id from work_manifests where id = $id and state = 'running'"
      /% Var.uuid "id")
end

module Tenv_cache = Cache.Filesystem.Make (struct
  type k = string [@@deriving eq]
  type v = string
  type err = Http.request_err
  type args = unit -> (v, err) result Abb.Future.t

  let fetch f = f ()
  let weight = CCString.length
end)

let on_hit fn () = Prmths.Counter.inc_one (Metrics.cache_fn_call_count ~l:"global" ~fn "hit")
let on_miss fn () = Prmths.Counter.inc_one (Metrics.cache_fn_call_count ~l:"global" ~fn "miss")
let on_evict fn () = Prmths.Counter.inc_one (Metrics.cache_fn_call_count ~l:"global" ~fn "evict")

let tenv_cache =
  Tenv_cache.create
    {
      Cache.Filesystem.on_hit = on_hit "tenv";
      on_miss = on_miss "tenv";
      on_evict = on_evict "tenv";
      path =
        Filename.concat
          (CCOption.get_or ~default:"/tmp" @@ Sys.getenv_opt "TERRAT_CACHE_DIR")
          "tenv";
    }

let get config storage _origin work_manifest_id path ctx =
  let open Abb.Future.Infix_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.fetch db Sql.validate_work_manifest ~f:CCFun.id work_manifest_id)
  >>= function
  | Ok [] -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx)
  | Ok (_ :: _) -> (
      let fetch () =
        let open Abbs_future_combinators.Infix_result_monad in
        let url = Uri.with_path (Uri.of_string "https://github.com") path in
        Http.get url >>= fun (resp, body) -> Abb.Future.return (Ok body)
      in
      Tenv_cache.fetch tenv_cache path fetch
      >>= function
      | Ok body ->
          Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
      | Error (`Cache_err (#Cache.Filesystem.cache_err as err)) ->
          Logs.err (fun m ->
              m "%s : GET : %a" (Brtl_ctx.token ctx) Cache.Filesystem.pp_cache_err err);
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Error (`Fetch_err (#Http.request_err as err)) ->
          Logs.err (fun m -> m "%s : GET : %a" (Brtl_ctx.token ctx) Http.pp_request_err err);
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "%s : GET : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "%s : GET : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
