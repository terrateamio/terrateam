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

type t = [ Cohttp.Body.t | `Stream of string Lwt_stream.t ] [@@deriving sexp]

include Cohttp.S.Body with type t := t

val is_empty : t -> bool Lwt.t
val to_string : t -> string Lwt.t
val to_string_list : t -> string list Lwt.t
val to_stream : t -> string Lwt_stream.t
val of_stream : string Lwt_stream.t -> t
val to_form : t -> (string * string list) list Lwt.t

val create_stream :
  ('a -> Cohttp.Transfer.chunk Lwt.t) -> 'a -> string Lwt_stream.t

val length : t -> (int64 * t) Lwt.t
val write_body : (string -> unit Lwt.t) -> t -> unit Lwt.t
val drain_body : t -> unit Lwt.t
