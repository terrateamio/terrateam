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

type t = {
  scheme: string option;
  userinfo: string option;
  host: string option;
  port: int option;
  path: string;
  query: string option;
  fragment: string option;
}  

type safe_chars = bool array

(** Safe characters that are always allowed in a URI *)
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

(* An alias just as a hint *)
type pct_encoded = string

(** Scan for reserved characters and replace them with 
    percent-encoded equivalents.
    @return a percent-encoded string *)
let pct_encode ?(safe_chars = safe_chars_for_path) b : pct_encoded =
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
let pct_decode (b:pct_encoded) =
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

(** Parse a URI string into a structure *)
let of_string s =
  let get_opt s n =
    try Some (pct_decode (Re.get s n))
    with Not_found -> None
  in
  let subs = Re.exec Uri_re.uri_reference s in 
  let scheme = get_opt subs 2 in
  let userinfo, host, port =
    match get_opt subs 4 with
    |None -> None, None, None
    |Some a ->
       let subs' = Re.exec Uri_re.authority a in
       let userinfo = get_opt subs' 1 in 
       let host = get_opt subs' 2 in
       let port =
         match get_opt subs' 3 with
         |None -> None
         |Some x -> (try Some (int_of_string x) with _ -> None)
       in
       userinfo, host, port
  in
  let path = try pct_decode (Re.get subs 5) with Not_found -> "" in
  let query = get_opt subs 7 in
  let fragment  = get_opt subs 9 in
  { scheme; userinfo; host; port; path; query; fragment }

(** Convert a URI structure into a percent-encoded string *)
let to_string uri = 
  let buf = Buffer.create 128 in
  let add_pct_string x = Buffer.add_string buf (pct_encode ~safe_chars x) in
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
          Buffer.add_string buf (pct_encode ~safe_chars:safe_chars_for_userinfo userinfo);
          Buffer.add_char buf '@'
      );
      Buffer.add_string buf (pct_encode ~safe_chars host);
      (match uri.port with
       |None -> ()
       |Some port ->
         Buffer.add_char buf ':';
         Buffer.add_string buf (string_of_int port)
      );
   |None -> ()
  );
  (match uri.path with 
   |"" ->
      (* If the buffer has no host, then always start URI with a slash *)
      if uri.host = None then Buffer.add_char buf '/'
   |path when path.[0] = '/' -> 
      (* Path starts with a slash, so ok to add *)
      Buffer.add_string buf (pct_encode ~safe_chars:safe_chars_for_path uri.path);  
   |path ->
      (* Path has no starting slash and is non-empty, so force a starting slash *)
      Buffer.add_char buf '/';
      Buffer.add_string buf (pct_encode ~safe_chars:safe_chars_for_path uri.path);
  );
  (match uri.query with
   |None -> ()
   |Some q -> Buffer.(add_char buf '?'; add_string buf q)
  );
  (match uri.fragment with
   |None -> ()
   |Some f -> Buffer.(add_char buf '#'; add_string buf f)
  );
  Buffer.contents buf

(** Regular expression to separate out the query string components *)
let query_re = Re_str.regexp "[&=]"

(** Replace a + in a query string with a space in-place *)
let plus_to_space s =
  for i = 0 to String.length s - 1 do
    if s.[i] = '+' then s.[i] <- ' '
  done; 
  s

(** Parse a query string into a list of key/value pairs *)
let parse_query qs =
    let bits = Re_str.split query_re qs in
    let rec loop acc = function
      | k::v::tl ->
          let acc = (plus_to_space k, plus_to_space v)::acc in
          loop acc tl
      | [k] -> List.rev ((k,"") :: acc)
      |_ -> List.rev acc in
    loop [] bits

(* Get a query string from a URI *)
let query uri =
  match uri.query with
  |None -> []
  |Some q -> parse_query q

(* Assemble a query string suitable for putting into a URI *)
let make_query l =
  let len = List.fold_left (fun a (k,v) -> 
    a + (String.length k) + (String.length v) + 2) (-1) l in
  let buf = Buffer.create len in
  let n = ref 0 in
  let len = List.length l in
  List.iter (fun (k,v) ->
    incr n;
    Buffer.add_string buf k;
    Buffer.add_char buf '=';
    Buffer.add_string buf v;
    if !n < len then
      Buffer.add_char buf '&';
  ) l;
  Buffer.contents buf

(* Return the path component, which is either relative and non-empty,
   or an absolute path.
   TODO: strip out ../. for normalisation *)
let path uri =
  match uri.path with
  |"" -> "/"
  |p -> p
