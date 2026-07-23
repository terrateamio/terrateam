(*{{{ Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
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
  }}}*)

(* From http://erratique.ch/software/jsonm/doc/Jsonm.html#datamodel *)
type t =
  [ `Null
  | `Bool of bool
  | `Float of float
  | `String of string
  | `A of t list
  | `O of (string * t) list ]

exception Escape of ((int * int) * (int * int)) * Jsonm.error

let json_of_src src =
  let d = Jsonm.decoder src in
  let dec () =
    match Jsonm.decode d with
    | `Lexeme l -> l
    | `Error e -> raise (Escape (Jsonm.decoded_range d, e))
    | `End | `Await -> assert false
  in
  let rec value v k =
    match v with
    | `Os -> obj [] k
    | `As -> arr [] k
    | (`Null | `Bool _ | `String _ | `Float _) as v -> k v
    | _ -> assert false
  and arr vs k =
    match dec () with
    | `Ae -> k (`A (List.rev vs))
    | v -> value v (fun v -> arr (v :: vs) k)
  and obj ms k =
    match dec () with
    | `Oe -> k (`O (List.rev ms))
    | `Name n -> value (dec ()) (fun v -> obj ((n, v) :: ms) k)
    | _ -> assert false
  in
  try `JSON (value (dec ()) (fun v -> v)) with Escape (r, e) -> `Error (r, e)

let json_to_dst ~minify dst (json : t) =
  let enc e l = ignore (Jsonm.encode e (`Lexeme l)) in
  let rec value v k e =
    match v with
    | `A vs -> arr vs k e
    | `O ms -> obj ms k e
    | (`Null | `Bool _ | `Float _ | `String _) as v ->
        enc e v;
        k e
  and arr vs k e =
    enc e `As;
    arr_vs vs k e
  and arr_vs vs k e =
    match vs with
    | v :: vs' -> value v (arr_vs vs' k) e
    | [] ->
        enc e `Ae;
        k e
  and obj ms k e =
    enc e `Os;
    obj_ms ms k e
  and obj_ms ms k e =
    match ms with
    | (n, v) :: ms ->
        enc e (`Name n);
        value v (obj_ms ms k) e
    | [] ->
        enc e `Oe;
        k e
  in
  let e = Jsonm.encoder ~minify dst in
  let finish e = ignore (Jsonm.encode e `End) in
  match json with
  | (`A _ | `O _) as json -> value json finish e
  | _ -> invalid_arg "invalid json text"

let to_buffer buf (json : t) = json_to_dst ~minify:true (`Buffer buf) json

let output t =
  let buf = Buffer.create 1024 in
  to_buffer buf t;
  Buffer.contents buf

let parse_error fmt =
  Printf.ksprintf
    (fun msg ->
      Printf.eprintf "parse error: %s\n" msg;
      exit 1)
    fmt

let string_of_error error =
  Jsonm.pp_error Format.str_formatter error;
  Format.flush_str_formatter ()

let of_buffer buf : t =
  let str = Buffer.contents buf in
  match json_of_src (`String str) with
  | `JSON j -> j
  | `Error (_, e) -> parse_error "JSON.of_buffer %s" (string_of_error e)

let of_channel ic =
  match json_of_src (`Channel ic) with
  | `JSON j -> j
  | `Error (_, e) -> parse_error "JSON.of_buffer %s" (string_of_error e)

let input str : t =
  match json_of_src (`String str) with
  | `JSON j -> j
  | `Error (_, e) ->
      Jsonm.pp_error Format.str_formatter e;
      parse_error "JSON.input %s" (string_of_error e)

(* string *)
let of_string s = `String s

let to_string = function
  | `String s -> s
  | j -> parse_error "JSON.to_string: %s" (output j)

type code = { code : int; constr : string; descr : string; doc : string }
type section = { section : string; codes : code list }

