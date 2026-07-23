(*{{{ Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
  }}}*)

open OUnit

let basic_req = "GET /index.html HTTP/1.1\r\nHost: www.example.com\r\n\r\n"

let basic_res =
  "HTTP/1.1 200 OK\r\n\
   Date: Mon, 23 May 2005 22:38:34 GMT\r\n\
   Server: Apache/1.3.3.7 (Unix) (Red-Hat/Linux)\r\n\
   Last-Modified: Wed, 08 Jan 2003 23:11:55 GMT\r\n\
   Etag: \"3f80f-1b6-3e1cb03b\"\r\n\
   Accept: text/*\r\n\
   Accept: application/xml\r\n\
   Accept-Ranges:  none\r\n\
   Content-Length: 0\r\n\
   Connection: close\r\n\
   Content-Type: text/html; charset=UTF-8"

let basic_res_content =
  "HTTP/1.1 200 OK\r\n\
   Date: Mon, 23 May 2005 22:38:34 GMT\r\n\
   Server: Apache/1.3.3.7 (Unix) (Red-Hat/Linux)\r\n\
   Last-Modified: Wed, 08 Jan 2003 23:11:55 GMT\r\n\
   Etag: \"3f80f-1b6-3e1cb03b\"\r\n\
   Accept-Ranges:  none\r\n\
   Content-Length: 32\r\n\
   Connection: close\r\n\
   Content-Type: text/html; charset=UTF-8\r\n\
   \r\n\
   home=Cosby&favorite+flavor=flies"

let post_req =
  "POST /path/script.cgi HTTP/1.0\r\n\
   From: frog@jmarshall.com\r\n\
   User-Agent: HTTPTool/1.0\r\n\
   Content-Type: application/x-www-form-urlencoded\r\n\
   Content-Length: 32\r\n\
   \r\n\
   home=Cosby&favorite+flavor=flies"

let post_data_req =
  "POST /path/script.cgi HTTP/1.0\r\n\
   From: frog@jmarshall.com\r\n\
   User-Agent: HTTPTool/1.0\r\n\
   Content-Length: 32\r\n\
   \r\n\
   home=Cosby&favorite+flavor=flies"

let post_chunked_req =
  "POST /foo HTTP/1.1\r\n\
   Date: Fri, 31 Dec 1999 23:59:59 GMT\r\n\
   Content-Type: text/plain\r\n\
   Transfer-Encoding: chunked\r\n\
   \r\n\
   1a; ignore-stuff-here\r\n\
   abcdefghijklmnopqrstuvwxyz\r\n\
   10\r\n\
   1234567890abcdef\r\n\
   0\r\n\
   some-footer: some-value\r\n\
   another-footer: another-value\r\n\
   \r\n"

let chunked_res =
  "HTTP/1.1 200 OK\r\n\
   Date: Fri, 31 Dec 1999 23:59:59 GMT\r\n\
   Content-Type: text/plain\r\n\
   Transfer-Encoding: chunked\r\n\
   \r\n\
   1a; ignore-stuff-here\r\n\
   abcdefghijklmnopqrstuvwxyz\r\n\
   10\r\n\
   1234567890abcdef\r\n\
   0\r\n\
   some-footer: some-value\r\n\
   another-footer: another-value\r\n\
   \r\n"

let user_agent = Cohttp.Header.user_agent
let basic_res_plus_crlf = basic_res ^ "\r\n\r\n"
let ic_of_buffer buf = Lwt_io.of_bytes ~mode:Lwt_io.input buf
let oc_of_buffer buf = Lwt_io.of_bytes ~mode:Lwt_io.output buf

open Lwt

let pp_diff fmt (a, b) =
  Format.pp_print_string fmt "Expected:";
  Format.pp_print_newline fmt ();
  Format.pp_print_string fmt a;
  Format.pp_print_string fmt "Result:";
  Format.pp_print_newline fmt ();
  Format.pp_print_string fmt b

let p_sexp f x = x |> f |> Sexplib0.Sexp.to_string

module Req_io = Cohttp.Request.Make (Cohttp_lwt_unix.IO)
module Rep_io = Cohttp.Response.Make (Cohttp_lwt_unix.IO)

