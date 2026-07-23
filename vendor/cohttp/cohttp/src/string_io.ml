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

(* input channel type - a string with a (file) position and length *)
type buf = { str : string; mutable pos : int; len : int }

let open_in str = { str; pos = 0; len = String.length str }

module M = struct
  type 'a t = 'a

  let return a = a

  type conn = buf

  let ( >>= ) = ( |> )

  type ic = buf

  (* output channels are just buffers *)
  type oc = Buffer.t

  (* the following read/write logic has only been lightly tested... *)
  let read_rest x =
    let s = String.sub x.str x.pos (x.len - x.pos) in
    x.pos <- x.len;
    s

  let read_line' x =
    if x.pos < x.len then
      let start = x.pos in
      try
        while x.str.[x.pos] != '\n' do
          x.pos <- x.pos + 1
        done;
        let l =
          if x.pos > 0 && x.str.[x.pos - 1] = '\r' then x.pos - start - 1
          else x.pos - start
        in
        let s = String.sub x.str start l in
        x.pos <- x.pos + 1;
        Some s
      with _ -> Some (read_rest x)
    else None

  let read_line x = return (read_line' x)

  let read_exactly' x n =
    if x.len - x.pos < n then None
    else
      let s = String.sub x.str x.pos n in
      x.pos <- x.pos + n;
      Some s

  let read x n =
    match read_exactly' x n with
    | None when x.pos >= x.len -> raise End_of_file
    | None -> return (read_rest x)
    | Some x -> return x

  let write x s =
    Buffer.add_string x s;
    return ()

  let flush _x = return ()
end
