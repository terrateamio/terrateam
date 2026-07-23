open Cohttp
module String_io = Cohttp__String_io
module StringRequest = Request.Make (String_io.M)

let uri_userinfo = Uri.of_string "http://foo:bar%2525@ocaml.org"

let header_auth =
  let h = Header.init () in
  let h = Header.add_authorization h (`Basic ("qux", "qwerty")) in
  h

let is_some = function None -> false | Some _ -> true

let header_has_auth _ =
  Alcotest.check Alcotest.bool "Test header has auth"
    (header_auth |> Header.get_authorization |> is_some)
    true

let uri_has_userinfo _ =
  Alcotest.check Alcotest.bool "Uri has user info"
    (uri_userinfo |> Uri.userinfo |> is_some)
    true

let t_credentials =
  Alcotest.testable
    (fun fmt c ->
      let sexp = Cohttp.Auth.sexp_of_credential c in
      Sexplib0.Sexp.pp_hum fmt sexp)
    ( = )

let auth_uri_no_override _ =
  let r = Request.make ~headers:header_auth uri_userinfo in
  Alcotest.check
    (Alcotest.option t_credentials)
    "auth uri no override"
    (r |> Request.headers |> Header.get_authorization)
    (Header.get_authorization header_auth)

let auth_uri _ =
  let r = Request.make uri_userinfo in
  Alcotest.check
    (Alcotest.option t_credentials)
    "auth_uri"
    (r |> Request.headers |> Header.get_authorization)
    (Some (`Basic ("foo", "bar%25")))

let t_encoding =
  Alcotest.testable
    (fun fmt e ->
      let sexp = Cohttp.Transfer.sexp_of_encoding e in
      Sexplib0.Sexp.pp fmt sexp)
    ( = )

let encoding_content_length_header () =
  let r =
    Request.make
      ~headers:(Cohttp.Header.of_list [ ("content-length", "100") ])
      (Uri.of_string "http://someuri.com")
  in
  Alcotest.check t_encoding "body encoding determined by content-length header"
    (r |> Request.encoding) (Fixed 100L)

let encoding_transfer_encoding_header () =
  let r =
    Request.make
      ~headers:(Cohttp.Header.of_list [ ("transfer-encoding", "chunked") ])
      (Uri.of_string "http://someuri.com")
  in
  Alcotest.check t_encoding
    "body encoding determined by transfer-encoding header"
    (r |> Request.encoding) Chunked

let encoding_both_headers () =
  let r =
    Request.make
      ~headers:
        (Cohttp.Header.of_list
           [ ("transfer-encoding", "chunked"); ("content-length", "100") ])
      (Uri.of_string "http://someuri.com")
  in
  Alcotest.check t_encoding
    "body encoding with content-length and transfer-encoding headers."
    (r |> Request.encoding) Chunked

let encoding_header_opt_argument () =
  let r =
    Request.make ~encoding:Chunked
      ~headers:(Cohttp.Header.of_list [ ("content-length", "100") ])
      (Uri.of_string "http://someuri.com")
  in
  Alcotest.check t_encoding
    "body encoding with content-length and transfer-encoding headers."
    (r |> Request.encoding) (Fixed 100L)

let opt_default default = function None -> default | Some v -> v

module Parse_result = struct
  type 'a t = [ `Ok of 'a | `Invalid of string | `Eof ]

  let map t ~f =
    match t with `Ok x -> `Ok (f x) | (`Invalid _ | `Eof) as e -> e
end

let uri_testable : Uri.t Alcotest.testable =
  Alcotest.testable Uri.pp_hum Uri.equal

