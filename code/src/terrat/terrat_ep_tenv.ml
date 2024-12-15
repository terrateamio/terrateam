module Http = Cohttp_abb.Make (Abb)

let github_api_host = Uri.of_string "https://api.github.com"
let user_agent = "Terrateam"
let timeout = Duration.(to_f (of_sec 10))

module Releases = struct
  module Metrics = struct
    let namespace = "terrat"
    let subsystem = "ep_tenv"

    let cache_call_count =
      let help = "Count of cache calls by function with hit or miss or evict" in
      let family =
        Prmths.Counter.v_labels
          ~label_names:[ "type" ]
          ~help
          ~namespace
          ~subsystem
          "cache_call_count"
      in
      fun t -> Prmths.Counter.labels family [ t ]
  end

  module Cache = Abbs_cache.Expiring.Make (struct
    (* installation_id * owner * repo * page *)
    type k = int64 * string * string * int option [@@deriving eq]
    type v = Cohttp.Response.t * string

    type err =
      [ Cohttp_abb.request_err
      | Terrat_github.get_installation_access_token_err
      ]

    type args = unit -> (v, err) result Abb.Future.t

    let fetch f = f ()
    let weight (_, body) = CCString.length body
  end)

  let cache =
    Cache.create
      {
        Abbs_cache.Expiring.on_hit =
          (fun () -> Prmths.Counter.inc_one (Metrics.cache_call_count "hit"));
        on_miss = (fun () -> Prmths.Counter.inc_one (Metrics.cache_call_count "miss"));
        on_evict = (fun () -> Prmths.Counter.inc_one (Metrics.cache_call_count "evict"));
        duration = Duration.of_day 1;
        capacity = 100 * 1024 * 1024;
      }

  module Sql = struct
    let select_installation_id () =
      Pgsql_io.Typed_sql.(
        sql
        //
        (* id *)
        Ret.bigint
        /^ "select gir.installation_id from github_work_manifests as gwm inner join \
            github_installation_repositories as gir on gwm.repository = gir.id where gwm.id = $id \
            and state = 'running'"
        /% Var.uuid "id")
  end

  let tls_config = Otls.Tls_config.create ()

  let get' config storage owner repo page_opt work_manifest_id =
    match Ouuid.of_string work_manifest_id with
    | Some work_manifest_id -> (
        let open Abb.Future.Infix_monad in
        Pgsql_pool.with_conn storage ~f:(fun db ->
            let open Abbs_future_combinators.Infix_result_monad in
            Pgsql_io.Prepared_stmt.fetch
              db
              (Sql.select_installation_id ())
              ~f:CCFun.id
              work_manifest_id
            >>= function
            | installation_id :: _ -> Abb.Future.return (Ok installation_id)
            | _ -> Abb.Future.return (Error `Bad_request))
        >>= function
        | Ok installation_id -> (
            Cache.fetch cache (installation_id, owner, repo, page_opt) (fun () ->
                Abbs_future_combinators.timeout
                  ~timeout:(Abb.Sys.sleep timeout)
                  (let open Abbs_future_combinators.Infix_result_monad in
                   Terrat_github.get_installation_access_token
                     config
                     (CCInt64.to_int installation_id)
                   >>= fun access_token ->
                   Http.Client.call
                     ~headers:
                       (Cohttp.Header.of_list
                          [
                            ("user-agent", user_agent); ("authorization", "Bearer " ^ access_token);
                          ])
                     ~tls_config
                     `GET
                     (github_api_host
                     |> CCFun.flip Uri.with_path (Printf.sprintf "repos/%s/%s/releases" owner repo)
                     |> CCFun.flip
                          Uri.add_query_params'
                          (CCOption.map_or
                             ~default:[]
                             (fun page -> [ ("page", CCInt.to_string page) ])
                             page_opt)))
                >>= function
                | `Ok (Ok (response, body)) -> Abb.Future.return (Ok (response, body))
                | `Ok (Error err) -> Abb.Future.return (Error err)
                | `Timeout -> Abb.Future.return (Error `Timeout))
            >>= function
            | Ok _ as ret -> Abb.Future.return ret
            | Error (#Cache.err as err) -> Abb.Future.return (Error err))
        | Error ((`Bad_request | #Pgsql_pool.err | #Pgsql_io.err) as err) ->
            Abb.Future.return (Error err))
    | None -> Abb.Future.return (Error `Bad_request)

  let get config storage owner repo page_opt ctx =
    match Brtl_permissions.get_auth ctx with
    | Ok (Brtl_permissions.Auth.Bearer work_manifest_id) -> (
        let open Abb.Future.Infix_monad in
        get' config storage owner repo page_opt work_manifest_id
        >>= function
        | Ok (response, body) ->
            Abb.Future.return
              (Brtl_ctx.set_response
                 (Brtl_rspnc.create
                    ~headers:(Http.Response.headers response)
                    ~status:(Http.Response.status response)
                    body)
                 ctx)
        | Error `Bad_request ->
            Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx)
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m -> m "EP_TENV : %s : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m -> m "EP_TENV : %s : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (#Cohttp_abb.request_err as err) ->
            Logs.err (fun m ->
                m "EP_TENV : %s : %a" (Brtl_ctx.token ctx) Cohttp_abb.pp_request_err err);
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (#Terrat_github.get_installation_access_token_err as err) ->
            Logs.err (fun m ->
                m
                  "EP_TENV : %s : %a"
                  (Brtl_ctx.token ctx)
                  Terrat_github.pp_get_installation_access_token_err
                  err);
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
    | Error (#Brtl_permissions.get_auth_err as err) ->
        Logs.err (fun m ->
            m "EP_TENV : %s : %a" (Brtl_ctx.token ctx) Brtl_permissions.pp_get_auth_err err);
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx)
end
