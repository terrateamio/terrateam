val request :
  ?interrupt:unit Async_kernel.Deferred.t ->
  ?ssl_config:Conduit_async.V2.Ssl.Config.t ->
  ?uri:Uri.t ->
  ?body:Body.t ->
  Cohttp.Request.t ->
  (Cohttp.Response.t * Body.t) Async_kernel.Deferred.t
(** Send an HTTP request with an arbitrary body The request is sent as-is. *)

val call :
  ?interrupt:unit Async_kernel.Deferred.t ->
  ?ssl_config:Conduit_async.V2.Ssl.Config.t ->
  ?headers:Cohttp.Header.t ->
  ?chunked:bool ->
  ?body:Body.t ->
  Cohttp.Code.meth ->
  Uri.t ->
  (Cohttp.Response.t * Body.t) Async_kernel.Deferred.t
(** Send an HTTP request with arbitrary method and a body Infers the transfer
    encoding. Depending on the given [uri], we choose a way to start a
    communication such as:

    - If the scheme is [https], we try to initiate an SSL connection with the
      given [ssl_ctx] or a default one on the default port ([*:443]) or the
      specified one.
    - If the scheme is [httpunix], we use a UNIX domain socket.
    - If the scheme ie [http], we try an usual TCP/IP connection on the default
      port ([*:80]) or the specified one. *)

module Connection : sig
  type t

  val connect :
    ?interrupt:unit Async_kernel.Deferred.t ->
    ?ssl_config:Conduit_async.V2.Ssl.Config.t ->
    Uri.t ->
    t Async_kernel.Deferred.t

  val close : t -> unit Async_kernel.Deferred.t
  val is_closed : t -> bool

  val request :
    ?body:Body.t ->
    t ->
    Cohttp.Request.t ->
    (Cohttp.Response.t * Body.t) Async_kernel.Deferred.t
end

val callv :
  ?interrupt:unit Async_kernel.Deferred.t ->
  ?ssl_config:Conduit_async.V2.Ssl.Config.t ->
  Uri.t ->
  (Cohttp.Request.t * Body.t) Async_kernel.Pipe.Reader.t ->
  (Cohttp.Response.t * Body.t) Async_kernel.Pipe.Reader.t
  Async_kernel.Deferred.t

val get :
  ?interrupt:unit Async_kernel.Deferred.t ->
  ?ssl_config:Conduit_async.V2.Ssl.Config.t ->
  ?headers:Cohttp.Header.t ->
  Uri.t ->
  (Cohttp.Response.t * Body.t) Async_kernel.Deferred.t
(** Send an HTTP GET request *)

val head :
  ?interrupt:unit Async_kernel.Deferred.t ->
  ?ssl_config:Conduit_async.V2.Ssl.Config.t ->
  ?headers:Cohttp.Header.t ->
  Uri.t ->
  Cohttp.Response.t Async_kernel.Deferred.t
(** Send an HTTP HEAD request *)

val delete :
  ?interrupt:unit Async_kernel.Deferred.t ->
  ?ssl_config:Conduit_async.V2.Ssl.Config.t ->
  ?headers:Cohttp.Header.t ->
  ?chunked:bool ->
  ?body:Body.t ->
  Uri.t ->
  (Cohttp.Response.t * Body.t) Async_kernel.Deferred.t
(** Send an HTTP DELETE request *)

val post :
  ?interrupt:unit Async_kernel.Deferred.t ->
  ?ssl_config:Conduit_async.V2.Ssl.Config.t ->
  ?headers:Cohttp.Header.t ->
  ?chunked:bool ->
  ?body:Body.t ->
  Uri.t ->
  (Cohttp.Response.t * Body.t) Async_kernel.Deferred.t
(** Send an HTTP POST request. [chunked] encoding is off by default as not many
    servers support it *)

val put :
  ?interrupt:unit Async_kernel.Deferred.t ->
  ?ssl_config:Conduit_async.V2.Ssl.Config.t ->
  ?headers:Cohttp.Header.t ->
  ?chunked:bool ->
  ?body:Body.t ->
  Uri.t ->
  (Response.t * Body.t) Async_kernel.Deferred.t
(** Send an HTTP PUT request. [chunked] encoding is off by default as not many
    servers support it *)

val patch :
  ?interrupt:unit Async_kernel.Deferred.t ->
  ?ssl_config:Conduit_async.V2.Ssl.Config.t ->
  ?headers:Cohttp.Header.t ->
  ?chunked:bool ->
  ?body:Body.t ->
  Uri.t ->
  (Response.t * Body.t) Async_kernel.Deferred.t
(** Send an HTTP PATCH request. [chunked] encoding is off by default as not many
    servers support it *)

val post_form :
  ?interrupt:unit Async_kernel.Deferred.t ->
  ?ssl_config:Conduit_async.V2.Ssl.Config.t ->
  ?headers:Cohttp.Header.t ->
  params:(string * string list) list ->
  Uri.t ->
  (Response.t * Body.t) Async_kernel.Deferred.t
(** Send an HTTP POST request in form format *)
