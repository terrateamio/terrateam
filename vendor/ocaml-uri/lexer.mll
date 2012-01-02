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

{
open Parser
exception Eof
}

let gen_delims = [':' '/' '?' '#' '[' ']' '@']
let sub_delims = ['!' '$' '&' '\'' '(' ')' '*' '+' ',' ';' '=']
let reserved = gen_delims | sub_delims
let unreserved = ['A'-'Z' 'a'-'z' '0'-'9' '\\' '-' '.' '_' '~' ]
let hexdig = ['0'-'9''A'-'F''a'-'f']
let pct_encoded = '%' hexdig hexdig
let dec_octet = ('2''5'['0'-'5']) | ('2'['0'-'4']['0'-'9']) | (['0''1']?['0'-'9']['0'-'9']?)
let ipv4_address = dec_octet '.' dec_octet '.' dec_octet '.' dec_octet
let h16 = hexdig hexdig? hexdig? hexdig?
let ls32 = ( h16 ':' h16 ) | ipv4_address

let ipv6_address =
   (h16 ':' h16 ':' h16 ':' h16 ':' h16 ':' h16 ':' ls32) |
   (':' ':' h16 ':' h16 ':' h16 ':' h16 ':' h16 ':' ls32) |
   (h16 ':' ':' h16 ':' h16 ':' h16 ':' h16 ':' ls32) |
   ( (h16 ':')? h16 ':'':' h16 ':' h16 ':' h16 ':' ls32) |
   ( (h16 ':')? (h16 ':')? h16 ':'':' h16 ':' h16 ':' ls32) |
   ( (h16 ':')? (h16 ':')? (h16 ':')? h16 ':'':' h16 ':' ls32) |
   ( (h16 ':')? (h16 ':')? (h16 ':')? (h16 ':')? h16 ':'':' ls32) |
   ( (h16 ':')? (h16 ':')? (h16 ':')? (h16 ':')? (h16 ':')? ':'':' h16)  |
   ( (h16 ':')? (h16 ':')? (h16 ':')? (h16 ':')? (h16 ':')? (h16 ':')? h16 ':'':') 
 
let ipv_future = ['v''V'] hexdig+ '.' ( unreserved | sub_delims | ':' )+
let ip_literal = '[' ( ipv6_address | ipv_future  ) ']'
let reg_name = ( unreserved | pct_encoded | sub_delims )*
let host = ip_literal | ipv4_address | reg_name
let userinfo = unreserved | pct_encoded | sub_delims | ":" 
let port = ['0'-'9']*
let authority = ((userinfo) as userinfo '@')? host (':' port)?


let absolute_uri =
  ( 
    ([^':''/''?''#']+ as scheme) 
    ':'
  )
  ('/''/'
     authority as authority
  )?
     ([^'?''#']* as path)
  ('?'
     ([^'#']* as query)
  )?
  ('#'
     (_* as fragment)
  )?

rule token = parse
| absolute_uri {
    let u = {Uri.scheme; authority; path; query; fragment} in
    ABSOLUTE_URI(u)
  }
