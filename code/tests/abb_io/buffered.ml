module Abb = Abb_scheduler_select
module Oth_abb = Oth_abb.Make (Abb)
module Buffered = Abb_io_buffered.Make (Abb.Future)
module Fut = Abb.Future

let bytes_read =
  Oth_abb.test ~desc:"Simple read test" ~name:"Bytes Read" (fun () ->
      let open Fut.Infix_monad in
      let b = Bytes.of_string "testing" in
      let r, _ = Buffered.of_bytes b in
      let b' = Bytes.create (Bytes.length b) in
      Buffered.read r ~buf:b' ~pos:0 ~len:(Bytes.length b')
      >>= fun ret ->
      assert (ret = Ok (Bytes.length b'));
      assert (b' = b);
      Buffered.read r ~buf:b' ~pos:0 ~len:(Bytes.length b')
      >>= fun ret ->
      assert (ret = Ok 0);
      Fut.return ())

let bytes_write =
  Oth_abb.test ~desc:"Simple write test" ~name:"Bytes Write" (fun () ->
      let open Fut.Infix_monad in
      let b = Bytes.of_string "" in
      let buf = Bytes.of_string "testing" in
      let len = Bytes.length buf in
      let r, w = Buffered.of_bytes b in
      Buffered.write w ~bufs:Abb_intf.Write_buf.[ { buf; pos = 0; len } ]
      >>= fun write_ret ->
      Buffered.flushed w
      >>= fun flushed_ret ->
      assert (write_ret = Ok len);
      assert (flushed_ret = Ok ());
      let b' = Bytes.create (Bytes.length buf) in
      Buffered.read r ~buf:b' ~pos:0 ~len:(Bytes.length b')
      >>= fun read_ret ->
      assert (read_ret = Ok (Bytes.length b'));
      assert (b' = buf);
      Buffered.read r ~buf:b' ~pos:0 ~len:(Bytes.length b')
      >>= fun read_ret ->
      assert (read_ret = Ok 0);
      Fut.return ())

let read_line =
  Oth_abb.test ~desc:"Simple read_line" ~name:"Read line" (fun () ->
      let open Fut.Infix_monad in
      let b = Bytes.of_string "foo\nbar" in
      let r, _ = Buffered.of_bytes b in
      Buffered.read_line r
      >>= fun read_ret ->
      assert (read_ret = Ok (Some "foo"));
      Buffered.read_line r
      >>= fun read_ret ->
      assert (read_ret = Ok (Some "bar"));
      Buffered.read_line r
      >>= fun read_ret ->
      assert (read_ret = Ok None);
      Fut.return ())

let close_gives_read_eof =
  Oth_abb.test ~desc:"Closing writer gives EOF on reader" ~name:"Close gives read EOF" (fun _ ->
      let open Abb.Future.Infix_monad in
      let b = Bytes.of_string "" in
      let r, _ = Buffered.of_bytes b in
      let b' = Bytes.create 1024 in
      Buffered.read r ~buf:b' ~pos:0 ~len:(Bytes.length b')
      >>= fun read_ret ->
      assert (read_ret = Ok (Bytes.length b));
      assert (Bytes.sub b' 0 (Bytes.length b) = b);
      Buffered.read r ~buf:b' ~pos:0 ~len:(Bytes.length b')
      >>= fun read_ret ->
      assert (read_ret = Ok 0);
      Abb.Future.return ())

let test =
  Oth_abb.(to_sync_test (parallel [ bytes_read; bytes_write; read_line; close_gives_read_eof ]))

let () =
  Random.self_init ();
  Oth.run test
