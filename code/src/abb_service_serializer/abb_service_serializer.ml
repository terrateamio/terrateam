module Make (S : Abb_intf.S) = struct
  module Fut = S.Future
  module Service_local = Abb_service_local.Make (S)

  module Req = struct
    type 'resp t = Run : (unit -> 'resp Fut.t) -> 'resp t
  end

  module Svc = Service_local.Make_typed (Req)

  type msg = Svc.msg
  type t = Svc.svc

  module Server = struct
    let rec loop chan =
      let open Fut.Infix_monad in
      S.Chan.recv chan
      >>= function
      | Ok (Svc.Msg req) ->
          let (Req.Run f) = Service_local.Request.payload req in
          Service_local.respond req f >>= fun () -> loop chan
      | Error `Chan_closed -> Fut.return ()
  end

  let create () = Svc.create Server.loop

  let run t ~f =
    let open Fut.Infix_monad in
    Svc.call t (Req.Run f)
    >>= function
    | Ok v -> Fut.return (`Ok v)
    | Error `Chan_closed -> Fut.return `Closed

  module Mutex = struct
    type serializer = t

    type 'a t = {
      value : 'a;
      serializer : serializer;
    }

    let create s v = { value = v; serializer = s }
    let run t ~f = run t.serializer ~f:(fun () -> f t.value)
  end
end
