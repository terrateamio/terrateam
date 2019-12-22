(*
 * Copyright (c) 2012-2014 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2012-2014 David Sheets <sheets@alum.mit.edu>
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

  module Raw = struct
    let (+) a b = seq [a;b]
    let (/) a b = alt [a;b]

    let sub_delims = Posix.re "[!$&'()*+,;=]"
    let c_at = char '@'
    let c_colon = char ':'
    let c_dot = char '.'

    let unreserved = Posix.re "[A-Za-z0-9-._~]"
    let hexdig = Posix.re "[0-9A-Fa-f]"
    let pct_encoded = (char '%') + hexdig + hexdig

    let dec_octet = Posix.re "25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?"
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
        + (opt (Posix.re "%25" + rep1 zone_id))
        + char ']'
      )

    let reg_name = rep ( unreserved / pct_encoded / sub_delims )

    let host = ipv6_address / ipv4_address / reg_name (* | ipv4_literal TODO *)
    let userinfo = rep (unreserved / pct_encoded / sub_delims / c_colon)
    let port = Posix.re "[0-9]*"
    let authority = (opt ((group userinfo) + c_at)) + (group host) + (opt (c_colon + (group port)))

    let uri_reference = Posix.re "^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?"
  end

  let ipv4_address = Posix.compile Raw.ipv4_address
  let ipv6_address = Posix.compile Raw.ipv6_address
  let uri_reference = Posix.compile Raw.uri_reference
  let authority = Posix.compile Raw.authority

  let host = Posix.compile Raw.host
