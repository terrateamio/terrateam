let () = Curl.global_init Curl.CURLINIT_GLOBALALL
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
  type opt =
    | Follow_location
    | Http_version of [ `Http2 | `Http1_1 ]

  type t = opt list

  let default = [ Follow_location ]

  let with_opt opt t =
    opt
    :: CCList.remove
         ~eq:(fun v1 v2 ->
           match (v1, v2) with
           | Http_version _, Http_version _ -> true
           | v1, v2 -> v1 = v2)
         ~key:opt
         t

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
  module Options = Options

  type request_err =
    [ `Closed
    | `Cancelled
    ]
  [@@deriving show, eq]

  module Connector = struct
    module Id_map = CCMap.Make (CCString)

    module Request = struct
      type t = {
        options : Options.t;
        headers : Headers.t;
        body_reader : string -> unit Abb.Future.t;
        meth_ : Method.t;
        uri : Uri.t;
        id : Id.t;
      }
    end

    module In_event = struct
      type t =
        | Request of Request.t
        | Cancel of Id.t
        | Shutdown
    end

    module Out_event = struct
      type t =
        | Ret of (Id.t * (Response.t, request_err) result)
        | Body of (Id.t * string)
    end

    let trigger_bytes = Bytes.of_string "0"
    let trigger_eventfd eventfd = ignore (UnixLabels.write eventfd ~buf:trigger_bytes ~pos:0 ~len:1)

    let consume_eventfd eventfd =
      let buf = Bytes.create 4 in
      try ignore (UnixLabels.read eventfd ~buf ~pos:0 ~len:(Bytes.length buf))
      with Unix.Unix_error (Unix.EAGAIN, _, _) | Unix.Unix_error (Unix.EWOULDBLOCK, _, _) -> ()

    module Loop = struct
      type t = {
        kq : Kqueue.t;
        eventlist : Kqueue.Eventlist.t;
        eventfd : Unix.file_descr;
        in_event : In_event.t Queue.t;
        out_event : Out_event.t Queue.t;
        mutex : Mutex.t;
        mt : Curl.Multi.mt;
        mutable requests : Request.t Id_map.t;
        mutable responses : Response.t Id_map.t;
        mutable handles : Curl.t Id_map.t;
        mutable timeout : Duration.t option;
        mutable shutdown : bool;
      }

      let socket_function t fd poll =
        match poll with
        | Curl.Multi.POLL_NONE -> ()
        | Curl.Multi.POLL_IN ->
            let changelist =
              Kqueue.Eventlist.of_list
                [
                  Kqueue.Change.(
                    Filter.to_kevent
                      Action.(to_t [ Flag.Add ])
                      (Filter.Read (Kqueue.unsafe_int_of_file_descr fd)));
                ]
            in
            let ret =
              Kqueue.kevent t.kq ~changelist ~eventlist:Kqueue.Eventlist.null ~timeout:None
            in
            assert (ret = 0)
        | Curl.Multi.POLL_OUT ->
            let changelist =
              Kqueue.Eventlist.of_list
                [
                  Kqueue.Change.(
                    Filter.to_kevent
                      Action.(to_t [ Flag.Add ])
                      (Filter.Write (Kqueue.unsafe_int_of_file_descr fd)));
                ]
            in
            let ret =
              Kqueue.kevent t.kq ~changelist ~eventlist:Kqueue.Eventlist.null ~timeout:None
            in
            assert (ret = 0)
        | Curl.Multi.POLL_INOUT ->
            let changelist =
              Kqueue.Eventlist.of_list
                [
                  Kqueue.Change.(
                    Filter.to_kevent
                      Action.(to_t [ Flag.Add ])
                      (Filter.Read (Kqueue.unsafe_int_of_file_descr fd)));
                  Kqueue.Change.(
                    Filter.to_kevent
                      Action.(to_t [ Flag.Add ])
                      (Filter.Write (Kqueue.unsafe_int_of_file_descr fd)));
                ]
            in
            let ret =
              Kqueue.kevent t.kq ~changelist ~eventlist:Kqueue.Eventlist.null ~timeout:None
            in
            assert (ret = 0)
        | Curl.Multi.POLL_REMOVE ->
            let changelist =
              Kqueue.Eventlist.of_list
                [
                  Kqueue.Change.(
                    Filter.to_kevent
                      Action.(to_t [ Flag.Delete ])
                      (Filter.Read (Kqueue.unsafe_int_of_file_descr fd)));
                  Kqueue.Change.(
                    Filter.to_kevent
                      Action.(to_t [ Flag.Delete ])
                      (Filter.Write (Kqueue.unsafe_int_of_file_descr fd)));
                ]
            in
            ignore (Kqueue.kevent t.kq ~changelist ~eventlist:Kqueue.Eventlist.null ~timeout:None)

      let maybe_set_body_writer handle = function
        | Some body ->
            let pos = ref 0 in
            let length = CCString.length body in
            Curl.set_readfunction handle (fun n ->
                if !pos < length then (
                  let len = length - !pos in
                  let pos' = !pos in
                  pos := !pos + CCInt.min n len;
                  CCString.sub body pos' (CCInt.min n len))
                else "")
        | None -> ()

      let setup_request handle meth_ headers uri =
        Logs.debug (fun _ -> Curl.set_verbose handle true);
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
        Curl.set_httpheader
          handle
          (CCList.map (fun (k, v) -> k ^ ": " ^ v) (Headers.to_list headers))

      let setup_response t handle id =
        Curl.set_headerfunction handle (fun s ->
            match CCString.Split.left ~by:":" s with
            | Some (k, v) -> (
                let k = CCString.trim k in
                let v = CCString.trim v in
                match Id_map.get id t.responses with
                | Some ({ Response.headers; _ } as resp) ->
                    t.responses <-
                      Id_map.add
                        id
                        { resp with Response.headers = Headers.add k v headers }
                        t.responses;
                    CCString.length s
                | None ->
                    t.responses <-
                      Id_map.add
                        id
                        {
                          Response.status = `Internal_server_error;
                          headers = Headers.of_list [ (k, v) ];
                        }
                        t.responses;
                    CCString.length s)
            | None -> CCString.length s);
        Curl.set_writefunction handle (fun s ->
            Mutex.lock t.mutex;
            Queue.add (Out_event.Body (id, s)) t.out_event;
            Mutex.unlock t.mutex;
            CCString.length s)

      let process_request
          t
          ({ Request.options; headers; body_reader; meth_; uri; id; _ } as request) =
        let handle = Curl.init () in
        t.requests <- Id_map.add id request t.requests;
        t.responses <-
          Id_map.add
            id
            { Response.status = `Internal_server_error; headers = Headers.empty }
            t.responses;
        t.handles <- Id_map.add id handle t.handles;
        CCList.iter
          (function
            | Options.Follow_location -> Curl.set_followlocation handle true
            | Options.Http_version `Http1_1 -> Curl.set_httpversion handle Curl.HTTP_VERSION_1_1
            | Options.Http_version `Http2 -> Curl.set_httpversion handle Curl.HTTP_VERSION_2)
          options;
        (* Use our id to track this *)
        Curl.setopt handle (Curl.CURLOPT_PRIVATE id);
        setup_request handle meth_ headers uri;
        setup_response t handle id;
        Curl.Multi.add t.mt handle

      let process_cancel t id =
        match Id_map.get id t.handles with
        | Some handle ->
            Curl.Multi.remove t.mt handle;
            Curl.cleanup handle;
            t.requests <- Id_map.remove id t.requests;
            t.responses <- Id_map.remove id t.responses;
            t.handles <- Id_map.remove id t.handles
        | None -> ()

      let process_shutdown t =
        Id_map.iter (fun id _ -> process_cancel t id) t.handles;
        Curl.Multi.cleanup t.mt;
        t.shutdown <- true

      let trigger_out_events t =
        Mutex.lock t.mutex;
        if Queue.length t.out_event > 0 then trigger_eventfd t.eventfd;
        Mutex.unlock t.mutex

      let rec process_in_events t =
        Mutex.lock t.mutex;
        let event = Queue.take_opt t.in_event in
        Mutex.unlock t.mutex;
        match event with
        | Some (In_event.Request request) ->
            process_request t request;
            process_in_events t
        | Some (In_event.Cancel id) ->
            process_cancel t id;
            process_in_events t
        | Some In_event.Shutdown -> process_shutdown t
        | None -> ()

      let rec process_finished t =
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
            Curl.cleanup handle;
            match Id_map.get id t.responses with
            | Some resp ->
                t.responses <- Id_map.remove id t.responses;
                t.requests <- Id_map.remove id t.requests;
                t.handles <- Id_map.remove id t.handles;
                Mutex.lock t.mutex;
                Queue.add (Out_event.Ret (id, Ok { resp with Response.status })) t.out_event;
                Mutex.unlock t.mutex;
                process_finished t
            | None -> assert false)
        | None -> ()

      let rec loop t =
        let timeout =
          CCOption.map
            (fun duration ->
              let sec = Duration.to_f duration in
              let frac, sec = modf sec in
              let nsec = frac *. 1e9 in
              Kqueue.Timeout.create ~sec:(CCFloat.to_int sec) ~nsec:(CCFloat.to_int nsec))
            t.timeout
        in
        let start = Mtime_clock.elapsed () in
        let ret =
          Kqueue.kevent t.kq ~changelist:Kqueue.Eventlist.null ~eventlist:t.eventlist ~timeout
        in
        assert (ret >= 0);
        let end_ = Mtime_clock.elapsed () in
        let wait_time = Mtime.Span.(to_float_ns (abs_diff start end_)) /. 1e9 in
        t.timeout <-
          CCOption.map
            (fun timeout -> Duration.of_f (CCFloat.max 0.0 (Duration.to_f timeout -. wait_time)))
            t.timeout;
        if ret > 0 then (
          let eventfd_event = ref false in
          Kqueue.Eventlist.iter
            ~f:(fun event ->
              match Kqueue.Event.of_kevent event with
              | Kqueue.Event.Read r
                when Kqueue.unsafe_file_descr_of_int r.Kqueue.Event.Read.descr = t.eventfd ->
                  consume_eventfd t.eventfd;
                  eventfd_event := true;
                  ()
              | Kqueue.Event.Read r ->
                  let fd = Kqueue.unsafe_file_descr_of_int r.Kqueue.Event.Read.descr in
                  ignore (Curl.Multi.action t.mt fd Curl.Multi.EV_IN)
              | Kqueue.Event.Write w ->
                  let fd = Kqueue.unsafe_file_descr_of_int w.Kqueue.Event.Write.descr in
                  ignore (Curl.Multi.action t.mt fd Curl.Multi.EV_OUT)
              | _ -> ())
            t.eventlist;
          if !eventfd_event && ret = 1 then Curl.Multi.action_timeout t.mt)
        else Curl.Multi.action_timeout t.mt;
        ignore (Curl.Multi.perform t.mt);
        process_in_events t;
        if not t.shutdown then (
          process_finished t;
          trigger_out_events t;
          loop t)

      let start () =
        let eventfd, loop_eventfd = Unix.pipe ~cloexec:true () in
        UnixLabels.set_nonblock eventfd;
        UnixLabels.set_nonblock loop_eventfd;
        let t =
          {
            kq = Kqueue.create ();
            eventlist = Kqueue.Eventlist.create 1024;
            eventfd = loop_eventfd;
            in_event = Queue.create ();
            out_event = Queue.create ();
            mutex = Mutex.create ();
            mt = Curl.Multi.create ();
            requests = Id_map.empty;
            responses = Id_map.empty;
            handles = Id_map.empty;
            timeout = None;
            shutdown = false;
          }
        in
        Curl.Multi.set_socket_function t.mt (socket_function t);
        Curl.Multi.set_timer_function t.mt (function
          | -1 -> t.timeout <- None
          | timeout -> t.timeout <- Some (Duration.of_ms timeout));
        Kqueue.Eventlist.set_from_list
          t.eventlist
          [
            Kqueue.Change.(
              Filter.to_kevent
                Action.(to_t [ Flag.Add ])
                (Filter.Read (Kqueue.unsafe_int_of_file_descr t.eventfd)));
          ];
        let ret =
          Kqueue.kevent t.kq ~changelist:t.eventlist ~eventlist:Kqueue.Eventlist.null ~timeout:None
        in
        assert (ret = 0);
        ignore
          (Domain.spawn (fun () ->
               try loop t with exn -> Logs.err (fun m -> m "%s" (Printexc.to_string exn))));
        (eventfd, t.mutex, t.in_event, t.out_event)
    end

    module Server = struct
      module Msg = struct
        type t =
          | Request of {
              request : Request.t;
              p : (Response.t, request_err) result Abb.Future.Promise.t;
            }
          | Cancel of Id.t
          | Iterate
      end

      type t = {
        eventfd : Unix.file_descr;
        mutex : Mutex.t;
        in_event : In_event.t Queue.t;
        out_event : Out_event.t Queue.t;
        iterate_fut : unit Abb.Future.t;
        body_readers : (string -> unit Abb.Future.t) Id_map.t;
        responses : (Response.t, request_err) result Abb.Future.Promise.t Id_map.t;
      }

      let rec process_events t =
        Mutex.lock t.mutex;
        let event = Queue.take_opt t.out_event in
        Mutex.unlock t.mutex;
        match event with
        | Some (Out_event.Ret (id, ret)) -> (
            let open Abb.Future.Infix_monad in
            match Id_map.get id t.responses with
            | Some p ->
                Abb.Future.Promise.set p ret
                >>= fun () ->
                process_events
                  {
                    t with
                    body_readers = Id_map.remove id t.body_readers;
                    responses = Id_map.remove id t.responses;
                  }
            | None -> process_events t)
        | Some (Out_event.Body (id, string)) -> (
            let open Abb.Future.Infix_monad in
            match Id_map.get id t.body_readers with
            | Some body_reader -> body_reader string >>= fun () -> process_events t
            | None -> process_events t)
        | None -> Abb.Future.return t

      let handle_msg t w r = function
        | Msg.Request { request; p } ->
            let id = request.Request.id in
            Logs.debug (fun m -> m "MSG : REQUEST : id=%s" id);
            let body_reader = request.Request.body_reader in
            let t =
              {
                t with
                body_readers = Id_map.add id body_reader t.body_readers;
                responses = Id_map.add id p t.responses;
              }
            in
            Mutex.lock t.mutex;
            Queue.add (In_event.Request request) t.in_event;
            Mutex.unlock t.mutex;
            trigger_eventfd t.eventfd;
            Abb.Future.return t
        | Msg.Cancel id ->
            let open Abb.Future.Infix_monad in
            Logs.debug (fun m -> m "MSG : CANCEL : id=%s" id);
            Mutex.lock t.mutex;
            Queue.add (In_event.Cancel id) t.in_event;
            Mutex.unlock t.mutex;
            trigger_eventfd t.eventfd;
            (match Id_map.get id t.responses with
            | Some p -> Abb.Future.Promise.set p (Error `Cancelled)
            | None -> Fc.unit)
            >>= fun () ->
            Abb.Future.return
              {
                t with
                body_readers = Id_map.remove id t.body_readers;
                responses = Id_map.remove id t.responses;
              }
        | Msg.Iterate -> process_events t

      let rec loop t w r =
        let open Abb.Future.Infix_monad in
        Channel.recv r
        >>= function
        | `Ok msg -> handle_msg t w r msg >>= fun t -> loop t w r
        | `Closed ->
            Mutex.lock t.mutex;
            Queue.add In_event.Shutdown t.in_event;
            Mutex.unlock t.mutex;
            trigger_eventfd t.eventfd;
            Abb.Future.return ()

      let rec iterate_loop eventfd buf w =
        let open Abb.Future.Infix_monad in
        Abb.File.read eventfd ~buf ~pos:0 ~len:(Bytes.length buf)
        >>= fun _ ->
        Channel.send w Msg.Iterate
        >>= function
        | `Ok () -> iterate_loop eventfd buf w
        | `Closed -> Abb.Future.return ()

      let start w r =
        let open Abb.Future.Infix_monad in
        let eventfd, mutex, in_event, out_event = Loop.start () in
        Abb.Future.fork
          (let buf = Bytes.create 4 in
           let eventfd = Abb.File.of_native eventfd in
           iterate_loop eventfd buf w)
        >>= fun iterate_fut ->
        let t =
          {
            eventfd;
            mutex;
            in_event;
            out_event;
            iterate_fut;
            body_readers = Id_map.empty;
            responses = Id_map.empty;
          }
        in
        Logs.debug (fun m -> m "LOOP");
        loop t w r
    end

    type t = {
      w : Server.Msg.t Service_local.w;
      mutable id_gen : Id.Gen.t;
    }

    let create () =
      let open Abb.Future.Infix_monad in
      Service_local.create Server.start
      >>= fun w ->
      Logs.debug (fun m -> m "STARTED");
      Abb.Future.return { w; id_gen = Id.Gen.make () }

    let destroy t = Fc.ignore (Channel.close t.w)

    let request t options headers body_reader meth_ uri =
      let open Fc.Infix_result_monad in
      let id, id_gen = Id.Gen.next t.id_gen in
      t.id_gen <- id_gen;
      let p = Abb.Future.Promise.create () in
      Channel.Combinators.to_result
        (Channel.send
           t.w
           (Server.Msg.Request
              { request = { Request.options; headers; body_reader; meth_; uri; id }; p }))
      >>= fun () -> Abb.Future.return (Ok (id, Abb.Future.Promise.future p))

    let cancel t id = Channel.Combinators.to_result (Channel.send t.w (Server.Msg.Cancel id))
  end

  let default_connector = Connector.create ()

  let call ?connector ?(options = Options.default) ?(headers = Headers.empty) meth_ uri =
    let open Abb.Future.Infix_monad in
    Fc.protect_finally
      ~setup:(fun () ->
        let open Abb.Future.Infix_monad in
        let connector =
          match connector with
          | None -> default_connector
          | Some connector -> Abb.Future.return connector
        in
        connector
        >>= fun connector ->
        let open Fc.Infix_result_monad in
        let buf = Buffer.create 10 in
        let body s =
          Buffer.add_string buf s;
          Abb.Future.return ()
        in
        Connector.request connector options headers body meth_ uri
        >>= fun (id, p) -> Abb.Future.return (Ok (connector, id, buf, p)))
      (fun res ->
        let open Fc.Infix_result_monad in
        Abb.Future.return res
        >>= fun (_, _, buf, p) ->
        p >>= fun resp -> Abb.Future.return (Ok (resp, Buffer.contents buf)))
      ~finally:(fun res ->
        Fc.ignore
          (let open Fc.Infix_result_monad in
           Abb.Future.return res
           >>= fun (connector, id, _, _) ->
           (* We don't know if we are really destroying a connector or not, so
              however we got to this [finally], then cancel the request.  If we
              are in the [finally] because the request ended successfully, then
              this is a noop. *)
           Connector.cancel connector id))
    >>= function
    | Ok res -> Abb.Future.return (Ok res)
    | Error (#request_err as err) -> Abb.Future.return (Error err)

  let get ?connector ?options ?headers uri = call ?connector ?options ?headers `GET uri
  let put ?connector ?options ?headers ?body uri = call ?connector ?options ?headers (`PUT body) uri

  let post ?connector ?options ?headers ?body uri =
    call ?connector ?options ?headers (`POST body) uri

  let delete ?connector ?options ?headers uri = call ?connector ?options ?headers (`DELETE None) uri
end
