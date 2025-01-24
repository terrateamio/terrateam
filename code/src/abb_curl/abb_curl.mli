(** Curl interface using the multi interface. DO NOT USE, this is in development and depending on
    changes in an upcoming version of Curl. Using this will crash the program.

    The underlying issue is that file descriptors that are sent to [socketfunction] are not always
    ones that we can control when they are closed. Because we need to alter the world in the Abb
    monad, and we do not have access to the state in the callback. However, for some sockets, Curl
    will call it [socketfunction] with [POLL_REMOVE] and then immediately close the socket, when
    wrecks havoc with Abb. We need a new callback (which will hopefully be added to curl soon). *)

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
  type opt = Follow_location
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

  module Connector : sig
    type t

    val create : unit -> t Abb.Future.t
    val destroy : t -> unit Abb.Future.t
  end

  type request_err =
    [ `Closed
    | `Cancelled
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
