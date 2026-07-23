(*{{{ Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2011-2012 Martin Jambon <martin@mjambon.com>
 * Copyright (c) 2010 Mika Illouz
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

let caseless_equal a b =
  if a == b then true
  else
    let len = String.length a in
    len = String.length b
    &&
    let stop = ref false in
    let idx = ref 0 in
    while (not !stop) && !idx < len do
      let c1 = String.unsafe_get a !idx in
      let c2 = String.unsafe_get b !idx in
      if Char.lowercase_ascii c1 <> Char.lowercase_ascii c2 then stop := true;
      incr idx
    done;
    not !stop

type t = (string * string) list

let compare = Stdlib.compare
let init () = []
let is_empty = function [] -> true | _ -> false
let init_with k v = [ (k, v) ]

let mem h k =
  let rec loop = function
    | [] -> false
    | (k', _) :: h' -> if caseless_equal k k' then true else loop h'
  in
  loop h

let add h k v : t = (k, v) :: h
let add_list h l = List.fold_left (fun h (k, v) -> add h k v) h l
let add_multi h k l = List.fold_left (fun h v -> add h k v) h l

let add_opt h_opt k v =
  match h_opt with None -> init_with k v | Some h -> add h k v

let add_unless_exists h k v = if mem h k then h else add h k v

let add_opt_unless_exists h k v =
  match h with None -> init_with k v | Some h -> add_unless_exists h k v

let get h k =
  let rec loop h =
    match h with
    | [] -> None
    | (k', v) :: h' -> if caseless_equal k k' then Some v else loop h'
  in
  loop h

let get_multi (h : t) (k : string) =
  let rec loop h acc =
    match h with
    | [] -> acc
    | (k', v) :: h' ->
        if caseless_equal k k' then loop h' (v :: acc) else loop h' acc
  in
  loop h []

let remove h k =
  let rec loop seen = function
    | [] -> if seen then [] else raise Not_found
    | (k', _) :: h when caseless_equal k k' -> loop true h
    | x :: h -> x :: loop seen h
  in
  try loop false h with Not_found -> h

let remove_last h k =
  let rec loop seen = function
    | [] -> raise Not_found
    | (k', _) :: h when caseless_equal k k' -> h
    | x :: h -> x :: loop seen h
  in
  try loop false h with Not_found -> h

let replace_ last h k v =
  let rec loop seen = function
    | [] -> if seen then [] else raise Not_found
    | (k'', _) :: h when caseless_equal k k'' ->
        if last then (k'', v) :: h
        else if not seen then (k, v) :: loop true h
        else loop seen h
    | x :: h -> x :: loop seen h
  in
  try loop false h with Not_found -> add h k v

let replace = replace_ false

let update h k f =
  let vorig = get h k in
  match (f vorig, vorig) with
  | None, None -> h
  | None, _ -> remove_last h k
  | Some s, Some s' when s == s' -> h
  | Some s, _ -> replace_ true h k s

let update_all h k f =
  let vorig = get_multi h k in
  match (f vorig, vorig) with
  | [], [] -> h
  | [], _ -> remove h k
  | xs, xs' when xs = xs' -> h
  | xs, _ ->
      let h = remove h k in
      add_multi h k xs

let map (f : string -> string -> string) (h : t) : t =
  List.map
    (fun (k, v) ->
      let vs' = f k v in
      (k, vs'))
    h

let iter (f : string -> string -> unit) (h : t) : unit =
  List.iter (fun (k, v) -> f k v) h

let fold (f : string -> string -> 'a -> 'a) (h : t) (init : 'a) : 'a =
  List.fold_left (fun acc (k, v) -> f k v acc) init h

let of_list h = List.rev h
let to_list h = List.rev h

let to_lines (h : t) =
  let header_line k v = Printf.sprintf "%s: %s\r\n" k v in
  List.fold_left (fun acc (k, v) -> header_line k v :: acc) [] h

let to_frames h =
  let to_frame k v = Printf.sprintf "%s: %s" k v in
  List.fold_left (fun acc (k, v) -> to_frame k v :: acc) [] h

let to_string h =
  let b = Buffer.create 128 in
  to_list h
  |> List.iter (fun (k, v) ->
         Buffer.add_string b k;
         Buffer.add_string b ": ";
         Buffer.add_string b v;
         Buffer.add_string b "\r\n");
  Buffer.add_string b "\r\n";
  Buffer.contents b

let headers_with_list_values =
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

let is_header_with_list_value =
  let tbl = Hashtbl.create (Array.length headers_with_list_values) in
  headers_with_list_values |> Array.iter (fun h -> Hashtbl.add tbl h ());
  fun h -> Hashtbl.mem tbl h

let is_set_cookie k = caseless_equal k "set-cookie"

(* set-cookie is an exception according to
   {{:https://tools.ietf.org/html/rfc7230#section-3.2.2}
    RFC7230§3.2.2} and can appear multiple times in a response message.
*)
let clean_dup (h : t) : t =
  let add h k v =
    if is_set_cookie k then (k, v) :: h
    else
      let to_add = ref false in
      let rec loop = function
        | [] ->
            to_add := true;
            []
        | (k', v') :: hs ->
            if caseless_equal k k' then
              if is_header_with_list_value k then (k, v' ^ "," ^ v) :: hs
              else (
                to_add := true;
                hs)
            else (k', v') :: loop hs
      in
      let h = loop h in
      if !to_add then (k, v) :: h else h
  in
  List.rev h |> List.fold_left (fun acc (k, v) -> add acc k v) []

let get_multi_concat ?(list_value_only = false) h k : string option =
  if (not list_value_only) || is_header_with_list_value k then
    let vs = get_multi h k in
    match vs with [] -> None | _ -> Some (String.concat "," vs)
  else get h k

let parse_content_range s =
  try
    let start, fini, total =
      Scanf.sscanf s "bytes %Ld-%Ld/%Ld" (fun start fini total ->
          (start, fini, total))
    in
    Some (start, fini, total)
  with Scanf.Scan_failure _ -> None

(* If we see a "Content-Range" header, than we should limit the
   number of bytes we attempt to read *)
let get_content_range headers =
  match get headers "content-length" with
  | Some clen -> ( try Some (Int64.of_string clen) with _ -> None)
  | None -> (
      match get headers "content-range" with
      | Some range_s -> (
          match parse_content_range range_s with
          | Some (start, fini, total) ->
              (* some sanity checking before we act on these values *)
              if fini < total && start <= total && 0L <= start && 0L <= total
              then
                let num_bytes_to_read = Int64.add (Int64.sub fini start) 1L in
                Some num_bytes_to_read
              else None
          | None -> None)
      | None -> None)

let get_connection_close headers =
  match get headers "connection" with Some "close" -> true | _ -> false

let media_type_re =
  let re = Re.Emacs.re ~case:true "[ \t]*\\([^ \t;]+\\)" in
  Re.(compile (seq [ start; re ]))

let get_first_match _re s =
  try
    let subs = Re.exec ~pos:0 media_type_re s in
    let start, stop = Re.Group.offset subs 1 in
    Some (String.sub s start (stop - start))
  with Not_found -> None

(* Grab "foo/bar" from " foo/bar ; charset=UTF-8" *)
let get_media_type headers =
  match get headers "content-type" with
  | Some s -> get_first_match media_type_re s
  | None -> None

let get_acceptable_media_ranges headers =
  Accept.media_ranges (get_multi_concat ~list_value_only:true headers "accept")

let get_acceptable_charsets headers =
  Accept.charsets
    (get_multi_concat ~list_value_only:true headers "accept-charset")

let get_acceptable_encodings headers =
  Accept.encodings
    (get_multi_concat ~list_value_only:true headers "accept-encoding")

let get_acceptable_languages headers =
  Accept.languages
    (get_multi_concat ~list_value_only:true headers "accept-language")

(* Parse the transfer-encoding and content-length headers to
 * determine how to decode a body *)
let get_transfer_encoding headers =
  (* It should actually be [get] as the interresting value is actually the last.*)
  match get_multi_concat ~list_value_only:true headers "transfer-encoding" with
  | Some "chunked" -> Transfer.Chunked
  | Some _ | None -> (
      match get_content_range headers with
      | Some len -> Transfer.Fixed len
      | None -> Transfer.Unknown)

let add_transfer_encoding headers enc =
  let open Transfer in
  (* Only add a header if one doesnt already exist, e.g. from the app *)
  match (get_transfer_encoding headers, enc) with
  | Fixed _, _ (* App has supplied a content length, so use that *) | Chunked, _
    ->
      headers (* TODO: this is a protocol violation *)
  | Unknown, Chunked -> add headers "transfer-encoding" "chunked"
  | Unknown, Fixed len -> add headers "content-length" (Int64.to_string len)
  | Unknown, Unknown -> headers

let add_authorization_req headers challenge =
  add headers "www-authenticate" (Auth.string_of_challenge challenge)

let add_authorization headers cred =
  add headers "authorization" (Auth.string_of_credential cred)

let get_authorization headers =
  match get headers "authorization" with
  | None -> None
  | Some v -> Some (Auth.credential_of_string v)

let is_form headers =
  get_media_type headers = Some "application/x-www-form-urlencoded"

let get_location headers =
  match get headers "location" with
  | None -> None
  | Some u -> Some (Uri.of_string u)

let get_links headers =
  List.rev
    (List.fold_left
       (fun list link_s -> List.rev_append (Link.of_string link_s) list)
       [] (get_multi headers "link"))

let add_links headers links =
  add_multi headers "link" (List.map Link.to_string links)

let user_agent = Printf.sprintf "ocaml-cohttp/%s" Conf.version

let prepend_user_agent headers user_agent =
  let k = "user-agent" in
  match get headers k with
  | Some ua -> replace headers k (user_agent ^ " " ^ ua)
  | None -> add headers k user_agent

let connection h =
  match get h "connection" with
  | Some v when v = "keep-alive" -> Some `Keep_alive
  | Some v when v = "close" -> Some `Close
  | Some x -> Some (`Unknown x)
  | _ -> None

open Sexplib0.Sexp_conv

let sexp_of_t t =
  sexp_of_list (sexp_of_pair sexp_of_string sexp_of_string) (to_list t)

let t_of_sexp s =
  of_list (list_of_sexp (pair_of_sexp string_of_sexp string_of_sexp) s)

let pp_hum ppf h =
  Format.fprintf ppf "%s" (h |> sexp_of_t |> Sexplib0.Sexp.to_string_hum)
