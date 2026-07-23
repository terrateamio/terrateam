(** HTTP server with conduit. *)

module type S = sig
  include Cohttp_lwt.S.Server

  val callback : t -> IO.conn -> unit Lwt.t
end

module Flow (F : Mirage_flow.S) : S with type IO.conn = F.flow

module Make (S : Conduit_mirage.S) : sig
  include S with type IO.conn = S.flow

  val callback : t -> S.flow -> unit Lwt.t
  val listen : S.t -> Conduit_mirage.server -> t -> unit Lwt.t
end