let basic_req_parse () =
  let module CU = Cohttp_lwt_unix in
  let ic = ic_of_buffer (Lwt_bytes.of_string basic_req) in
  Req_io.read ic >>= function
  | `Ok req ->
      assert_equal (Cohttp.Request.version req) `HTTP_1_1;
      assert_equal (CU.Request.meth req) `GET;
      assert_equal
        ~printer:(fun x -> x)
        "//www.example.com/index.html"
        (Uri.to_string (CU.Request.uri req));
      return ()
  | _ -> assert false

let basic_res_parse res () =
  let open Cohttp in
  let open Cohttp_lwt_unix in
  let ic = ic_of_buffer (Lwt_bytes.of_string res) in
  Rep_io.read ic >>= function
  | `Ok res ->
      (* Parse first line *)
      assert_equal (Response.version res) `HTTP_1_1;
      assert_equal (Response.status res) `OK;
      let headers = Response.headers res in
      assert_equal (Header.get headers "connection") (Some "close");
      assert_equal (Header.get headers "Accept-ranges") (Some "none");
      assert_equal
        (Header.get headers "content-type")
        (Some "text/html; charset=UTF-8");
      return ()
  | _ -> assert false

let req_parse () =
  let open Cohttp_lwt_unix in
  let ic = ic_of_buffer (Lwt_bytes.of_string basic_req) in
  Req_io.read ic >>= function
  | `Ok req ->
      assert_equal `GET (Request.meth req);
      assert_equal "/index.html" (Uri.path (Request.uri req));
      assert_equal `HTTP_1_1 (Request.version req);
      return ()
  | _ -> assert false

let post_data_parse () =
  let open Cohttp in
  let ic = ic_of_buffer (Lwt_bytes.of_string post_data_req) in
  Req_io.read ic >>= function
  | `Ok req ->
      let printer = p_sexp Transfer.sexp_of_chunk in
      let reader = Req_io.make_body_reader req ic in
      Req_io.read_body_chunk reader >>= fun body ->
      assert_equal ~printer
        (Transfer.Final_chunk "home=Cosby&favorite+flavor=flies") body;
      (* A subsequent request for the body will have consumed it, therefore None *)
      Req_io.read_body_chunk reader >>= fun body ->
      assert_equal ~printer Transfer.Done body;
      return ()
  | _ -> assert false

let post_chunked_parse () =
  let open Cohttp in
  let open Cohttp_lwt_unix in
  let ic = ic_of_buffer (Lwt_bytes.of_string post_chunked_req) in
  Req_io.read ic >>= function
  | `Ok req ->
      assert_equal
        (Transfer.string_of_encoding (Request.encoding req))
        "chunked";
      let reader = Req_io.make_body_reader req ic in
      Req_io.read_body_chunk reader >>= fun chunk ->
      assert_equal chunk (Transfer.Chunk "abcdefghijklmnopqrstuvwxyz");
      Req_io.read_body_chunk reader >>= fun chunk ->
      assert_equal chunk (Transfer.Chunk "1234567890abcdef");
      return ()
  | _ -> assert false

let res_content_parse () =
  let open Cohttp in
  let open Cohttp_lwt_unix in
  let ic = ic_of_buffer (Lwt_bytes.of_string basic_res_content) in
  Rep_io.read ic >>= function
  | `Ok res ->
      assert_equal `HTTP_1_1 (Response.version res);
      assert_equal `OK (Response.status res);
      let reader = Rep_io.make_body_reader res ic in
      Rep_io.read_body_chunk reader >>= fun body ->
      assert_equal (Transfer.Final_chunk "home=Cosby&favorite+flavor=flies")
        body;
      return ()
  | _ -> assert false

let res_chunked_parse () =
  let open Cohttp in
  let open Cohttp_lwt_unix in
  let ic = ic_of_buffer (Lwt_bytes.of_string chunked_res) in
  Rep_io.read ic >>= function
  | `Ok res ->
      assert_equal `HTTP_1_1 (Response.version res);
      assert_equal `OK (Response.status res);
      let reader = Rep_io.make_body_reader res ic in
      Rep_io.read_body_chunk reader >>= fun chunk ->
      assert_equal chunk (Transfer.Chunk "abcdefghijklmnopqrstuvwxyz");
      Rep_io.read_body_chunk reader >>= fun chunk ->
      assert_equal chunk (Transfer.Chunk "1234567890abcdef");
      return ()
  | _ -> assert false

(* Extract the substring of the byte buffer that has been written to *)
let get_substring oc buf =
  let len = Int64.to_int (Lwt_io.position oc) in
  let b = Bytes.create len in
  Lwt_bytes.blit_to_bytes buf 0 b 0 len;
  b |> Bytes.to_string

let write_req expected req =
  (* Use the low-level write_header/footer API *)
  let buf = Lwt_bytes.create 4096 in
  let oc = oc_of_buffer buf in
  let body = Cohttp_lwt.Body.of_string "foobar" in
  Req_io.write
    (fun writer -> Cohttp_lwt.Body.write_body (Req_io.write_body writer) body)
    req oc
  >>= fun () ->
  assert_equal ~pp_diff expected (get_substring oc buf);
  (* Use the high-level write API. This also tests that req is immutable
   * by re-using it *)
  let buf = Lwt_bytes.create 4096 in
  let oc = oc_of_buffer buf in
  Req_io.write (fun writer -> Req_io.write_body writer "foobar") req oc
  >|= fun () -> assert_equal expected (get_substring oc buf)

let make_simple_req () =
  let open Cohttp in
  let open Cohttp_lwt_unix in
  let expected =
    "POST /foo/bar HTTP/1.1\r\nFoo: bar\r\nhost: localhost\r\nuser-agent: "
    ^ user_agent
    ^ "\r\ntransfer-encoding: chunked\r\n\r\n6\r\nfoobar\r\n0\r\n\r\n"
  in
  let req =
    Request.make ~encoding:Transfer.Chunked ~meth:`POST
      ~headers:(Header.init_with "Foo" "bar")
      (Uri.of_string "/foo/bar")
  in
  write_req expected req

