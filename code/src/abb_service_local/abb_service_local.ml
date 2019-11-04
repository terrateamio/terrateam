module Make (Fut : Abb_intf.Future.S) = struct
  open Fut.Infix_monad
  module Channel = Abb_channel.Make (Fut)
  module Channel_queue = Abb_channel_queue.Make (Fut)

  type 'a r = (Abb_channel.Make(Fut).reader, 'a) Abb_channel.Make(Fut).t

  type 'a w = (Abb_channel.Make(Fut).writer, 'a) Abb_channel.Make(Fut).t

  let run f writer reader = Fut.await (f writer reader) >>= fun _ -> Channel.close_reader reader

  let create f =
    let open Fut.Infix_monad in
    Channel_queue.T.create ~fast_count:100 ()
    >>= fun queue ->
    let (r_chan, w_chan) = Channel_queue.to_abb_channel queue in
    Fut.fork (run f w_chan r_chan) >>| fun _ -> w_chan
end
