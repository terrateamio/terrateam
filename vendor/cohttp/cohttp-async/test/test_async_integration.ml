open Base
open Async_kernel
open OUnit
open Cohttp
open Cohttp_async
open Cohttp_async_test

let chunk_body = [ "one"; ""; " "; "bar"; "" ]
let large_string = String.make (Int.pow 2 16) 'A'
let response_bodies = [ "Testing"; "Foo bar" ]
let ok s = Server.respond `OK ~body:(Body.of_string s)
let chunk size = String.init ~f:(Fn.const 'X') size
let chunk_size = 33_000
let chunks = 3

let server =
  [
    (* empty_chunk *)
    const @@ Server.respond `OK ~body:(Body.of_string_list chunk_body);
    (* large response *)
    const @@ Server.respond_string large_string;
    (* large request *)
    (fun _ body ->
      body |> Body.to_string >>| String.length >>= fun len ->
      Server.respond_string (Int.to_string len) >>| response);
  ]
  (* pipelined_chunk *)
  @ (response_bodies |> List.map ~f:(Fn.compose const ok))
  @ (* large response chunked *)
  [
    (fun _ _ ->
      let body =
        let r, w = Pipe.create () in
        let chunk = chunk chunk_size in
        for _ = 0 to chunks - 1 do
          Pipe.write_without_pushback w chunk
        done;
        Pipe.close w;
        r
      in
      Server.respond_with_pipe ~code:`OK body >>| response);
    (* pipelined_expert *)
    expert (fun _ic oc ->
        Async_unix.Writer.write oc "8\r\nexpert 1\r\n0\r\n\r\n";
        Async_unix.Writer.flushed oc);
    expert (fun ic oc ->
        Async_unix.Writer.write oc "8\r\nexpert 2\r\n0\r\n\r\n";
        Async_unix.Writer.flushed oc >>= fun () -> Async_unix.Reader.close ic);
  ]
  |> response_sequence

let ts =
  test_server_s server (fun uri ->
      let headers = Header.init_with "connection" "close" in
      let empty_chunk () =
        Client.get ~headers uri >>= fun (_, body) ->
        body |> Body.to_string >>| fun body ->
        assert_equal body (String.concat ~sep:"" chunk_body)
      in
      let large_response () =
        Client.get ~headers uri >>= fun (_, body) ->
        body |> Body.to_string >>| fun body -> assert_equal body large_string
      in
      let large_request () =
        Client.post ~headers ~body:(Body.of_string large_string) uri
        >>= fun (_, body) ->
        body |> Body.to_string >>| fun s ->
        assert_equal (String.length large_string) (Int.of_string s)
      in
      let pipelined_chunk () =
        let printer x = x in
        let reqs =
          [
            (Request.make ~meth:`POST uri, Body.of_string "foo");
            (Request.make ~meth:`POST uri, Body.of_string "bar");
          ]
        in
        let body_q = response_bodies |> Queue.of_list in
        reqs |> Pipe.of_list |> Client.callv uri >>= fun responses ->
        responses |> Pipe.to_list >>= fun resps ->
        resps
        |> Deferred.List.iter ~how:`Sequential ~f:(fun (_resp, body) ->
               let expected_body = body_q |> Queue.dequeue_exn in
               body |> Body.to_string >>| fun body ->
               assert_equal ~printer expected_body body)
      in
      let large_chunked_response () =
        Client.get ~headers uri >>= fun (resp, body) ->
        assert_equal Cohttp.Transfer.Chunked (Response.encoding resp);
        body |> Body.to_string >>| String.length >>| fun len ->
        assert_equal ~printer:Int.to_string (chunk_size * chunks) len
      in
      let expert_pipelined () =
        let printer x = x in
        Client.get uri >>= fun (_rsp, body) ->
        Body.to_string body >>= fun body ->
        assert_equal ~printer "expert 1" body;
        Client.get ~headers uri >>= fun (_rsp, body) ->
        Body.to_string body >>| fun body ->
        assert_equal ~printer "expert 2" body
      in
      let check_body_empty_status () =
        let is_empty = Cohttp_async.Body.is_empty in
        let tests =
          [
            ("empty pipe", Pipe.of_list [], true);
            ("pipe with elements", Pipe.of_list [ "foo"; "bar" ], false);
            ( "pipe with empty items at the beginning",
              Pipe.of_list [ ""; "baz" ],
              false );
            ("Pipe with empty strings", Pipe.of_list [ ""; ""; "" ], true);
          ]
        in
        Deferred.List.iter ~how:`Sequential tests ~f:(fun (msg, pipe, expected) ->
            is_empty (`Pipe pipe) >>| fun real ->
            assert_equal ~msg expected real)
        >>= fun () ->
        let b = Pipe.of_list [ ""; ""; "foo"; "bar" ] in
        is_empty (`Pipe b) >>= fun _ ->
        Pipe.to_list b >>| fun real ->
        let msg =
          "Checking if pipe is empty consumes all leading empty strings"
        in
        assert_equal ~msg [ "foo"; "bar" ] real
      in
      [
        ("empty chunk test", empty_chunk);
        ("large response", large_response);
        ("large request", large_request);
        ("pipelined chunk test", pipelined_chunk);
        ("large chunked response", large_chunked_response);
        ("expert response", expert_pipelined);
        ("check body is_empty status for pipes", check_body_empty_status);
      ])

let () =
  ts
  |> run_async_tests
  >>= (fun _ -> Async_unix.Shutdown.exit 0)
  |> don't_wait_for;
  Core.never_returns (Async_unix.Scheduler.go ())
