(*{{{ Copyright (C) <2012> Anil Madhavapeddy <anil@recoil.org>
 * Copyright (C) <2009> David Sheets <sheets@alum.mit.edu>
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

open Sexplib0.Sexp_conv

type expiration = [ `Session | `Max_age of int64 ] [@@deriving sexp]
type cookie = string * string [@@deriving sexp]

module Set_cookie_hdr = struct
  type t = {
    cookie : cookie;
    expiration : expiration;
    domain : string option;
    path : string option;
    secure : bool;
    http_only : bool;
  }
  [@@deriving sexp]

  let cookie t = t.cookie
  let expiration t = t.expiration
  let domain t = t.domain
  let path t = t.path
  let secure t = t.secure
  let http_only t = t.http_only

  (* Does not check the contents of name or value for ';', ',', '\s', or name[0]='$' *)
  let make ?(expiration = `Session) ?path ?domain ?(secure = false)
      ?(http_only = false) cookie =
    { cookie; expiration; domain; path; secure; http_only }

  (* TODO: deprecated by RFC 6265 and almost certainly buggy without
     reference to cookie field *)
  let serialize_1_1 c =
    let attrs = [ "Version=1" ] in
    let attrs = if c.secure then "Secure" :: attrs else attrs in
    let attrs =
      match c.path with None -> attrs | Some p -> ("Path=" ^ p) :: attrs
    in
    let attrs =
      match c.expiration with
      | `Session -> "Discard" :: attrs
      | `Max_age age -> ("Max-Age=" ^ Int64.to_string age) :: attrs
    in
    let attrs =
      match c.domain with None -> attrs | Some d -> ("Domain=" ^ d) :: attrs
    in
    ("Set-Cookie2", String.concat "; " attrs)

  let serialize_1_0 c =
    let attrs = if c.http_only then [ "httponly" ] else [] in
    let attrs = if c.secure then "secure" :: attrs else attrs in
    let attrs =
      match c.path with None -> attrs | Some p -> ("path=" ^ p) :: attrs
    in
    let attrs =
      match c.domain with None -> attrs | Some d -> ("domain=" ^ d) :: attrs
    in
    let attrs =
      match c.expiration with
      | `Session -> attrs
      | `Max_age age -> ("Max-Age=" ^ Int64.to_string age) :: attrs
    in
    let n, c = c.cookie in
    (* TODO: may be buggy, some UAs will ignore cookie-strings without '='*)
    let attrs = (n ^ match c with "" -> "" | v -> "=" ^ v) :: attrs in
    ("Set-Cookie", String.concat "; " attrs)

  let serialize ?(version = `HTTP_1_0) c =
    match version with
    | `HTTP_1_0 -> serialize_1_0 c
    | `HTTP_1_1 -> serialize_1_1 c

  (* TODO: implement *)
  let extract_1_1 _cstr alist = alist

  let extract_1_0 cstr alist =
    let attrs = Stringext.split_trim_left cstr ~on:",;" ~trim:" \t" in
    let attrs =
      List.map
        (fun attr ->
          match Stringext.split ~on:'=' attr with
          | [] -> ("", "")
          | n :: v -> (n, String.concat "=" v))
        attrs
    in
    try
      let cookie = List.hd attrs in
      let attrs =
        List.map (fun (n, v) -> (String.lowercase_ascii n, v)) (List.tl attrs)
      in
      let path =
        try
          let v = List.assoc "path" attrs in
          if v = "" || v.[0] <> '/' then raise Not_found else Some v
        with Not_found -> None
      in
      let domain =
        try
          let v = List.assoc "domain" attrs in
          if v = "" then raise Not_found
          else
            Some
              (String.lowercase_ascii
                 (if v.[0] = '.' then Stringext.string_after v 1 else v))
        with Not_found -> None
      in
      (* TODO: trim wsp *)
      ( fst cookie,
        {
          cookie;
          (* TODO: respect expires attribute *)
          expiration = `Session;
          domain;
          path;
          http_only = List.mem_assoc "httponly" attrs;
          secure = List.mem_assoc "secure" attrs;
        } )
      :: alist
    with Failure _ -> alist

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

  (* TODO: check dupes+order *)
  let extract hdr =
    Header.fold
      (fun k c a ->
        if caseless_equal k "set-cookie" then extract_1_0 c a
        else if caseless_equal k "set-cookie2" then extract_1_1 c a
        else a)
      hdr []

  let value { cookie = _, v; _ } = v
end

module Cookie_hdr = struct
  (* RFC 2965 has
     cookie          =  "Cookie:" cookie-version 1*((";" | ",") cookie-value)
     cookie-value    =  NAME "=" VALUE [";" path] [";" domain] [";" port]
     cookie-version  =  "$Version" "=" value
     NAME            =  attr
     VALUE           =  value
     path            =  "$Path" "=" value
     domain          =  "$Domain" "=" value
     port            =  "$Port" [ "=" <"> value <"> ]
  *)

  let extract hdr =
    List.fold_left
      (fun acc header ->
        let comps = Stringext.split_trim_left ~on:";" ~trim:" \t" header in
        (* We don't handle $Path, $Domain, $Port, $Version (or $anything
           $else) *)
        let cookies =
          List.filter (fun s -> String.length s > 0 && s.[0] != '$') comps
        in
        let split_pair nvp =
          match Stringext.split ~on:'=' nvp ~max:2 with
          | [] -> ("", "")
          | [ n ] -> (n, "")
          | n :: v :: _ -> (n, v)
        in
        List.map split_pair cookies @ acc)
      []
      (Header.get_multi hdr "cookie")

  let serialize cookies =
    ("cookie", String.concat "; " (List.map (fun (k, v) -> k ^ "=" ^ v) cookies))
end
