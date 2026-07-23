(** HTTP server. *)
module Server (Flow : Mirage_flow.S) : sig
  include Cohttp_lwt.S.Server with type IO.conn = Flow.flow

  val listen : t -> IO.conn -> unit Lwt.t
end