let normalize s =
  let b = Bytes.of_string s in
  Bytes.iteri
    (fun i -> function
      | 'A' .. 'Z' as c -> if i > 1 then Bytes.set b i (Char.lowercase_ascii c)
      | ' ' | '-' | '\'' -> Bytes.set b i '_'
      | _ -> ())
    (Bytes.of_string s);
  Bytes.to_string b

let read ic =
  let json = of_channel ic in
  match json with
  | `O o ->
      let section =
        match List.assoc "class" o with
        | `O o ->
            let s =
              String.uncapitalize_ascii (to_string (List.assoc "title" o))
            in
            normalize s
        | _ -> assert false
      in

      let codes =
        match List.assoc "codes" o with
        | `O o ->
            List.fold_left
              (fun codes (code, o) ->
                let code = int_of_string code in
                if code = 122 then (* Same as 414 but for IE7 ??? *)
                  codes
                else
                  let o = match o with `O o -> o | _ -> assert false in
                  let descr = to_string (List.assoc "title" o) in
                  let constr =
                    "`"
                    ^
                    try
                      let i = String.index descr '(' in
                      String.sub descr 0 (i - 1)
                    with Not_found -> descr
                  in
                  let constr = normalize constr in
                  (* XXX: dirty hack *)
                  let constr = if constr = "`Ok" then "`OK" else constr in
                  let doc = to_string (List.assoc "summary" o) in
                  { constr; descr; code; doc } :: codes)
              [] o
        | _ -> assert false
      in
      { section; codes = List.rev codes }
  | _ -> assert false

let append oc fmt = Printf.fprintf oc (fmt ^^ "\n")

let output_type oc ~mli t =
  append oc "type %s_status =" t.section;
  List.iteri
    (fun i c ->
      let doc = if mli then Printf.sprintf " (** %s *)" c.doc else "" in
      if i = 0 then append oc "  [ %s%s" c.constr doc
      else append oc "  | %s%s" c.constr doc)
    t.codes;
  append oc "  ] [@@deriving sexp]";
  if mli then append oc "(** %s *)" (String.capitalize_ascii t.section);
  append oc ""

let output_status_types oc ~mli t =
  List.iter (output_type oc ~mli) t;
  append oc "type status = [";
  List.iter (fun t -> append oc "  | %s_status" t.section) t;
  append oc "] [@@deriving sexp]";
  append oc "";
  append oc "type status_code = [`Code of int | status ] [@@deriving sexp]";
  append oc ""

let iter fn s = List.iter (fun s -> List.iter fn s.codes) s

let output_status_of_code oc ~mli s =
  if mli then (
    append oc "val status_of_code: int -> status_code";
    append oc "(** Generate status values from int codes. *)")
  else (
    append oc "let status_of_code: int -> status_code = function";
    iter (fun c -> append oc "  | %d -> %s" c.code c.constr) s;
    append oc "  | cod -> `Code cod");
  append oc ""

let output_code_of_status oc ~mli s =
  if mli then (
    append oc "val code_of_status: status_code -> int";
    append oc "(** Generate an int code from a status value. *)")
  else (
    append oc "let code_of_status: status_code -> int = function";
    iter (fun c -> append oc "  | %s -> %d" c.constr c.code) s;
    append oc "  | `Code cod -> cod");
  append oc ""

