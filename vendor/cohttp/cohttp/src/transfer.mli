(*{{{ Copyright (c) 2012-2014 Anil Madhavapeddy <anil@recoil.org>
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

(** Read and write the HTTP/1.1 transfer-encoding formats. Currently supported
    are [chunked] and [content-length]. *)

(** The encoding format detected from the [transfer-encoding] and
    [content-length] headers *)
type encoding =
  | Chunked  (** dynamic chunked encoding *)
  | Fixed of int64  (** fixed size content *)
  | Unknown  (** unknown body size, which leads to best-effort *)
[@@deriving sexp]

(** A chunk of body that also signals if there to more to arrive *)
type chunk =
  | Chunk of string  (** chunk of data and not the end of stream *)
  | Final_chunk of string
      (** the last chunk of data, so no more should be read *)
  | Done  (** no more body data is present *)
[@@deriving sexp]

val string_of_encoding : encoding -> string
(** Convert the encoding format to a human-readable string *)

val has_body : encoding -> [ `No | `Unknown | `Yes ]
(** [has_body encoding] returns the appropriate variant that indicates whether
    the HTTP request or response has an associated body. It does not guess:
    instead [Unknown] is returned if there is no explicit association. *)
