let src = Logs.Src.create "terrat_tenv"

module Logs = (val Logs.src_log src : Logs.LOG)
module Http = Abb_curl.Make (Abb)
module Cache = Abb_cache.Make (Abb)

module Tenv_cache = Cache.Filesystem.Make (struct
  type k = string [@@deriving eq]
  type v = string
  type err = Http.request_err
  type args = unit -> (v, err) result Abb.Future.t

  let fetch f = f ()
  let weight = CCString.length
end)

let tenv_cache =
  Tenv_cache.create
    {
      Cache.Filesystem.on_hit = CCFun.const ();
      on_miss = CCFun.const ();
      on_evict = CCFun.const ();
      path =
        Filename.concat
          (CCOption.get_or ~default:"/tmp" @@ Sys.getenv_opt "TERRAT_CACHE_DIR")
          "tenv";
    }

let get config storage _origin work_manifest_id path ctx =
  let open Abb.Future.Infix_monad in
  let fetch () =
    let open Abbs_future_combinators.Infix_result_monad in
    let url = Uri.with_path (Uri.of_string "https://github.com") path in
    Http.get url >>= fun (resp, body) -> Abb.Future.return (Ok body)
  in
  Tenv_cache.fetch tenv_cache path fetch
  >>= function
  | Ok body -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
  | Error (`Cache_err (#Cache.Filesystem.cache_err as err)) ->
      Logs.err (fun m -> m "GET : %a" Cache.Filesystem.pp_cache_err err);
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (`Fetch_err (#Http.request_err as err)) ->
      Logs.err (fun m -> m "GET : %a" Http.pp_request_err err);
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
