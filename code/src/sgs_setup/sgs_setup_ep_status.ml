let src = Logs.Src.create "ep_status"

let response ~step ~mode =
  let needs_setup =
    match step with
    | `License | `Register -> true
    | `Done -> false
  in
  let body =
    Yojson.Safe.to_string
    @@ Sgs_api_components_setup_status_response.to_yojson
         { Sgs_api_components_setup_status_response.mode; needs_setup }
  in
  Brtl_rspnc.create ~status:`OK body

let run ~requirement ~api_mode config storage =
  Brtl_ep.run_json ~f:(fun ctx ->
      let open Abb.Future.Infix_monad in
      let mode = api_mode () in
      Pgsql_pool.with_conn storage ~f:(fun db -> Sgs_setup_step.next ~requirement config db)
      >>= function
      | Ok step -> Abb.Future.return (Brtl_ctx.set_response (response ~step ~mode) ctx)
      | Error ((#Pgsql_pool.err | #Pgsql_io.err) as err) ->
          Abb.Future.return @@ Sgs_eplib.respond_db_err ~src ctx err)