let t_parse_result_uri : Uri.t Parse_result.t Alcotest.testable =
  Alcotest.testable
    (fun fmt -> function
      | `Invalid s -> Format.fprintf fmt "`Invalid %s" s
      | `Eof -> Format.fprintf fmt "`Eof"
      | `Ok u -> Uri.pp_hum fmt u)
    (fun x y ->
      match (x, y) with `Ok x, `Ok y -> Uri.equal x y | x, y -> x = y)

let parse_request_uri_ r (expected : Uri.t Parse_result.t) name =
  String_io.M.(
    StringRequest.read (String_io.open_in r)
    >>= fun (result : Cohttp.Request.t Parse_result.t) ->
    let uri = Parse_result.map result ~f:Request.uri in
    return @@ Alcotest.check t_parse_result_uri name uri expected)

let bad_request = `Invalid "bad request URI"

let parse_request_uri _ =
  let r = "GET / HTTP/1.1\r\n\r\n" in
  let uri = `Ok (Uri.of_string "/") in
  parse_request_uri_ r uri "parse_request_uri"

let parse_request_uri_host _ =
  let r = "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n" in
  let uri = `Ok (Uri.of_string "//example.com/") in
  parse_request_uri_ r uri "parse_request_uri_host"

let parse_request_uri_host_port _ =
  let r = "GET / HTTP/1.1\r\nHost: example.com:8080\r\n\r\n" in
  let uri = `Ok (Uri.of_string "//example.com:8080/") in
  parse_request_uri_ r uri "parse_request_uri_host_port"

let parse_request_uri_double_slash _ =
  let r = "GET // HTTP/1.1\r\n\r\n" in
  let uri = `Ok (Uri.with_path (Uri.of_string "") "//") in
  parse_request_uri_ r uri "parse_request_uri_double_slash"

let parse_request_uri_host_double_slash _ =
  let r = "GET // HTTP/1.1\r\nHost: example.com\r\n\r\n" in
  let uri = `Ok (Uri.of_string "//example.com//") in
  parse_request_uri_ r uri "parse_request_uri_host_double_slash"

let parse_request_uri_triple_slash _ =
  let r = "GET /// HTTP/1.1\r\n\r\n" in
  let uri = `Ok (Uri.with_path (Uri.of_string "") "///") in
  parse_request_uri_ r uri "parse_request_uri_triple_slash"

let parse_request_uri_host_triple_slash _ =
  let r = "GET /// HTTP/1.1\r\nHost: example.com\r\n\r\n" in
  let uri = `Ok (Uri.of_string "//example.com///") in
  parse_request_uri_ r uri "parse_request_uri_host_triple_slash"

let parse_request_uri_no_slash _ =
  let r = "GET foo HTTP/1.1\r\n\r\n" in
  parse_request_uri_ r bad_request "parse_request_uri_no_slash"

let parse_request_uri_host_no_slash _ =
  let r = "GET foo HTTP/1.1\r\nHost: example.com\r\n\r\n" in
  parse_request_uri_ r bad_request "parse_request_uri_host_no_slash"

let parse_request_uri_empty _ =
  let r = "GET  HTTP/1.1\r\n\r\n" in
  let uri = `Ok (Uri.of_string "/") in
  parse_request_uri_ r uri "parse_request_uri_empty"

let parse_request_uri_host_empty _ =
  let r = "GET  HTTP/1.1\r\nHost: example.com\r\n\r\n" in
  let uri = `Ok (Uri.of_string "//example.com/") in
  parse_request_uri_ r uri "parse_request_uri_host_empty"

let parse_request_uri_path_like_scheme _ =
  let r = "GET http://example.net HTTP/1.1\r\n\r\n" in
  let uri = `Ok (Uri.of_string "http://example.net/") in
  parse_request_uri_ r uri "parse_request_uri_path_like_scheme"

let parse_request_uri_host_path_like_scheme _ =
  let r = "GET http://example.net HTTP/1.1\r\nHost: example.com\r\n\r\n" in
  let uri = `Ok (Uri.of_string "http://example.net/") in
  parse_request_uri_ r uri "parse_request_uri_host_path_like_scheme"

let parse_request_uri_path_like_host_port _ =
  let path = "//example.net:8080" in
  let r = "GET " ^ path ^ " HTTP/1.1\r\n\r\n" in
  let uri = `Ok (Uri.with_path (Uri.of_string "") path) in
  parse_request_uri_ r uri "parse_request_uri_path_like_host_port"

let parse_request_uri_host_path_like_host_port _ =
  let path = "//example.net:8080" in
  let r = "GET " ^ path ^ " HTTP/1.1\r\nHost: example.com\r\n\r\n" in
  let uri = `Ok (Uri.with_path (Uri.of_string "//example.com") path) in
  parse_request_uri_ r uri "parse_request_uri_host_path_like_host_port"

let parse_request_uri_query _ =
  let pqs = "/?foo" in
  let r = "GET " ^ pqs ^ " HTTP/1.1\r\n\r\n" in
  let uri = `Ok (Uri.of_string pqs) in
  parse_request_uri_ r uri "parse_request_uri_query"

let parse_request_uri_host_query _ =
  let pqs = "/?foo" in
  let r = "GET " ^ pqs ^ " HTTP/1.1\r\nHost: example.com\r\n\r\n" in
  let uri = `Ok (Uri.of_string ("//example.com" ^ pqs)) in
  parse_request_uri_ r uri "parse_request_uri_host_query"

let parse_request_uri_query_no_slash _ =
  let r = "GET ?foo HTTP/1.1\r\n\r\n" in
  parse_request_uri_ r bad_request "parse_request_uri_query_no_slash"

let parse_request_uri_host_query_no_slash _ =
  let r = "GET ?foo HTTP/1.1\r\nHost: example.com\r\n\r\n" in
  parse_request_uri_ r bad_request "parse_request_uri_host_query_no_slash"

let parse_request_connect _ =
  let r = "CONNECT vpn.example.net:443 HTTP/1.1\r\n" in
  let uri = `Ok (Uri.of_string "//vpn.example.net:443") in
  parse_request_uri_ r uri "parse_request_connect"

let parse_request_connect_host _ =
  let r =
    "CONNECT vpn.example.net:443 HTTP/1.1\r\nHost: vpn.example.com:443\r\n\r\n"
  in
  let uri = `Ok (Uri.of_string "//vpn.example.net:443") in
  parse_request_uri_ r uri "parse_request_connect_host"

let parse_request_options _ =
  let r = "OPTIONS * HTTP/1.1\r\n\r\n" in
  let uri = `Ok (Uri.of_string "") in
  parse_request_uri_ r uri "parse_request_options"

let parse_request_options_host _ =
  let r = "OPTIONS * HTTP/1.1\r\nHost: example.com:443\r\n\r\n" in
  let uri = `Ok (Uri.of_string "//example.com:443") in
  parse_request_uri_ r uri "parse_request_options_host"

let parse_request_uri_traversal _ =
  let r = "GET /../../../../etc/shadow HTTP/1.1\r\n\r\n" in
  let uri = `Ok (Uri.of_string "/etc/shadow") in
  parse_request_uri_ r uri "parse_request_uri_traversal"

let parse_request_uri_host_traversal _ =
  let r = "GET /../../../../etc/shadow HTTP/1.1\r\nHost: example.com\r\n\r\n" in
  let uri = `Ok (Uri.of_string "//example.com/etc/shadow") in
  parse_request_uri_ r uri "parse_request_uri_host_traversal"

let uri_round_trip _ =
  let expected_uri = Uri.of_string "https://www.example.com/test" in
  let actual_uri = Request.make expected_uri |> Request.uri in
  Alcotest.check uri_testable "Request.make uri round-trip" actual_uri
    expected_uri

let () = Printexc.record_backtrace true

let () =
  Alcotest.run "test_request"
    [
      ( "Auth",
        [
          ("header has auth", `Quick, header_has_auth);
          ("URI has user info", `Quick, uri_has_userinfo);
          ("from URI - do not override", `Quick, auth_uri_no_override);
          ("from URI", `Quick, auth_uri);
        ] );
      ( "Encoding",
        [
          ("from content-length header", `Quick, encoding_content_length_header);
          ( "from transfer-encoding header",
            `Quick,
            encoding_transfer_encoding_header );
          ("with both headers", `Quick, encoding_both_headers);
          ( "from both optional argument and headers",
            `Quick,
            encoding_header_opt_argument );
        ] );
      ( "Parse URI",
        [
          ("simple", `Quick, parse_request_uri);
          ("with host", `Quick, parse_request_uri_host);
          ("with host and port", `Quick, parse_request_uri_host_port);
          ("double slash", `Quick, parse_request_uri_double_slash);
          ("double slash with host", `Quick, parse_request_uri_host_double_slash);
          ("triple slash", `Quick, parse_request_uri_triple_slash);
          ("triple slash with host", `Quick, parse_request_uri_host_triple_slash);
          ("no slash", `Quick, parse_request_uri_no_slash);
          ("no slash with host", `Quick, parse_request_uri_host_no_slash);
          ("empty", `Quick, parse_request_uri_empty);
          ("empty with host", `Quick, parse_request_uri_host_empty);
          ("path like scheme", `Quick, parse_request_uri_path_like_scheme);
          ( "path like scheme with host",
            `Quick,
            parse_request_uri_host_path_like_scheme );
          ("path like host:port", `Quick, parse_request_uri_path_like_host_port);
          ( "path like host:port with host",
            `Quick,
            parse_request_uri_host_path_like_host_port );
          ("with query string", `Quick, parse_request_uri_query);
          ("with query with host", `Quick, parse_request_uri_host_query);
          ( "no slash with query string",
            `Quick,
            parse_request_uri_query_no_slash );
          ( "no slash with query with host",
            `Quick,
            parse_request_uri_host_query_no_slash );
          ("CONNECT", `Quick, parse_request_connect);
          ("CONNECT with host", `Quick, parse_request_connect_host);
          ("OPTIONS", `Quick, parse_request_options);
          ("OPTIONS with host", `Quick, parse_request_options_host);
          ("parent traversal", `Quick, parse_request_uri_traversal);
          ( "parent traversal with host",
            `Quick,
            parse_request_uri_host_traversal );
          ("uri round-trip", `Quick, uri_round_trip);
        ] );
    ]
