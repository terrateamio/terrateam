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

(** Safe characters that are always allowed in a URI 
  * Unfortunately, this varies depending on which bit of the URI
  * is being parsed, so there are multiple variants (and this
  * set is probably not exhaustive. TODO: check.
  *)
type safe_chars = bool array

let safe_chars : safe_chars = 
  let a = Array.create 256 false in
  let always_safe =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-" in
   for i = 0 to String.length always_safe - 1 do
     let c = Char.code always_safe.[i] in
     a.(c) <- true
   done;
   a

(** Safe characters for the path portion of a URI *)
let safe_chars_for_path : safe_chars =
  let a = Array.copy safe_chars in
  a.(Char.code '/') <- true;
  a

(** Safe characters for the userinfo portion of a URI.
    TODO: this needs more reserved characters added *)
let safe_chars_for_userinfo : safe_chars =
  let a = Array.copy safe_chars in
  a.(Char.code ':') <- true;
  a

(** Portions of the URL must be converted to-and-from percent-encoding
  * and this really, really shouldn't be mixed up. So this Pct module
  * defines abstract Pct.encoded and Pct.decoded types which sets the
  * state of the underlying string.  There are functions to "cast" to
  * and from these and normal strings, and this promotes a bit of 
  * internal safety.  These types are not exposed to the external 
  * interface, as casting to-and-from is quite a bit of hassle and
  * probably not a lot of use to the average consumer of this library 
  *)
module Pct : sig
  type encoded
  type decoded

  val encode : ?safe_chars:safe_chars -> decoded -> encoded
  val decode : encoded -> decoded

  (* The empty decoded string *)
  val empty_decoded : decoded
  (* Identity functions so we need to explicitly cast when using them below *)
  val cast_encoded : string -> encoded
  val cast_decoded : string -> decoded
  val uncast_encoded : encoded -> string
  val uncast_decoded : decoded -> string
end = struct
  type encoded = string
  type decoded = string
  let cast_encoded x = x
  let cast_decoded x = x
  let empty_decoded = ""
  let uncast_decoded x = x
  let uncast_encoded x = x

  (** Scan for reserved characters and replace them with 
      percent-encoded equivalents.
      @return a percent-encoded string *)
  let encode ?(safe_chars=safe_chars_for_path) b =
    let len = String.length b in
    let buf = Buffer.create len in
    let rec scan start cur =
      if cur >= len then begin
        Buffer.add_substring buf b start (cur-start);
      end else begin
        let c = Char.code b.[cur] in
        if safe_chars.(c) then
          scan start (cur+1)
        else begin
          if cur > start then Buffer.add_substring buf b start (cur-start);
          Buffer.add_string buf (Printf.sprintf "%%%2X" c);
          scan (cur+1) (cur+1)
        end
      end
    in
    scan 0 0;
    Buffer.contents buf

  (** Scan for percent-encoding and convert them into ASCII.
      @return a percent-decoded string *)
  let decode b = 
    let len = String.length b in
    let buf = Buffer.create len in
    let rec scan start cur =
      if cur >= len then begin
        Buffer.add_substring buf b start (cur-start);
      end else begin
        if b.[cur] = '%' then begin
          Buffer.add_substring buf b start (cur-start);
          let c = Scanf.sscanf (String.sub b (cur+1) 2 ^ " ") "%2x" (fun x -> x) in
          Buffer.add_char buf (Char.chr c);
          scan (cur+3) (cur+3)
        end else begin
          scan start (cur+1)
        end
      end
    in
    scan 0 0;
    Buffer.contents buf
end

(* Percent encode a string *)
let pct_encode ?safe_chars s = Pct.(uncast_encoded (encode ?safe_chars (cast_decoded s)))

(* Percent decode a string *)
let pct_decode s = Pct.(uncast_decoded (decode (cast_encoded s)))

(* Query string handling, to and from an assoc list of key/values *)
module Query = struct

  type t = (string * string) list

  (** Regular expression to separate out the query string components *)
  let query_re = Re_str.regexp "[&=]"

  (* TODO: only make the query tuple parsing lazy and an additional
   * record in Url.t ?  *)

  (* Make a query tuple list from a percent-decoded string *)
  let query_of_decoded qs =
    let bits = Re_str.split query_re qs in
    (** Replace a + in a query string with a space in-place *)
    let plus_to_space s =
      for i = 0 to String.length s - 1 do
        if s.[i] = '+' then s.[i] <- ' '
      done; 
      s
    in
    let rec loop acc = function
    | k::v::tl ->
        let n = plus_to_space k, plus_to_space v in
        loop (n::acc) tl
    | [k] ->
        let n = k, "" in
        List.rev (n::acc)
    |_ -> List.rev acc in
    loop [] bits

  (* Make a query tuple list from a percent-encoded string *)
  let query_of_encoded qs = query_of_decoded (pct_decode qs)

  (* Assemble a query string suitable for putting into a URI.
   * Tuple inputs are percent decoded and will be encoded by
   * this function.
   *)
  let encoded_of_query l =
    let len = List.fold_left (fun a (k,v) ->
      a + (String.length k) + (String.length v) + 2) (-1) l in
    let buf = Buffer.create len in
    let n = ref 0 in
    let len = List.length l in
    List.iter (fun (k,v) ->
      incr n;
      Buffer.add_string buf (pct_encode k);
      Buffer.add_char buf '=';
      Buffer.add_string buf (pct_encode v);
      if !n < len then
        Buffer.add_char buf '&';
    ) l;
    Buffer.contents buf 
end

let query_of_decoded = Query.query_of_decoded
let query_of_encoded = Query.query_of_encoded
let encoded_of_query = Query.encoded_of_query

(* Type of the URI, with most bits being optional
 *)
type t = {
  scheme: Pct.decoded option;
  userinfo: Pct.decoded option;
  host: Pct.decoded option;
  port: int option;
  path: Pct.decoded;
  query: Query.t;
  fragment: Pct.decoded option;
}  

(* Make a URI record. This is a bit more inefficient than it needs to be due to the
 * casting/uncasting (which isn't fully identity due to the option box), but it is
 * no big deal for now.
 *)
let make ?scheme ?userinfo ?host ?port ?path ?query ?fragment () =
  let decode x = match x with |Some x -> Some (Pct.cast_decoded x) |None -> None in
  let path = match path with |None -> Pct.empty_decoded |Some p -> Pct.cast_decoded p in
  let query = match query with |None -> [] |Some p -> p in
  { scheme=decode scheme; userinfo=decode userinfo; host=decode host;
    port; path; query; fragment=decode fragment }

(** Parse a URI string into a structure *)
let of_string s =
  (* Given a series of Re substrings, cast each component
   * into a Pct.encoded and return an optional type (None if
   * the component is not present in the Uri *)
  let get_opt s n =
    try
      let pct = Pct.cast_encoded (Re.get s n) in
      Some (Pct.decode pct)
    with Not_found -> None
  in
  let subs = Re.exec Uri_re.uri_reference s in 
  let scheme = get_opt subs 2 in
  let userinfo, host, port =
    match get_opt subs 4 with
    |None -> None, None, None
    |Some a ->
       let subs' = Re.exec Uri_re.authority (Pct.uncast_decoded a) in
       let userinfo = get_opt subs' 1 in 
       let host = get_opt subs' 2 in
       let port =
         match get_opt subs' 3 with
         |None -> None
         |Some x -> (try Some (int_of_string (Pct.uncast_decoded x)) with _ -> None)
       in
       userinfo, host, port
  in
  let path =
    match get_opt subs 5 with
    | Some x -> x
    | None -> Pct.empty_decoded 
  in
  let query =
    match get_opt subs 7 with
    | Some x -> Query.query_of_decoded (Pct.uncast_decoded x)
    | None -> []
  in
  let fragment  = get_opt subs 9 in
  { scheme; userinfo; host; port; path; query; fragment }

(** Convert a URI structure into a percent-encoded string *)
let to_string uri = 
  let buf = Buffer.create 128 in
  (* Percent encode a decoded string and add it to the buffer *)
  let add_pct_string ?(safe_chars=safe_chars) x =
    Buffer.add_string buf (Pct.uncast_encoded (Pct.encode ~safe_chars x)) in
  (match uri.scheme with
   |None -> ()
   |Some x ->
      add_pct_string x; 
      Buffer.add_char buf ':' 
  );
  (match uri.host with
   |Some host ->
      Buffer.add_string buf "//";
      (match uri.userinfo with
       |None -> ()
       |Some userinfo ->
          add_pct_string ~safe_chars:safe_chars_for_userinfo userinfo;
          Buffer.add_char buf '@'
      );
      add_pct_string host;
      (match uri.port with
       |None -> ()
       |Some port ->
         Buffer.add_char buf ':';
         Buffer.add_string buf (string_of_int port)
      );
   |None -> ()
  );
  (match Pct.uncast_decoded uri.path with 
   |"" ->
      (* If the buffer has no host, then always start URI with a slash *)
      if uri.host = None then Buffer.add_char buf '/'
   |path when path.[0] = '/' -> 
      (* Path starts with a slash, so ok to add *)
      add_pct_string ~safe_chars:safe_chars_for_path uri.path;
   |path ->
      (* Path has no starting slash and is non-empty, so force a starting slash *)
      Buffer.add_char buf '/';
      add_pct_string ~safe_chars:safe_chars_for_path uri.path;
  );
  (match uri.query with
   |[] -> ()
   |q -> Buffer.(add_char buf '?'; add_string buf (Query.encoded_of_query q))
  );
  (match uri.fragment with
   |None -> ()
   |Some f -> Buffer.(add_char buf '#'; add_pct_string f)
  );
  Buffer.contents buf

(* Return the path component *)
let path uri = Pct.uncast_decoded uri.path

(* Various accessor functions, as the external uri type is abstract  *)
let get_decoded_opt = function None -> None |Some x -> Some (Pct.uncast_decoded x)
let scheme uri = get_decoded_opt uri.scheme
let userinfo uri = get_decoded_opt uri.userinfo
let host uri = get_decoded_opt uri.host
let port uri = uri.port
let fragment uri = get_decoded_opt uri.fragment
let query uri = uri.query
let with_query uri query = { uri with query=query }
let add_query_param uri p = { uri with query=p::uri.query }
let add_query_params uri ps = { uri with query=ps@uri.query }

(* TODO: functions to add and remove from a URI *)

(* Subroutine for resolve <http://tools.ietf.org/html/rfc3986#section-5.2.3> *)
let merge base rpath =
  match host base, path base with
    | Some _, "" -> Pct.cast_decoded ("/"^rpath)
    | _, bpath -> Pct.cast_decoded begin
      try (String.sub bpath 0 (1+(String.rindex bpath '/')))^rpath
      with Not_found -> rpath
    end

(* Subroutine for resolve <http://tools.ietf.org/html/rfc3986#section-5.2.4> *)
let remove_dot_segments p =
  let ascend = function [] -> [] | h::t -> t in
  let p = Pct.uncast_decoded p in
  let inp = Re_str.split_delim (Re_str.regexp "/") p in
  let rec loop outp = function
    | ".."::n::r | "."::n::r -> loop outp (n::r) (* A *)
    | ""::"."::n::r -> loop outp (""::n::r) (* B *)
    | ""::"."::[] -> loop outp ["";""] (* B *)
    | ""::".."::n::r -> loop (ascend outp) (""::n::r) (* C *)
    | ""::".."::[] -> loop (ascend outp) ["";""] (* C *)
    | "."::[] | ".."::[] | [] -> String.concat "/" (List.rev outp) (* D *)
    | ""::s::r -> loop (s::""::outp) r (* E *)
    | s::r -> loop (s::outp) r (* E *)
  in Pct.cast_decoded (loop [] inp)

(* Resolve a URI wrt a base URI <http://tools.ietf.org/html/rfc3986#section-5.2> *)
let resolve schem base uri =
  let base = match scheme base with
    | None -> {base with scheme=Some (Pct.cast_decoded schem)}
    | Some _ -> base
  in match scheme uri, host uri with
    | Some _, _ ->
      {uri with path=remove_dot_segments uri.path}
    | None, Some _ ->
      {uri with scheme=base.scheme; path=remove_dot_segments uri.path}
    | None, None ->
      let uri = {uri with scheme=base.scheme; host=base.host; port=base.port} in
      if (path uri)=""
      then {uri with path=base.path;
        query=if uri.query=[] then base.query else uri.query}
      else if (path uri).[0]='/'
      then {uri with path=remove_dot_segments uri.path}
      else {uri with path=remove_dot_segments (merge base (path uri))}

