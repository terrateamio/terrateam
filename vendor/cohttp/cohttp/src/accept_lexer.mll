(*{{{ Copyright (C) 2012, David Sheets <sheets@alum.mit.edu>

  Permission to use, copy, modify, and/or distribute this software for
  any purpose with or without fee is hereby granted, provided that the
  above copyright notice and this permission notice appear in all
  copies.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
  WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
  AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
  DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA
  OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
  TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
  PERFORMANCE OF THIS SOFTWARE.
}}}*)
{
  open Accept_parser
}

(* <http://tools.ietf.org/html/rfc2616#section-2.2> *)
let token = [^'('')''<''>''@'','';'':''\\''"''/''['']''?''=''{''}'' ''\t']

rule header_value = parse
  | '*' { STAR }
  | '/' { SLASH }
  | ';' { SEMI }
  | ',' { COMMA }
  | '=' { EQUAL }
  | '\"' { QS (List.fold_right (^) (qs [] lexbuf) "") }
  | (token)+ as tok { TOK tok }
  | ' ' { header_value lexbuf }
  | eof { EOI }
and qs sl = parse
  | "\\\"" { qs ("\""::sl) lexbuf }
  | "\"" { sl }
  | [^'"']+ as s { qs (s::sl) lexbuf }
