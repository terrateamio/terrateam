open Lwt.Infix
open OUnit
open Cohttp
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
let () = Logs.set_level (Some Info)
let () = Logs.set_reporter Logs.nop_reporter

let check_logs test () =
  let old = Logs.(warn_count () + err_count ()) in
  test () >|= fun () ->
  let new_errs = Logs.(warn_count () + err_count ()) - old in
  if new_errs > 0 then
    Fmt.failwith "Test produced %d log messages at level >= warn" new_errs

let server_noisy =
  List.map const
    [
      (* empty_chunk *)
      Server.respond ~status:`OK ~body:(Body.of_string_list chunk_body) ();
      (* not modified *)
      Server.respond ~status:`Not_modified ~body:Body.empty ();
    ]
  @ [
      (fun _ body ->
        (* Returns 500 on bad file *)
        Body.to_string body >>= fun fname ->
        Server.respond_file ~fname () >|= fun rsp -> `Response rsp);
    ]
  |> response_sequence

let ts_noisy =
  Cohttp_lwt_unix_test.test_server_s ~port:10193 server_noisy (fun uri ->
      let ctx = Cohttp_lwt_unix.Net.default_ctx in
      let empty_chunk () =
        Client.get ~ctx uri >>= fun (_, body) ->
        body |> Body.to_string >|= fun body ->
        assert_equal body (String.concat "" chunk_body)
      in
      let not_modified_has_no_body () =
        Client.get ~ctx uri >>= fun (resp, body) ->
        assert_equal (Response.status resp) `Not_modified;
        let headers = Response.headers resp in
        assert_equal ~printer:Transfer.string_of_encoding Transfer.Unknown
          (Header.get_transfer_encoding headers);
        body |> Body.is_empty >|= fun is_empty ->
        assert_bool "No body returned when not modified" is_empty
      in
      let unreadable_file_500 () =
        let fname = "unreadable500" in
        Lwt.finalize
          (fun () ->
            Lwt_io.open_file ~flags:[ Lwt_unix.O_CREAT ] ~perm:0o006
              ~mode:Lwt_io.Output fname
            >>= fun oc ->
            Lwt_io.write_line oc "never read" >>= fun () ->
            Lwt_io.close oc >>= fun () ->
            ( Client.post ~ctx uri ~body:(Body.of_string fname)
            >>= fun (resp, body) ->
              assert_equal ~printer:Code.string_of_status (Response.status resp)
                `Internal_server_error;
              Body.to_string body )
            >|= fun body ->
            assert_equal
              ~printer:(fun x -> "'" ^ x ^ "'")
              body "Error: Internal Server Error")
          (fun () -> Lwt_unix.unlink fname)
      in
      [
        ("empty chunk test", check_logs empty_chunk);
        ( "no body when response is not modified",
          check_logs not_modified_has_no_body );
        ("unreadable file returns 500", unreadable_file_500);
      ])

let _ = ts_noisy |> run_async_tests |> Lwt_main.run
