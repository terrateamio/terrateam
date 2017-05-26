(*
 * Copyright (c) 2012-2014 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2012-2014 David Sheets <sheets@alum.mit.edu>
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
 *)

open OUnit
open Printf

(* Tuples of decoded and encoded strings. The first element is a number to
   refer to the test, as the pcts_large version duplicates the second field
   to a large size, so it cant be used as the name of the test *)
let pcts = [
  (1, "hello world!", "hello%20world!");
  (2, "[", "%5B");
  (3, "[[[[[", "%5B%5B%5B%5B%5B");
  (4, "1]", "1%5D");
  (5, "%20", "%2520");
  (6, "", "");
  (7, "f", "f");
  (8, "\001", "%01");
  (9, "\n", "%0A");
]

(* Make an artificially large string version of the pct strings *)
let pcts_large =
  List.map (fun (n,a,b) ->
    let num = 100000 in
    let a' = Buffer.create (String.length a * num) in
    let b' = Buffer.create (String.length b * num) in
    for i = 1 to num do
      Buffer.add_string a' a;
      Buffer.add_string b' b;
    done;
    (n, Buffer.contents a', Buffer.contents b')
  ) pcts

(* Tuple of string URI and the decoded version *)
let uri_encodes = [
  "https://user:pass@foo.com:123/wh/at/ever?foo=1&bar=5#5",
   (Uri.make ~scheme:"https" ~userinfo:"user:pass" ~host:"foo.com"
      ~port:123 ~path:"/wh/at/ever" ~query:["foo",["1"];"bar",["5"]] ~fragment:"5" ());
  "http://foo.com", (Uri.make ~scheme:"http" ~host:"foo.com" ());
  "http://foo-bar.com", (Uri.make ~scheme:"http" ~host:"foo-bar.com" ());
  "http://foo-bar.com:8080/h1", (Uri.make ~scheme:"http" ~host:"foo-bar.com" ~port:8080 ~path:"/h1" ());
  "http://foo%21.com", (Uri.make ~scheme:"http" ~host:"foo!.com" ());
  "/wh/at/ev/er", (Uri.make ~path:"/wh/at/ev/er" ());
  "/wh/at!/ev%20/er", (Uri.make ~path:"/wh/at!/ev /er" ());
  (* IPv6 literal *)
  "http://%5Bdead%3Abeef%3A%3Adead%3A0%3Abeaf%5D",
    (Uri.make ~scheme:"http" ~host:"[dead:beef::dead:0:beaf]" ());
  "http://user:pass@%5B2001%3A41d1%3Afe67%3A500%3A227%3Ac6ff%3Afe5a%3Aefa0%5D:6789/wh/at/ever?foo=1&bar=5#5",
  (Uri.make ~scheme:"http" ~userinfo:"user:pass" ~host:"[2001:41d1:fe67:500:227:c6ff:fe5a:efa0]"
     ~port:6789 ~path:"/wh/at/ever" ~query:["foo",["1"];"bar",["5"]] ~fragment:"5" ());
  (* IPv6 literal with zone id *)
  "http://user:pass@%5B2001%3A41d1%3Afe67%3A500%3A227%3Ac6ff%3Afe5a%3Aefa0%25wlan0%5D:6789/wh/at/ever?foo=1&bar=5#5",
  (Uri.make ~scheme:"http" ~userinfo:"user:pass" ~host:"[2001:41d1:fe67:500:227:c6ff:fe5a:efa0%wlan0]"
     ~port:6789 ~path:"/wh/at/ever" ~query:["foo",["1"];"bar",["5"]] ~fragment:"5" ());
  "foo+bar:", (Uri.make ~scheme:"foo+bar" ());
  "foo+bar:///", (Uri.make ~scheme:"foo+bar" ~host:"" ~path:"/" ());
  "foo2-bar.baz:///", (Uri.make ~scheme:"foo2-bar.baz" ~host:"" ~path:"/" ());
  "//foobar.com/quux", (Uri.make ~host:"foobar.com" ~path:"quux" ());
  "quux%2F%20", (Uri.make ~path:"quux%2f " ());
  "urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
  (Uri.make ~scheme:"urn" ~path:"uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6" ());
]

