(** Portable Lwt implementation of HTTP client and server, without depending on
    a particular I/O implementation. The various [Make] functors must be
    instantiated by an implementation that provides a concrete IO monad. *)

(** The IO module is specialized for the [Lwt] monad. *)
module type IO = sig
  include Cohttp.S.IO with type 'a t = 'a Lwt.t

  type error

  val catch : (unit -> 'a t) -> ('a, error) result t
  (** [catch f] is [f () >|= Result.ok], unless [f] fails with an IO error, in
      which case it returns the error. *)

  val pp_error : Format.formatter -> error -> unit
end

(** The [Net] module type defines how to connect to a remote node and close the
    resulting channels to clean up. *)
module type Net = sig
  module IO : IO

  type ctx [@@deriving sexp_of]

  val default_ctx : ctx
  val connect_uri : ctx:ctx -> Uri.t -> (IO.conn * IO.ic * IO.oc) Lwt.t
  val close_in : IO.ic -> unit
  val close_out : IO.oc -> unit
  val close : IO.ic -> IO.oc -> unit
end

(** The [Client] module implements non-pipelined single HTTP client calls. Each
    call will open a separate {!Net} connection. For best results, the {!Body}
    that is returned should be consumed in order to close the file descriptor in
    a timely fashion. It will still be finalized by a GC hook if it is not used
    up, but this can take some additional time to happen. *)
module type Client = sig
  type ctx

  val call :
    ?ctx:ctx ->
    ?headers:Cohttp.Header.t ->
    ?body:Body.t ->
    ?chunked:bool ->
    Cohttp.Code.meth ->
    Uri.t ->
    (Cohttp.Response.t * Body.t) Lwt.t
  (** [call ?ctx ?headers ?body ?chunked meth uri] will resolve the [uri] to a
      concrete network endpoint using context [ctx]. It will then issue an HTTP
      request with method [meth], adding request headers from [headers] if
      present. If a [body] is specified then that will be included with the
      request, using chunked encoding if [chunked] is true. The default is to
      disable chunked encoding for HTTP request bodies for compatibility
      reasons.

      In most cases you should use the more specific helper calls in the
      interface rather than invoke this function directly. See {!head}, {!get}
      and {!post} for some examples.

      To avoid leaks, the body needs to be consumed, using the functions
      provided in the {!Body} module and, if not necessary, should be explicitly
      drained calling {!Body.drain_body}. Leaks are logged as debug messages by
      the client, these can be enabled activating the debug logging. For
      example, this can be done as follows in [cohttp-lwt-unix]

      {[
        Cohttp_lwt_unix.Debug.activate_debug ();
        Logs.set_level (Some Logs.Warning)
      ]}

      Depending on [ctx], the library is able to send a simple HTTP request or
      an encrypted one with a secured protocol (such as TLS). Depending on how
      conduit is configured, [ctx] might initiate a secured connection with TLS
      (using [ocaml-tls]) or SSL (using [ocaml-ssl]), on [*:443] or on the
      specified port by the user. If neitehr [ocaml-tls] or [ocaml-ssl] are
      installed on the system, [cohttp]/[conduit] tries the usual ([*:80]) or
      the specified port by the user in a non-secured way. *)

  val head :
    ?ctx:ctx -> ?headers:Cohttp.Header.t -> Uri.t -> Cohttp.Response.t Lwt.t

  val get :
    ?ctx:ctx ->
    ?headers:Cohttp.Header.t ->
    Uri.t ->
    (Cohttp.Response.t * Body.t) Lwt.t

  val delete :
    ?ctx:ctx ->
    ?body:Body.t ->
    ?chunked:bool ->
    ?headers:Cohttp.Header.t ->
    Uri.t ->
    (Cohttp.Response.t * Body.t) Lwt.t

  val post :
    ?ctx:ctx ->
    ?body:Body.t ->
    ?chunked:bool ->
    ?headers:Cohttp.Header.t ->
    Uri.t ->
    (Cohttp.Response.t * Body.t) Lwt.t

  val put :
    ?ctx:ctx ->
    ?body:Body.t ->
    ?chunked:bool ->
    ?headers:Cohttp.Header.t ->
    Uri.t ->
    (Cohttp.Response.t * Body.t) Lwt.t

  val patch :
    ?ctx:ctx ->
    ?body:Body.t ->
    ?chunked:bool ->
    ?headers:Cohttp.Header.t ->
    Uri.t ->
    (Cohttp.Response.t * Body.t) Lwt.t

  val post_form :
    ?ctx:ctx ->
    ?headers:Cohttp.Header.t ->
    params:(string * string list) list ->
    Uri.t ->
    (Cohttp.Response.t * Body.t) Lwt.t

  val callv :
    ?ctx:ctx ->
    Uri.t ->
    (Cohttp.Request.t * Body.t) Lwt_stream.t ->
    (Cohttp.Response.t * Body.t) Lwt_stream.t Lwt.t
