(*
 * Copyright (c) 2012 Richard Mortier <mort@cantab.net>
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

open Re

let (|>) x f = f x (* pipe *)
let (&&&) x y = Int32.logand x y
let (|||) x y = Int32.logor x y
let (<<<) x y = Int32.shift_left x y
let (>>>) x y = Int32.shift_right_logical x y
let sp = Printf.sprintf

type byte = char
let byte_to_int32 b = b |> int_of_char |> Int32.of_int

type bytes = string
let bytes (s:string) : bytes = s
let bytes_to_string (bs:bytes) : string =
  let s = ref [] in 
  let l = String.length bs in
  for i = 0 to (l-1) do 
    s := (Printf.sprintf "%02lx" (byte_to_int32 bs.[i])) :: !s
  done;
  String.concat "." !s

type ipv4 = Int32.t

let ipv4_to_string i =   
  sp "%ld.%ld.%ld.%ld" 
    ((i &&& 0x0_ff000000_l) >>> 24) ((i &&& 0x0_00ff0000_l) >>> 16)
    ((i &&& 0x0_0000ff00_l) >>>  8) ((i &&& 0x0_000000ff_l)       )

let bytes_to_ipv4 bs = 
  ((bs.[0] |> byte_to_int32 <<< 24) ||| (bs.[1] |> byte_to_int32 <<< 16) 
    ||| (bs.[2] |> byte_to_int32 <<< 8) ||| (bs.[3] |> byte_to_int32))

type ipv6 = int32 * int32 * int32 * int32

let ipv6_to_string i = 
  (* TODO should make this rfc 5952 compliant *)
  let i1, i2, i3, i4 = i in
  let s = sp "%lx:%lx:%lx:%lx:%lx:%lx:%lx:%lx"
    ((i1 &&& 0x0_ffff0000_l) >>> 16) ((i1 &&& 0x0_0000ffff_l))
    ((i2 &&& 0x0_ffff0000_l) >>> 16) ((i2 &&& 0x0_0000ffff_l))
    ((i3 &&& 0x0_ffff0000_l) >>> 16) ((i3 &&& 0x0_0000ffff_l))
    ((i4 &&& 0x0_ffff0000_l) >>> 16) ((i4 &&& 0x0_0000ffff_l))
  in
  s

let bytes_to_ipv6 bs = 
  (bytes_to_ipv4 (String.sub bs 0 4), bytes_to_ipv4 (String.sub bs 4 4),
   bytes_to_ipv4 (String.sub bs 8 4), bytes_to_ipv4 (String.sub bs 12 4))










