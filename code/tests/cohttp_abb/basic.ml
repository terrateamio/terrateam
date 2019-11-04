module Abb = Abb_scheduler_select
module Oth_abb = Oth_abb.Make (Abb)
module Http = Cohttp_abb.Make (Abb)
module Buffered = Abb_io_buffered.Make (Abb.Future)

let basic =
  Oth_abb.test ~desc:"Basic http test" ~name:"Basic" (fun () ->
      let open Abb.Future.Infix_monad in
      let (rc, ws) = Buffered.of_bytes (Bytes.of_string "HTTP/1.1 200 OK\r\nFoo: bar\r\n\r\n") in
      let (rs, wc) = Buffered.of_bytes (Bytes.of_string "") in
      Http.Client.do_request ~flush:true (Http.Request.make_for_client `GET (Uri.make ())) rc wc
      >>= fun (res, ic) ->
      assert (Cohttp.Code.string_of_status res.Http.Response.status = "200 OK");
      Buffered.read_line rs
      >>= fun ret ->
      assert (ret = Ok "GET / HTTP/1.1");
      Abb.Future.return ())

let test = Oth_abb.(to_sync_test (parallel [ basic ]))

let () =
  Random.self_init ();
  Oth.run test
