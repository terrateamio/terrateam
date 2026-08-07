(* Pretty printing using Format module. Escape any template introducer (${ or
   %{) as $${ / %%{ so the output re-parses to the same literal string rather
   than being interpreted as interpolation. *)
let escape_hcl_string s =
  let buf = Buffer.create (CCString.length s + 10) in
  let len = CCString.length s in
  let rec loop i =
    if i >= len then ()
    else
      let c = s.[i] in
      if (c = '$' || c = '%') && i + 1 < len && s.[i + 1] = '{' then (
        Buffer.add_char buf c;
        Buffer.add_char buf c;
        Buffer.add_char buf '{';
        loop (i + 2))
      else (
        (match c with
        | '"' -> Buffer.add_string buf "\\\""
        | '\\' -> Buffer.add_string buf "\\\\"
        | '\n' -> Buffer.add_string buf "\\n"
        | '\r' -> Buffer.add_string buf "\\r"
        | '\t' -> Buffer.add_string buf "\\t"
        | c -> Buffer.add_char buf c);
        loop (i + 1))
  in
  loop 0;
  Buffer.contents buf

let pp_quoted_string fmt s = Format.fprintf fmt "\"%s\"" (escape_hcl_string s)

let pp_block_label fmt = function
  | Hcl_parser_value.Block_label.Id s -> Format.fprintf fmt "%s" s
  | Hcl_parser_value.Block_label.Lit s -> pp_quoted_string fmt s

let pp_attr fmt = function
  | Hcl_parser_value.Attr.A_string s -> Format.fprintf fmt "%s" s
  | Hcl_parser_value.Attr.A_int i -> Format.fprintf fmt "%d" i
  | Hcl_parser_value.Attr.A_splat -> Format.fprintf fmt "*"

let max_attr_width body =
  CCList.fold_left
    (fun acc -> function
      | Hcl_parser_value.Attribute (name, _) -> max acc (CCString.length name)
      | _ -> acc)
    0
    body

let pad_right s width =
  let len = CCString.length s in
  if len >= width then s else s ^ CCString.make (width - len) ' '

(* A heredoc can only carry a value that starts and ends with a newline: the AST body keeps the
   opener's newline (evaluation drops it again) and the closing marker has to sit alone on its line.
   A trim marker can eat either one — [%{ endfor ~}] just before the terminator takes the final
   newline, a leading [%{~ for }] takes the opener's — and the result is not expressible as a
   heredoc at all. Adding the newline back would change the value, so such bodies are printed as a
   quoted template instead, which can express any string. Before this they printed as
   [..%{endfor}EOT] and the next reader died with "Unterminated heredoc". *)
let heredoc_shaped body = CCString.prefix ~pre:"\n" body && CCString.suffix ~suf:"\n" body

(* Undo the opener-newline convention when leaving heredoc form, so the quoted rendering carries the
   same value the heredoc would have evaluated to. *)
let drop_heredoc_leading_newline s = if CCString.prefix ~pre:"\n" s then CCString.drop 1 s else s

let drop_heredoc_leading_newline_parts = function
  | Hcl_parser_value.Template_part.Literal s :: rest ->
      Hcl_parser_value.Template_part.Literal (drop_heredoc_leading_newline s) :: rest
  | parts -> parts

(* The [strip_before] / [strip_after] tildes are NOT printed back, and that is deliberate.

   Trimming happens once, in [Hcl_ast_template], and is baked into the literal parts; evaluation
   ignores the flags entirely. They survive on the AST only as a record of the surface syntax.
   Re-emitting one would make the next reader trim an already-trimmed literal, and the trim is not
   idempotent -- it is line-scoped, so a second pass eats the next line too. Printing them bare is
   also what this printer has always done for the terminators ([%{endfor}] / [%{endif}] below carry
   no marker), so the whole template now round-trips consistently. *)
let rec pp_template_part_gen lit_escape fmt = function
  | Hcl_parser_value.Template_part.Literal s -> Format.fprintf fmt "%s" (lit_escape s)
  | Hcl_parser_value.Template_part.Interpolation { expr; strip_before = _; strip_after = _ } ->
      Format.fprintf fmt "${%a}" pp_expr expr
  | Hcl_parser_value.Template_part.If_directive
      { cond; then_; else_; strip_before = _; strip_after = _ } ->
      Format.fprintf
        fmt
        "%%{if %a}%a%a%%{endif}"
        pp_expr
        cond
        (Format.pp_print_list ~pp_sep:(fun _ () -> ()) (pp_template_part_gen lit_escape))
        then_
        (fun fmt -> function
          | Some else_parts ->
              Format.fprintf
                fmt
                "%%{else}%a"
                (Format.pp_print_list ~pp_sep:(fun _ () -> ()) (pp_template_part_gen lit_escape))
                else_parts
          | None -> ())
        else_
  | Hcl_parser_value.Template_part.For_directive
      { vars = v, key_opt; input; body; strip_before = _; strip_after = _ } ->
      Format.fprintf
        fmt
        "%%{for %s%s in %a}%a%%{endfor}"
        (match key_opt with
        | Some k -> k ^ ", "
        | None -> "")
        v
        pp_expr
        input
        (Format.pp_print_list ~pp_sep:(fun _ () -> ()) (pp_template_part_gen lit_escape))
        body

(* Quoted-string context: literals are escaped as HCL string content (newlines,
   quotes, and [${] / [%{] introducers). *)
and pp_template_part fmt p = pp_template_part_gen escape_hcl_string fmt p

(* Heredoc context: literal bytes (newlines, quotes) are kept verbatim and only
   the [${] / [%{] template introducers are re-escaped, so the rendered body
   round-trips back through the heredoc lexer. *)
and pp_heredoc_template_part fmt p = pp_template_part_gen Hcl_ast_template.escape_literal fmt p

(* Renders a template as a quoted-string literal: [{"foo${var.x}bar"}] *)
and pp_quoted_template fmt parts =
  Format.fprintf fmt "\"%a\"" (Format.pp_print_list ~pp_sep:(fun _ () -> ()) pp_template_part) parts

and pp_expr fmt = function
  | Hcl_parser_value.Expr.Id s -> Format.fprintf fmt "%s" s
  | Hcl_parser_value.Expr.String s -> pp_quoted_string fmt s
  | Hcl_parser_value.Expr.Template parts -> pp_quoted_template fmt parts
  | Hcl_parser_value.Expr.Int i -> Format.fprintf fmt "%d" i
  | Hcl_parser_value.Expr.Float f ->
      Format.fprintf fmt "%s" (Hcl_parser_value.Number.shortest_float f)
  | Hcl_parser_value.Expr.Bool b -> Format.fprintf fmt "%b" b
  | Hcl_parser_value.Expr.Null -> Format.fprintf fmt "null"
  | Hcl_parser_value.Expr.Tuple l ->
      Format.fprintf
        fmt
        "[%a]"
        (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.fprintf fmt ", ") pp_expr)
        l
  | Hcl_parser_value.Expr.Object l -> (
      match l with
      | [] -> Format.fprintf fmt "{}"
      | _ ->
          let entries = CCList.map (fun (k, v) -> (Format.asprintf "%a" pp_obj_key k, v)) l in
          let max_kw =
            CCList.fold_left (fun acc (ks, _) -> max acc (CCString.length ks)) 0 entries
          in
          Format.fprintf
            fmt
            "{@;<0 2>@[<v 0>%a@]@;}"
            (Format.pp_print_list
               ~pp_sep:(fun fmt () -> Format.fprintf fmt "@;")
               (fun fmt (key_str, v) ->
                 Format.fprintf fmt "%s = %a" (pad_right key_str max_kw) pp_expr v))
            entries)
  | Hcl_parser_value.Expr.Fun_call (id, args) ->
      Format.fprintf
        fmt
        "%s(%a)"
        id
        (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.fprintf fmt ", ") pp_expr)
        args
  | Hcl_parser_value.Expr.For_tuple { identifiers = id, ids; input; output; cond } ->
      Format.fprintf
        fmt
        "[for %a in %a : %a%a]"
        (Format.pp_print_list
           ~pp_sep:(fun fmt () -> Format.fprintf fmt ", ")
           Format.pp_print_string)
        (id :: ids)
        pp_expr
        input
        pp_expr
        output
        (fun fmt -> function
          | Some c -> Format.fprintf fmt " if %a" pp_expr c
          | None -> ())
        cond
  | Hcl_parser_value.Expr.For_object { identifiers; input; key_output; value_output; cond } ->
      let first_id, other_ids = identifiers in
      Format.fprintf
        fmt
        "{@;<0 2>@[<v 0>for %a in %a :@;%a => %a%a@]@;}"
        (Format.pp_print_list
           ~pp_sep:(fun fmt () -> Format.fprintf fmt ", ")
           Format.pp_print_string)
        (first_id :: other_ids)
        pp_expr
        input
        pp_expr
        key_output
        pp_expr
        value_output
        (fun fmt -> function
          | Some c -> Format.fprintf fmt " if %a" pp_expr c
          | None -> ())
        cond
  | Hcl_parser_value.Expr.Cond { if_; then_; else_ } ->
      (* Wrap in parens so the conditional re-parses with its own grouping
         when it sits inside a higher-precedence operator (e.g. the [Cond]
         arm of [a + (b ? c : d)] — without these parens, re-parsing
         would bind [+] tighter than [?:] per the grammar's precedence
         declarations and produce [(a + b) ? c : d]). *)
      Format.fprintf fmt "(%a ? %a : %a)" pp_expr if_ pp_expr then_ pp_expr else_
  | Hcl_parser_value.Expr.Idx (e, idx_expr) ->
      Format.fprintf fmt "%a[%a]" pp_expr e pp_expr idx_expr
  | Hcl_parser_value.Expr.Attr (e, attr) -> Format.fprintf fmt "%a.%a" pp_expr e pp_attr attr
  | Hcl_parser_value.Expr.Splat -> Format.fprintf fmt "*"
  | Hcl_parser_value.Expr.Not e -> Format.fprintf fmt "!%a" pp_expr e
  | Hcl_parser_value.Expr.Minus e -> Format.fprintf fmt "-%a" pp_expr e
  | Hcl_parser_value.Expr.Add (e1, e2) -> pp_binop fmt "+" e1 e2
  | Hcl_parser_value.Expr.Subtract (e1, e2) -> pp_binop fmt "-" e1 e2
  | Hcl_parser_value.Expr.Mult (e1, e2) -> pp_binop fmt "*" e1 e2
  | Hcl_parser_value.Expr.Div (e1, e2) -> pp_binop fmt "/" e1 e2
  | Hcl_parser_value.Expr.Log_and (e1, e2) -> pp_binop fmt "&&" e1 e2
  | Hcl_parser_value.Expr.Log_or (e1, e2) -> pp_binop fmt "||" e1 e2
  | Hcl_parser_value.Expr.Equal (e1, e2) -> pp_binop fmt "==" e1 e2
  | Hcl_parser_value.Expr.Not_equal (e1, e2) -> pp_binop fmt "!=" e1 e2
  | Hcl_parser_value.Expr.Gt (e1, e2) -> pp_binop fmt ">" e1 e2
  | Hcl_parser_value.Expr.Lt (e1, e2) -> pp_binop fmt "<" e1 e2
  | Hcl_parser_value.Expr.Gte (e1, e2) -> pp_binop fmt ">=" e1 e2
  | Hcl_parser_value.Expr.Lte (e1, e2) -> pp_binop fmt "<=" e1 e2
  | Hcl_parser_value.Expr.Mod (e1, e2) -> pp_binop fmt "%" e1 e2
  (* Trailing newline is required so that, when this heredoc is embedded inside another
     expression (eg [chomp(<<EOT\n..\nEOT)]), the closing marker is on its own line —
     hclsyntax only recognises [EOT] as a closer when nothing else follows it on the line. *)
  (* A literal heredoc body is stored in raw source form, so the quoted fallback has to resolve its
     [$${] / [%%{] escapes first — [escape_hcl_string] re-introduces them, and skipping this would
     double them. *)
  | Hcl_parser_value.Expr.Heredoc (marker, s) ->
      if heredoc_shaped s then Format.fprintf fmt "<<%s%s%s\n" marker s marker
      else pp_quoted_string fmt (Hcl_ast_template.unescape_literal (drop_heredoc_leading_newline s))
  | Hcl_parser_value.Expr.Heredoc' (marker, s) ->
      if heredoc_shaped s then Format.fprintf fmt "<<-%s%s%s\n" marker s marker
      else pp_quoted_string fmt (Hcl_ast_template.unescape_literal (drop_heredoc_leading_newline s))
  (* [<<-] is not re-emitted: the common-indent strip is already baked into the parts, so the printed
     body needs no second pass. *)
  | Hcl_parser_value.Expr.Template_heredoc (marker, parts) -> pp_template_heredoc fmt ~marker parts
  | Hcl_parser_value.Expr.Ellipsis e -> Format.fprintf fmt "%a..." pp_expr e

and pp_template_heredoc fmt ~marker parts =
  let body =
    Format.asprintf
      "%a"
      (Format.pp_print_list ~pp_sep:(fun _ () -> ()) pp_heredoc_template_part)
      parts
  in
  if heredoc_shaped body then Format.fprintf fmt "<<%s%s%s\n" marker body marker
  else pp_quoted_template fmt (drop_heredoc_leading_newline_parts parts)

and pp_binop fmt op e1 e2 = Format.fprintf fmt "(%a %s %a)" pp_expr e1 op pp_expr e2

(* An [Obj_key.Bare s] only prints back as valid HCL when the HCL grammar
   tokenizes [s] as a single bare object key — i.e. an identifier, a number
   literal, or a keyword (which is itself an identifier). The parser only ever
   builds [Bare] from those forms, but JSON-sourced objects map every key to
   [Bare] (see Hcl_parser_value_json.json_to_expr), so [s] may be an arbitrary
   string such as a UUID ([3ae5...]) or anything with a leading digit followed
   by letters. Printing those bare yields HCL the parser rejects, so they must
   be quoted — mirroring hclwrite, which writes a key bare only when it is a
   valid identifier and quotes it otherwise. tofu parses [{"80" = 1}] and
   [{80 = 1}] to the same key, so quoting only ever normalizes, never changes
   meaning. *)
and is_bare_obj_key s =
  (* A byte >= 0x80 is part of a UTF-8 multibyte sequence; HCL identifiers admit
     Unicode letters, so treat such bytes as identifier characters rather than
     quoting an otherwise-valid Unicode bare key. *)
  let is_id_start c =
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c = '_' || Char.code c >= 0x80
  in
  let is_id_continue c = is_id_start c || (c >= '0' && c <= '9') || c = '-' in
  let is_digit c = c >= '0' && c <= '9' in
  let is_identifier () = is_id_start s.[0] && CCString.for_all is_id_continue s in
  (* Number literal per the HCL grammar: one or more digits, an optional
     fractional part, and an optional exponent. *)
  let is_number () =
    is_digit s.[0]
    && CCString.for_all
         (fun c -> is_digit c || c = '.' || c = 'e' || c = 'E' || c = '+' || c = '-')
         s
  in
  (not (CCString.is_empty s)) && (is_identifier () || is_number ())

and pp_obj_key fmt = function
  | Hcl_parser_value.Obj_key.Bare s when is_bare_obj_key s -> Format.pp_print_string fmt s
  | Hcl_parser_value.Obj_key.Bare s -> pp_quoted_string fmt s
  | Hcl_parser_value.Obj_key.Quoted s -> pp_quoted_string fmt s
  | Hcl_parser_value.Obj_key.Template parts -> pp_quoted_template fmt parts
  | Hcl_parser_value.Obj_key.Computed e -> Format.fprintf fmt "(%a)" pp_expr e
  | Hcl_parser_value.Obj_key.Expr e -> pp_expr fmt e

let rec pp_hcl_value ~attr_width fmt = function
  | Hcl_parser_value.Attribute (id, expr) ->
      Format.fprintf fmt "%s = %a" (pad_right id attr_width) pp_expr expr
  | Hcl_parser_value.Block { type_; labels; body } -> (
      let labels_str =
        if CCList.is_empty labels then ""
        else " " ^ CCString.concat " " (CCList.map (Format.asprintf "%a" pp_block_label) labels)
      in
      match body with
      | [] -> Format.fprintf fmt "%s%s {@;}" type_ labels_str
      | _ ->
          let body_attr_width = max_attr_width body in
          Format.fprintf
            fmt
            "%s%s {@;<0 2>@[<v 0>%a@]@;}"
            type_
            labels_str
            (pp_body ~attr_width:body_attr_width)
            body)

and pp_body ~attr_width fmt body =
  let rec loop prev = function
    | [] -> ()
    | item :: rest ->
        (match (prev, item) with
        | Some _, Hcl_parser_value.Block _ -> Format.fprintf fmt "@;@;"
        | Some _, _ -> Format.fprintf fmt "@;"
        | None, _ -> ());
        pp_hcl_value ~attr_width fmt item;
        loop (Some item) rest
  in
  loop None body

let format_ast fmt ast =
  let attr_width = max_attr_width ast in
  let rec loop prev = function
    | [] -> ()
    | item :: rest ->
        (match prev with
        | Some _ -> Format.fprintf fmt "@;@;"
        | None -> ());
        pp_hcl_value ~attr_width fmt item;
        loop (Some item) rest
  in
  loop None ast

(* A heredoc marker is an HCL identifier, so it admits [-] and Unicode letters as well as ASCII
   word characters — see [Hcl_lexer.identifier_rest]. Bytes >= 0x80 are accepted wholesale because
   they can only be part of a UTF-8 encoded Unicode code point; what this has to exclude is the
   punctuation that would mark the [<<] as something other than an opener (quotes, braces, spaces),
   and every one of those is ASCII. Rejecting a legal marker un-guards the heredoc region below,
   which then loses its all-space content lines. *)
let is_marker_char c =
  match c with
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '-' -> true
  | c -> Char.code c >= 0x80

(* The heredoc a line opens, if it opens one: [<<MARKER] or [<<-MARKER] at end of line. Anchored at
   the end because that is the only place an opener can appear -- a [<<] inside a quoted value leaves
   the closing quote after it, so it cannot be mistaken for one. *)
let heredoc_open_marker line =
  match CCString.rfind ~sub:"<<" line with
  | -1 -> None
  | i ->
      let rest = CCString.drop (i + 2) line in
      let rest = if CCString.prefix ~pre:"-" rest then CCString.drop 1 rest else rest in
      if (not (CCString.is_empty rest)) && CCString.for_all is_marker_char rest then Some rest
      else None

(* The Format module inserts indentation after every break hint, including on blank lines used to
   separate blocks, which leaves trailing whitespace on lines meant to be empty. Those are blanked
   here.

   Heredoc bodies are exempt, and that exemption is the entire point. A heredoc line made only of
   spaces is *content*: the provider stores it, so blanking it changes the value and every later plan
   shows a diff against the stored one. Blanking every all-space line indiscriminately cannot tell a
   generated separator from a line the AST actually carries, because by this point both are just
   lines in one string. Tracking heredoc regions restores the distinction, using HCL's own rule: a
   region opens on a trailing [<<MARKER] and closes on the line whose trimmed text is that marker. *)
type ast = Hcl_parser_value.t list

let ast a =
  let raw = Format.asprintf "@[<v 0>%a@]" format_ast a in
  let _, rev_lines =
    CCList.fold_left
      (fun (in_heredoc, acc) line ->
        match in_heredoc with
        | Some marker ->
            let in_heredoc =
              if CCString.equal (CCString.trim line) marker then None else Some marker
            in
            (in_heredoc, line :: acc)
        | None ->
            let blanked = if CCString.for_all (( = ) ' ') line then "" else line in
            (heredoc_open_marker blanked, blanked :: acc))
      (None, [])
      (CCString.split_on_char '\n' raw)
  in
  CCString.concat "\n" (CCList.rev rev_lines)

let pp_ast fmt a = Format.pp_print_string fmt (ast a)
let show_ast = ast

let template parts =
  Format.asprintf "%a" (Format.pp_print_list ~pp_sep:(fun _ () -> ()) pp_template_part) parts

(* Render template parts as a heredoc body: literal bytes verbatim, only the
   [${] / [%{] introducers re-escaped. Reconstructs the raw body of a
   [Template_heredoc] (used by evaluation and other raw-body consumers). *)
let heredoc_template parts =
  Format.asprintf
    "%a"
    (Format.pp_print_list ~pp_sep:(fun _ () -> ()) pp_heredoc_template_part)
    parts

let expr e = Format.asprintf "%a" pp_expr e

(* Render an expression but stop once [max_len] bytes have been produced, appending ["..."]. The
   formatter's low-level output raises as soon as the budget is spent, so the recursive walk is
   abandoned mid-render: cost is O(max_len), not O(size of expr). A small margin keeps Format
   flushing into [out] eagerly (rather than buffering the whole line first), which is what lets the
   early termination actually bound the work. Used by callers that render one (possibly huge)
   expression per log line, where the full text is neither readable nor affordable. *)
exception Render_budget_spent

let expr_capped ~max_len e =
  if max_len <= 0 then ""
  else begin
    let buf = Buffer.create (min 1024 (max_len + 8)) in
    let truncated = ref false in
    let out s ofs len =
      let room = max_len - Buffer.length buf in
      if len <= room then Buffer.add_substring buf s ofs len
      else begin
        Buffer.add_substring buf s ofs (max 0 room);
        truncated := true;
        raise_notrace Render_budget_spent
      end
    in
    let fmt = Format.make_formatter out (fun () -> ()) in
    (* Margin = budget so Format flushes into [out] (and so trips the cap) within one margin's worth
       of material, rather than buffering the whole line first. *)
    Format.pp_set_margin fmt (max 2 max_len);
    (try Format.fprintf fmt "%a%!" pp_expr e with Render_budget_spent -> ());
    if !truncated then Buffer.add_string buf "...";
    Buffer.contents buf
  end

let files ?(comment_filenames = true) files =
  let buf = Buffer.create 1024 in
  let first = ref true in
  CCList.iter
    (fun (path, a) ->
      if not !first then Buffer.add_char buf '\n';
      if comment_filenames then Buffer.add_string buf (Printf.sprintf "# %s\n" path);
      Buffer.add_string buf (ast a);
      first := false)
    files;
  Buffer.contents buf
