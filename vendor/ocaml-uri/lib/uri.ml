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

let get_opt s n =
  try Some (Re.get s n)
  with Not_found -> None

let safe_chars = 
  let a = Array.create 256 false in
  let always_safe =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-" in
   for i = 0 to String.length always_safe do
     a.(Char.code always_safe.[i]) <- true
   done;
   a

(** Scan for reserved characters and replace them with 
    percent-encoded equivalents.
    @return a percent-encoded string *)
let urlencode b =
  let len = String.length b in
  let buf = Buffer.create len in
  let rec scan start cur =
    if cur >= len then begin
      Buffer.add_substring buf b start (cur-start);
    end else begin
      match Char.code b.[cur] with
      |_ -> ()
    end
  in
  ()

(** Scan for percent-encoding and convert them into ASCII.
    @return a percent-decoded string *)
let urldecode b =
  let len = String.length b in
  let buf = Buffer.create len in
  let rec scan start cur =
    if cur >= len then begin
      Buffer.add_substring buf b start (cur-start);
    end else begin
      if b.[cur] = '%' then begin
        Buffer.add_substring buf b start (cur-start);
        Buffer.add_char buf (Char.chr (int_of_string (String.sub b (cur+1) 2)));
        scan (cur+2) (cur+2)
      end else begin
        scan start (cur+1)
      end
    end
  in
  scan 0 0;
  Buffer.contents buf

let of_string s =
  let subs = Re.exec Uri_re.uri_reference s in 
  let scheme = get_opt subs 2 in
  let userinfo, host, port =
    match get_opt subs 4 with
    |None -> 
       None, None, None
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
  let path = try Re.get subs 5 with Not_found -> "" in
  let query = get_opt subs 7 in
  let fragment  = get_opt subs 9 in
  { scheme; userinfo; host; port; path; query; fragment }

let to_string uri = 
  let buf = Buffer.create 128 in
  (match uri.scheme with
   |None -> ()
   |Some x -> Buffer.(add_string buf x; add_char buf ':')
  );
  (match uri.host with
   |Some host ->
      Buffer.add_string buf "//";
      (match uri.userinfo with
       |None -> ()
       |Some userinfo ->
          Buffer.add_string buf userinfo;
          Buffer.add_char buf ':'
      );
      Buffer.add_string buf host;
      (match uri.port with
       |None -> ()
       |Some port ->
         Buffer.add_char buf ':';
         Buffer.add_string buf (string_of_int port)
      );
      Buffer.add_char buf '/'
   |None -> ()
  );
  Buffer.add_string buf uri.path;
  (match uri.query with
   |None -> ()
   |Some q -> Buffer.(add_char buf '?'; add_string buf q)
  );
  (match uri.fragment with
   |None -> ()
   |Some f -> Buffer.(add_char buf '#'; add_string buf f)
  );
  Buffer.contents buf
