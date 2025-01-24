let src = Logs.Src.create "abb_curl"

module Logs = (val Logs.src_log src : Logs.LOG)

module Method = struct
  type body = string

  type t =
    [ `GET
    | `PUT of body option
    | `POST of body option
    | `DELETE of body option
    | `PATCH of body option
    | `Custom of string * body option
    ]
end

module Status = struct
  type t =
    [ `Continue
    | `Switching_protocols
    | `Processing_webdav_rfc_2518
    | `Checkpoint
    | `Ok
    | `Created
    | `Accepted
    | `Non_authoritative_information_since_http_1_1
    | `No_content
    | `Reset_content
    | `Partial_content
    | `Multi_status_webdav_rfc_4918
    | `Already_reported_webdav_rfc_5842
    | `Im_used_rfc_3229
    | `Multiple_choices
    | `Moved_permanently
    | `Found
    | `See_other
    | `Not_modified
    | `Use_proxy_since_http_1_1
    | `Switch_proxy
    | `Temporary_redirect_since_http_1_1
    | `Permanent_redirect
    | `Bad_request
    | `Unauthorized
    | `Payment_required
    | `Forbidden
    | `Not_found
    | `Method_not_allowed
    | `Not_acceptable
    | `Proxy_authentication_required
    | `Request_timeout
    | `Conflict
    | `Gone
    | `Length_required
    | `Precondition_failed
    | `Request_entity_too_large
    | `Request_uri_too_long
    | `Unsupported_media_type
    | `Requested_range_not_satisfiable
    | `Expectation_failed
    | `Im_a_teapot_rfc_2324
    | `Enhance_your_calm
    | `Unprocessable_entity_webdav_rfc_4918
    | `Locked_webdav_rfc_4918
    | `Failed_dependency_webdav_rfc_4918
    | `Upgrade_required_rfc_2817
    | `Precondition_required
    | `Too_many_requests
    | `Request_header_fields_too_large
    | `No_response
    | `Retry_with
    | `Blocked_by_windows_parental_controls
    | `Wrong_exchange_server
    | `Client_closed_request
    | `Internal_server_error
    | `Not_implemented
    | `Bad_gateway
    | `Service_unavailable
    | `Gateway_timeout
    | `Http_version_not_supported
    | `Variant_also_negotiates_rfc_2295
    | `Insufficient_storage_webdav_rfc_4918
    | `Loop_detected_webdav_rfc_5842
    | `Bandwidth_limit_exceeded_apache_bw_limited_extension
    | `Not_extended_rfc_2774
    | `Network_authentication_required
    | `Network_read_timeout_error
    | `Network_connect_timeout_error
    | `Unknown of int
    ]

  let of_int = function
    | 100 -> `Continue
    | 101 -> `Switching_protocols
    | 102 -> `Processing_webdav_rfc_2518
    | 103 -> `Checkpoint
    | 200 -> `Ok
    | 201 -> `Created
    | 202 -> `Accepted
    | 203 -> `Non_authoritative_information_since_http_1_1
    | 204 -> `No_content
    | 205 -> `Reset_content
    | 206 -> `Partial_content
    | 207 -> `Multi_status_webdav_rfc_4918
    | 208 -> `Already_reported_webdav_rfc_5842
    | 226 -> `Im_used_rfc_3229
    | 300 -> `Multiple_choices
    | 301 -> `Moved_permanently
    | 302 -> `Found
    | 303 -> `See_other
    | 304 -> `Not_modified
    | 305 -> `Use_proxy_since_http_1_1
    | 306 -> `Switch_proxy
    | 307 -> `Temporary_redirect_since_http_1_1
    | 308 -> `Permanent_redirect
    | 400 -> `Bad_request
    | 401 -> `Unauthorized
    | 402 -> `Payment_required
    | 403 -> `Forbidden
    | 404 -> `Not_found
    | 405 -> `Method_not_allowed
    | 406 -> `Not_acceptable
    | 407 -> `Proxy_authentication_required
    | 408 -> `Request_timeout
    | 409 -> `Conflict
    | 410 -> `Gone
    | 411 -> `Length_required
    | 412 -> `Precondition_failed
    | 413 -> `Request_entity_too_large
    | 414 -> `Request_uri_too_long
    | 415 -> `Unsupported_media_type
    | 416 -> `Requested_range_not_satisfiable
    | 417 -> `Expectation_failed
    | 418 -> `Im_a_teapot_rfc_2324
    | 420 -> `Enhance_your_calm
    | 422 -> `Unprocessable_entity_webdav_rfc_4918
    | 423 -> `Locked_webdav_rfc_4918
    | 424 -> `Failed_dependency_webdav_rfc_4918
    | 426 -> `Upgrade_required_rfc_2817
    | 428 -> `Precondition_required
    | 429 -> `Too_many_requests
    | 431 -> `Request_header_fields_too_large
    | 444 -> `No_response
    | 449 -> `Retry_with
    | 450 -> `Blocked_by_windows_parental_controls
    | 451 -> `Wrong_exchange_server
    | 499 -> `Client_closed_request
    | 500 -> `Internal_server_error
    | 501 -> `Not_implemented
    | 502 -> `Bad_gateway
    | 503 -> `Service_unavailable
    | 504 -> `Gateway_timeout
    | 505 -> `Http_version_not_supported
    | 506 -> `Variant_also_negotiates_rfc_2295
    | 507 -> `Insufficient_storage_webdav_rfc_4918
    | 508 -> `Loop_detected_webdav_rfc_5842
    | 509 -> `Bandwidth_limit_exceeded_apache_bw_limited_extension
    | 510 -> `Not_extended_rfc_2774
    | 511 -> `Network_authentication_required
    | 598 -> `Network_read_timeout_error
    | 599 -> `Network_connect_timeout_error
    | code -> `Unknown code

  let to_int = function
    | `Continue -> 100
    | `Switching_protocols -> 101
    | `Processing_webdav_rfc_2518 -> 102
    | `Checkpoint -> 103
    | `Ok -> 200
    | `Created -> 201
    | `Accepted -> 202
    | `Non_authoritative_information_since_http_1_1 -> 203
    | `No_content -> 204
    | `Reset_content -> 205
    | `Partial_content -> 206
    | `Multi_status_webdav_rfc_4918 -> 207
    | `Already_reported_webdav_rfc_5842 -> 208
    | `Im_used_rfc_3229 -> 226
    | `Multiple_choices -> 300
    | `Moved_permanently -> 301
    | `Found -> 302
    | `See_other -> 303
    | `Not_modified -> 304
    | `Use_proxy_since_http_1_1 -> 305
    | `Switch_proxy -> 306
    | `Temporary_redirect_since_http_1_1 -> 307
    | `Permanent_redirect -> 308
    | `Bad_request -> 400
    | `Unauthorized -> 401
    | `Payment_required -> 402
    | `Forbidden -> 403
    | `Not_found -> 404
    | `Method_not_allowed -> 405
    | `Not_acceptable -> 406
    | `Proxy_authentication_required -> 407
    | `Request_timeout -> 408
    | `Conflict -> 409
    | `Gone -> 410
    | `Length_required -> 411
    | `Precondition_failed -> 412
    | `Request_entity_too_large -> 413
    | `Request_uri_too_long -> 414
    | `Unsupported_media_type -> 415
    | `Requested_range_not_satisfiable -> 416
    | `Expectation_failed -> 417
    | `Im_a_teapot_rfc_2324 -> 418
    | `Enhance_your_calm -> 420
    | `Unprocessable_entity_webdav_rfc_4918 -> 422
    | `Locked_webdav_rfc_4918 -> 423
    | `Failed_dependency_webdav_rfc_4918 -> 424
    | `Upgrade_required_rfc_2817 -> 426
    | `Precondition_required -> 428
    | `Too_many_requests -> 429
    | `Request_header_fields_too_large -> 431
    | `No_response -> 444
    | `Retry_with -> 449
    | `Blocked_by_windows_parental_controls -> 450
    | `Wrong_exchange_server -> 451
    | `Client_closed_request -> 499
    | `Internal_server_error -> 500
    | `Not_implemented -> 501
    | `Bad_gateway -> 502
    | `Service_unavailable -> 503
    | `Gateway_timeout -> 504
    | `Http_version_not_supported -> 505
    | `Variant_also_negotiates_rfc_2295 -> 506
    | `Insufficient_storage_webdav_rfc_4918 -> 507
    | `Loop_detected_webdav_rfc_5842 -> 508
    | `Bandwidth_limit_exceeded_apache_bw_limited_extension -> 509
    | `Not_extended_rfc_2774 -> 510
    | `Network_authentication_required -> 511
    | `Network_read_timeout_error -> 598
    | `Network_connect_timeout_error -> 599
    | `Unknown code -> code

  let is_success t =
    let code = to_int t in
    200 <= code && code < 300

  let to_string = function
    | `Continue -> "Continue"
    | `Switching_protocols -> "Switching protocols"
    | `Processing_webdav_rfc_2518 -> "Processing webdav rfc 2518"
    | `Checkpoint -> "Checkpoint"
    | `Ok -> "Ok"
    | `Created -> "Created"
    | `Accepted -> "Accepted"
    | `Non_authoritative_information_since_http_1_1 ->
        "Non-authoritative information since_http/1.1"
    | `No_content -> "No content"
    | `Reset_content -> "Reset content"
    | `Partial_content -> "Partial content"
    | `Multi_status_webdav_rfc_4918 -> "Multi status webdav rfc 4918"
    | `Already_reported_webdav_rfc_5842 -> "Already reported webdav rfc 5842"
    | `Im_used_rfc_3229 -> "I'm used rfc 3229"
    | `Multiple_choices -> "Multiple choices"
    | `Moved_permanently -> "Moved permanently"
    | `Found -> "Found"
    | `See_other -> "See other"
    | `Not_modified -> "Not modified"
    | `Use_proxy_since_http_1_1 -> "Use proxy since http/1.1"
    | `Switch_proxy -> "Switch proxy"
    | `Temporary_redirect_since_http_1_1 -> "Temporary redirect since http/1.1"
    | `Permanent_redirect -> "Permanent redirect"
    | `Bad_request -> "Bad request"
    | `Unauthorized -> "Unauthorized"
    | `Payment_required -> "Payment required"
    | `Forbidden -> "Forbidden"
    | `Not_found -> "Not found"
    | `Method_not_allowed -> "Method not allowed"
    | `Not_acceptable -> "Not acceptable"
    | `Proxy_authentication_required -> "Proxy authentication required"
    | `Request_timeout -> "Request timeout"
    | `Conflict -> "Conflict"
    | `Gone -> "Gone"
    | `Length_required -> "Length required"
    | `Precondition_failed -> "Precondition failed"
    | `Request_entity_too_large -> "Request entity too large"
    | `Request_uri_too_long -> "Request uri too long"
    | `Unsupported_media_type -> "Unsupported media type"
    | `Requested_range_not_satisfiable -> "Requested range not satisfiable"
    | `Expectation_failed -> "Expectation failed"
    | `Im_a_teapot_rfc_2324 -> "I'm a teapot rfc 2324"
    | `Enhance_your_calm -> "Enhance your calm"
    | `Unprocessable_entity_webdav_rfc_4918 -> "Unprocessable entity webdav rfc 4918"
    | `Locked_webdav_rfc_4918 -> "Locked webdav rfc 4918"
    | `Failed_dependency_webdav_rfc_4918 -> "Failed dependency webdav rfc 4918"
    | `Upgrade_required_rfc_2817 -> "Upgrade required rfc 2817"
    | `Precondition_required -> "Precondition required"
    | `Too_many_requests -> "Too many requests"
    | `Request_header_fields_too_large -> "Request header fields too large"
    | `No_response -> "No response"
    | `Retry_with -> "Retry with"
    | `Blocked_by_windows_parental_controls -> "Blocked by windows parental controls"
    | `Wrong_exchange_server -> "Wrong exchange server"
    | `Client_closed_request -> "Client closed request"
    | `Internal_server_error -> "Internal server error"
    | `Not_implemented -> "Not implemented"
    | `Bad_gateway -> "Bad gateway"
    | `Service_unavailable -> "Service unavailable"
    | `Gateway_timeout -> "Gateway timeout"
    | `Http_version_not_supported -> "Http version not supported"
    | `Variant_also_negotiates_rfc_2295 -> "Variant also negotiates rfc 2295"
    | `Insufficient_storage_webdav_rfc_4918 -> "Insufficient storage webdav rfc 4918"
    | `Loop_detected_webdav_rfc_5842 -> "Loop detected webdav rfc 5842"
    | `Bandwidth_limit_exceeded_apache_bw_limited_extension ->
        "Bandwidth limit exceeded apache bw limited extension"
    | `Not_extended_rfc_2774 -> "Not extended rfc 2774"
    | `Network_authentication_required -> "Network authentication required"
    | `Network_read_timeout_error -> "Network read timeout error"
    | `Network_connect_timeout_error -> "Network connect timeout error"
    | `Unknown code -> CCInt.to_string code
