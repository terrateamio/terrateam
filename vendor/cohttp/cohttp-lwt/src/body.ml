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

open Cohttp
open Lwt

type t = [ Body.t | `Stream of (string Lwt_stream.t[@sexp.opaque]) ]
[@@deriving sexp]

let empty = (Body.empty :> t)

let create_stream fn arg =
  let fin = ref false in
  Lwt_stream.from (fun () ->
      match !fin with
      | true -> return_none
      | false -> (
          fn arg >>= function
          | Transfer.Done -> return_none
          | Transfer.Final_chunk c ->
              fin := true;
              return (Some c)
          | Transfer.Chunk c -> return (Some c)))

let is_empty (body : t) =
  match body with
  | #Body.t as body -> return (Body.is_empty body)
  | `Stream s ->
      Lwt_stream.get_while (fun x -> x = "") s >>= fun _ ->
      Lwt_stream.is_empty s

let to_string (body : t) =
  match body with
  | #Body.t as body -> return (Body.to_string body)
  | `Stream s ->
      let b = Buffer.create 1024 in
      Lwt_stream.iter (Buffer.add_string b) s >>= fun () ->
      return (Buffer.contents b)

let to_string_list (body : t) =
  match body with
  | #Body.t as body -> return (Body.to_string_list body)
  | `Stream s -> Lwt_stream.to_list s

let of_string s = (Body.of_string s :> t)

let to_stream (body : t) =
  match body with
  | `Empty -> Lwt_stream.of_list []
  | `Stream s -> s
  | `String s -> Lwt_stream.of_list [ s ]
  | `Strings sl -> Lwt_stream.of_list sl

let drain_body (body : t) =
  match body with
  | `Empty | `String _ | `Strings _ -> return_unit
  | `Stream s -> Lwt_stream.junk_while (fun _ -> true) s

let of_string_list l = `Strings l
let of_stream s = `Stream s

let transfer_encoding = function
  | #Body.t as t -> Body.transfer_encoding t
  | `Stream _ -> Transfer.Chunked

(* This will consume the body and return a length, and a
 * new body that should be used instead of the input *)
let length (body : t) : (int64 * t) Lwt.t =
  match body with
  | #Body.t as body -> return (Body.length body, body)
  | `Stream _ ->
      to_string body >>= fun buf ->
      let len = Int64.of_int (String.length buf) in
      return (len, `String buf)

let write_body fn = function
  | `Empty -> return_unit
  | `Stream st -> Lwt_stream.iter_s fn st
  | `String s -> fn s
  | `Strings sl -> Lwt_list.iter_s fn sl

let map f t =
  match t with
  | #Body.t as t -> (Body.map f t :> t)
  | `Stream s -> `Stream (Lwt_stream.map f s)

let to_form (body : t) = to_string body >|= Uri.query_of_encoded
let of_form ?scheme f = Uri.encoded_of_query ?scheme f |> of_string
