/*
  Copyright (C) 2012, David Sheets <sheets@alum.mit.edu>

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
*/

%{
  open Accept_types

  type param = Q of int | Kv of p

  let rec get_q = function
    | (Q q)::_ -> q
    | _::r -> get_q r
    | [] -> 1000

  let get_rest pl = List.fold_right
    (function Kv p -> fun l -> p::l | Q _ -> fun l -> l) pl []
%}

%token STAR SLASH SEMI COMMA EQUAL EOI
%token <string> TOK QS
%start media_ranges charsets encodings languages
%type <(Accept_types.media_range * Accept_types.p list) Accept_types.qlist> media_ranges
%type <Accept_types.charset Accept_types.qlist> charsets
%type <Accept_types.encoding Accept_types.qlist> encodings
%type <Accept_types.language Accept_types.qlist> languages
%%

param :
| SEMI TOK EQUAL QS { Kv ($2, $4) }
| SEMI TOK EQUAL TOK {
  if $2="q" then try Q (truncate (1000.*.(float_of_string $4)))
    with Failure _ -> raise Parsing.Parse_error
  else Kv ($2, $4)
}

params :
| param params { $1::$2 }
| { [] }

media_range :
| STAR SLASH STAR params {
  (get_q $4, (AnyMedia, get_rest $4))
}
| TOK SLASH STAR params {
  (get_q $4, (AnyMediaSubtype (String.lowercase_ascii $1), get_rest $4))
}
| TOK SLASH TOK params {
  (get_q $4, (MediaType (String.lowercase_ascii $1, String.lowercase_ascii $3), get_rest $4))
}

media_ranges :
| media_range EOI { [$1] }
| media_range COMMA media_ranges { $1::$3 }
| EOI { [] }

charset :
| TOK params { (get_q $2, Charset (String.lowercase_ascii $1)) }
| STAR params { (get_q $2, AnyCharset) }

charsets :
| charset EOI { [$1] }
| charset COMMA charsets { $1::$3 }

encoding :
| TOK params {
  (get_q $2, match (String.lowercase_ascii $1) with
    | "gzip" -> Gzip
    | "compress" -> Compress
    | "deflate" -> Deflate
    | "identity" -> Identity
    | enc -> Encoding enc
  )
}
| STAR params { (get_q $2, AnyEncoding) }

encodings :
| encoding EOI { [$1] }
| encoding COMMA encodings { $1::$3 }
| EOI { [] }

language :
| TOK params {
  (get_q $2, Language (Stringext.split ~on:'-' (String.lowercase_ascii $1)))
}
| STAR params { (get_q $2, AnyLanguage) }

languages :
| language EOI { [$1] }
| language COMMA languages { $1::$3 }

%%
