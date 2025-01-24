external unsafe_int_of_file_descr : Unix.file_descr -> int = "%identity"
external unsafe_file_descr_of_int : int -> Unix.file_descr = "%identity"

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

module Id = struct
  module Gen = struct
    type t = int

    let make () = 0
    let next t = (CCInt.to_string t, t + 1)
  end

  type t = string
end

module Make (Abb : Abb_intf.S with type Native.t = Unix.file_descr) = struct
  module Service_local = Abb_service_local.Make (Abb.Future)
  module Channel = Abb_channel.Make (Abb.Future)
  module Fc = Abb_future_combinators.Make (Abb.Future)
  module Method = Method
  module Status = Status
  module Headers = Headers
  module Response = Response

  type request_err =
    [ `Closed
    | `Cancelled
    ]
  [@@deriving show, eq]

  module Connector = struct
    module Id_map = CCMap.Make (CCString)

    module Fd_map = CCMap.Make (struct
      type t = Unix.file_descr

      let compare = compare
    end)

    module Event = struct
      type t =
        | Socket of (Unix.file_descr * Curl.Multi.poll)
        | Header of (Id.t * (string * string))
        | Write of (Id.t * string)
        | Set_timeout of int
        | Close_socket of Unix.file_descr
    end

    module Server = struct
      module Msg = struct
        module Request = struct
          type t = {
            options : Options.t;
            headers : Headers.t;
            body_reader : string -> unit Abb.Future.t;
            meth_ : Method.t;
            uri : Uri.t;
            id_p : Id.t Abb.Future.Promise.t;
            p : (Response.t, request_err) result Abb.Future.Promise.t;
          }
        end

        type t =
          | Request of Request.t
          | Cancel of Id.t
          | Iterate_in of Unix.file_descr
          | Iterate_out of Unix.file_descr
          | Timeout
      end

      type t = {
        mt : Curl.Multi.mt;
        requests : Msg.Request.t Id_map.t;
        responses : Response.t Id_map.t;
        handles : Curl.t Id_map.t;
        fds_in : unit Abb.Future.t Fd_map.t;
        fds_out : unit Abb.Future.t Fd_map.t;
        ev_queue : Event.t Queue.t; (* Watch your fingers, this queue is mutable *)
        id_gen : Id.Gen.t;
        timeout : unit Abb.Future.t option;
      }

      let maybe_set_body_writer handle = function
        | Some body ->
            let pos = ref 0 in
            let length = CCString.length body in
            Curl.set_readfunction handle (fun n ->
                Logs.debug (fun m -> m "readfunction");
                if !pos < length then (
                  let len = length - !pos in
                  let pos' = !pos in
                  pos := !pos + CCInt.min n len;
                  CCString.sub body pos' (CCInt.min n len))
                else "")
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
            Logs.debug (fun m -> m "writefunction : %s" s);
            Buffer.add_string response_body s;
            CCString.length s);
        Curl.set_httpheader
          handle
          (CCList.map (fun (k, v) -> k ^ ": " ^ v) (Headers.to_list headers))

      let setup_response handle queue id =
        Curl.set_headerfunction handle (fun s ->
            Logs.debug (fun m -> m "header : %s" s);
            match CCString.Split.left ~by:":" s with
            | Some (key, v) ->
                Queue.add (Event.Header (id, (CCString.trim key, CCString.trim v))) queue;
                CCString.length s
            | None -> CCString.length s);
        Curl.set_writefunction handle (fun s ->
            Queue.add (Event.Write (id, s)) queue;
            CCString.length s)

      let start_fd_listen fd w wait msg =
        let open Abb.Future.Infix_monad in
        Abb.Future.fork
          (let fd' = Abb.Socket.Tcp.of_native fd in
           Logs.debug (fun m -> m "wait fd : %d" (unsafe_int_of_file_descr fd));
           wait fd'
           >>= fun () ->
           Logs.debug (fun m -> m "trigger fd : %d" (unsafe_int_of_file_descr fd));
           Fc.ignore (Channel.send w msg))

      let stop_listener fd m =
        match Fd_map.get fd m with
        | Some fut ->
            let open Abb.Future.Infix_monad in
            Logs.debug (fun m -> m "stop_listener : %d" (unsafe_int_of_file_descr fd));
            (match Abb.Future.state fut with
            | `Aborted -> Logs.debug (fun m -> m "aborted")
            | `Undet -> Logs.debug (fun m -> m "undet")
            | `Exn _ -> Logs.debug (fun m -> m "exn")
            | `Det _ -> Logs.debug (fun m -> m "det"));
            Abb.Future.abort fut
            >>= fun () ->
            (* Ensure that the abort has time to remove the listening socket
               because we might close it as part of this scheduler iteration *)
            Abb.Sys.sleep 0.0 >>= fun () -> Abb.Future.return (Fd_map.remove fd m)
        | None -> Abb.Future.return m

      let rec process_event t w =
        match Queue.take_opt t.ev_queue with
        | Some (Event.Header (id, (k, v))) -> (
            match Id_map.get id t.responses with
            | Some ({ Response.headers; _ } as resp) ->
                let resp = { resp with Response.headers = Headers.add k v headers } in
                let t = { t with responses = Id_map.add id resp t.responses } in
                process_event t w
            | None ->
                let resp =
                  { Response.status = `Internal_server_error; headers = Headers.of_list [ (k, v) ] }
                in
                let t = { t with responses = Id_map.add id resp t.responses } in
                process_event t w)
        | Some (Event.Socket (fd, poll)) -> (
            let open Abb.Future.Infix_monad in
            match poll with
            | Curl.Multi.POLL_NONE ->
                Logs.debug (fun m -> m "socket : poll_none : %d" (unsafe_int_of_file_descr fd));
                assert false
            | Curl.Multi.POLL_IN ->
                Logs.debug (fun m -> m "socket : poll_in : %d" (unsafe_int_of_file_descr fd));
                start_fd_listen fd w Abb.Socket.readable (Msg.Iterate_in fd)
                >>= fun fut ->
                let t = { t with fds_in = Fd_map.add fd fut t.fds_in } in
                process_event t w
            | Curl.Multi.POLL_OUT ->
                Logs.debug (fun m -> m "socket : poll_out : %d" (unsafe_int_of_file_descr fd));
                start_fd_listen fd w Abb.Socket.writable (Msg.Iterate_out fd)
                >>= fun fut ->
                let t = { t with fds_in = Fd_map.add fd fut t.fds_out } in
                process_event t w
            | Curl.Multi.POLL_INOUT ->
                Logs.debug (fun m -> m "socket : poll_inout : %d" (unsafe_int_of_file_descr fd));
                start_fd_listen fd w Abb.Socket.readable (Msg.Iterate_in fd)
                >>= fun fut ->
                let t = { t with fds_in = Fd_map.add fd fut t.fds_in } in
                start_fd_listen fd w Abb.Socket.writable (Msg.Iterate_out fd)
                >>= fun fut ->
                let t = { t with fds_in = Fd_map.add fd fut t.fds_out } in
                process_event t w
            | Curl.Multi.POLL_REMOVE ->
                Logs.debug (fun m -> m "socket : poll_remove : %d" (unsafe_int_of_file_descr fd));
                stop_listener fd t.fds_in
                >>= fun fds_in ->
                stop_listener fd t.fds_out
                >>= fun fds_out ->
                let t = { t with fds_in; fds_out } in
                process_event t w)
        | Some (Event.Write (id, s)) -> (
            let open Abb.Future.Infix_monad in
            match Id_map.get id t.requests with
            | Some { Msg.Request.body_reader; _ } -> body_reader s >>= fun () -> process_event t w
            | None -> process_event t w)
        | Some (Event.Set_timeout timeout) ->
            let open Abb.Future.Infix_monad in
            (match t.timeout with
            | Some fut -> Abb.Future.abort fut
            | None -> Abb.Future.return ())
            >>= fun () ->
            if timeout >= 0 then
              Abb.Future.fork
                (Abb.Sys.sleep Duration.(to_f (of_ms timeout))
                >>= fun () ->
                Logs.debug (fun m -> m "firing timeout");
                Fc.ignore (Channel.send w Msg.Timeout))
              >>= fun fut ->
              let t = { t with timeout = Some fut } in
              process_event t w
            else
              let open Abb.Future.Infix_monad in
              Fc.ignore (Channel.send w Msg.Timeout) >>= fun () -> process_event t w
        | Some (Event.Close_socket fd) ->
            let open Abb.Future.Infix_monad in
            Logs.debug (fun m -> m "close_socket : %d" (unsafe_int_of_file_descr fd));
            stop_listener fd t.fds_in
            >>= fun fds_in ->
            stop_listener fd t.fds_out
            >>= fun fds_out ->
            let t = { t with fds_in; fds_out } in
            let fd = Abb.Socket.Tcp.of_native fd in
            Abb.Socket.close fd >>= fun _ -> process_event t w
        | None -> Abb.Future.return t

      let rec iterate_removed t =
        match Curl.Multi.remove_finished t.mt with
        | Some (handle, exit_code) -> (
            let id =
              match Curl.getinfo handle Curl.CURLINFO_PRIVATE with
              | Curl.CURLINFO_String id -> id
              | Curl.CURLINFO_Long _ -> assert false
              | Curl.CURLINFO_Double _ -> assert false
              | Curl.CURLINFO_StringList _ -> assert false
              | Curl.CURLINFO_StringListList _ -> assert false
              | Curl.CURLINFO_Socket _ -> assert false
              | Curl.CURLINFO_Version _ -> assert false
            in
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
            Logs.debug (fun m -> m "removed : %s : %s" id (Status.to_string status));
            Curl.cleanup handle;
            match (Id_map.get id t.requests, Id_map.get id t.responses) with
            | Some { Msg.Request.p; _ }, Some resp ->
                let open Abb.Future.Infix_monad in
                let t =
                  {
                    t with
                    responses = Id_map.remove id t.responses;
                    requests = Id_map.remove id t.requests;
                    handles = Id_map.remove id t.handles;
                  }
                in
                let resp = { resp with Response.status } in
                Abb.Future.Promise.set p (Ok resp) >>= fun () -> iterate_removed t
            | _, _ ->
                Logs.debug (fun m -> m "impossible");
                assert false)
        | None -> Abb.Future.return t

      let run_iter t w =
        let open Abb.Future.Infix_monad in
        Logs.debug (fun m -> m "perform");
        let still_running = Curl.Multi.perform t.mt in
        Logs.debug (fun m -> m "still_running : %d" still_running);
        process_event t w >>= fun t -> iterate_removed t

      let handle_msg t w r = function
        | Msg.Request
            ({ Msg.Request.options; headers; body_reader; meth_; uri; id_p; _ } as request) ->
            let open Abb.Future.Infix_monad in
            let id, id_gen = Id.Gen.next t.id_gen in
            Logs.debug (fun m -> m "request : %a : %s" Uri.pp uri id);
            Abb.Future.Promise.set id_p id
            >>= fun () ->
            let handle = Curl.init () in
            Logs.debug (fun m ->
                Curl.set_verbose handle true;
                m "verbose");
            let t =
              {
                t with
                id_gen;
                requests = Id_map.add id request t.requests;
                responses =
                  Id_map.add
                    id
                    { Response.status = `Internal_server_error; headers = Headers.empty }
                    t.responses;
                handles = Id_map.add id handle t.handles;
              }
            in
            CCList.iter
              (function
                | Options.Follow_location -> Curl.set_followlocation handle true)
              options;
            (* Use our id to track this *)
            Curl.setopt handle (Curl.CURLOPT_PRIVATE id);
            setup_request handle meth_ headers uri;
            setup_response handle t.ev_queue id;
            Curl.Multi.add t.mt handle;
            Abb.Future.return t
        | Msg.Cancel id -> (
            Logs.debug (fun m -> m "canceling : %s" id);
            match Id_map.get id t.handles with
            | Some handle ->
                let open Abb.Future.Infix_monad in
                Curl.Multi.remove t.mt handle;
                (match Id_map.get id t.requests with
                | Some { Msg.Request.p; uri; _ } ->
                    Logs.debug (fun m -> m "canceled : %s : %a" id Uri.pp uri);
                    Abb.Future.Promise.set p (Error `Cancelled)
                | None -> Abb.Future.return ())
                >>= fun () ->
                Abb.Future.return
                  {
                    t with
                    requests = Id_map.remove id t.requests;
                    responses = Id_map.remove id t.responses;
                    handles = Id_map.remove id t.handles;
                  }
            | None -> Abb.Future.return t)
        | Msg.Iterate_in fd ->
            let open Abb.Future.Infix_monad in
            Logs.debug (fun m -> m "iterate_in : %d" (unsafe_int_of_file_descr fd));
            (* TODO: Handle errors *)
            ignore (Curl.Multi.action t.mt fd Curl.Multi.EV_IN);
            start_fd_listen fd w Abb.Socket.readable (Msg.Iterate_in fd)
            >>= fun fut ->
            let t = { t with fds_in = Fd_map.add fd fut t.fds_in } in
            Abb.Future.return t
        | Msg.Iterate_out fd ->
            let open Abb.Future.Infix_monad in
            Logs.debug (fun m -> m "iterate_out : %d" (unsafe_int_of_file_descr fd));
            (* TODO: Handle errors *)
            ignore (Curl.Multi.action t.mt fd Curl.Multi.EV_OUT);
            start_fd_listen fd w Abb.Socket.writable (Msg.Iterate_out fd)
            >>= fun fut ->
            let t = { t with fds_in = Fd_map.add fd fut t.fds_out } in
            Abb.Future.return t
        | Msg.Timeout ->
            Logs.debug (fun m -> m "timeout");
            Curl.Multi.action_timeout t.mt;
            Abb.Future.return t

      let rec loop t w r =
        let open Abb.Future.Infix_monad in
        Channel.recv r
        >>= function
        | `Ok msg -> handle_msg t w r msg >>= fun t -> run_iter t w >>= fun t -> loop t w r
        | `Closed ->
            let open Abb.Future.Infix_monad in
            Logs.debug (fun m -> m "closing");
            run_iter t w
            >>= fun t ->
            Id_map.iter
              (fun _ handle ->
                Curl.Multi.remove t.mt handle;
                Curl.cleanup handle)
              t.handles;
            Fc.List.iter
              ~f:Abb.Future.abort
              (CCList.map snd (Fd_map.to_list t.fds_in @ Fd_map.to_list t.fds_out))
            >>= fun () ->
            let t =
              { t with fds_in = Fd_map.empty; fds_out = Fd_map.empty; handles = Id_map.empty }
            in
            (try Curl.Multi.cleanup t.mt
             with exn ->
               Logs.debug (fun m -> m "failed : %s" (Printexc.to_string exn));
               raise exn);
            Fc.ignore (process_event t w)
            >>= fun () ->
            Logs.debug (fun m -> m "closed");
            Abb.Future.return ()
    end

    type t = Server.Msg.t Service_local.w

    let create () =
      Curl.global_init Curl.CURLINIT_GLOBALALL;
      let t =
        {
          Server.mt = Curl.Multi.create ();
          requests = Id_map.empty;
          responses = Id_map.empty;
          handles = Id_map.empty;
          fds_in = Fd_map.empty;
          fds_out = Fd_map.empty;
          ev_queue = Queue.create ();
          id_gen = Id.Gen.make ();
          timeout = None;
        }
      in
      Curl.Multi.set_socket_function t.Server.mt (fun fd poll ->
          Logs.debug (fun m ->
              m
                "socket_function : %s : %d"
                (match poll with
                | Curl.Multi.POLL_NONE -> "poll_none"
                | Curl.Multi.POLL_IN -> "poll_in"
                | Curl.Multi.POLL_OUT -> "poll_out"
                | Curl.Multi.POLL_INOUT -> "poll_inout"
                | Curl.Multi.POLL_REMOVE -> "poll_remove")
                (unsafe_int_of_file_descr fd));
          Queue.add (Event.Socket (fd, poll)) t.Server.ev_queue);
      Curl.Multi.set_closesocket_function t.Server.mt (fun fd ->
          Logs.debug (fun m -> m "closesocket_function : %d" (unsafe_int_of_file_descr fd));
          Queue.add (Event.Close_socket fd) t.Server.ev_queue);
      Curl.Multi.set_timer_function t.Server.mt (fun timeout ->
          Logs.debug (fun m -> m "timeout_function : %d" timeout);
          Queue.add (Event.Set_timeout timeout) t.Server.ev_queue);
      Service_local.create (Server.loop t)

    let destroy t = Fc.ignore (Channel.close t)

    let request t options headers body_reader meth_ uri =
      let open Fc.Infix_result_monad in
      let id_p = Abb.Future.Promise.create () in
      let p = Abb.Future.Promise.create () in
      Channel.Combinators.to_result
        (Channel.send
           t
           (Server.Msg.Request
              { Server.Msg.Request.options; headers; body_reader; meth_; uri; id_p; p }))
      >>= fun () -> Abb.Future.return (Ok (id_p, p))

    let cancel t id = Channel.Combinators.to_result (Channel.send t (Server.Msg.Cancel id))
  end

  let call ?connector ?(options = Options.default) ?(headers = Headers.empty) meth_ uri =
    let open Abb.Future.Infix_monad in
    let create_connector, destroy_connector =
      match connector with
      | None -> (Connector.create, Connector.destroy)
      | Some connector -> ((fun _ -> Abb.Future.return connector), CCFun.const Fc.unit)
    in
    Fc.protect_finally
      ~setup:(fun () ->
        let open Abb.Future.Infix_monad in
        create_connector ()
        >>= fun connector ->
        let open Fc.Infix_result_monad in
        let buf = Buffer.create 10 in
        let body s =
          Buffer.add_string buf s;
          Abb.Future.return ()
        in
        Connector.request connector options headers body meth_ uri
        >>= fun (id_p, p) ->
        let open Abb.Future.Infix_monad in
        Abb.Future.Promise.future id_p >>= fun id -> Abb.Future.return (Ok (connector, id, buf, p)))
      (fun res ->
        let open Fc.Infix_result_monad in
        Abb.Future.return res
        >>= fun (_, _, buf, p) ->
        Abb.Future.Promise.future p
        >>= fun resp -> Abb.Future.return (Ok (resp, Buffer.contents buf)))
      ~finally:(fun res ->
        Fc.ignore
          (let open Fc.Infix_result_monad in
           Abb.Future.return res
           >>= fun (connector, id, _, _) ->
           (* We don't know if we are really destroying a connector or not, so
              however we got to this [finally], then cancel the request.  If we
              are in the [finally] because the request ended successfully, then
              this is a noop. *)
           Connector.cancel connector id >>= fun () -> Fc.to_result (destroy_connector connector)))
    >>= function
    | Ok res -> Abb.Future.return (Ok res)
    | Error (#request_err as err) -> Abb.Future.return (Error err)

  let get ?connector ?options ?headers uri = call ?connector ?options ?headers `GET uri
  let put ?connector ?options ?headers ?body uri = call ?connector ?options ?headers (`PUT body) uri

  let post ?connector ?options ?headers ?body uri =
    call ?connector ?options ?headers (`POST body) uri

  let delete ?connector ?options ?headers uri = call ?connector ?options ?headers (`DELETE None) uri
end
