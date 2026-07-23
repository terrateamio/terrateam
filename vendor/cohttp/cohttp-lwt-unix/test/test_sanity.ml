open Lwt.Infix
open OUnit
open Cohttp_lwt_unix
open Cohttp_lwt_unix_test
module Body = Cohttp_lwt.Body
module IO = Cohttp_lwt_unix.IO

module Request = struct
  include Cohttp.Request
  include (Make (IO) : module type of Make (IO) with type t := t)
  end

let message = "Hello sanity!"
let chunk_body = [ "one"; ""; " "; "bar"; "" ]
let leak_repeat = 1024
let () = Debug.activate_debug ()
let () = Logs.set_level (Some Warning)

let server =
  List.map const
    [
      (* t *)
      Server.respond_string ~status:`OK ~body:message ();
      (* pipelined_chunk *)
      Server.respond ~status:`OK ~body:(Body.of_string "") ();
      Server.respond ~status:`OK ~body:(Body.of_string_list chunk_body) ();
      Server.respond ~status:`OK ~body:(Body.of_string "") ();
      (* pipelined_interleave *)
      Server.respond_string ~status:`OK ~body:"one" ();
      Server.respond_string ~status:`OK ~body:"two" ();
      Server.respond_string ~status:`OK ~body:"three" ();
      (* Massive chunked *)
      Server.respond ~status:`OK
        ~body:
          (let count = ref 0 in
           let chunk = String.make 64 '0' in
           `Stream
             (Lwt_stream.from_direct (fun () ->
                  if !count < 1000 then (
                    incr count;
                    Some chunk)
                  else None)))
        ();
    ]
  @ (Array.init (leak_repeat * 2) (fun _ _ _ ->
         (* no leaks *)
         Server.respond_string ~status:`OK ~body:"no leak" () >|= fun rsp ->
         `Response rsp)
    |> Array.to_list)
  (* pipelined_expert *)
  @ [
      (fun _ _ ->
        Lwt.return
          (`Expert
            ( Cohttp.Response.make (),
              fun _ic oc -> Lwt_io.write oc "8\r\nexpert 1\r\n0\r\n\r\n" )));
      (fun _ _ ->
        Lwt.return
          (`Expert
            ( Cohttp.Response.make (),
              fun ic oc ->
                Lwt_io.write oc "8\r\nexpert 2\r\n0\r\n\r\n" >>= fun () ->
                Lwt_io.flush oc >>= fun () -> Lwt_io.close ic )));
    ]
  |> response_sequence

let check_logs test () =
  let old = Logs.(warn_count () + err_count ()) in
  test () >|= fun () ->
  let new_errs = Logs.(warn_count () + err_count ()) - old in
  if new_errs > 0 then
    Fmt.failwith "Test produced %d log messages at level >= warn" new_errs

let ts =
  Cohttp_lwt_unix_test.test_server_s server (fun uri ->
      let ctx = Cohttp_lwt_unix.Net.default_ctx in
      let t () =
        Client.get ~ctx uri >>= fun (_, body) ->
        body |> Body.to_string >|= fun body -> assert_equal body message
      in
      let pipelined_chunk () =
        let printer x = x in
        let body = String.concat "" chunk_body in
        let reqs =
          [
            (Request.make ~meth:`HEAD uri, `Empty);
            (Request.make ~meth:`GET uri, `Empty);
            (Request.make ~meth:`HEAD uri, `Empty);
          ]
        in
        let counter = ref 0 in
        Client.callv ~ctx uri (Lwt_stream.of_list reqs) >>= fun resps ->
        Lwt_stream.iter_s
          (fun (_, rbody) ->
            rbody |> Body.to_string >|= fun rbody ->
            (match !counter with
            | 0 | 2 -> assert_equal ~printer "" rbody
            | _ -> assert_equal ~printer body rbody);
            incr counter)
          resps
        >>= fun () ->
        assert_equal ~printer:string_of_int 3 !counter;
        Lwt.return_unit
      in
      let pipelined_interleave () =
        let r n =
          let uri = Uri.with_query' uri [ ("test", string_of_int n) ] in
          (Request.make uri, Body.empty)
        in
        let reqs, push = Lwt_stream.create () in
        push (Some (r 1));
        push (Some (r 2));
        Client.callv ~ctx uri reqs >>= fun resps ->
        let resps = Lwt_stream.map_s (fun (_, b) -> Body.to_string b) resps in
        Lwt_stream.fold
          (fun b i ->
            Logs.info (fun f -> f "Request %i\n" i);
            (match i with
            | 0 -> assert_equal b "one"
            | 1 ->
                assert_equal b "two";
                Logs.info (fun f -> f "Sending extra request");
                push (Some (r 3))
            | 2 ->
                assert_equal b "three";
                push None
            | x -> assert_failure ("Test failed with " ^ string_of_int x));
            succ i)
          resps 0
        >|= fun l -> assert_equal l 3
      in
      let massive_chunked () =
        Client.get ~ctx uri >>= fun (_resp, body) ->
        Body.to_string body >|= fun body ->
        assert_equal ~printer:string_of_int (1000 * 64) (String.length body)
      in
      let test_no_leak () =
        let stream =
          Array.init leak_repeat (fun _ -> uri) |> Lwt_stream.of_array
        in
        Lwt_stream.fold_s
          (fun uri () ->
            Client.head ~ctx uri >>= fun resp_head ->
            assert_equal (Response.status resp_head) `OK;
            Client.get ~ctx uri >>= fun (resp_get, body) ->
            assert_equal (Response.status resp_get) `OK;
            Body.drain_body body)
          stream ()
      in
      let expert_pipelined () =
        let printer x = x in
        Client.get ~ctx uri >>= fun (_rsp, body) ->
        Body.to_string body >>= fun body ->
        assert_equal ~printer "expert 1" body;
        Client.get ~ctx uri >>= fun (_rsp, body) ->
        Body.to_string body >|= fun body ->
        assert_equal ~printer "expert 2" body
      in
      [
        ("sanity test", check_logs t);
        ("pipelined chunk test", check_logs pipelined_chunk);
        ("pipelined with interleaving requests", check_logs pipelined_interleave);
        ("massive chunked", check_logs massive_chunked);
        ("no leaks on requests", check_logs test_no_leak);
        ("expert response", check_logs expert_pipelined);
      ])

let _ = ts |> run_async_tests |> Lwt_main.run
