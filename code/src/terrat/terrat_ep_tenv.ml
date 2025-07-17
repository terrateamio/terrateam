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

module V = struct
  type t = {
    headers : (string * string) list;
    body : string;
  }
  [@@deriving yojson]
end

module Tenv_cache = Cache.Filesystem.Make (struct
  type k = string [@@deriving eq]
  type v = V.t
  type err = Http.request_err
  type args = unit -> (v, err) result Abb.Future.t

  let fetch f = f ()
  let weight = CCFun.(V.to_yojson %> Yojson.Safe.to_string %> CCString.length)
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
      to_string = CCFun.(V.to_yojson %> Yojson.Safe.pretty_to_string);
      of_string =
        CCFun.(
          CCOption.wrap Yojson.Safe.from_string
          %> CCOption.flat_map (V.of_yojson %> CCOption.of_result));
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
        Http.get url
        >>= fun (resp, body) ->
        let headers = Http.Response.headers resp in
        let headers_of_interest =
          CCList.filter_map
            (fun h -> CCOption.map (fun v -> (h, v)) @@ Http.Headers.get h headers)
            [ "content-length"; "content-type" ]
        in
        Abb.Future.return (Ok { V.body; headers = headers_of_interest })
      in
      Tenv_cache.fetch tenv_cache path fetch
      >>= function
      | Ok v ->
          let headers = Cohttp.Header.of_list v.V.headers in
          let body = v.V.body in
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~headers ~status:`OK body) ctx)
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
