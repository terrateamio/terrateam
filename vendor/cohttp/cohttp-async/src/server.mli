type ('address, 'listening_on) t
  constraint 'address = [< Async_unix.Socket.Address.t ]
[@@deriving sexp_of]

val close : (_, _) t -> unit Async_kernel.Deferred.t
val close_finished : (_, _) t -> unit Async_kernel.Deferred.t
val is_closed : (_, _) t -> bool
val listening_on : (_, 'listening_on) t -> 'listening_on

type response = Response.t * Body.t [@@deriving sexp_of]

type 'r respond_t =
  ?flush:bool ->
  ?headers:Cohttp.Header.t ->
  ?body:Body.t ->
  Cohttp.Code.status_code ->
  'r Async_kernel.Deferred.t

type response_action =
  [ `Expert of
    Cohttp.Response.t
    * (Async_unix.Reader.t ->
      Async_unix.Writer.t ->
      unit Async_kernel.Deferred.t)
  | `Response of response ]
(** A request handler can respond in two ways:

    - Using [`Response], with a {!Response.t} and a {!Body.t}.
    - Using [`Expert], with a {!Response.t} and an IO function that is expected
      to write the response body. The IO function has access to the underlying
      {!Async_unix.Reader.t} and {!Async_unix.Writer.t}, which allows writing a
      response body more efficiently, stream a response or to switch protocols
      entirely (e.g. websockets). Processing of pipelined requests continue
      after the {!unit Async_kernel.Deferred.t} is resolved. The connection can
      be closed by closing the {!Async_unix.Reader.t}. *)

val respond : response respond_t

val resolve_local_file : docroot:string -> uri:Uri.t -> string
(** Resolve a URI and a docroot into a concrete local filename.

    Deprecated. Please use Cohttp.Path.resolve_local_file. *)

val respond_with_pipe :
  ?flush:bool ->
  ?headers:Cohttp.Header.t ->
  ?code:Cohttp.Code.status_code ->
  string Async_kernel.Pipe.Reader.t ->
  response Async_kernel.Deferred.t
(** Respond with a [string] Pipe that provides the response string
    Pipe.Reader.t.

    @param code Default is HTTP 200 `OK *)

val respond_string :
  ?flush:bool ->
  ?headers:Cohttp.Header.t ->
  ?status:Cohttp.Code.status_code ->
  string ->
  response Async_kernel.Deferred.t

val respond_with_redirect :
  ?headers:Cohttp.Header.t -> Uri.t -> response Async_kernel.Deferred.t
(** Respond with a redirect to an absolute [uri]

    @param uri Absolute URI to redirect the client to *)

val respond_with_file :
  ?flush:bool ->
  ?headers:Cohttp.Header.t ->
  ?error_body:string ->
  string ->
  response Async_kernel.Deferred.t
(** Respond with file contents, and [error_string Pipe.Async_unix.Reader.t] if
    the file isn't found *)

type mode = Conduit_async.server

val create_expert :
  ?max_connections:int ->
  ?backlog:int ->
  ?buffer_age_limit:Async_unix.Writer.buffer_age_limit ->
  ?mode:mode ->
  on_handler_error:[ `Call of 'address -> exn -> unit | `Ignore | `Raise ] ->
  ('address, 'listening_on) Async.Tcp.Where_to_listen.t ->
  (body:Body.t ->
  'address ->
  Request.t ->
  response_action Async_kernel.Deferred.t) ->
  ('address, 'listening_on) t Async_kernel.Deferred.t
(** Build a HTTP server and expose the [IO.ic] and [IO.oc]s, based on the
    [Tcp.Server] interface. *)

val create :
  ?max_connections:int ->
  ?backlog:int ->
  ?buffer_age_limit:Async_unix.Writer.buffer_age_limit ->
  ?mode:Conduit_async.server ->
  on_handler_error:[ `Call of 'address -> exn -> unit | `Ignore | `Raise ] ->
  ('address, 'listening_on) Async.Tcp.Where_to_listen.t ->
  (body:Body.t -> 'address -> Request.t -> response Async_kernel.Deferred.t) ->
  ('address, 'listening_on) t Async_kernel.Deferred.t
(** Build a HTTP server, based on the [Tcp.Server] interface *)
