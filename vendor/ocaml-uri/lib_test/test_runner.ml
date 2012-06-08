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
  (1, "hello world!", "hello%20world%21");
  (2, "!", "%21");
  (3, "!!!!!", "%21%21%21%21%21");
  (4, "1!", "1%21");
  (5, "%20", "%2520");
  (6, "", "");
  (7, "f", "f");
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
      ~port:123 ~path:"/wh/at/ever" ~query:["foo","1";"bar","5"] ~fragment:"5" ());
  "http://foo.com", (Uri.make ~scheme:"http" ~host:"foo.com" ());
  "http://foo%21.com", (Uri.make ~scheme:"http" ~host:"foo!.com" ());
  "/wh/at/ev/er", (Uri.make ~path:"/wh/at/ev/er" ());
  "/wh/at%21/ev%20/er", (Uri.make ~path:"/wh/at!/ev /er" ());
  "http://%5Bdead%3Abeef%3A%3Adead%3A0%3Abeaf%5D",
    (Uri.make ~scheme:"http" ~host:"[dead:beef::dead:0:beaf]" ())
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

(* Test URI query decoding *)
let uri_query = [
  "https://user:pass@foo.com:123/wh/at/ever?foo=1&bar=5#5", ["foo","1"; "bar","5"];
  "//domain?f+1=bar&+f2=bar%212", ["f 1","bar";" f2","bar!2"];
  "//domain?foo=&bar=", ["foo","";"bar",""];
  "//domain?a=b%26c%3Dd", ["a","b&c=d"];
]

let test_query_decode =
  List.map (fun (uri_str,res) ->
    let uri = Uri.of_string uri_str in
    let test () = assert_equal ~printer:(fun l ->
      String.concat " " (List.map (fun (k,v) -> sprintf "(%s=%s)" k v) l)) res (Uri.query uri) in
    uri_str >:: test
  ) uri_query

(* Test URI query encoding. No pct encoding as that is done later by Uri.to_string *)
let uri_query_make = [
  [], "";
  ["foo","bar"], "foo=bar";
  ["foo1","bar1";"foo2","bar2"], "foo1=bar1&foo2=bar2";
  ["foo1","bar1";"foo2","bar2";"foo3","bar3"], "foo1=bar1&foo2=bar2&foo3=bar3";
]

let test_query_encode =
  List.map (fun (qs,res) ->
    let test () = assert_equal ~printer:(fun l -> l) (Uri.encoded_of_query qs) res in
    res >:: test
  ) uri_query_make

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
  let suite = "URI" >::: (test_pct_small @ test_pct_large @ test_uri_encode @ test_query_decode @ test_query_encode) in
  let verbose = ref false in
  let set_verbose _ = verbose := true in
  Arg.parse
    [("-verbose", Arg.Unit set_verbose, "Run the test in verbose mode.");]
    (fun x -> raise (Arg.Bad ("Bad argument : " ^ x)))
    ("Usage: " ^ Sys.argv.(0) ^ " [-verbose]");
  if not (was_successful (run_test_tt ~verbose:!verbose suite)) then
  exit 1

