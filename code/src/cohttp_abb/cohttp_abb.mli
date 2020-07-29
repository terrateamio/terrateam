(** Cohttp-based client and server. *)

type connect_http_err =
  [ Abb_intf.Errors.sock_create
  | Abb_intf.Errors.tcp_sock_connect
  ]

type connect_https_err =
  [ connect_http_err
  | `Error
  ]

type request_err =
  [ connect_https_err
  | `Invalid_scheme of string
  | `Invalid of string
  ]

type run_err =
  [ `Exn                            of exn
  | `E_address_family_not_supported
  | `E_address_in_use
  | `E_address_not_available
  ]

val show_request_err : request_err -> string

val pp_request_err : Format.formatter -> request_err -> unit

val show_connect_https_err : connect_https_err -> string

val pp_connect_https_err : Format.formatter -> connect_https_err -> unit

val show_connect_http_err : connect_http_err -> string

val pp_connect_http_err : Format.formatter -> connect_http_err -> unit

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

  (** An HTTP and HTTPs client.  Provides a high-level API for doing complete
      requests in one call down to the underlying APIs for managing a
      connection.  This client does not follow redirects or handle caching but
      simply provides the underlying HTTP request creation and response
      parsing. *)
  module Client : sig
    module Scheme : sig
      type t =
        | Http
        | Https of Otls.Tls_config.t
    end

    (** Open an HTTP connection. *)
    val connect_http :
      Abb_intf.Socket.Addrinfo.t ->
      Uri.t ->
      (Io.ic * Io.oc, [> connect_http_err ]) result Abb.Future.t

    (** Open an HTTPs connection using the provided TLS configuration. *)
    val connect_https :
      Abb_intf.Socket.Addrinfo.t ->
      Otls.Tls_config.t ->
      Uri.t ->
      (Io.ic * Io.oc, [> connect_https_err ]) result Abb.Future.t

    (** With an open connection, either HTTP or HTTPs, perform a request on the
        connection. *)
    val do_request :
      ?flush:bool ->
      ?body:Body.t ->
      Request.t ->
      Cohttp_abb_io.Make(Abb).ic ->
      Cohttp_abb_io.Make(Abb).oc ->
      (Response.t * Io.ic, [> request_err ]) result Abb.Future.t

    (** Perform an HTTP or HTTPs request.  If the URI in Request has no scheme
        it is assumed to be HTTP.  The [tls_config] will be used only for HTTPS
        requests and can be present for all requests. *)
    val request :
      ?flush:bool ->
      ?body:Body.t ->
      Scheme.t ->
      Request.t ->
      (Response.t * Io.ic, [> request_err ]) result Abb.Future.t

    (** A friendly wrapper over {!request}. *)
    val call :
      ?flush:bool ->
      ?headers:Cohttp.Header.t ->
      ?chunked:bool ->
      ?body:Body.t ->
      ?tls_config:Otls.Tls_config.t ->
      Cohttp.Code.meth ->
      Uri.t ->
      (Response.t * string, [> request_err ]) result Abb.Future.t
  end

  (** Simple HTTP and HTTPs server.  The server runs a configuration and returns
      when the server has stopped. *)
  module Server : sig
    (** The scheme type to serve. *)
    module Scheme : sig
      type t =
        | Http
        | Https of Otls.Tls_config.t
    end

    (** The type of a request handler.  A handler takes the parsed headers of a
        Request and the input and output buffers for the connection.  A handler
        is called per request however there can be multiple requests per
        connection.  A handler can decide to stop the TCP server by returning
        [`Stop].  If a handler throws an exception, the behaviour depends on the
        value of [on_handler_err] in the {!Config.t}. *)
    type handler =
      Abb.Socket.tcp Abb.Socket.t ->
      Request.t ->
      Request_io.IO.ic ->
      Response_io.IO.oc ->
      [ `Stop | `Ok ] Abb.Future.t

    (** The type of a failure handler.  A failure handler is run if a handler
       fails with an exception.  A failure handler returning [`Stop] means that
       the error was so severe that the server should be stopped.  An [`Ok]
       means to continue.  If the handler fails, by throwing an exception or
       aborting, it is the equivalent of returning [`Stop]. *)
    type on_handler_err =
      Request.t ->
      [ `Timeout | `Exn     of exn * Printexc.raw_backtrace option ] ->
      [ `Stop | `Ok ] Abb.Future.t

    (** The type of a protocol error handler.  This is called if the underlying
       HTTP request is malformed or timeout during read. *)
    type on_protocol_err = [ `Timeout | `Error   of string ] -> [ `Stop | `Ok ] Abb.Future.t

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

    (** Run the configuration.  Return when the server fails due to an error or
        a handler returns [`Stop]. *)
    val run : Config.t -> (unit, [> run_err ]) result Abb.Future.t
  end
  end
