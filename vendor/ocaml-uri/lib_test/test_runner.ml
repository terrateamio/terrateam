(*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
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
  "http://%5Bdead%3Abeef%3A%3Adead%3A0%3Abeaf%5D",
    (Uri.make ~scheme:"http" ~host:"[dead:beef::dead:0:beaf]" ());
  "foo+bar%3A", (Uri.make ~path:"foo+bar:" ());
  "foo+bar:///", (Uri.make ~scheme:"foo+bar" ~host:"" ~path:"/" ());
  "foo2-bar.baz:///", (Uri.make ~scheme:"foo2-bar.baz" ~host:"" ~path:"/" ());
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
  "?",[];
  "?&",["",[];"",[]];
  "?&&",["",[];"",[];"",[]];
  "??&/&",["?",[];"/",[];"",[]];
  "?#?/#",[];
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
]

let test_rel_res =
  let base = Uri.of_string "http://a/b/c/d;p?q" in
  List.map (fun (rel,abs) ->
    let test () = assert_equal ~printer:(fun l -> l)
      abs (Uri.to_string (Uri.resolve "http" base (Uri.of_string rel))) in
    rel >:: test
  ) uri_rel_res

let file_uri_rel_res = [ (* http://tools.ietf.org/html/rfc1738#section-3.10 *)
  "/foo/bar/baz", "///foo/bar/baz";
  "//localhost/foo", "///foo";
]

let test_file_rel_res =
  List.map (fun (rel,abs) ->
    let test () = assert_equal ~printer:(fun l -> l)
      abs (Uri.to_string (Uri.resolve "file" (Uri.of_string "")
                            (Uri.of_string rel))) in
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
  "http://example.com/%3a%3f", "http://example.com/%3A%3F";
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
]

let test_generic_uri_norm =
  List.map (fun (o,n) ->
    let test () = assert_equal ~printer:(fun l -> l)
      n (Uri.to_string (Uri.resolve "http" (Uri.of_string "")
                          (Uri.of_string o))) in
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
    | Some i -> Printf.sprintf "Some %d" i
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
      "((scheme https)(host example.com)(path /foo)(query((bar(1))))(fragment frag))";
    "2", "", "((path\"\")(query()))";
    "3", "/?foo=bar", "((path /)(query((foo(bar)))))"
  ] in
  let test uri exp =
    let uri = Uri.of_string uri in
    let s = Sexplib.Sexp.to_string (Uri.sexp_of_t uri) in
    assert_equal s exp
  in
  List.map (fun (id,uri,exp) -> ("test_sexping_%s"^id) >:: (fun () -> test uri exp)) tests

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
  let suite = "URI" >::: (test_pct_small @ test_pct_large @ test_uri_encode @ test_uri_decode @ test_query_decode @ test_query_encode @ test_rel_res @ test_file_rel_res @ test_rel_rel_res @ test_generic_uri_norm @ test_rel_id @ test_tcp_port_of_uri @ query_key_add_remove @ test_sexping) in
  let verbose = ref false in
  let set_verbose _ = verbose := true in
  Arg.parse
    [("-verbose", Arg.Unit set_verbose, "Run the test in verbose mode.");]
    (fun x -> raise (Arg.Bad ("Bad argument : " ^ x)))
    ("Usage: " ^ Sys.argv.(0) ^ " [-verbose]");
  if not (was_successful (run_test_tt ~verbose:!verbose suite)) then
  exit 1

