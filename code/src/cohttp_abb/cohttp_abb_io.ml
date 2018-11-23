module Make (Abb : Abb_intf.S) = struct
  module Fut_comb = Abb_future_combinators.Make(Abb.Future)
  module Buffered = Abb_io_buffered.Make(Abb.Future)

  type +'a t = 'a Abb.Future.t

  type ic = Buffered.reader Buffered.t
  type oc = Buffered.writer Buffered.t

  type conn = unit

  let (>>=) = Abb.Future.Infix_monad.(>>=)

  let return = Abb.Future.return

  let read_line ic =
    let open Abb.Future.Infix_monad in
    Buffered.read_line ic
    >>| function
    | Ok s ->
      Some s
    | Error (`Unexpected End_of_file) ->
      None
    | Error _ ->
      assert false

  let read ic n =
    let open Abb.Future.Infix_monad in
    let buf = Bytes.create n in
    Buffered.read ic ~buf ~pos:0 ~len:n
    >>| function
    | Ok 0 ->
      ""
    | Ok n ->
      Bytes.sub_string buf 0 n
    | Error _ ->
      assert false

  let flush oc =
    let open Abb.Future.Infix_monad in
    Buffered.flushed oc
    >>| fun _ ->
    ()

  let write oc s =
    let open Abb.Future.Infix_monad in
    let buf = Bytes.unsafe_of_string s in
    Buffered.write oc ~bufs:Abb_intf.Write_buf.([{buf; pos = 0; len = Bytes.length buf}])
    >>= function
    | Ok _ ->
      Fut_comb.unit
    | Error _ ->
      assert false
end