let output_string_of_status oc ~mli s =
  if mli then (
    append oc "val string_of_status: status_code -> string";
    append oc "(** Give a description of the given status value. *)")
  else (
    append oc "let string_of_status: status_code -> string = function";
    iter (fun c -> append oc "  | %s -> \"%d %s\"" c.constr c.code c.descr) s;
    (* the response status must include an extra space even if no description is present, cf. #752 *)
    append oc "  | `Code cod ->";
    append oc "      let code = string_of_int cod in";
    append oc "      code ^ \" Status \" ^ code");
  append oc ""

let output_reason_phrase_of_code oc ~mli s =
  if mli then (
    append oc "val reason_phrase_of_code: int -> string";
    append oc "(** Give a description of the given int code. *)")
  else (
    append oc "let reason_phrase_of_code: int -> string = function";
    iter (fun c -> append oc "  | %d -> %S" c.code c.descr) s;
    append oc "  | cod -> string_of_int cod");
  append oc ""

let output_is_code oc ~mli t =
  List.iter
    (fun t ->
      if mli then (
        append oc "val is_%s: int -> bool" t.section;
        append oc
          "(** Is the given int code belong to the class of %S return code ? *)"
          t.section)
      else (
        append oc "let is_%s code =" t.section;
        append oc "  match status_of_code code with";
        append oc "  | #%s_status -> true" t.section;
        append oc "  |  _ -> false");
      append oc "")
    t;
  append oc "";
  if mli then (
    append oc "val is_error: int -> bool";
    append oc "(** Return true for client and server error status codes. *)")
  else
    append oc "let is_error code = is_client_error code || is_server_error code";
  append oc ""

type gen = { constr : string; string : string }

let g constr string = { constr; string }

let output_gen_types oc (_name, typ, gens) =
  append oc "type %s = [" typ;
  List.iter (fun { constr; _ } -> append oc "  | %s" constr) gens;
  append oc "  | `Other of string";
  append oc "] [@@deriving sexp]";
  append oc ""

let output_gen_convert oc ~mli (name, typ, gens) =
  if mli then (
    append oc "val string_of_%s: %s -> string" name typ;
    append oc "(** Convert a %s to a string. *)" name;
    append oc "";
    append oc "val %s_of_string: string -> %s" name typ;
    append oc "(** Convert a string to a %s. *)" name;
    append oc "";
    append oc "val compare_%s: %s -> %s -> int" name typ typ;
    append oc "(** Comparison function for [%s] values *)" name;
    append oc "")
  else (
    append oc "let string_of_%s: %s -> string = function" name typ;
    List.iter (fun g -> append oc "  | %s -> %S" g.constr g.string) gens;
    append oc "  | `Other s -> s";
    append oc "";
    append oc "let %s_of_string: string -> %s = function" name typ;
    List.iter (fun g -> append oc "  | %S -> %s" g.string g.constr) gens;
    append oc "  | s -> `Other s";
    append oc "";
    append oc "let compare_%s a b =" name;
    append oc "  String.compare (string_of_%s a) (string_of_%s b)" name name;
    append oc "");
  append oc ""

let t =
  List.map
    (fun f -> read (open_in f))
    [
      "codes/1.json";
      "codes/2.json";
      "codes/3.json";
      "codes/4.json";
      "codes/5.json";
    ]

let version =
  ("version", "version", [ g "`HTTP_1_0" "HTTP/1.0"; g "`HTTP_1_1" "HTTP/1.1" ])

let known_methods =
  [
    g "`GET" "GET";
    g "`POST" "POST";
    g "`HEAD" "HEAD";
    g "`DELETE" "DELETE";
    g "`PATCH" "PATCH";
    g "`PUT" "PUT";
    g "`OPTIONS" "OPTIONS";
    g "`TRACE" "TRACE";
    g "`CONNECT" "CONNECT";
  ]

let meth = ("method", "meth", known_methods)

let gen oc ~mli =
  append oc "(* Auto-Generated by 'ocaml generate.ml' *)";
  append oc "open! Sexplib0.Sexp_conv";
  append oc "";
  output_gen_types oc version;
  output_gen_types oc meth;
  output_status_types oc ~mli t;
  output_gen_convert oc ~mli version;
  output_gen_convert oc ~mli meth;
  output_status_of_code oc ~mli t;
  output_code_of_status oc ~mli t;
  output_string_of_status oc ~mli t;
  output_reason_phrase_of_code oc ~mli t;
  output_is_code oc ~mli t

let () =
  let ml = open_out "../src/code.ml" in
  let mli = open_out "../src/code.mli" in
  gen ml ~mli:false;
  gen mli ~mli:true;
  close_out ml;
  close_out mli
