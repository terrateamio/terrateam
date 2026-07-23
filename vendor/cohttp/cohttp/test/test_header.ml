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
 *}}}*)

module String_io = Cohttp__String_io
module StringResponse = Cohttp.Response.Make (String_io.M)
module H = Cohttp.Header

let aes = Alcotest.check Alcotest.string
let aeso = Alcotest.check Alcotest.(option string)

let t_credentials =
  Alcotest.testable
    (fun fmt c ->
      let sexp = Cohttp.Auth.sexp_of_credential c in
      Sexplib0.Sexp.pp_hum fmt sexp)
    ( = )

let valid_auth () =
  let auth = `Basic ("Aladdin", "open sesame") in
  let h = H.add_authorization (H.init ()) auth in
  let digest = H.get h "authorization" in
  aeso "valid_auth 1" digest (Some "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==");
  Alcotest.check
    (Alcotest.option t_credentials)
    "valid_auth 2" (H.get_authorization h) (Some auth)

let valid_set_cookie () =
  let c =
    Cohttp.Cookie.Set_cookie_hdr.make ~expiration:`Session ~path:"/foo/bar"
      ~domain:"ocaml.org" ~secure:true ~http_only:true ("key", "value")
  in
  let k, v = Cohttp.Cookie.Set_cookie_hdr.serialize ~version:`HTTP_1_0 c in
  aes "header key" "Set-Cookie" k;
  aes "header value"
    "key=value; domain=ocaml.org; path=/foo/bar; secure; httponly" v;
  let c =
    Cohttp.Cookie.Set_cookie_hdr.make ~expiration:(`Max_age 100L)
      ~path:"/foo/bar" ~domain:"ocaml.org" ("key", "value")
  in
  let k, v = Cohttp.Cookie.Set_cookie_hdr.serialize ~version:`HTTP_1_0 c in
  aes "header key2" "Set-Cookie" k;
  aes "header value2" "key=value; Max-Age=100; domain=ocaml.org; path=/foo/bar"
    v;
  let k, v = Cohttp.Cookie.Set_cookie_hdr.serialize ~version:`HTTP_1_1 c in
  aes "header key 1.1" "Set-Cookie2" k;
  aes "header value 1.1"
    "Domain=ocaml.org; Max-Age=100; Path=/foo/bar; Version=1" v

let cookie_printer x =
  String.concat "; " (List.map (fun (x, y) -> x ^ ":" ^ y) x)

let t_cookies = Alcotest.(list (pair string string))

let cookie_with_eq_val () =
  let cookies = [ ("test", "me=") ] in
  let k, v = Cohttp.Cookie.Cookie_hdr.serialize cookies in
  let h = Cohttp.Header.of_list [ (k, v) ] in
  let cookies = Cohttp.Cookie.Cookie_hdr.extract h in
  Alcotest.check t_cookies "cookie_with_eq_val" cookies [ ("test", "me=") ]

let ignores_empty_cookie () =
  let cookies = [ ("foo", "bar") ] in
  let k, v = Cohttp.Cookie.Cookie_hdr.serialize cookies in
  (* prepend an invalid empty component *)
  let v = "; " ^ v in
  let h = Cohttp.Header.of_list [ (k, v) ] in
  let cookies = Cohttp.Cookie.Cookie_hdr.extract h in
  Alcotest.check t_cookies "cookie" cookies [ ("foo", "bar") ]

let valid_cookie () =
  let cookies = [ ("foo", "bar"); ("a", "b") ] in
  let k, v = Cohttp.Cookie.Cookie_hdr.serialize cookies in
  aes "key" "cookie" k;
  aes "value" "foo=bar; a=b" v;
  let h = Cohttp.Header.of_list [ (k, v) ] in
  let cookies = Cohttp.Cookie.Cookie_hdr.extract h in
  Alcotest.check t_cookies "headers" [ ("foo", "bar"); ("a", "b") ] cookies

let opt_printer f = function
  | None -> "nothing"
  | Some x -> Printf.sprintf "'%s'" (f x)