end

(** The [Server] module implements a pipelined HTTP/1.1 server. *)
module type Server = sig
  module IO : IO

  type conn = IO.conn * Cohttp.Connection.t

  type response_action =
    [ `Expert of Cohttp.Response.t * (IO.ic -> IO.oc -> unit Lwt.t)
    | `Response of Cohttp.Response.t * Body.t ]
  (** A request handler can respond in two ways:

      - Using [`Response], with a {!Response.t} and a {!Body.t}.
      - Using [`Expert], with a {!Response.t} and an IO function that is
        expected to write the response body. The IO function has access to the
        underlying {!IO.ic} and {!IO.oc}, which allows writing a response body
        more efficiently, stream a response or to switch protocols entirely
        (e.g. websockets). Processing of pipelined requests continue after the
        {!unit Lwt.t} is resolved. The connection can be closed by closing the
        {!IO.ic}. *)

  type t

  val make_response_action :
    ?conn_closed:(conn -> unit) ->
    callback:(conn -> Cohttp.Request.t -> Body.t -> response_action Lwt.t) ->
    unit ->
    t

  val make_expert :
    ?conn_closed:(conn -> unit) ->
    callback:
      (conn ->
      Cohttp.Request.t ->
      Body.t ->
      (Cohttp.Response.t * (IO.ic -> IO.oc -> unit Lwt.t)) Lwt.t) ->
    unit ->
    t

  val make :
    ?conn_closed:(conn -> unit) ->
    callback:
      (conn -> Cohttp.Request.t -> Body.t -> (Cohttp.Response.t * Body.t) Lwt.t) ->
    unit ->
    t

  val resolve_local_file : docroot:string -> uri:Uri.t -> string
  (** Resolve a URI and a docroot into a concrete local filename.

      Deprecated. Please use Cohttp.Path.resolve_local_file. *)

  val respond :
    ?headers:Cohttp.Header.t ->
    ?flush:bool ->
    status:Cohttp.Code.status_code ->
    body:Body.t ->
    unit ->
    (Cohttp.Response.t * Body.t) Lwt.t
  (** [respond ?headers ?flush ~status ~body] will respond to an HTTP request
      with the given [status] code and response [body]. If [flush] is true, then
      every response chunk will be flushed to the network rather than being
      buffered. [flush] is true by default. The transfer encoding will be
      detected from the [body] value and set to chunked encoding if it cannot be
      determined immediately. You can override the encoding by supplying an
      appropriate [Content-length] or [Transfer-encoding] in the [headers]
      parameter. *)

  val respond_string :
    ?flush:bool ->
    ?headers:Cohttp.Header.t ->
    status:Cohttp.Code.status_code ->
    body:string ->
    unit ->
    (Cohttp.Response.t * Body.t) Lwt.t

  val respond_error :
    ?headers:Cohttp.Header.t ->
    ?status:Cohttp.Code.status_code ->
    body:string ->
    unit ->
    (Cohttp.Response.t * Body.t) Lwt.t

  val respond_redirect :
    ?headers:Cohttp.Header.t ->
    uri:Uri.t ->
    unit ->
    (Cohttp.Response.t * Body.t) Lwt.t

  val respond_need_auth :
    ?headers:Cohttp.Header.t ->
    auth:Cohttp.Auth.challenge ->
    unit ->
    (Cohttp.Response.t * Body.t) Lwt.t

  val respond_not_found :
    ?uri:Uri.t -> unit -> (Cohttp.Response.t * Body.t) Lwt.t

  val callback : t -> IO.conn -> IO.ic -> IO.oc -> unit Lwt.t
end