let map_pcts_tests size name test args =
  List.map (fun (n, a,b) ->
    let name = sprintf "pct_%s:%d:%s" size n a in
    let a1, b1 = test a b in
    let test () = assert_equal ~printer:(fun x -> x) a1 b1 in
    name >:: test
  ) args

let test_pct_small =
  (map_pcts_tests "small" "encode" (fun a b -> b, (Uri.pct_encode a)) pcts) @
  (map_pcts_tests "small" "decode" (fun a b -> (Uri.pct_decode b), a) pcts)

let test_pct_large =
  (map_pcts_tests "large" "encode" (fun a b -> (Uri.pct_encode a), b) pcts_large) @
  (map_pcts_tests "large" "decode" (fun a b -> (Uri.pct_decode b), a) pcts_large)

(* Test that a URL encodes to the expected value *)
let test_uri_encode =
  List.map (fun (uri_str, uri) ->
    let name = sprintf "uri:%s" uri_str in
    let test () = assert_equal ~printer:(fun x -> x) uri_str (Uri.to_string uri) in
    name >:: test
  ) uri_encodes

(* Test that a URI decodes to the expected value *)
let test_uri_decode =
  List.map (fun (uri_str, uri) ->
    let name = sprintf "uribi:%s" uri_str in
    let test () = assert_equal ~printer:(fun x -> x) uri_str (Uri.(to_string (of_string (Uri.to_string uri)))) in
    name >:: test
  ) uri_encodes

(* Test URI query decoding *)
let uri_query = [
  "https://user:pass@foo.com:123/wh/at/ever?foo=1&bar=5#5", ["foo",["1"]; "bar",["5"]];
  "//domain?f+1=bar&+f2=bar%212", ["f 1",["bar"];" f2",["bar!2"]];
  "//domain?foo=&bar=", ["foo",[""];"bar",[""]];
  "//domain?a=b%26c%3Dd", ["a",["b&c=d"]];
  "",[];
  "?",["",[]];
  "?&",["",[];"",[]];
  "?&&",["",[];"",[];"",[]];
  "??&/&",["?",[];"/",[];"",[]];
  "?#?/#",["",[]];
  "?%23",["#",[]];
  "?=&==",["",[""];"",["="]];
  "?==,&=,=",["",["=";""];"",["";"="]];
  "?a=,,%26&,%2C=%2C,",["a",["";"";"&"];",,",[",";""]];
  "?%3D=%3D",["=",["="]];
  "?,",[",",[]];
]

let test_query_decode =
  List.map (fun (uri_str,res) ->
    let uri = Uri.of_string uri_str in
    let test () = assert_equal ~printer:(fun l ->
      String.concat " "
        (List.map
           (fun (k,v) -> sprintf "\"%s\" = \"%s\"" k (String.concat "," v)) l))
      res (Uri.query uri) in
    uri_str >:: test
  ) uri_query

(* Test URI query encoding. No pct encoding as that is done later by Uri.to_string *)
let uri_query_make = [
  [], "";
  ["foo",["bar"]], "foo=bar";
  ["foo1",["bar1"];"foo2",["bar2"]], "foo1=bar1&foo2=bar2";
  ["foo1",["bar1"];"foo2",["bar2"];"foo3",["bar3"]],
  "foo1=bar1&foo2=bar2&foo3=bar3";
  ["semicolon",[";"]],"semicolon=%3B";
  [";",["semicolon"]],"%3B=semicolon";
  ["#",["#";"#"]], "%23=%23,%23";
  ["",[]], "";
  ["",[""]], "=";
  ["",["";""]], "=,";
  ["&",["&"]], "%26=%26";
  ["=",["="]], "%3D==";
  [",",[",";""]], ",=%2C,";
]

let test_query_encode =
  List.map (fun (qs,res) ->
    let test () = assert_equal ~printer:(fun l -> l) res (Uri.encoded_of_query qs) in
    res >:: test
  ) uri_query_make

