(*{{{ Copyright (c) 2014 Andy Ray
 * Copyright (c) 2014 Anil Madhavapeddy <anil@recoil.org>
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

(** IO implementation that uses strings to marshal and unmarshal HTTP *)

type buf = { str : string; mutable pos : int; len : int }
(** The buffer structured used to keep track of where in the string the library
    is currently reading from *)

val open_in : string -> buf
(** [open_in s] will make the string [s] available as a [buf] that can be parsed
    via Cohttp *)

(** IO interface that uses {!buf} for input data and queues output data into a
    {!Buffer.t} *)
module M : S.IO with type 'a t = 'a and type ic = buf and type oc = Buffer.t
