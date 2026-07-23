(*{{{ Copyright (c) 2021 Carine Morel <carine@tarides.com>
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

module H = Cohttp.Header
(** These tests try as much as possible to tests each header functions
    independently. *)

let aei = Alcotest.check Alcotest.int
let aes = Alcotest.check Alcotest.string
let aeso = Alcotest.check Alcotest.(option string)
let aesl = Alcotest.check Alcotest.(list string)
let aessl = Alcotest.check Alcotest.(list (pair string string))
let aeb = Alcotest.check Alcotest.bool

let t_header =
  Alcotest.testable
    (fun fmt h ->
      let sexp = Cohttp.Header.sexp_of_t h in
      Sexplib0.Sexp.pp_hum fmt sexp)
    (fun x y -> Cohttp.Header.compare x y = 0)

let aeh = Alcotest.check t_header

let hstr =
  [
    ("accept", "application/xml");
    ("transfer-encoding", "chunked");
    ("accept", "text/html");
    ("content-length", "100");
  ]

let prebuilt = H.of_list hstr
let to_list_rev h = List.rev (H.to_list h)

let to_list_tests () =
  aessl "to_list (init ())" [] H.(to_list (init ()));
  aessl "to_list (add (init ()) k v"
    [ ("a", "a1") ]
    H.(to_list (add (init ()) "a" "a1"));
  aessl "to_list (of_list h) = h" hstr H.(to_list prebuilt)

let is_empty_tests () =
  aeb "is_empty (init ())" true H.(is_empty (init ()));
  aeb "is_empty (add (init ()) k v" false H.(is_empty (add (init ()) "a" "a1"));
  aeb "is_empty (remove (add (init ()) k v) k)" true
    H.(is_empty (remove (add (init ()) "a" "a1") "a"))

let init_with_tests () =
  aessl "init_with k v"
    [ ("traNsfer-eNcoding", "chunked") ]
    H.(to_list (init_with "traNsfer-eNcoding" "chunked"))

let mem_tests () =
  aeb "mem (init ()) k = false" false H.(mem (init ()) "a");
  aeb "mem h k" true H.(mem prebuilt "accept");
  aeb "mem h k" true H.(mem prebuilt "content-length");
  aeb "mem h k" false H.(mem prebuilt "a")

let add_tests () =
  aessl "add h k v" (hstr @ [ ("a", "a1") ]) H.(to_list (add prebuilt "a" "a1"));
  aessl "add (add h k v) k v"
    (hstr @ [ ("a", "a1"); ("a", "a1") ])
    H.(to_list (add (add prebuilt "a" "a1") "a" "a1"));
  aessl "add (add h k' v') k v"
    (hstr @ [ ("a", "a1"); ("b", "b1") ])
    H.(to_list (add (add prebuilt "a" "a1") "b" "b1"))

let get_tests () =
  aeso "get (add (init () k v) k" (Some "a1")
    H.(get (add (init ()) "a" "a1") "a");
  aeso "get (add h k v) k when mem h k = false" (Some "a1")
    H.(get (add prebuilt "a" "a1") "a");
  aeso "get (add h k v) k when mem h k = true" (Some "text/html")
    H.(get (add prebuilt "a" "a1") "accept");
  aeso "get (add (add h k v') k v) k = v" (Some "a2")
    H.(get (add (add prebuilt "a" "a1") "a" "a2") "a")

let add_list_tests () =
  let l = [ ("a", "a1"); ("b", "b1") ] in
  aessl "add_list (init ()) []" [] H.(to_list (add_list (init ()) []));
  aessl "add_list (init ()) l" l H.(to_list (add_list (init ()) l));
  aessl "add_list h []" hstr H.(to_list (add_list prebuilt []));
  aessl "add_list h [k, v]"
    (hstr @ [ ("a", "a1") ])
    H.(to_list (add_list prebuilt [ ("a", "a1") ]));
  aessl "add_list h l" (hstr @ l) H.(to_list (add_list prebuilt l))

let add_multi_tests () =
  let k, vals = ("a", [ "a1"; "a2"; "a3" ]) in
  let l = List.map (fun v -> ("a", v)) vals in
  aessl "add_multi (init ()) k []" [] H.(to_list (add_multi (init ()) k []));
  aessl "add_multi (init ()) k vals" l H.(to_list (add_multi (init ()) k vals));
  aessl "add_multi h k []" hstr H.(to_list (add_multi prebuilt k []));
  aessl "add_multi h k vals" (hstr @ l) H.(to_list (add_multi prebuilt k vals))

let add_unless_exists_tests () =
  let k, v = ("a", "a1") in
  let k', v' = ("transfer-encoding", "chunked") in
  let k'', v'' = ("accept", "text/*") in
  aessl "add_unless_exists (init ()) k v"
    [ (k, v) ]
    H.(to_list (add_unless_exists (init ()) k v));
  aessl "add_unless_exists h k v when mem h k = false"
    (hstr @ [ (k, v) ])
    H.(to_list (add_unless_exists prebuilt k v));
  aessl "add_unless_exists h k v when mem h k = true)" hstr
    H.(to_list (add_unless_exists prebuilt k' v'));
  aessl "add_unless_exists h k v when mem h k = true)" hstr
    H.(to_list (add_unless_exists prebuilt k'' v''))

let remove_tests () =
  aessl "remove (init ()) k" [] H.(to_list (remove (init ()) "accept"));
  aessl "remove (add (add (init ()) k v) k v) k" []
    H.(to_list (remove (add (add (init ()) "k" "v") "k" "v") "k"));
  aessl "remove h k when mem h k = false" hstr H.(to_list (remove prebuilt "a"));
  aessl "remove h k when mem h k = true"
    [
      ("accept", "application/xml");
      ("accept", "text/html");
      ("content-length", "100");
    ]
    H.(to_list (remove prebuilt "transfer-encoding"));
  aessl "remove h k when mem h k = true"
    [ ("transfer-encoding", "chunked"); ("content-length", "100") ]
    H.(to_list (remove prebuilt "accept"))

let replace_tests () =
  let k, v, v' = ("a", "a1", "a2") in
  aessl "replace (init ()) k v" [ (k, v) ] H.(to_list (replace (init ()) k v));
  aessl "replace (add (init ()) k v) k v"
    [ (k, v) ]
    H.(to_list (replace (add (init ()) k v) k v));
  aessl "replace (add (init ()) k v) k v'"
    [ (k, v') ]
    H.(to_list (replace (add (init ()) k v) k v'));
  aessl "replace h k v when mem h k = false"
    (hstr @ [ (k, v) ])
    H.(to_list (replace prebuilt k v));
  aessl "replace h k v when mem h k = true"
    [
      ("accept", "application/xml");
      ("transfer-encoding", "gzip");
      ("accept", "text/html");
      ("content-length", "100");
    ]
    H.(to_list (replace prebuilt "transfer-encoding" "gzip"));
  aessl "replace h k v when mem h = true"
    [
      ("transfer-encoding", "chunked");
      ("accept", "text/*");
      ("content-length", "100");
    ]
    H.(to_list (replace prebuilt "accept" "text/*"))

let h =
  H.init () |> fun h ->
  H.add h "first" "1" |> fun h ->
  H.add h "second" "2" |> fun h ->
  H.add h "accept" "foo" |> fun h -> H.add h "accept" "bar"

let update_tests () =
  let h1 =
    H.update h "second" (function Some _ -> Some "2a" | None -> None)
  in
  let h2 = H.replace h "second" "2a" in
  aeh "update existing header" h1 h2;
  let h1 = H.update h "second" (function Some _ -> None | None -> Some "3") in
  let h2 = H.remove h "second" in
  aeh "update remove header" h1 h2;
  let h1 =
    H.update h "accept" (function Some _ -> Some "baz" | None -> None)
  in
  aesl "update existing header with multiple values"
    H.(get_multi h1 "accept")
    [ "foo"; "baz" ];
  let h' = H.update h "third" (function Some _ -> None | None -> Some "3") in
  aesl "update add new header" (H.get_multi h' "third") [ "3" ];
  let h1 = H.update h "third" (function _ -> None) in
  aeh "update_remove_absent_header" h h1;
  let h1 = H.update h "third" (function Some _ -> Some "3" | None -> None) in
  aeh "update_new_header: unchanged" h h1;
  let h1 = H.update h "accept" (function Some _ -> None | None -> None) in
  aeso "update_existing_header_remove_multivalue: remove last" (Some "foo")
    (H.get h1 "accept")

let update_all_tests () =
  let h1 = H.update_all h "second" (function [] -> [] | _ -> [ "2a" ]) in
  let h2 = H.(add (remove h "second") "second" "2a") in
  aeh "update_all existing header" h1 h2;
  let h1 = H.update_all h "second" (function [] -> [ "3" ] | _ -> []) in
  let h2 = H.remove h "second" in
  aeh "update_all remove header" h1 h2;
  let h1 = H.update_all h "accept" (function [] -> [] | _ -> [ "baz" ]) in
  aesl "update_all existing header with multiple values"
    H.(get_multi h1 "accept")
    [ "baz" ];
  let h1 =
    H.update_all h "accept" (function [] -> [] | xs -> xs @ [ "baz" ])
  in
  let h2 = H.add h "accept" "baz" in
  aeso "update_all_existing_header_multivalued"
    (H.get_multi_concat h1 "accept")
    (H.get_multi_concat h2 "accept");
  let h1 = H.update_all h "accept" (function _ -> []) in
  aeh "update_all_existing_header_multivalue : remove all" (H.remove h "accept")
    h1;
  let h1 = H.update_all h "third" (function [] -> [ "3"; "33" ] | _ -> []) in
  let h2 = H.add_multi h "third" [ "3"; "33" ] in
  aeh "update add new header" h1 h2;
  let h1 = H.update_all h "third" (function _ -> []) in
  aeh "update_remove_absent_header" h h1;
  let h1 = H.update_all h "third" (function [] -> [] | _ -> [ "3" ]) in
  aeh "update_new_header: unchanged" h h1

let get_multi_tests () =
  aesl "get_multi (init ()) k" [] H.(get_multi (init ()) "a");
  aesl "get_multi h k when mem h k = false" [] H.(get_multi prebuilt "a");
  aesl "get_multi h k when mem h k = true" [ "chunked" ]
    H.(get_multi prebuilt "transfer-encoding");
  aesl "get_multi h k when mem h k = true"
    [ "application/xml"; "text/html" ]
    H.(get_multi prebuilt "accept")

let hstr =
  [
    ("accept", "application/xml");
    ("transfer-encoding", "chunked");
    ("accept", "text/html");
    ("content-length", "100");
  ]

let get_multi_concat_tests () =
  let h1 = H.(add (add prebuilt "a" "a1") "a" "a2") in
  aeso "get_multi_concat (init ()) k" None H.(get_multi_concat (init ()) "a");
  aeso "get_multi_concat h k when mem h k = false" None
    H.(get_multi_concat prebuilt "a");
  aeso "get_multi_concat h k when mem h k = true"
    (Some "application/xml,text/html")
    H.(get_multi_concat prebuilt "accept");
  aeso "get_multi_concat ~list_value_only:false h k when mem h k = true"
    (Some "a1,a2")
    H.(get_multi_concat h1 "a");
  aeso "get_multi_concat ~list_value_only:true h k when mem h k = true"
    (Some "a2")
    H.(get_multi_concat ~list_value_only:true h1 "a")

let map_tests () =
  let a = ", a" in
  aessl "map (fun _ v -> v) (init ())" []
    H.(to_list (map (fun _k v -> v) (init ())));
  aessl "map (fun _ v -> v) (init ())" (H.to_list prebuilt)
    H.(to_list (map (fun _k v -> v) prebuilt));
  aessl "map (fun _ v -> v ^ a ) (init ())"
    [
      ("accept", "application/xml, a");
      ("transfer-encoding", "chunked, a");
      ("accept", "text/html, a");
      ("content-length", "100, a");
    ]
    H.(to_list (map (fun _k v -> v ^ a) prebuilt))

let fold_tests () =
  let rev k v acc = H.(add acc k v) in
  let h1 = H.(fold rev prebuilt (init ())) in
  aessl
    "[fold (fun k v acc -> H.(add acc k v)) h (init ())] reverses the header"
    (List.rev H.(to_list h1))
    H.(to_list prebuilt);
  let h1 = H.(fold rev (fold rev prebuilt (init ())) (init ())) in
  aeh "[fold rev (fold rev h (init ())) (init ()) = h] " h1 prebuilt;
  let count _ _ acc = acc + 1 in
  aei "[fold (fun _ _ acc -> acc+1) h 0] returns the length of h"
    (List.length H.(to_list prebuilt))
    H.(fold count prebuilt 0)

let iter_tests () =
  let h = ref H.(init ()) in
  let rev k v = h := H.(add !h k v) in
  H.(iter rev prebuilt);
  aessl "[iter (fun k v -> href := H.(add !href k v)) h] reverses the header"
    (List.rev H.(to_list !h))
    H.(to_list prebuilt);
  let c = ref 0 in
  let count _ _ = c := !c + 1 in
  aei "[iter (fun _ _ -> count := !count+1) h] works fine"
    (List.length H.(to_list prebuilt))
    (H.(iter count prebuilt);
     !c)

let to_lines_tests () =
  aesl "to_lines h"
    [
      "accept: application/xml\r\n";
      "transfer-encoding: chunked\r\n";
      "accept: text/html\r\n";
      "content-length: 100\r\n";
    ]
    H.(to_lines prebuilt)

let to_frames_tests () =
  aesl "to_frames h"
    [
      "accept: application/xml";
      "transfer-encoding: chunked";
      "accept: text/html";
      "content-length: 100";
    ]
    H.(to_frames prebuilt)

let to_string_tests () =
  aes "to_string h"
    "accept: application/xml\r\n\
     transfer-encoding: chunked\r\n\
     accept: text/html\r\n\
     content-length: 100\r\n\
     \r\n"
    H.(to_string prebuilt)

let many_headers () =
  let size = 1000000 in
  let rec add_header num h =
    match num with
    | 0 -> h
    | n ->
        let k = Printf.sprintf "h%d" n in
        let v = Printf.sprintf "v%d" n in
        let h = H.add h k v in
        add_header (num - 1) h
  in
  let h = add_header size (H.init ()) in
  Alcotest.(check int) "many_headers" (List.length (H.to_list h)) size

let transfer_encoding_tests () =
  let h =
    H.of_list
      [ ("transfer-encoding", "gzip"); ("transfer-encoding", "chunked") ]
  in
  let sh = H.to_string h in
  aes "transfer_encoding_string_is_ordered" sh
    "transfer-encoding: gzip\r\ntransfer-encoding: chunked\r\n\r\n";
  let sh = H.get_multi_concat h "transfer-encoding" in
  aeso "transfer_encoding_get_is_ordered" (Some "gzip,chunked") sh

module String_io = Cohttp__String_io
module HIO = Cohttp__Header_io.Make (String_io.M)

let large_header () =
  let sz = 1024 * 1024 * 100 in
  let h = H.init () in
  let v1 = String.make sz 'a' in
  let h = H.add h "x-large" v1 in
  let h = H.add h v1 "foo" in
  aeso "x-large" (H.get h "x-large") (Some v1);
  let obuf = Buffer.create (sz + 1024) in
  HIO.write h obuf;
  let ibuf = Buffer.contents obuf in
  let sbuf = String_io.open_in ibuf in
  Alcotest.check t_header "large_header" (HIO.parse sbuf) h

let tests =
  ( "Unitary Header tests",
    [
      ("Header.to_list", `Quick, to_list_tests);
      ("Header.is_empty", `Quick, is_empty_tests);
      ("Header.init_with", `Quick, init_with_tests);
      ("Header.mem", `Quick, mem_tests);
      ("Header.add", `Quick, add_tests);
      ("Header.get", `Quick, get_tests);
      ("Header.add_list", `Quick, add_list_tests);
      ("Header.add_multi", `Quick, add_multi_tests);
      ("Header.add_unless_exists", `Quick, add_unless_exists_tests);
      ("Header.remove", `Quick, remove_tests);
      ("Header.replace", `Quick, replace_tests);
      ("Header.get_multi", `Quick, get_multi_tests);
      ("Header.get_multi_concat", `Quick, get_multi_concat_tests);
      ("Header.to_lines", `Quick, to_lines_tests);
      ("Header.to_frames", `Quick, to_frames_tests);
      ("Header.to_string", `Quick, to_string_tests);
      ("Header.map", `Quick, map_tests);
      ("Header.fold", `Quick, fold_tests);
      ("Header.iter", `Quick, iter_tests);
      ("Header.update", `Quick, update_tests);
      ("Header.update_all", `Quick, update_all_tests);
      ("many headers", `Slow, many_headers);
      ("transfer encoding is in correct order", `Quick, transfer_encoding_tests);
    ]
    @
    if Sys.word_size = 64 then [ ("large header", `Slow, large_header) ] else []
  )
