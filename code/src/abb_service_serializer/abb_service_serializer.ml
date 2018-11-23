module Make (Fut : Abb_intf.Future.S) = struct
  open Fut.Infix_monad

  module Channel = Abb_channel.Make(Fut)
  module Service_local = Abb_service_local.Make(Fut)
  module Fut_comb = Abb_future_combinators.Make(Fut)

  type msg = Run : ((unit -> 'a Fut.t) * 'a Fut.Promise.t) -> msg

  type t = (Channel.writer, msg) Channel.t

  module Server = struct
    let loop (Run (f, p)) =
      Fut.await (Fut_comb.on_failure f ~failure:(fun () -> Fut_comb.unit))
      >>= function
      | `Det v ->
        Fut.Promise.set p v
      | `Exn exn ->
        Fut.Promise.set_exn p exn
      | `Aborted ->
        Fut.abort (Fut.Promise.future p)

    let init _ reader =
      Channel.Combinators.fold ~f:(fun () msg -> loop msg) ~init:() reader
  end

  let create () =
    Service_local.create Server.init

  let run t ~f =
    let p = Fut.Promise.create () in
    Channel.Combinators.send_promise t (Run (f, p)) p

  module Mutex = struct
    type serializer = t
    type 'a t = { value : 'a
                ; serializer : serializer
                }

    let create s v = { value = v; serializer = s }
    let run t ~f = run t.serializer ~f:(fun () -> f t.value)
  end
end