(* Test relative URI resolution
   from <http://tools.ietf.org/html/rfc3986#section-5.4> *)
let uri_rel_res = [
  (* "normal" *)
  "g:h",     "g:h";
  "g",       "http://a/b/c/g";
  "./g",     "http://a/b/c/g";
  "g/",      "http://a/b/c/g/";
  "/g",      "http://a/g";
  "//g",     "http://g";
  "?y",      "http://a/b/c/d;p?y";
  "g?y",     "http://a/b/c/g?y";
  "#s",      "http://a/b/c/d;p?q#s";
  "g#s",     "http://a/b/c/g#s";
  "g?y#s",   "http://a/b/c/g?y#s";
  ";x",      "http://a/b/c/;x";
  "g;x",     "http://a/b/c/g;x";
  "g;x?y#s", "http://a/b/c/g;x?y#s";
  "",        "http://a/b/c/d;p?q";
  ".",       "http://a/b/c/";
  "./",      "http://a/b/c/";
  "..",      "http://a/b/";
  "../",     "http://a/b/";
  "../g",    "http://a/b/g";
  "../..",   "http://a/";
  "../../",  "http://a/";
  "../../g", "http://a/g";
  (* "abnormal" *)
  "../../../g",    "http://a/g";
  "../../../../g", "http://a/g";
  "/./g",          "http://a/g";
  "/../g",         "http://a/g";
  "g.",            "http://a/b/c/g.";
  ".g",            "http://a/b/c/.g";
  "g..",           "http://a/b/c/g..";
  "..g",           "http://a/b/c/..g";
  "./../g",        "http://a/b/g";
  "./g/.",         "http://a/b/c/g/";
  "g/./h",         "http://a/b/c/g/h";
  "g/../h",        "http://a/b/c/h";
  "g;x=1/./y",     "http://a/b/c/g;x=1/y";
  "g;x=1/../y",    "http://a/b/c/y";
  "g?y/./x",       "http://a/b/c/g?y/./x";
  "g?y/../x",      "http://a/b/c/g?y/../x";
  "g#s/./x",       "http://a/b/c/g#s/./x";
  "g#s/../x",      "http://a/b/c/g#s/../x";
  "http:g",        "http:g";
  (* extra *)
  (* From <http://lists.w3.org/Archives/Public/uri/2014Jun/0000.html> *)
  ".%2E",          "http://a/b/";
]

let test_rel_res =
  let base = Uri.of_string "http://a/b/c/d;p?q" in
  List.map (fun (rel,abs) ->
    let test () = assert_equal ~printer:(fun l -> l)
      abs (Uri.to_string (Uri.resolve "http" base (Uri.of_string rel))) in
    rel >:: test
  ) uri_rel_res

let file_uri_rel_res = [ (* http://tools.ietf.org/html/rfc1738#section-3.10 *)
  "/foo/bar/baz", "/foo/bar/baz";
  "//localhost/foo", "///foo";
]

let test_file_rel_res =
  List.map (fun (rel,abs) ->
    let test () = assert_equal ~printer:(fun l -> l)
      abs (Uri.to_string (Uri.resolve "file" Uri.empty (Uri.of_string rel))) in
    rel >:: test
  ) file_uri_rel_res

let uri_rel_rel_res = [ (* relative-relative resolution *)
  "a", "b", "a";
  "a", "/", "/a";
  "a", "b/", "b/a";
  "a", "//b", "//b/a";
  "a", "//b/","//b/a";
  "a", "///", "///a";
  "?a", "b", "b?a";
  "?a", "/", "/?a";
  "?a", "//b", "//b?a";
  "?a", "///", "///?a";
  "#a", "b", "b#a";
  "#a", "/", "/#a";
  "#a", "//b", "//b#a";
  "#a", "///", "///#a";
  "../a", "b", "../a";
  "../a", "b/", "a";
  "../a", "b/./", "a";
  "../a", "../b", "../../a";
  "../a", "../b/", "../a";
  "../a", "../b/./", "../a";
  "../a", "../b/c/", "../b/a";
  "../a", "../../b", "../../../a";
  "../a", "../b/../", "../../a";
  "../a", "../b/./", "../a";
  "../a/..", "../", "../../";
  "../a/../", "../", "../../";
  "..", "b/c/", "b/";
  "", "b", "b";
  "a", "", "a";
  (* TODO: relative username, ... *)
]

let rel_empty_path_res = [
  "/foo/bar/..", "/foo/";
  "/foo/bar//..", "/foo/bar/";
  "/foo/bar///..", "/foo/bar//";
  "/foo/bar//../baz", "/foo/bar/baz"
]

let test_rel_empty_path_res =
  List.map (fun (rel, res) ->
      let test () = assert_equal ~printer:(fun l -> l)
          res Uri.(to_string (resolve "" empty (of_string rel))) in
      rel >:: test
    ) rel_empty_path_res

let test_rel_rel_res =
  List.map (fun (rel,base,res) ->
    let rel = Uri.of_string rel in
    let base = Uri.of_string base in
    let test () = assert_equal ~printer:(fun l -> l)
      res (Uri.to_string (Uri.resolve "" base rel)) in
    res >:: test
  ) uri_rel_rel_res

let generic_uri_norm = [
  "HTTP://example.com/", "http://example.com/";
  "http://example.com/%3a%3f", "http://example.com/:%3F";
  "http://Example.Com/", "http://example.com/";
  "http://example.com/%68%65%6c%6c%6f", "http://example.com/hello";
  "http://example.com/../", "http://example.com/";
  "http://example.com/./././", "http://example.com/";
  "%", "%25";
  "%3", "%253";
  "%3g", "%253g";
  "%3:", "%253:";
  "%3@", "%253@";
  "%3/", "%253/";
  "%%25", "%25%25";
  "%2%25", "%252%25";
  "/foo%2fbar/", "/foo%2Fbar/";
  "//colon%3Auser:colon%3Apassword@example.net/",
  "//colon%3Auser:colon%3Apassword@example.net/";
  "//colon%3Auser@example.net/",
  "//colon%3Auser@example.net/";
  "foo+bar%3a", "./foo+bar:";
  (let p_q = "/foo%20bar/" in
   p_q, Uri.(path_and_query (of_string p_q)));
]

let test_generic_uri_norm =
  List.map (fun (o,n) ->
    let test () = assert_equal ~printer:(fun l -> l)
      n (Uri.to_string (Uri.resolve "http" Uri.empty (Uri.of_string o))) in
    o >:: test
  ) generic_uri_norm

let rel_id = [
  "a/path/fragment";
  "/an/absolute/path";
  "?a&b&c";
  "?a=&b=&c=";
  "?a=b&b=c&c=a";
  "foo+bar:///";
]

let test_rel_id =
  List.map (fun id ->
    let test () = assert_equal ~printer:(fun l -> l)
      id (Uri.to_string (Uri.of_string id)) in
    id >:: test
  ) rel_id

let default_scheme = "ftp"
let tcp_port_of_uri = [
  "a/relative/path",
  List.hd (Uri_services.tcp_port_of_service default_scheme);
  "https://foo.bar/", 443;
  "ssh://user@host.tld/", 22;
  "http://foo.bar/", 80;
  "http://foo.bar:8000/", 8000;
]

let test_tcp_port_of_uri =
  let string_of_int_option = function None -> "None"
    | Some i -> sprintf "Some %d" i
  in List.map (fun (uri,pn) ->
    let test () = assert_equal ~printer:string_of_int_option
      (Some pn)
      (Uri_services.tcp_port_of_uri ~default:default_scheme
         (Uri.of_string uri))
    in uri >:: test
  ) tcp_port_of_uri

let query_key_add_remove =
  let test () =
  let uri = Uri.of_string "http://foo.com/?k1=1&k2=2" in
  let printer x = Uri.(to_string (with_query uri x)) in
  assert_equal ~printer (Uri.query uri) [("k1",["1"]);("k2",["2"])];
  let uri = Uri.add_query_param uri ("k3",["3"]) in
  assert_equal ~printer (Uri.query uri) [("k3",["3"]);("k1",["1"]);("k2",["2"])];
  assert_equal (Uri.get_query_param' uri "k3") (Some ["3"]);
  assert_equal (Uri.get_query_param uri "k3") (Some "3");
  let uri = Uri.remove_query_param uri "k1" in
  assert_equal ~printer (Uri.query uri) [("k3",["3"]);("k2",["2"])];
  let uri = Uri.remove_query_param uri "k2" in
  let uri = Uri.remove_query_param uri "k3" in
  assert_equal ~printer (Uri.query uri) []
  in ["query_key_add_remove" >:: test]

let test_sexping =
  let tests = [
    "1", "https://example.com/foo?bar=1#frag",
      "((scheme https)(host example.com)(path(/ foo))(query((bar(1))))(fragment frag))";
    "2", "", "((path())(query()))";
    "3", "/?foo=bar", "((path(/))(query((foo(bar)))))"
  ] in
  let test uri exp =
    let uri = Uri.of_string uri in
    let s = Sexplib.Sexp.to_string (Uri.sexp_of_t uri) in
    let msg = sprintf "%s <> %s" s exp in
    assert_equal ~msg s exp
  in
  List.map (fun (id,uri,exp) ->
    ("test_sexping_"^id) >:: (fun () -> test uri exp)
  ) tests

let test_with_change = [
  "test_with_scheme" >:: (fun () ->
    let printer = Uri.to_string in
    let uri = Uri.of_string "https://foo.bar/a/b/c" in
    let uri2 = Uri.with_scheme uri (Some "https") in
    let uri3 = Uri.with_scheme uri (Some "f o o") in
    assert_equal ~printer uri uri2;
    let exp = "f%20o%20o://foo.bar/a/b/c" in
    let msg = sprintf "%s <> %s" (Uri.to_string uri3) exp in
    assert_equal ~msg (Uri.to_string uri3) exp;

    let uri = Uri.with_scheme Uri.empty (Some "http") in
    let uri_s = Uri.to_string uri in
    let uri_exp = "http:" in
    let msg = sprintf "with_scheme empty (%s <> %s).string" uri_s uri_exp in
    assert_equal ~msg uri_s uri_exp;

    let urn = Uri.of_string "urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6" in
    let urn2= Uri.with_scheme urn (Some "urn") in
    assert_equal ~printer urn urn2;

    let urn_path =
      Uri.with_path Uri.empty "uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6"
    in
    let urn2 = Uri.with_scheme urn_path (Some "urn") in
    assert_equal ~printer urn urn2
  );

  "test_with_userinfo" >:: (fun () ->
    let uri = Uri.of_string "https://foo.bar/a/b/c" in
    let uri2 = Uri.with_userinfo uri (Some "avsm:pa:sswo%20rd") in
    let uri3 = Uri.with_userinfo uri (Some "avsm:pa%3Asswo rd") in
    let exp = "https://avsm:pa%3Asswo%20rd@foo.bar/a/b/c" in
    let msg t = sprintf "%s %s <> %s" t (Uri.to_string uri2) exp in
    assert_equal ~msg:(msg "string") (Uri.to_string uri2) exp;
    assert_equal ~msg:(msg "rep") uri2 (Uri.of_string exp);
    let msg t = sprintf "%s %s <> %s" t (Uri.to_string uri3) exp in
    assert_equal ~msg:(msg "string") (Uri.to_string uri3) exp;
    assert_equal ~msg:(msg "rep") uri3 (Uri.of_string exp);
    let uri_some = Uri.with_userinfo Uri.empty (Some "avsm") in
    let exp = "//avsm@" in
    let msg t = sprintf "%s %s <> %s" t (Uri.to_string uri_some) exp in
    assert_equal ~msg:(msg "string") (Uri.to_string uri_some) exp;
    assert_equal ~msg:(msg "rep") uri_some (Uri.of_string exp)
  );

  "test_with_password" >:: (fun () ->
    let uri = Uri.of_string "/" in
    let uri_wp = Uri.with_password uri None in
    assert_equal "/" (Uri.to_string uri_wp);
    let uri_wp = Uri.with_password uri (Some "") in
    assert_equal "//:@/" (Uri.to_string uri_wp);
    let uri_wp = Uri.with_password uri (Some ":") in
    assert_equal "//:%3A@/" (Uri.to_string uri_wp);
    let uri = Uri.of_string "//user:pass@foo" in
    let uri_wp = Uri.with_password uri None in
    assert_equal "//user@foo" (Uri.to_string uri_wp);
    let uri_wp = Uri.with_password uri (Some "") in
    assert_equal "//user:@foo" (Uri.to_string uri_wp);
    let uri_wp = Uri.with_password uri (Some ":") in
    assert_equal "//user:%3A@foo" (Uri.to_string uri_wp)
  );

  "test_with_host" >:: (fun () ->
    let uri      = Uri.of_string "//www.meow.com" in
    let uri_none = Uri.with_host uri None in
    let uri_exp  = "" in
    let msg = sprintf "host removal with None (%s <> %s)"
      uri_exp (Uri.to_string uri_none) in
    assert_equal ~msg (Uri.of_string uri_exp) uri_none;
    let uri_exp  = "//" in
    let uri_some_empty = Uri.with_host uri (Some "") in
    let msg = sprintf "host removal with empty (%s <> %s)"
      uri_exp (Uri.to_string uri_some_empty) in
    assert_equal ~msg (Uri.of_string uri_exp) uri_some_empty;
    let uri_some = Uri.with_host uri (Some "www.woof.com") in
    let uri_woof = Uri.of_string "//www.woof.com" in
    assert_equal ~msg:"host change" uri_woof uri_some;
    let uri_some = Uri.with_host Uri.empty (Some "www.woof.com") in
    assert_equal ~msg:"create host" uri_woof uri_some
  );

  "test_with_port" >:: (fun () ->
    let uri_port = Uri.with_port Uri.empty (Some 80) in
    let uri_exp = "//:80" in
    let msg = sprintf "add port to empty (%s <> %s)"
      uri_exp (Uri.to_string uri_port) in
    assert_equal ~msg (Uri.of_string uri_exp) uri_port;
    let uri = Uri.of_string "//foo.com" in
    let uri_port = Uri.with_port uri (Some 80) in
    assert_equal (Uri.of_string "//foo.com:80") uri_port;
    let foo = Uri.of_string "http://foo.com" in
    let foo_port = Uri.with_port foo (Some 80) in
    assert_equal (Uri.of_string "http://foo.com:80") foo_port;
    let uri_no_port = Uri.with_port foo_port None in
    assert_equal foo uri_no_port;
    assert_equal (Uri.of_string "/") (Uri.with_port (Uri.of_string "/") None)
  );

  "test_with_path" >:: (fun () ->
    let uri_empty = Uri.with_path Uri.empty "" in
    assert_equal ~msg:"empty host empty path" Uri.empty uri_empty;
    let uri_pct = Uri.with_path Uri.empty "a%2F" in
    let msg = sprintf "empty host percent / path (%s <> %s)"
      (Uri.to_string uri_pct) "a%2F" in
    assert_equal ~msg (Uri.to_string uri_pct) "a%2F";
    let uri_some = Uri.with_path Uri.empty "a" in
    assert_equal ~msg:"empty host some path" (Uri.of_string "a") uri_some;
    let uri = Uri.of_string "//" in
    let uri_empty = Uri.with_path uri "" in
    let msg = sprintf "some host empty path (%s <> %s)"
      (Uri.to_string uri) (Uri.to_string uri_empty) in
    assert_equal ~msg uri uri_empty;
    let uri_some = Uri.with_path uri "a" in
    let uri_exp_s = "///a" in
    let uri_exp = Uri.of_string uri_exp_s in
    let uri_exp_sexp  = Sexplib.Sexp.to_string (Uri.sexp_of_t uri_exp) in
    let uri_some_sexp = Sexplib.Sexp.to_string (Uri.sexp_of_t uri_some) in
    let msg = sprintf "path relative host (%s <> %s)"
      uri_exp_sexp uri_some_sexp in
    assert_equal ~msg uri_exp uri_some
  );

  "test_with_query" >:: (fun () ->
    let cmp = Uri.equal in
    let test_with_query prefix =
      let uri = Uri.of_string prefix in
      let uri_empty = Uri.with_query uri [] in
      let msg = prefix ^ " empty" in
      assert_equal ~cmp ~msg (Uri.of_string prefix) uri_empty;
      let uri_quest = Uri.with_query uri ["",[]] in
      let uri_exp_s = prefix ^ "?" in
      let uri_exp   = Uri.of_string uri_exp_s in
      let uri_exp_sexp = Sexplib.Sexp.to_string (Uri.sexp_of_t uri_exp) in
      let uri_quest_sexp = Sexplib.Sexp.to_string (Uri.sexp_of_t uri_quest) in
      let msg = sprintf "'%s' quest (%s <> %s)"
        prefix uri_exp_sexp uri_quest_sexp in
      assert_equal ~cmp ~msg uri_exp uri_quest;
      let uri_equal = Uri.with_query uri ["",[""]] in
      let msg = prefix ^ " equal" in
      assert_equal ~cmp ~msg (Uri.of_string (prefix^"?=")) uri_equal;
      let uri_comma = Uri.with_query uri ["",["";""]] in
      let msg = prefix ^ " comma" in
      assert_equal ~cmp ~msg (Uri.of_string (prefix^"?=,")) uri_comma;
      let uri_empty = Uri.with_query' uri [] in
      let msg = prefix ^ " empty'" in
      assert_equal ~cmp ~msg (Uri.of_string prefix) uri_empty;
      let uri_equal = Uri.with_query' uri ["",""] in
      let msg = prefix ^" equal'" in
      assert_equal ~cmp ~msg (Uri.of_string (prefix^"?=")) uri_equal;
    in
    test_with_query "";
    test_with_query "//";
    test_with_query "///";
    let uri = Uri.of_string "//#" in
    let uri_quest = Uri.with_query uri ["",[]] in
    let msg = "?#" in
    assert_equal ~cmp ~msg (Uri.of_string "//?#") uri_quest;
    let uri_equal = Uri.with_query' uri ["",""] in
    let uri_exp_s = "//?=#" in
    let msg = sprintf "%s <> %s" uri_exp_s (Uri.to_string uri_equal) in
    assert_equal ~cmp ~msg (Uri.of_string "//?=#") uri_equal;

    let printer x = x in
    let uri_exp_s = "?name=3+4%20+%3a|" in
    let uri = Uri.of_string uri_exp_s in
    (match Uri.verbatim_query uri with
     | None -> assert_failure "no query string! (1)"
     | Some qs -> assert_equal uri_exp_s ("?"^qs)
    );
    assert_equal ~printer "?name=3%204%20%20:%7C" (Uri.to_string uri);
    let uri_plus = Uri.add_query_param' uri ("time","now") in
    let uri_exp_s = "?time=now&name=3%204%20%20:%7C" in
    (match Uri.verbatim_query uri_plus with
     | None -> assert_failure "no query string! (2)"
     | Some qs -> assert_equal ~printer uri_exp_s ("?"^qs)
    );
  );

  "test_with_fragment" >:: (fun () ->
    let test_with_fragment prefix =
      let uri = Uri.of_string prefix in
      let uri_empty = Uri.with_fragment uri None in
      assert_equal uri uri_empty;
      let uri_some = Uri.with_fragment uri (Some "") in
      assert_equal (Uri.of_string (prefix^"#")) uri_some
    in
    test_with_fragment "";
    test_with_fragment "//";
    let uri = Uri.of_string "//#" in
    let uri_empty = Uri.with_fragment uri None in
    assert_equal (Uri.of_string "//") uri_empty
  );
]

let canonical_map = [
  "http://foo.bar/a/b/c",      "http://foo.bar/a/b/c";
  "http://foo.bar:/a/b/c",     "http://foo.bar/a/b/c";
  "http://foo.bar:80/a/b/c",   "http://foo.bar/a/b/c";
  "http://foo.bar:443/a/b/c",  "http://foo.bar:443/a/b/c";
  "https://foo.bar/a/b/c",     "https://foo.bar/a/b/c";
  "https://foo.bar:/a/b/c",    "https://foo.bar/a/b/c";
  "https://foo.bar:80/a/b/c",  "https://foo.bar:80/a/b/c";
  "https://foo.bar:443/a/b/c", "https://foo.bar/a/b/c";
  "//example.net:80/a",        "//example.net:80/a";
  "http://example.org",        "http://example.org/";
  "https://example.org",       "https://example.org/";
  "ftp://example.org",         "ftp://example.org";
  "ssh://example.org",         "ssh://example.org";
  "git://example.org",         "git://example.org";
  "",                          "";
  "..",                        "../";
  "/..",                       "/";
  "/foo/./bar",                "/foo/bar";
  "/foo/../../",               "/";
  "http://@bar:?#",            "http://@bar/?#";
  (*"mailto:Joe@Example.COM",    "mailto:Joe@example.com";*)
]

let canonical uri_s = Uri.(to_string (canonicalize (of_string uri_s)))

let test_canonicalize =
  List.map (fun (input, output) ->
    input >:: (fun () ->
      assert_equal ~printer:(fun l -> l) output (canonical input)
    )
  ) canonical_map

let with_uri =
  let base = Uri.of_string "scheme://user:pass@host:0/path?query=arg#fragment" in
  [Uri.with_uri base,                              Uri.to_string base;
   Uri.with_uri ~scheme:None base,                 "//user:pass@host:0/path?query=arg#fragment";
   Uri.with_uri ~scheme:(Some "new") base,         "new://user:pass@host:0/path?query=arg#fragment";
   Uri.with_uri ~userinfo:None base,               "scheme://host:0/path?query=arg#fragment";
   Uri.with_uri ~userinfo:(Some "new") base,       "scheme://new@host:0/path?query=arg#fragment";
   Uri.with_uri ~host:None base,                   "scheme://user:pass@:0/path?query=arg#fragment";
   Uri.with_uri ~host:(Some "new") base,           "scheme://user:pass@new:0/path?query=arg#fragment";
   Uri.with_uri ~port:None base,                   "scheme://user:pass@host/path?query=arg#fragment";
   Uri.with_uri ~port:(Some 1) base,               "scheme://user:pass@host:1/path?query=arg#fragment";
   Uri.with_uri ~path:None base,                   "scheme://user:pass@host:0?query=arg#fragment";
   Uri.with_uri ~path:(Some "new") base,           "scheme://user:pass@host:0/new?query=arg#fragment";
   Uri.with_uri ~query:None base,                  "scheme://user:pass@host:0/path#fragment";
   Uri.with_uri ~query:(Some ["new", ["a"]]) base, "scheme://user:pass@host:0/path?new=a#fragment";
   Uri.with_uri ~fragment:None base,               "scheme://user:pass@host:0/path?query=arg";
   Uri.with_uri ~fragment:(Some "new") base,       "scheme://user:pass@host:0/path?query=arg#new"]

let test_with_uri =
  List.map (fun (input, output) ->
    input >:: (fun () ->
          assert_equal ~printer:(fun l -> l) output input
    )
  ) (List.map (fun (i, o) -> Uri.to_string i, o) with_uri)

(* Returns true if the result list contains successes only.
   Copied from oUnit source as it isnt exposed by the mli *)
let rec was_successful =
  function
    | [] -> true
    | RSuccess _::t
    | RSkip _::t ->
        was_successful t
    | RFailure _::_
    | RError _::_
    | RTodo _::_ ->
        false

let _ =
  let suite = "URI" >::: (
    test_pct_small
    @ test_pct_large
    @ test_uri_encode
    @ test_uri_decode
    @ test_query_decode
    @ test_query_encode
    @ test_rel_res
    @ test_file_rel_res
    @ test_rel_rel_res
    @ test_rel_empty_path_res
    @ test_generic_uri_norm
    @ test_rel_id
    @ test_tcp_port_of_uri
    @ query_key_add_remove
    @ test_sexping
    @ test_with_change
    @ test_canonicalize
    @ test_with_uri
  ) in
  let verbose = ref false in
  let set_verbose _ = verbose := true in
  Arg.parse
    [("-verbose", Arg.Unit set_verbose, "Run the test in verbose mode.");]
    (fun x -> raise (Arg.Bad ("Bad argument : " ^ x)))
    ("Usage: " ^ Sys.argv.(0) ^ " [-verbose]");
  if not (was_successful (run_test_tt ~verbose:!verbose suite)) then
  exit 1
