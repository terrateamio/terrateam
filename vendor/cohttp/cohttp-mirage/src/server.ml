open Lwt.Infix

module type S = sig
  include Cohttp_lwt.S.Server

  val callback : t -> IO.conn -> unit Lwt.t
end

module Flow (F : Mirage_flow.S) = struct
  module Channel = Mirage_channel.Make (F)
  module HTTP_IO = Io.Make (Channel)
  include Cohttp_lwt.Make_server (HTTP_IO)

  let callback spec flow =
    let ch = Channel.create flow in
    Lwt.finalize
      (fun () -> callback spec flow ch ch)
      (fun () -> Channel.close ch >|= fun _ -> ())
end

module Make (S : Conduit_mirage.S) = struct
  include Flow (S.Flow)

  let listen s conf t = S.listen s conf (callback t)
end
