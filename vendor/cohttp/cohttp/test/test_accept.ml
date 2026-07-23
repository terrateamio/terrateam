(*{{{ Copyright (c) 2012 David Sheets <sheets@alum.mit.edu>
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

module A = Cohttp.Accept

let suite_of :
    type a.
    (string option -> a) -> a Alcotest.testable -> (string * a) list -> _ list =
 fun pf t ->
  List.map (fun (s, expected) ->
      let test () = Alcotest.check t s (pf (Some s)) expected in
      (s, `Quick, test))

let suite_of_fail :
    type a.
    (string option -> a) -> a Alcotest.testable -> (string * exn) list -> _ list
    =
 fun pf _ ->
  List.map (fun (s, e) ->
      let test () =
        Alcotest.check_raises s e (fun () -> ignore (pf (Some s)))
      in
      (s, `Quick, test))

let suite_to_string_of : type a. (a -> string) -> (a * string) list -> _ list =
 fun pf ->
  List.map (fun (v, expected_str) ->
      let test () = Alcotest.(check string expected_str expected_str (pf v)) in
      (expected_str, `Quick, test))

let suite_to_string_of_fail :
    type a. (a -> string) -> (a * string * exn) list -> _ list =
 fun pf ->
  List.map (fun (v, descr, e) ->
      let test () = Alcotest.(check_raises descr e (fun () -> ignore (pf v))) in
      ("", `Quick, test))

let valid_media_ranges =
  [
    ("text/plain", [ (1000, (A.MediaType ("text", "plain"), [])) ]);
    ("text/*", [ (1000, (A.AnyMediaSubtype "text", [])) ]);
    ("*/*", [ (1000, (A.AnyMedia, [])) ]);
    ("*/*;q=1", [ (1000, (A.AnyMedia, [])) ]);
    ("*/*;q=0", [ (0, (A.AnyMedia, [])) ]);
    ("*/*;q=1.", [ (1000, (A.AnyMedia, [])) ]);
    ("*/*;q=1.0", [ (1000, (A.AnyMedia, [])) ]);
    ("*/*;q=.0", [ (0, (A.AnyMedia, [])) ]);
    ("*/*;q=0.", [ (0, (A.AnyMedia, [])) ]);
    ("*/*;q=0.1", [ (100, (A.AnyMedia, [])) ]);
    ( "image/*,text/*",
      [
        (1000, (A.AnyMediaSubtype "image", []));
        (1000, (A.AnyMediaSubtype "text", []));
      ] );
    ( "text/plain; q=0.8; charset=utf-8,text/HTML;charset=utf-8;q=0.9",
      [
        (800, (A.MediaType ("text", "plain"), [ ("charset", "utf-8") ]));
        (900, (A.MediaType ("text", "html"), [ ("charset", "utf-8") ]));
      ] );
    ( "text/*;foo=\"bar\"",
      [ (1000, (A.AnyMediaSubtype "text", [ ("foo", "bar") ])) ] );
    ("*/*;qu=\"\\\"\"", [ (1000, (A.AnyMedia, [ ("qu", "\"") ])) ]);
    ( "*/*;f=\";q=0,text/plain\"",
      [ (1000, (A.AnyMedia, [ ("f", ";q=0,text/plain") ])) ] );
  ]

let invalid_media_ranges = [ ("*/*;q=.", Parsing.Parse_error) ]

let valid_media_ranges_suite =
  let t_media_ranges =
    Alcotest.testable (Fmt.of_to_string A.string_of_media_ranges) ( = )
  in
  suite_of A.media_ranges t_media_ranges valid_media_ranges

let invalid_media_ranges_suite =
  let t_media_ranges =
    Alcotest.testable (Fmt.of_to_string A.string_of_media_ranges) ( = )
  in
  suite_of_fail A.media_ranges t_media_ranges invalid_media_ranges

let valid_qualities =
  [
    ((1000, (A.AnyMedia, [])), "*/*;q=1");
    ((0, (A.AnyMedia, [])), "*/*;q=0.000");
    ((353, (A.AnyMedia, [])), "*/*;q=0.353");
    ((25, (A.AnyMedia, [])), "*/*;q=0.025");
    ((1, (A.AnyMedia, [])), "*/*;q=0.001");
  ]

let invalid_qualities =
  [
    ( (-3, (A.AnyMedia, [])),
      "negative",
      Invalid_argument "qvalue -3 must be positive" );
    ( (1001, (A.AnyMedia, [])),
      "bigger than 1000",
      Invalid_argument "qvalue 1001 must be less than 1000" );
  ]

let valid_qualities_suite =
  suite_to_string_of (fun (q, a) -> A.string_of_media_range a q) valid_qualities

let invalid_qualities_suite =
  suite_to_string_of_fail
    (fun (q, a) -> A.string_of_media_range a q)
    invalid_qualities

let valid_charsets =
  [
    ("utf-8", [ (1000, A.Charset "utf-8") ]);
    ("UTF-8", [ (1000, A.Charset "utf-8") ]);
    ("iso-8859-1", [ (1000, A.Charset "iso-8859-1") ]);
    ( "ISO-8859-1; q = 0.8, *; q=0.7",
      [ (800, A.Charset "iso-8859-1"); (700, A.AnyCharset) ] );
  ]

let valid_charsets_suite =
  let t_charsets =
    Alcotest.testable (Fmt.of_to_string A.string_of_charsets) ( = )
  in
  suite_of A.charsets t_charsets valid_charsets

let valid_encodings =
  [
    ("compress, gzip", [ (1000, A.Compress); (1000, A.Gzip) ]);
    ("", []);
    ("*", [ (1000, A.AnyEncoding) ]);
    ("compress;q=0.5, gzip;q=1.0", [ (500, A.Compress); (1000, A.Gzip) ]);
    ( "Gzip;q=1.0, identity; q=0.5, *;q=0",
      [ (1000, A.Gzip); (500, A.Identity); (0, A.AnyEncoding) ] );
  ]

let valid_encodings_suite =
  let t_encodings =
    Alcotest.testable (Fmt.of_to_string A.string_of_encodings) ( = )
  in
  suite_of A.encodings t_encodings valid_encodings

let valid_languages =
  [
    ("en", [ (1000, A.Language [ "en" ]) ]);
    ("en-US", [ (1000, A.Language [ "en"; "us" ]) ]);
    ("en-cockney", [ (1000, A.Language [ "en"; "cockney" ]) ]);
    ("i-cherokee", [ (1000, A.Language [ "i"; "cherokee" ]) ]);
    ("x-pig-latin", [ (1000, A.Language [ "x"; "pig"; "latin" ]) ]);
    ( "da, en-gb;q=0.8, en;q=0.7",
      [
        (1000, A.Language [ "da" ]);
        (800, A.Language [ "en"; "gb" ]);
        (700, A.Language [ "en" ]);
      ] );
    ( "en-US, *;q=0.9",
      [ (1000, A.Language [ "en"; "us" ]); (900, A.AnyLanguage) ] );
  ]

let valid_languages_suite =
  let t_languages =
    Alcotest.testable (Fmt.of_to_string A.string_of_languages) ( = )
  in
  suite_of A.languages t_languages valid_languages

let () = Printexc.record_backtrace true

let () =
  Alcotest.run "test_accept"
    [
      ("valid string to media range", valid_media_ranges_suite);
      ("invalid string to media range", invalid_media_ranges_suite);
      ("valid media range to string", valid_qualities_suite);
      ("invalid media range to string", invalid_qualities_suite);
      ("valid string to charset", valid_charsets_suite);
      ("valid string to encoding", valid_encodings_suite);
      ("valid string to language", valid_languages_suite);
    ]
