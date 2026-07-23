(** The [Client] module implements the full UNIX HTTP client interface,
    including the UNIX-specific functions defined in {!C}. *)

include Cohttp_lwt.S.Client with type ctx = Net.ctx

val custom_ctx :
  ?ctx:Conduit_lwt_unix.ctx -> ?resolver:Resolver_lwt.t -> unit -> ctx
(** [custom_ctx ?ctx ?resolver ()] will return a context that is the same as the
    {!default_ctx}, but with either the connection handling or resolution module
    overridden with [ctx] or [resolver] respectively. This is useful to supply a
    {!Conduit_lwt_unix.ctx} with a custom source network interface, or a
    {!Resolver_lwt.t} with a different name resolution strategy (for instance to
    override a hostname to point it to a Unix domain socket). *)
