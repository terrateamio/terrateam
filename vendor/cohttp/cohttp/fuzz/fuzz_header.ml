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

(** Here, we test the Header module with fuzzing. Some of these tests may be
    redundant with Alcotest tests.

    The tests are launched with [dune runtest] but can also be run with [afl]
    with the command line : [dune build @cohttp/fuzz/fuzz --no-buffer].

    The tests below reflects the semantics we want for each function, however in
    some cases, it may actually be specific to the current implementation and
    does not necessary need to be enforced in future implementations. To make it
    clear, tests are annoted by their categories:

    - FS (Functions semantics): tests the semantics described in the
      documentation.

    - SI (Specific to current Implementation): these tests are here to check the
      implementation is doing what we think it is doing but may change
      accordingly to implementation changes. *)

(* Generators *)
let list_value_headers =
  [|
    "accept";
    "accept-charset";
    "accept-encoding";
    "accept-language";
    "accept-ranges";
    "allow";
    "cache-control";
    "connection";
    "content-encoding";
    "content-language";
    "expect";
    "if-match";
    "if-none-match";
    "link";
    "pragma";
    "proxy-authenticate";
    "te";
    "trailer";
    "transfer-encoding";
    "upgrade";
    "vary";
    "via";
    "warning";
    "www-authenticate";
  |]

(** Pick a random list-value header name from a predefined array of values. *)
let list_value_header_gen =
  let open Crowbar in
  let gen =
    map
      [ range (Array.length list_value_headers) ]
      (fun i -> list_value_headers.(i))
  in
  let printer fmt str = pp fmt "%s" str in
  with_printer printer gen

