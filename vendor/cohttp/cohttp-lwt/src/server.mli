(** The [Make] functor glues together a {!Cohttp.S.IO} implementation to send
    requests down a connection that is established by the user. The resulting
    module satisfies the {!Server} module type.

    The {!Logs} source name for this module's logger is ["cohttp.lwt.server"].*)

module Make (IO : S.IO) : S.Server with module IO = IO