end

module Headers = struct
  module M = CCMap.Make (CCString)

  type t = string M.t

  let empty = M.empty
  let add k v t = M.add (CCString.lowercase_ascii k) v t
  let get k t = M.get (CCString.lowercase_ascii k) t

  let add_if_not_present k v t =
    match get k t with
    | Some _ -> t
    | None -> add k v t

  let rem k t = M.remove (CCString.lowercase_ascii k) t
  let to_list = M.to_list
  let of_list ls = M.of_list (CCList.map (fun (k, v) -> (CCString.lowercase_ascii k, v)) ls)
end

module Response = struct
  type t = {
    status : Status.t;
    headers : Headers.t;
  }

  let status t = t.status
  let headers t = t.headers
end

module Options = struct
  type opt = Follow_location
  type t = opt list

  let default = [ Follow_location ]
  let with_opt opt t = opt :: t
  let without_opt opt = CCList.filter (( <> ) opt)
end

module Make (Abb : Abb_intf.S with type Native.t = Unix.file_descr) = struct
  module Method = Method
  module Status = Status
  module Headers = Headers
  module Response = Response
  module Options = Options

  type request_err = [ `Curl_request_err of string ] [@@deriving show, eq]

  let maybe_set_body_writer handle = function
    | Some body ->
        let pos = ref 0 in
        let length = CCString.length body in
        Curl.set_readfunction handle (fun n ->
            if !pos < length then (
              let len = length - !pos in
              let pos' = !pos in
              pos := !pos + CCInt.min n len;
              let s = CCString.sub body pos' (CCInt.min n len) in
              Logs.debug (fun m -> m "write_body: %S" s);
              s)
            else (
              Logs.debug (fun m -> m "write_body: ");
              ""))
    | None -> ()

  let setup_request handle meth_ headers uri =
    Curl.set_url handle (Uri.to_string uri);
    (match meth_ with
    | `GET -> ()
    | `PUT body ->
        Curl.set_put handle true;
        maybe_set_body_writer handle body
    | `POST body ->
        Curl.set_post handle true;
        maybe_set_body_writer handle body
    | `DELETE body ->
        Curl.set_customrequest handle "DELETE";
        maybe_set_body_writer handle body
    | `PATCH body ->
        Curl.set_customrequest handle "PATCH";
        maybe_set_body_writer handle body
    | `Custom (meth_, body) ->
        Curl.set_customrequest handle meth_;
        maybe_set_body_writer handle body);
    let response_body = Buffer.create 100 in
    Curl.set_writefunction handle (fun s ->
        Buffer.add_string response_body s;
        CCString.length s);
    Curl.set_httpheader handle (CCList.map (fun (k, v) -> k ^ ": " ^ v) (Headers.to_list headers))

  let setup_response handle headers body =
    Curl.set_headerfunction handle (fun s ->
        match CCString.Split.left ~by:":" s with
        | Some (key, v) ->
            headers := Headers.add (CCString.trim key) (CCString.trim v) !headers;
            CCString.length s
        | None -> CCString.length s);
    Curl.set_writefunction handle (fun s ->
        Logs.debug (fun m -> m "read_body : %S" s);
        Buffer.add_string body s;
        CCString.length s)

  let perform options headers meth_ uri =
    try
      let handle = Curl.init () in
      Logs.debug (fun m -> Curl.set_verbose handle true);
      CCList.iter
        (function
          | Options.Follow_location -> Curl.set_followlocation handle true)
        options;
      setup_request handle meth_ headers uri;
      let resp_headers = ref Headers.empty in
      let resp_body = Buffer.create 100 in
      setup_response handle resp_headers resp_body;
      Curl.perform handle;
      let status =
        match Curl.getinfo handle Curl.CURLINFO_RESPONSE_CODE with
        | Curl.CURLINFO_Long status -> Status.of_int status
        | Curl.CURLINFO_String _ -> assert false
        | Curl.CURLINFO_Double _ -> assert false
        | Curl.CURLINFO_StringList _ -> assert false
        | Curl.CURLINFO_StringListList _ -> assert false
        | Curl.CURLINFO_Socket _ -> assert false
        | Curl.CURLINFO_Version _ -> assert false
      in
      Curl.cleanup handle;
      Ok ({ Response.status; headers = !resp_headers }, Buffer.contents resp_body)
    with Curl.CurlException (_, _, err) -> Error (`Curl_request_err err)

  let call ?(options = Options.default) ?(headers = Headers.empty) meth_ uri =
    let open Abb.Future.Infix_monad in
    Abb.Thread.run (fun () -> perform options headers meth_ uri)
    >>= function
    | Ok res -> Abb.Future.return (Ok res)
    | Error (#request_err as err) -> Abb.Future.return (Error err)

  let get ?options ?headers uri = call ?options ?headers `GET uri
  let put ?options ?headers ?body uri = call ?options ?headers (`PUT body) uri
  let post ?options ?headers ?body uri = call ?options ?headers (`POST body) uri
  let delete ?options ?headers uri = call ?options ?headers (`DELETE None) uri
end