let get_media_type () =
  let mt = " foo/bar ; charset=UTF-8" in
  let header = Cohttp.Header.init_with "content-type" mt in
  Alcotest.check
    Alcotest.(option string)
    "media type" (Some "foo/bar")
    (Cohttp.Header.get_media_type header)

module Content_range = struct
  let h1 = H.of_list [ ("Content-Length", "123") ]
  let h2 = H.of_list [ ("Content-Range", "bytes 200-300/1000") ]
  let aeio = Alcotest.(check (option int64))
  let none () = aeio "none" None (H.init () |> H.get_content_range)

  let content_length () =
    aeio "content_length" (Some 123L) (H.get_content_range h1)

  let content_range () =
    aeio "content_range" (Some 101L) (H.get_content_range h2)
end

module Link = Cohttp.Link

let t_links =
  Alcotest.testable
    (fun fmt links ->
      Format.pp_print_list ~pp_sep:Format.pp_print_newline
        (fun fmt l -> Format.fprintf fmt "%s" (Link.to_string l))
        fmt links)
    ( = )

let headers_of_response test_name response_string =
  String_io.M.(
    StringResponse.read (String_io.open_in response_string) >>= function
    | `Ok resp -> Cohttp.Response.headers resp
    | _ -> failwith (test_name ^ " response parse failed"))

let get_resp lines =
  "HTTP/1.1 200 OK\r\n" ^ String.concat "\r\n" lines ^ "\r\n\r\n"

let empty_uri = Uri.of_string ""

let link_simple () =
  let next_tgt = "/page/2" in
  let resp = get_resp [ "Link: <" ^ next_tgt ^ ">; rel=next" ] in
  let headers = headers_of_response "link_simple" resp in
  Alcotest.check t_links "link_simple"
    Link.
      [
        {
          context = empty_uri;
          arc = Arc.{ empty with relation = Rel.[ next ] };
          target = Uri.of_string next_tgt;
        };
      ]
    (H.get_links headers)

let link_multi_rel () =
  let next_tgt = "/page/2" in
  let resp = get_resp [ "Link: <" ^ next_tgt ^ ">; rel=\"next last\"" ] in
  let headers = headers_of_response "link_multi_rel" resp in
  Alcotest.check t_links "link_multi_rel"
    Link.
      [
        {
          context = empty_uri;
          arc = Arc.{ empty with relation = Rel.[ next; last ] };
          target = Uri.of_string next_tgt;
        };
      ]
    (H.get_links headers)

let link_multi_line () =
  let self_tgt = "/page/1" in
  let next_tgt = "/page/2" in
  let resp =
    get_resp
      [
        "Link: <" ^ next_tgt ^ ">; rel=\"next\"";
        "Link: <" ^ self_tgt ^ ">; rel=self";
      ]
  in
  let headers = headers_of_response "link_multi_line" resp in
  Alcotest.check t_links "link_multi_line"
    Link.
      [
        {
          context = empty_uri;
          arc = Arc.{ empty with relation = Rel.[ next ] };
          target = Uri.of_string next_tgt;
        };
        {
          context = empty_uri;
          arc = Arc.{ empty with relation = Rel.[ self ] };
          target = Uri.of_string self_tgt;
        };
      ]
    (H.get_links headers)

let link_multi_multi () =
  let next_tgt = "/page/2" in
  let last_tgt = "/page/3" in
  let resp =
    get_resp
      [ "Link: <" ^ next_tgt ^ ">; rel=\"next\", <" ^ last_tgt ^ ">; rel=last" ]
  in
  let headers = headers_of_response "link_multi_multi" resp in
  Alcotest.check t_links "link_multi_multi"
    Link.
      [
        {
          context = empty_uri;
          arc = Arc.{ empty with relation = Rel.[ next ] };
          target = Uri.of_string next_tgt;
        };
        {
          context = empty_uri;
          arc = Arc.{ empty with relation = Rel.[ last ] };
          target = Uri.of_string last_tgt;
        };
      ]
    (H.get_links headers)

let link_rel_uri () =
  let uri_tgt = "/page/2" in
  let uri_s = "http://example.com/a,valid;uri" in
  let resp =
    get_resp
      [ "Link: <" ^ uri_tgt ^ ">; rel=\"next " ^ uri_s ^ "\"; hreflang=en" ]
  in
  let headers = headers_of_response "link_rel_uri" resp in
  Alcotest.check t_links "link_rel_uri"
    Link.
      [
        {
          context = empty_uri;
          arc =
            Arc.
              {
                empty with
                relation = Rel.[ next; extension (Uri.of_string uri_s) ];
                hreflang = Some "en";
              };
          target = Uri.of_string uri_tgt;
        };
      ]
    (H.get_links headers)

let link_anchor () =
  let anchor = "/page/2" in
  let target = "/page/1" in
  let resp =
    get_resp [ "Link: <" ^ target ^ ">; anchor=\"" ^ anchor ^ "\"; rel=prev" ]
  in
  let headers = headers_of_response "link_rel_uri" resp in
  Alcotest.check t_links "link_anchor"
    Link.
      [
        {
          context = Uri.of_string anchor;
          arc = Arc.{ empty with relation = Rel.[ prev ] };
          target = Uri.of_string target;
        };
      ]
    (H.get_links headers)

let link_rev () =
  let anchor = "/page/2" in
  let resp = get_resp [ "Link: <" ^ anchor ^ ">; rev=prev" ] in
  let headers = headers_of_response "link_rev" resp in
  Alcotest.check t_links "link_multi_line"
    Link.
      [
        {
          context = Uri.of_string anchor;
          arc = Arc.{ empty with reverse = true; relation = Rel.[ prev ] };
          target = empty_uri;
        };
      ]
    (H.get_links headers)

let link_media () =
  let target = "/page/2" in
  let resp = get_resp [ "Link: <" ^ target ^ ">; media=screen" ] in
  let headers = headers_of_response "link_media" resp in
  Alcotest.check t_links "link_media"
    Link.
      [
        {
          context = empty_uri;
          arc = Arc.{ empty with media = Some "screen" };
          target = Uri.of_string target;
        };
      ]
    (H.get_links headers)

let link_media_complex () =
  let target = "/page/2" in
  let resp =
    get_resp [ "Link: <" ^ target ^ ">; media=\"screen, print and dpi < 200\"" ]
  in
  let headers = headers_of_response "link_media_complex" resp in
  Alcotest.check t_links "t_links"
    Link.
      [
        {
          context = empty_uri;
          arc = Arc.{ empty with media = Some "screen, print and dpi < 200" };
          target = Uri.of_string target;
        };
      ]
    (H.get_links headers)

let link_title () =
  let target = "/page/2" in
  let resp = get_resp [ "Link: <" ^ target ^ ">; title=\"Next!\"; rel=next" ] in
  let headers = headers_of_response "link_title" resp in
  Alcotest.check t_links "link_title"
    Link.
      [
        {
          context = empty_uri;
          arc = Arc.{ empty with relation = Rel.[ next ]; title = Some "Next!" };
          target = Uri.of_string target;
        };
      ]
    (H.get_links headers)

let link_title_star () =
  let target = "/page/2" in
  let resp =
    get_resp [ "Link: <" ^ target ^ ">; title*=UTF-8'en'Next!; rel=next" ]
  in
  let headers = headers_of_response "link_title_star" resp in
  Alcotest.check t_links "link_title_star"
    Link.
      [
        {
          context = empty_uri;
          arc =
            Arc.
              {
                empty with
                relation = Rel.[ next ];
                title_ext =
                  Some
                    (Ext.make
                       ~charset:(Charset.of_string "UTF-8")
                       ~language:(Language.of_string "en") "Next!");
              };
          target = Uri.of_string target;
        };
      ]
    (H.get_links headers)

let link_type_token () =
  let target = "/page/2" in
  let resp = get_resp [ "Link: <" ^ target ^ ">; type=text/html; rel=next" ] in
  let headers = headers_of_response "link_type_token" resp in
  Alcotest.check t_links "link_type_token"
    Link.
      [
        {
          context = empty_uri;
          arc =
            Arc.
              {
                empty with
                relation = Rel.[ next ];
                media_type = Some ("text", "html");
              };
          target = Uri.of_string target;
        };
      ]
    (H.get_links headers)

let link_type_quoted () =
  let target = "/page/2" in
  let resp =
    get_resp [ "Link: <" ^ target ^ ">; type=\"text/html\"; rel=next" ]
  in
  let headers = headers_of_response "link_type_quoted" resp in
  Alcotest.check t_links "link_type_quoted"
    Link.
      [
        {
          context = empty_uri;
          arc =
            Arc.
              {
                empty with
                relation = Rel.[ next ];
                media_type = Some ("text", "html");
              };
          target = Uri.of_string target;
        };
      ]
    (H.get_links headers)

let link_ext () =
  let target = "/page/2" in
  let resp = get_resp [ "Link: <" ^ target ^ ">; see=saw; rel=next" ] in
  let headers = headers_of_response "link_ext" resp in
  Alcotest.check t_links "link_ext"
    Link.
      [
        {
          context = empty_uri;
          arc =
            Arc.
              {
                empty with
                relation = Rel.[ next ];
                extensions = [ ("see", "saw") ];
              };
          target = Uri.of_string target;
        };
      ]
    (H.get_links headers)

let link_ext_star () =
  let target = "/page/2" in
  let resp = get_resp [ "Link: <" ^ target ^ ">; zig*=''zag; rel=next" ] in
  let headers = headers_of_response "link_ext" resp in
  Alcotest.check t_links "link_ext_star"
    Link.
      [
        {
          context = empty_uri;
          arc =
            Arc.
              {
                empty with
                relation = Rel.[ next ];
                extension_exts =
                  [
                    ( "zig",
                      Ext.make ~charset:(Charset.of_string "")
                        ~language:(Language.of_string "") "zag" );
                  ];
              };
          target = Uri.of_string target;
        };
      ]
    (H.get_links headers)

let trim_ws () =
  let resp = get_resp [ "Age: 281   " ] in
  let headers = headers_of_response "trim whitespace" resp in
  aeso "trim_ws" (H.get headers "age") (Some "281")

let test_cachecontrol_concat () =
  let resp =
    get_resp [ "Cache-Control: public"; "Cache-Control: max-age:86400" ]
  in
  let h = headers_of_response "concat Cache-Control" resp in
  aeso "test_cachecontrol_concat" (Some "public,max-age:86400")
    (H.get_multi_concat h "Cache-Control")

let () = Printexc.record_backtrace true

let () =
  Alcotest.run "test_header"
    [
      ( "Link",
        [
          ("simple", `Quick, link_simple);
          ("multiple rels", `Quick, link_multi_rel);
          ("multiple lines", `Quick, link_multi_line);
          ("multiheader", `Quick, link_multi_multi);
          ("rel uri", `Quick, link_rel_uri);
          ("anchor", `Quick, link_anchor);
          ("rev", `Quick, link_rev);
          ("media", `Quick, link_media);
          ("media complex", `Quick, link_media_complex);
          ("title", `Quick, link_title);
          ("title star", `Quick, link_title_star);
          ("type token", `Quick, link_type_token);
          ("type quoted", `Quick, link_type_quoted);
          ("extension", `Quick, link_ext);
          ("extension star", `Quick, link_ext_star);
        ] );
      ("Media Type", [ ("Media Type", `Quick, get_media_type) ]);
      ("Auth", [ ("Valid Auth", `Quick, valid_auth) ]);
      ( "Cookie",
        [
          ("Valid Set-Cookie", `Quick, valid_set_cookie);
          ("Valid Cookie", `Quick, valid_cookie);
          ("Cookie with =", `Quick, cookie_with_eq_val);
          ("Ignores empty cookie", `Quick, ignores_empty_cookie);
        ] );
      ( "Content Range",
        [
          ("none", `Quick, Content_range.none);
          ("content-length", `Quick, Content_range.content_length);
          ("content-range", `Quick, Content_range.content_range);
        ] );
      ("Cache Control", [ ("concat", `Quick, test_cachecontrol_concat) ]);
      Unitary_test_header.tests;
    ]
