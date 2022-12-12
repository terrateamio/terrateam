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

let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

module Initiate = struct
  let post config storage work_manifest_id work_manifest_initiate ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    Terrat_github_evaluator.Work_manifest.initiate
      ~request_id
      config
      storage
      work_manifest_id
      work_manifest_initiate
    >>= function
    | Some response ->
        let body =
          response
          |> Terrat_api_work_manifest.Initiate.Responses.OK.to_yojson
          |> Yojson.Safe.to_string
        in
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~headers:response_headers ~status:`OK body) ctx)
    | None ->
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
end

module Plans = struct
  module Pc = Terrat_api_components.Plan_create

  let post config storage work_manifest_id { Pc.path; workspace; plan_data } ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    let plan = Base64.decode_exn plan_data in
    Metrics.Plan_histogram.observe Metrics.plan_chars (CCFloat.of_int (CCString.length plan));
    Terrat_github_evaluator.Work_manifest.plan_store
      ~request_id
      ~path
      ~workspace
      storage
      work_manifest_id
      plan
    >>= function
    | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
    | Error `Error ->
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)

  let get config storage work_manifest_id path workspace ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    Terrat_github_evaluator.Work_manifest.plan_fetch
      ~request_id
      ~path
      ~workspace
      storage
      work_manifest_id
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
  let put config storage work_manifest_id results ctx =
    let open Abb.Future.Infix_monad in
    let request_id = Brtl_ctx.token ctx in
    Terrat_github_evaluator.Work_manifest.results_store
      ~request_id
      config
      storage
      work_manifest_id
      results
    >>= function
    | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
    | Error `Error ->
        Abb.Future.return
          (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
end
