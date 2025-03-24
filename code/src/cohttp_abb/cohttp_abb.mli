(** Cohttp-based client and server. *)

type connect_err =
  [ Abb_happy_eyeballs.connect_err
  | `E_connection_refused
  | `Unknown_scheme of string
  | `Unexpected_err of string
  | `Error
  ]
[@@deriving show]

type request_err =
  [ connect_err
  | `Invalid_request of string
  ]
[@@deriving show]

type run_err =
  [ `Exn of exn
  | `E_address_family_not_supported
  | `E_address_in_use
  | `E_address_not_available
  ]
[@@deriving show]

module Make (Abb : Abb_intf.S with type Native.t = Unix.file_descr) : sig
  (** Data structure representing a request. *)
  module Request : Cohttp.S.Request with type t = Cohttp.Request.t

  (** Data structure representing a response. *)
  module Response : Cohttp.S.Response with type t = Cohttp.Response.t

  (** Data structure representing the Body of a request or response. *)
  module Body : Cohttp.S.Body with type t = Cohttp.Body.t

  (** Underlying I/O operations. *)
  module Io : module type of Cohttp_abb_io.Make (Abb)

  (** Side-effectful API for working with requests. *)
  module Request_io : module type of Cohttp.Request.Make (Io) with type t = Request.t

  (** Side-effectful API for working with responses. *)
  module Response_io : module type of Cohttp.Response.Make (Io) with type t = Response.t

  (** An HTTP and HTTPs client. Provides a high-level API for doing complete requests in one call
      down to the underlying APIs for managing a connection. This client does not follow redirects
      or handle caching but simply provides the underlying HTTP request creation and response
      parsing. *)
  module Client : sig
    module Transport : sig
      type t

      val create :
        write_request:
          (?flush:bool ->
          ?body:(Request_io.writer -> unit Abb.Future.t) ->
          Request.t ->
          (Response.t, request_err) result Abb.Future.t) ->
        read_body_chunk:(unit -> (string option, request_err) result Abb.Future.t) ->
        destroy:(unit -> unit Abb.Future.t) ->
        t

      val default : Io.ic -> Io.oc -> t
    end

    module Connector : sig
      type t

      (** Create a connector using proxy-related environment variables to construct it *)
      val of_env : ?tls_config:(string -> Otls.Tls_config.t) -> unit -> t

      (** Make a connector and optionally override the connect function. *)
      val make :
        ?tls_config:(string -> Otls.Tls_config.t) ->
        ?connect:
          ((string -> Otls.Tls_config.t) ->
          Request.t ->
          (Transport.t, connect_err) result Abb.Future.t) ->
        unit ->
        t
    end

    (** Connect to a the destination of a request given a connector. Return a transport that can be
        used to send requests to. *)
    val connect : Connector.t -> Request.t -> (Transport.t, [> connect_err ]) result Abb.Future.t

    (** Given an open connection, perform a request. The body is not consumed and must be consumed
        via {!read_body_chunk} before doing another request. *)
    val do_request :
      ?flush:bool ->
      ?body:(Request_io.writer -> unit Abb.Future.t) ->
      Transport.t ->
      Request.t ->
      (Response.t, [> request_err ]) result Abb.Future.t

    (** Read the next chunk of a body, the body is fully consumed when [None] is returned. *)
    val read_body_chunk : Transport.t -> (string option, [> request_err ]) result Abb.Future.t

    (** Close a transport, the opposite of connect. *)
    val close : Transport.t -> unit Abb.Future.t

    val call :
      ?flush:bool ->
      ?headers:Cohttp.Header.t ->
      ?chunked:bool ->
      ?body:string ->
      ?connector:Connector.t ->
      Cohttp.Code.meth ->
      Uri.t ->
      (Response.t * string, [> request_err ]) result Abb.Future.t

    val get :
      ?headers:Cohttp.Header.t ->
      ?connector:Connector.t ->
      Uri.t ->
      (Response.t * string, [> request_err ]) result Abb.Future.t

    val put :
      ?headers:Cohttp.Header.t ->
      ?body:string ->
      ?connector:Connector.t ->
      Uri.t ->
      (Response.t * string, [> request_err ]) result Abb.Future.t

    val post :
      ?headers:Cohttp.Header.t ->
      ?body:string ->
      ?connector:Connector.t ->
      Uri.t ->
      (Response.t * string, [> request_err ]) result Abb.Future.t

    val delete :
      ?headers:Cohttp.Header.t ->
      ?connector:Connector.t ->
      Uri.t ->
      (Response.t * string, [> request_err ]) result Abb.Future.t
  end

  (** Simple HTTP and HTTPs server. The server runs a configuration and returns when the server has
      stopped. *)
  module Server : sig
    (** The scheme type to serve. *)
    module Scheme : sig
      type t =
        | Http
        | Https of Otls.Tls_config.t
    end

    (** The type of a request handler. A handler takes the parsed headers of a Request and the input
        and output buffers for the connection. A handler is called per request however there can be
        multiple requests per connection. A handler can decide to stop the TCP server by returning
        [`Stop]. If a handler throws an exception, the behaviour depends on the value of
        [on_handler_err] in the {!Config.t}. *)
    type handler =
      Abb.Socket.tcp Abb.Socket.t ->
      Request.t ->
      Request_io.IO.ic ->
      Response_io.IO.oc ->
      [ `Stop | `Ok ] Abb.Future.t

    (** The type of a failure handler. A failure handler is run if a handler fails with an
        exception. A failure handler returning [`Stop] means that the error was so severe that the
        server should be stopped. An [`Ok] means to continue. If the handler fails, by throwing an
        exception or aborting, it is the equivalent of returning [`Stop]. *)
    type on_handler_err =
      Request.t ->
      [ `Timeout | `Exn of exn * Printexc.raw_backtrace option ] ->
      [ `Stop | `Ok ] Abb.Future.t

    (** The type of a protocol error handler. This is called if the underlying HTTP request is
        malformed or timeout during read. *)
    type on_protocol_err = [ `Timeout | `Error of string ] -> [ `Stop | `Ok ] Abb.Future.t

    module Config : sig
      module View : sig
        type t = {
          scheme : Scheme.t;  (** HTTP or HTTPS server. *)
          on_handler_err : on_handler_err;  (** Function to execute on handler error. *)
          on_protocol_err : on_protocol_err;  (** Function to execute on protocol error. *)
          port : int;  (** Port ot listen on. *)
          handler : handler;  (** The handler to execute per requests. *)
          read_header_timeout : Duration.t option;  (** Time to wait to read all headers. *)
          handler_timeout : Duration.t option;  (** Time to allow a handler to run. *)
        }
      end

      type t
      type err = [ `Invalid_port ]

      val of_view : View.t -> (t, [> err ]) result
    end

    (** Run the configuration. Return when the server fails due to an error or a handler returns
        [`Stop]. *)
    val run : Config.t -> (unit, [> run_err ]) result Abb.Future.t
  end
  end
