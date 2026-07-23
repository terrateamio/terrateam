(*{{{ Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
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
open Printf

type challenge = [ `Basic of string (* realm *) ] [@@deriving sexp]

type credential =
  [ `Basic of string * string (* username, password *) | `Other of string ]
[@@deriving sexp]

let string_of_credential (cred : credential) =
  match cred with
  | `Basic (user, pass) ->
      "Basic " ^ Base64.encode_string (sprintf "%s:%s" user pass)
  | `Other buf -> buf

let credential_of_string (buf : string) : credential =
  try
    let b64 = Scanf.sscanf buf "Basic %s" (fun b -> b) in
    match Stringext.split ~on:':' (Base64.decode_exn b64) ~max:2 with
    | [ user; pass ] -> `Basic (user, pass)
    | _ -> `Other buf
  with _ -> `Other buf

let string_of_challenge (ty : challenge) =
  match ty with `Basic realm -> sprintf "Basic realm=\"%s\"" realm