(** Generate a tchar following
    {{:https://tools.ietf.org/html/rfc7230#appendix-B} RFC 7230}.

    tchar = "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "." / "^" /
    "_" / "`" / "|" / "~" / DIGIT / ALPHA *)
let tchar_gen =
  let tchar_code_gen =
    let uppercased_letter = Crowbar.range ~min:65 26 in
    let lowercased_letter = Crowbar.range ~min:97 26 in
    let others =
      List.map
        (fun i -> Crowbar.const i)
        [
          33 (* ! *);
          35 (* # *);
          36 (* $ *);
          37 (* % *);
          38 (* & *);
          42 (* * *);
          43 (* + *);
          45 (* - *);
          46 (* . *);
          94 (* ^ *);
          95 (* _ *);
          96 (* ` *);
          124 (* | *);
          126 (* ~ *);
        ]
      |> Crowbar.choose
    in
    let digit_and_others = Crowbar.(choose [ others; range ~min:48 10 ]) in
    Crowbar.(choose [ lowercased_letter; uppercased_letter; digit_and_others ])
  in
  Crowbar.(map [ tchar_code_gen ] (fun i -> Char.escaped (Char.chr i)))

(** Generate a non-empty word of arbitrary length (composed of tchar only). *)
let word_gen =
  let open Crowbar in
  let gen =
    fix (fun word_gen ->
        choose
          [
            (* one letter word *)
            tchar_gen;
            (* two letters word *)
            map [ tchar_gen; tchar_gen ] (fun l1 l2 -> l1 ^ l2);
            (* add one letter *)
            map [ tchar_gen; word_gen ] (fun l w -> l ^ w);
          ])
  in
  let printer = pp_string in
  with_printer printer gen

(** Generate an header name: either a predefined list-value header or a random
    word *)
let header_name_gen =
  let open Crowbar in
  let gen = choose [ list_value_header_gen; word_gen ] in
  let printer = pp_string in
  with_printer printer gen

let header_printer fmt (k, v) = Crowbar.pp fmt "%s, %s" k v

(** Generate a header key/value pair *)
let header_gen : (string * string) Crowbar.gen =
  let open Crowbar in
  let gen_setcookie = pair (const "Set-cookie") word_gen in
  let gen_otherheader = pair header_name_gen word_gen in
  let gen =
    (* one in ten generated header is a "set-cookie" header *)
    choose (gen_setcookie :: List.init 9 (fun _ -> gen_otherheader))
  in
  with_printer header_printer gen

(** Generate a list of headers *)
let header_list_gen : (string * string) list Crowbar.gen =
  let open Crowbar in
  let gen = list header_gen in
  let printer = pp_list header_printer in
  with_printer printer gen

(** Generate a [Cohttp.Header.t] headers. *)
let headers_gen : H.t Crowbar.gen =
  let open Crowbar in
  let gen =
    fix (fun headers_gen ->
        choose
          [
            (* empty header *)
            const (H.init ());
            (* add one pair (k, v) *)
            map [ header_gen; headers_gen ] (fun (k, v) h -> H.add h k v);
            (* add a list of headers *)
            map [ headers_gen; header_list_gen ] (fun h l -> H.add_list h l);
          ])
  in
  let printer fmt h = Crowbar.pp fmt "\n%s@." (H.to_string h) in
  with_printer printer gen

(* Tests *)
(* Important note : keys must be lowercased before comparison *)
let eqssl l1 l2 =
  List.map (fun (k, v) -> (String.lowercase_ascii k, v)) l1
  = List.map (fun (k, v) -> (String.lowercase_ascii k, v)) l2

let is_empty_test () =
  Crowbar.(
    (* FS *)
    (* forall h, k, v. is_empty (add h k v) = false) *)
    add_test ~name:"[is_empty] returns false on a non empty header"
      [ headers_gen; header_name_gen; word_gen ] (fun h k v ->
        check_eq false H.(is_empty (add h k v))))

let init_with_test () =
  Crowbar.(
    (* FS *)
    (* forall k v. to_list (init_with k v) = [k, v] *)
    add_test ~name:"[init_list k v] is [k, v]" [ header_name_gen; word_gen ]
      (fun k v -> check_eq H.(to_list (init_with k v)) [ (k, v) ]))

let mem_test () =
  Crowbar.(
    (* FS *)
    (* forall k. mem (init ()) k = false *)
    add_test ~name:"[mem h k] on an empty header is always false"
      [ header_name_gen ] (fun k -> check_eq false H.(mem (init ()) k));
    (* SI *)
    (* forall h, k. H.mem h k = List.(mem_assoc (String.lowercase_ascii x) (List.map (fun (k, v) -> String.lowercase_ascii k, v) (H.to_list h))) *)
    add_test ~name:"Header.mem has the same behavior than List.mem_assoc"
      [ headers_gen; header_name_gen ] (fun h k ->
        check_eq
          H.(mem h k)
          List.(
            mem_assoc (String.lowercase_ascii k)
              (List.map
                 (fun (k, v) -> (String.lowercase_ascii k, v))
                 (H.to_list h)))))

let add_test () =
  Crowbar.(
    (* FS *)
    (* forall k, v, h. mem (add h k v) k = true *)
    add_test ~name:"mem (add h k v) k  = true"
      [ headers_gen; header_name_gen; word_gen ] (fun h k v ->
        check_eq true H.(mem (add h k v) k));
    add_test
    (* FS *)
    (* forall h, k, v. to_list (add h k v) = to_list h @ [lowercase k, v] *)
      ~name:"[add] adds a value at the header end"
      [ headers_gen; header_name_gen; word_gen ] (fun h k v ->
        check_eq (H.to_list h @ [ (k, v) ]) H.(to_list (add h k v))))

let to_list_of_list_test () =
  Crowbar.(
    (* FS *)
    (* forall h. to_list (of_list h) = h (with lowercase key comparison) *)
    add_test ~name:"to_list (of_list h) = h" [ header_list_gen ] (fun h ->
        check_eq ~eq:eqssl H.(to_list (of_list h)) h);

    (* FS and RFC *)
    (* forall h, k1, v1, k2, v2. to_list (add (add h k1 v1) k2 v2) = to_list \
       h @ [k1, v1; k2, v2] *)
    add_test ~name:"checking [to_list] order after multiple [add] calls"
      [ headers_gen; header_name_gen; word_gen; header_name_gen; word_gen ]
      (fun h k1 v1 k2 v2 ->
        check_eq ~eq:eqssl
          H.(to_list (add (add h k1 v1) k2 v2))
          H.(to_list h @ [ (k1, v1); (k2, v2) ])))

let add_opt_test () =
  Crowbar.(
    (* FS *)
    (* forall hopt, k, v.
              add_opt hopt k v = | add h k v     if hopt = Some h
                                 | init_with k v if hopt = None *)
    add_test ~name:"add_opt (Some h) = add and add_opt None = init_with"
      [ option headers_gen; header_name_gen; word_gen ]
      (fun hopt k v ->
        check_eq
          H.(match hopt with None -> init_with k v | Some h -> add h k v)
          H.(add_opt hopt k v)))

let add_unless_exists_test () =
  Crowbar.(
    (* FS *)
    (* forall h, k, v. if mem h k = true then add_unless_exists h k v = h *)
    add_test ~name:"[add_unless_exists h k v] does nothing if k exists"
      [ headers_gen; header_list_gen; header_name_gen; word_gen; word_gen ]
      (fun h l k v1 v2 ->
        (* A random header such as mem h k = true *)
        let h = H.(add_list (add h k v1) l) in
        check_eq H.(add_unless_exists h k v2) h);
    (* FS *)
    (* forall h, k, v. if mem h k = false then add_unless_exists h k v = add \
         h k v *)
    add_test ~name:"add_unless_exists = add if key does not exist"
      [ headers_gen; header_name_gen; word_gen ] (fun h k v ->
        (* Making sure as mem h k = false *)
        guard (not (H.mem h k));
        check_eq H.(add_unless_exists h k v) H.(add h k v)))

let add_list () =
  Crowbar.(
    (* FS *)
    (* forall h, l. to_list (add_list h l) = to_list h @ l *)
    add_test
      ~name:"[add_list h l] adds all headers in [l] in order at the end of [h]"
      [ headers_gen; header_list_gen ] (fun h l ->
        check_eq ~eq:eqssl H.(to_list (add_list h l)) H.(to_list h @ l)))

let add_multi () =
  Crowbar.(
    (* FS *)
    (* forall h, k, vs. add_multi h k vs = add_list h (List.map (fun v -> k, v) vs) *)
    add_test ~name:"[add_list] and [add_multi] have compatible semantics"
      [ headers_gen; header_name_gen; list word_gen ]
      (fun h k vs ->
        check_eq
          H.(add_multi h k vs)
          H.(add_list h (List.map (fun v -> (k, v)) vs)));
    (* FS *)
    (* forall h, k, l. get_multi (add_multi h k l) k = get_multi h k @ l *)
    add_test ~name:"get_multi (add_multi h k l) k = get_multi h k @ l"
      [ headers_gen; header_name_gen; Crowbar.list word_gen ]
      (fun h k l ->
        check_eq H.(get_multi (add_multi h k l) k) H.(get_multi h k @ l)))

let get_test () =
  Crowbar.(
    (* FS *)
    (* forall h k, if mem h k = false then get h k = None *)
    add_test ~name:"[get h k] returns None if k does not exists in h"
      [ headers_gen; header_name_gen ] (fun h k ->
        guard H.(not (mem h k));
        check_eq H.(get h k) None);
    (* FS *)
    (* forall h k, get (add h k v) = Some v *)
    add_test ~name:"get (add h k v) = Some v"
      [ headers_gen; header_name_gen; word_gen ] (fun h k v ->
        check_eq H.(get (add h k v) k) (Some v)))

let get_multi_test () =
  Crowbar.(
    (* FS *)
    (* forall h k, if mem h k = false then get_multi h k = [] *)
    add_test ~name:"[get_multi h k] returns [] if k does not exists in h"
      [ headers_gen; header_name_gen ] (fun h k ->
        guard H.(not (mem h k));
        check_eq H.(get_multi h k) []);
    (* FS *)
    (* forall l1, l2, k, v.
          get_multi (of_list (l1 @ [ (k, v) ] @ l2)) k =
          get_multi (of_list l1) k @ [ v ] @ get_multi (of_list l2) k *)
    add_test ~name:"[get_multi] returns values in transmission order"
      [ header_list_gen; header_list_gen; header_name_gen; word_gen ]
      (fun l1 l2 k v ->
        check_eq
          H.(get_multi (of_list (l1 @ [ (k, v) ] @ l2)) k)
          H.(get_multi (of_list l1) k @ [ v ] @ get_multi (of_list l2) k));
    (* FS and RFC7230§3.2.2 *)
    (* forall h, v1, v2, forall k in list values headers.
            get_multi (add (add h k v1) k v2)) k = get_multi h k @ [v1; v2] *)
    add_test ~name:"headers order is preserved"
      [ headers_gen; list_value_header_gen; word_gen; word_gen ]
      (fun h k v1 v2 ->
        check_eq
          H.(get_multi (add (add h k v1) k v2) k)
          (H.(get_multi h k) @ [ v1; v2 ])))

let remove_test () =
  Crowbar.(
    (* FS *)
    (* forall h, k. mem (remove h k) k = false *)
    add_test ~name:"[remove] removes all values associated to a key"
      [ headers_gen; header_name_gen ] (fun h k ->
        check_eq false H.(mem (remove h k) k));
    (* FS *)
    (* forall h, k. remove (remove h k) k = remove h k*)
    add_test ~name:"(fun x -> remove x k) is idempotent"
      [ headers_gen; header_name_gen ] (fun h k ->
        check_eq H.(remove (remove h k) k) H.(remove h k)))

let replace_test () =
  Crowbar.(
    (* FS *)
    (* forall h, k, v. get_multi (replace h k v) = [ v ] *)
    add_test ~name:"[replace] replaces the last value and remove the others"
      [ headers_gen; header_list_gen; header_name_gen; word_gen; word_gen ]
      (fun h l k v1 v2 ->
        check_eq H.(get_multi (replace h k v1) k) [ v1 ];
        (* This second check is to make sure the case where mem h k = true is tested *)
        let h =
          H.(add_list (add h k v1) l)
          (* h is built such as mem h k = true *)
        in
        check_eq H.(get_multi (replace h k v2) k) [ v2 ]);
    (* FS *)
    (* forall h, k, v. if mem h k = false then replace h k v = add h k v) *)
    add_test ~name:"replace h k v = add h k v if k does not exists in h"
      [ headers_gen; header_name_gen; word_gen ] (fun h k v ->
        guard H.(mem h k = false);
        check_eq H.(replace h k v) H.(add h k v));
    (* SI *)
    (* forall h, l, k, v1, v2.
           if mem (of_list l) k = false then
              replace (add_list h ([ k, v1 ] @ l)) k v2 =
             add_list (add (remove h k) k v2) l k) *)
    add_test ~name:"[replace] does not change headers order"
      [ headers_gen; header_list_gen; header_name_gen; word_gen; word_gen ]
      (fun h l k v1 v2 ->
        guard H.(not (mem (of_list l) k));
        (* A random headers such as mem h k = true *)
        let h1 = H.(add_list h ([ (k, v1) ] @ l)) in
        let h2 = H.(add_list (remove h k) ([ (k, v2) ] @ l)) in
        check_eq ~eq:eqssl H.(to_list (replace h1 k v2)) H.(to_list h2)))

let update_test () =
  Crowbar.(
    (* FS *)
    (* forall h k, update h k id = h  *)
    add_test ~name:"[update h k id] does nothing"
      [ headers_gen; header_name_gen ] (fun h k ->
        check_eq H.(update h k (fun x -> x)) h);
    (*FS*)
    (* forall h k f, remove (update h k f) k = remove h k *)
    add_test ~name:"[update h k _] only changes k "
      [ headers_gen; header_name_gen; word_gen ] (fun h k w ->
        check_eq H.(remove (update h k (fun _ -> None)) k) H.(remove h k);
        check_eq H.(remove (update h k (fun _ -> Some w)) k) H.(remove h k));
    (*FS*)
    add_test ~name:"[update h k (fun _ -> None)] removes last occurence of k."
      [ headers_gen; header_name_gen ] (fun h k ->
        let h1 = H.update h k (fun _ -> None) in
        let r1 = H.get_multi h1 k in
        let r2 =
          match List.rev (H.get_multi h k) with
          | [] -> []
          | _ :: xs -> List.rev xs
        in
        check_eq r1 r2);
    (*FS*)
    add_test
      ~name:
        "[update h k (function Some _ -> Some w)] replaces last occurence of k."
      [ headers_gen; header_name_gen; word_gen ] (fun h k w ->
        let h1 = H.update h k (fun _ -> Some w) in
        let r1 = H.get_multi h1 k in
        let r2 =
          match List.rev (H.get_multi h k) with
          | [] -> [ w ]
          | _ :: xs -> List.rev (w :: xs)
        in
        check_eq r1 r2))

let update_all_test () =
  Crowbar.(
    (* FS *)
    (* forall h k, update_all h k id = h  *)
    add_test ~name:"[update_all h k id] does nothing"
      [ headers_gen; header_name_gen ] (fun h k ->
        check_eq H.(update_all h k (fun x -> x)) h);
    (*FS*)
    (* forall h k f, remove (update_all h k f) k = remove h k *)
    add_test ~name:"[update_all h k _] only changes k "
      [ headers_gen; header_name_gen; word_gen ] (fun h k w ->
        check_eq H.(remove (update_all h k (fun _ -> [])) k) H.(remove h k);
        check_eq H.(remove (update_all h k (fun _ -> [ w ])) k) H.(remove h k));
    (*FS*)
    add_test ~name:"[update_all h k (fun _ -> [])] removes all occurences of k."
      [ headers_gen; header_name_gen ] (fun h k ->
        let h1 = H.update_all h k (fun _ -> []) in
        check_eq H.(get_multi h1 k) []);
    (*FS*)
    add_test
      ~name:
        "[update_all h k (function _ -> [w])] removes all occurences of k and \
         adds w." [ headers_gen; header_name_gen; word_gen ] (fun h k w ->
        let h1 = H.update_all h k (fun _ -> [ w ]) in
        let r1 = H.get_multi h1 k in
        let r2 = [ w ] in
        check_eq r1 r2))

let get_multi_concat_test () =
  Crowbar.(
    (* FS *)
    (* forall h, k. if mem h k = false then get_multi_concat h k = None *)
    add_test
      ~name:"[get_multi_concat h k] returns \"\" if k does not exists in h"
      [ headers_gen; header_name_gen ] (fun h k ->
        guard H.(not (mem h k));
        check_eq H.(get_multi_concat h k) None);
    (* FS *)
    (* forall h, k. get_multi_concat ~list_value_only:true h k = get h k
       if k is not a list value header *)
    add_test ~name:"[get_multi_concat] optional argument works properly"
      [ headers_gen; word_gen ] (fun h k ->
        guard (not (Array.mem (String.lowercase_ascii k) list_value_headers));
        check_eq H.(get_multi_concat ~list_value_only:true h k) H.(get h k));
    (* FS - Very important for RFC 7230.3.2.2 *)
    add_test ~name:"[get_multi_concat] returns values in transmission order"
      [ header_list_gen; header_list_gen; header_name_gen; word_gen ]
      (fun l1 l2 k v ->
        let str_opt ?(bfr = false) ?(aft = false) s =
          match s with
          | None -> ""
          | Some v -> if bfr then "," ^ v else if aft then v ^ "," else v
        in
        check_eq
          H.(str_opt (get_multi_concat (of_list (l1 @ [ (k, v) ] @ l2)) k))
          H.(
            str_opt ~aft:true (get_multi_concat (of_list l1) k)
            ^ v
            ^ str_opt ~bfr:true (get_multi_concat (of_list l2) k))))

(* Note : clean_dup does nothing to already concatenated headers. For
   example, ["a", "v1,v2"] will be not be cleaned. *)
let clean_dup_test () =
  Crowbar.(
    (* FS *)
    (* Check that there is no more duplicates (except set-cookie). *)
    add_test
      ~name:
        "All headers name in [h] appears strictly once in [clean_dup h] except \
         for [set-cookie]" [ headers_gen ] (fun h ->
        let h = H.remove h "set-cookie" in
        let h = H.(to_list (clean_dup h)) in
        let compare_key (k, _) (k', _) = compare k k' in
        check_eq (List.sort_uniq compare_key h) (List.sort compare_key h));
    (* FS *)
    (* forall h, k in list_value_headers.
       String.concat "," (get_multi_concat h k) = get (clean_dup h) k *)
    add_test ~name:"[clean_dup] concatenates properly list-value headers"
      [ headers_gen; list_value_header_gen ] (fun h k ->
        check_eq H.(get_multi_concat h k) H.(get (clean_dup h) k));
    (* FS *)
    (* forall h. clean_dup (clean_dup h) = clean_dup h *)
    add_test ~name:"[clean_dup] is idempotent" [ headers_gen ] (fun h ->
        check_eq H.(clean_dup (clean_dup h)) H.(clean_dup h));
    (* FS *)
    (* forall h. get_multi (clean_dup h) "set-cookie" = get_multi h "set-cookie"*)
    add_test ~name:"[clean_dup] does nothing to [set-cookie] headers"
      [ headers_gen ] (fun h ->
        check_eq
          H.(get_multi h "set-cookie")
          H.(get_multi (clean_dup h) "set-cookie"));
    (* FS *)
    (* As the generated header values are only composed of tchar (it
       does not generate concatenated values like "gzip,chunked"), the
       only cases where there are commas in a value is if [clean_dup]
       concatenated multiple values.

       This test checks that only one value is kept for non-list-value
       headers and that this value is the last one. *)
    add_test
      ~name:"Only list-value headers can have multiple concatenated values "
      [ headers_gen ] (fun h ->
        (* As it is an exception, [set-cookie] is removed. *)
        let h = H.remove h "set-cookie" in
        let h' = H.(clean_dup h) in
        let has_multiple_values v =
          match String.split_on_char ',' v with
          | [] | [ _ ] -> false
          | _ -> true
        in
        check_eq true
          H.(
            fold
              (fun k v b ->
                if Array.mem k list_value_headers then b
                else if has_multiple_values v then false
                else b && get h k = Some v)
              h' true)))

let () =
  init_with_test ();
  is_empty_test ();
  mem_test ();
  add_test ();
  to_list_of_list_test ();
  add_opt_test ();
  add_unless_exists_test ();
  add_list ();
  add_multi ();
  get_test ();
  get_multi_test ();
  get_multi_concat_test ();
  remove_test ();
  replace_test ();
  update_test ();
  update_all_test ();
  clean_dup_test ();
  ()
