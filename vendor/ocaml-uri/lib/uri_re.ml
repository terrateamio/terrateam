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

[@@@ocaml.warning "-32"]

open Re

module Raw = struct
  let (+) a b = seq [a;b]
  let (/) a b = alt [a;b]

  let gen_delims = Re_posix.re "[:/?#\\[\\]@]"
  let sub_delims = Re_posix.re "[!$&'()*+,;=]"
  let c_at = char '@'
  let c_colon = char ':'
  let c_slash = char '/'
  let c_slash2 = Re_posix.re "//"
  let c_dot = char '.'
  let c_question = char '?'
  let c_hash = char '#'

  let reserved = gen_delims / sub_delims
  let unreserved = Re_posix.re "[A-Za-z0-9-._~]"
  let hexdig = Re_posix.re "[0-9A-Fa-f]"
  let pct_encoded = (char '%') + hexdig + hexdig

  let dec_octet = Re_posix.re "25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?"
  let ipv4_address = (repn (dec_octet + c_dot) 3 (Some 3)) + dec_octet

  (* following RFC2234, RFC3986, RFC6874 and
     http://people.spodhuis.org/phil.pennock/software/emit_ipv6_regexp-0.304
  *)
  let zone_id = unreserved / pct_encoded
  let ipv6_address =
    let (=|) n a = repn a n (Some n) in
    let (<|) n a = repn a 0 (Some n) in
    let h16 = repn hexdig 1 (Some 4) in
    let h16c = h16 + c_colon in
    let cc = c_colon + c_colon in
    let ls32 = (h16c + h16) / ipv4_address in
    ( char '['
      + (((6=|h16c) + ls32)
         / (                         cc + (5=|h16c) + ls32)
         / ((1<|             h16)  + cc + (4=|h16c) + ls32)
         / ((1<|((1<|h16c) + h16)) + cc + (3=|h16c) + ls32)
         / ((1<|((2<|h16c) + h16)) + cc + (2=|h16c) + ls32)
         / ((1<|((3<|h16c) + h16)) + cc +     h16c  + ls32)
         / ((1<|((4<|h16c) + h16)) + cc             + ls32)
         / ((1<|((5<|h16c) + h16)) + cc             +  h16)
         / ((1<|((6<|h16c) + h16)) + cc                   )
      )
      + (opt (Re_posix.re "%25" + rep1 zone_id))
      + char ']'
    )

  let reg_name = rep ( unreserved / pct_encoded / sub_delims )

  let host = ipv6_address / ipv4_address / reg_name (* | ipv4_literal TODO *)
  let userinfo = rep (unreserved / pct_encoded / sub_delims / c_colon)
  let port = Re_posix.re "[0-9]*"
  let authority = (opt ((group userinfo) + c_at)) + (group host) + (opt (c_colon + (group port)))
  let null_authority = (group empty) + (group empty) + (group empty)

  let pchar = unreserved / pct_encoded / sub_delims / c_colon / c_at
  let segment = rep pchar
  let segment_nz = rep1 pchar
  let segment_nz_nc = repn (unreserved / pct_encoded / sub_delims / c_at) 1 None 
  let path_abempty = rep (c_slash + segment)
  let path_absolute = c_slash + (opt (segment_nz + (rep (c_slash + segment))))
  let path_noscheme = segment_nz_nc + (rep (c_slash + segment ))
  let path_rootless = segment_nz + (rep (c_slash + segment ))
  let path_empty = empty

  let path = path_abempty  (* begins with "/" or is empty *)
             / path_absolute (* begins with "/" but not "//" *)
             / path_noscheme (* begins with a non-colon segment *)
             / path_rootless (* begins with a segment *)
             / path_empty    (* zero characters *)

  let hier_part = (c_slash2 + authority + path_abempty)
             / (path_absolute / path_rootless / path_empty)

  let scheme = Re_posix.re "[A-Za-z][A-Za-z0-9+\\\\-\\.]*"
  let query = group (rep ( pchar / c_slash / c_question))
  let fragment = group (rep (pchar / c_slash / c_question))

  let absolute_uri = scheme + c_colon + hier_part + (opt (c_question + query))

  let uri = scheme + c_colon + hier_part + (opt (c_question + query)) + (opt (c_hash + fragment))

  let relative_part = (c_slash2 + authority + path_abempty) / (path_absolute / path_noscheme / path_empty)

  let relative_ref = relative_part + (opt (c_question + query)) + (opt (c_hash + fragment))

  let uri_reference = Re_posix.re "^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?"
end

let ipv4_address = Re_posix.compile Raw.ipv4_address
let ipv6_address = Re_posix.compile Raw.ipv6_address
let uri_reference = Re_posix.compile Raw.uri_reference
let authority = Re_posix.compile Raw.authority
let host = Re_posix.compile Raw.host
