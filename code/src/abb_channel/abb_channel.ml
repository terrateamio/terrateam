module Make (Fut : Abb_intf.Future.S) = struct
  type reader
  type writer

  type ('a, 'msg) t = {
    send : 'msg -> unit Abb_channel_intf.channel_ret Fut.t;
    recv : unit -> 'msg Abb_channel_intf.channel_ret Fut.t;
    close : unit -> unit Fut.t;
    close_reader : unit -> unit Fut.t;
    closed : unit -> unit Fut.t;
  }

  let create
      (type mt msg)
      (module M : Abb_channel_intf.Make(Fut).S with type t = mt and type msg = msg)
      (mt : mt) : (reader, msg) t * (writer, msg) t =
    let t =
      {
        send = M.send mt;
        recv = (fun () -> M.recv mt);
        close = (fun () -> M.close mt);
        close_reader = (fun () -> M.close_with_abort mt);
        closed = (fun () -> M.closed mt);
      }
    in
    (t, t)

  let send t m = t.send m
  let recv t = t.recv ()
  let close t = t.close ()
  let close_reader t = t.close_reader ()
  let closed t = t.closed ()

  module Combinators = struct
    open Fut.Infix_monad

    let rec fold_with_close ~init ~f ~close reader =
      recv reader
      >>= function
      | `Ok msg -> f init msg >>= fun init -> fold_with_close ~init ~f ~close reader
      | `Closed -> close init

    let fold ~init ~f reader = fold_with_close ~init ~f ~close:Fut.return reader
    let iter ~f = fold ~init:() ~f:(fun () m -> f m)

    let send_promise writer msg p =
      send writer msg
      >>= function
      | `Closed -> Fut.return `Closed
      | `Ok () -> Fut.Promise.future p >>| fun v -> `Ok v

    let to_result fut =
      fut
      >>| function
      | `Ok v -> Ok v
      | `Closed -> Error `Closed
  end
end
