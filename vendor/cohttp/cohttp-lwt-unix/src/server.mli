(** The [Server] module implements the full UNIX HTTP server interface,
    including the UNIX-specific functions defined in {!S}.

    The {!Logs} source name for this module logger is ["cohttp.lwt.server"].
    Refer to the {!Debug} module for further details. *)

include Cohttp_lwt.S.Server with module IO = Io

val resolve_file : docroot:string -> uri:Uri.t -> string
(** Deprecated. Please use Cohttp.Path.resolve_local_file. *)

val respond_file :
  ?headers:Cohttp.Header.t ->
  fname:string ->
  unit ->
  (Cohttp.Response.t * Cohttp_lwt.Body.t) Lwt.t

val create :
  ?timeout:int ->
  ?backlog:int ->
  ?stop:unit Lwt.t ->
  ?on_exn:(exn -> unit) ->
  ?ctx:Net.ctx ->
  ?mode:Conduit_lwt_unix.server ->
  t ->
  unit Lwt.t
(** [create ?timeout ?backlog ?stop ?on_exn ?mode t] is a new HTTP server.

    The user can decide to start a simple HTTP server (without encryption) or
    one with TLS encryption. It depends on what the user gives as [mode] and how
    [conduit-unix] is configured.

    To create a simple HTTP server listening on port 8089:

    {[ let run = create (`TCP 8080) ]}

    When provided, the [stop] thread will terminate the server if it ever
    becomes determined.

    When provided, [backlog] will limit the number of open connections.

    Every connection will be served in a new lightweight thread that is invoked
    via the callback defined in [t]. If the callback raises an exception, it is
    passed to [on_exn] (by default, to a function that logs the exception using
    the {!Logs} library). *)
