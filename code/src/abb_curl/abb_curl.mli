(** Curl interface using the multi interface. This runs each [Connector] in its own domain with its
    own event loop. This is because libcurl expects that every operation requested in the
    [socket_function] callback is completed by the end of the callback. This is not possible in Abb
    because we do not have access to the scheduler in the callback. This is especially problematic
    because after the [POLL_REMOVE] request, libcurl might close the file descriptor (the
    [closesocketfunction] does not help here because libcurl manages other file descriptors that the
    callback is not used on) before we remove it from kqueue. So, instead, we implement its own
    event loop that can interact directly with the kqueue in the [socket_function] callback. *)

module Method : sig
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

module Status : sig
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

  val of_int : int -> t
  val to_int : t -> int
  val is_success : t -> bool
  val to_string : t -> string
end

module Headers : sig
  type t

  val empty : t
  val add : string -> string -> t -> t
  val add_if_not_present : string -> string -> t -> t
  val rem : string -> t -> t
  val get : string -> t -> string option
  val to_list : t -> (string * string) list
  val of_list : (string * string) list -> t
end

module Response : sig
  type t

  val status : t -> Status.t
  val headers : t -> Headers.t
end

module Options : sig
  type opt =
    | Follow_location
    | Http_version of [ `Http2 | `Http1_1 ]

  type t = opt list

  val default : t
  val with_opt : opt -> t -> t
  val without_opt : opt -> t -> t
end

module Make (Abb : Abb_intf.S with type Native.t = Unix.file_descr) : sig
  module Method = Method
  module Status = Status
  module Headers = Headers
  module Response = Response
  module Options = Options

  module Connector : sig
    type t

    val create : unit -> t Abb.Future.t
    val destroy : t -> unit Abb.Future.t
  end

  type request_err =
    [ `Closed
    | `Cancelled
    | `Curl_err of string
    ]
  [@@deriving show, eq]

  val call :
    ?connector:Connector.t ->
    ?options:Options.t ->
    ?headers:Headers.t ->
    Method.t ->
    Uri.t ->
    (Response.t * string, [> request_err ]) result Abb.Future.t

  val get :
    ?connector:Connector.t ->
    ?options:Options.t ->
    ?headers:Headers.t ->
    Uri.t ->
    (Response.t * string, [> request_err ]) result Abb.Future.t

  val put :
    ?connector:Connector.t ->
    ?options:Options.t ->
    ?headers:Headers.t ->
    ?body:string ->
    Uri.t ->
    (Response.t * string, [> request_err ]) result Abb.Future.t

  val post :
    ?connector:Connector.t ->
    ?options:Options.t ->
    ?headers:Headers.t ->
    ?body:string ->
    Uri.t ->
    (Response.t * string, [> request_err ]) result Abb.Future.t

  val delete :
    ?connector:Connector.t ->
    ?options:Options.t ->
    ?headers:Headers.t ->
    Uri.t ->
    (Response.t * string, [> request_err ]) result Abb.Future.t
end