let mutate_simple_req () =
  let open Cohttp in
  let open Cohttp_lwt_unix in
  let expected =
    "POST /foo/bar HTTP/1.1\r\nfoo: bar\r\nhost: localhost\r\nuser-agent: "
    ^ user_agent
    ^ "\r\ntransfer-encoding: chunked\r\n\r\n6\r\nfoobar\r\n0\r\n\r\n"
  in
  let req =
    Request.make ~encoding:Transfer.Chunked
      ~headers:(Header.init_with "foo" "bar")
      (Uri.of_string "/foo/bar")
  in
  let req = { req with Request.meth = `POST } in
  write_req expected req

let make_simple_res () =
  let open Cohttp in
  let open Cohttp_lwt_unix in
  let expected =
    "HTTP/1.1 200 OK\r\n\
     foo: bar\r\n\
     transfer-encoding: chunked\r\n\
     \r\n\
     6\r\n\
     foobar\r\n\
     0\r\n\
     \r\n"
  in
  (* Use the low-level write_header/footer API *)
  let buf = Lwt_bytes.create 4096 in
  let oc = oc_of_buffer buf in
  let res = Response.make ~headers:(Header.of_list [ ("foo", "bar") ]) () in
  let body = Cohttp_lwt.Body.of_string "foobar" in
  Rep_io.write
    (fun writer -> Cohttp_lwt.Body.write_body (Rep_io.write_body writer) body)
    res oc
  >>= fun () ->
  assert_equal expected (get_substring oc buf);
  (* Use the high-level write API. This also tests that req is immutable
   * by re-using it *)
  let buf = Lwt_bytes.create 4096 in
  let oc = oc_of_buffer buf in
  Rep_io.write (fun writer -> Rep_io.write_body writer "foobar") res oc
  >>= fun () ->
  assert_equal expected (get_substring oc buf);
  return ()

let test_cases =
  let tests =
    [
      ("basic_req_parse", basic_req_parse);
      ("req_parse", req_parse);
      ("post_data_parse", post_data_parse);
      ("post_chunked_parse", post_chunked_parse);
      ("basic_res_parse 1", basic_res_parse basic_res);
      ("basic_res_parse 2", basic_res_parse basic_res_plus_crlf);
      ("res_content_parse", res_content_parse);
      ("make_simple_req", make_simple_req);
      ("mutate_simple_req", mutate_simple_req);
      ("make_simple_res", make_simple_res);
    ]
  in
  List.map (fun (n, x) -> n >:: fun () -> Lwt_main.run (x ())) tests

(* Returns true if the result list contains successes only.
   Copied from oUnit source as it isnt exposed by the mli *)
let rec was_successful = function
  | [] -> true
  | RSuccess _ :: t | RSkip _ :: t -> was_successful t
  | RFailure _ :: _ | RError _ :: _ | RTodo _ :: _ -> false

let _ =
  let suite = "Parser" >::: test_cases in
  let verbose = ref false in
  let set_verbose _ = verbose := true in
  Arg.parse
    [ ("-verbose", Arg.Unit set_verbose, "Run the test in verbose mode.") ]
    (fun x -> raise (Arg.Bad ("Bad argument : " ^ x)))
    ("Usage: " ^ Sys.argv.(0) ^ " [-verbose]");
  if not (was_successful (run_test_tt ~verbose:!verbose suite)) then exit 1
