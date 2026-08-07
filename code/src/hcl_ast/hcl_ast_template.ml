module Expr = Hcl_parser_value.Expr
module Template_part = Hcl_parser_value.Template_part
module Obj_key = Hcl_parser_value.Obj_key

let contains_template_syntax s =
  let is_unescaped_at pos prefix_char =
    (* Unescaped if not preceded by the same character. *)
    pos = 0 || s.[pos - 1] <> prefix_char
  in
  let has_unescaped_pattern ~sub ~prefix_char =
    CCString.find_all_l ~sub s |> CCList.exists (fun pos -> is_unescaped_at pos prefix_char)
  in
  has_unescaped_pattern ~sub:"${" ~prefix_char:'$'
  || has_unescaped_pattern ~sub:"%{" ~prefix_char:'%'

(* If [s].[i..i+2] is a template escape ($${ or %%{), append the unescaped
   two bytes ($ or %, then {) to [buf] and return the position past the
   escape. Shared by [parse_template_string] and [unescape_literal] so the
   two decoding paths stay in lockstep. *)
let try_consume_template_escape buf s len i =
  if (s.[i] = '$' || s.[i] = '%') && i + 2 < len && s.[i + 1] = s.[i] && s.[i + 2] = '{' then (
    Buffer.add_char buf s.[i];
    Buffer.add_char buf '{';
    Some (i + 3))
  else None

(* Resolve template escape sequences in a literal string: $${ -> ${ and
   %%{ -> %{. Other characters pass through unchanged. *)
let unescape_literal s =
  let len = CCString.length s in
  let buf = Buffer.create len in
  let rec loop i =
    if i >= len then ()
    else
      match try_consume_template_escape buf s len i with
      | Some i' -> loop i'
      | None ->
          Buffer.add_char buf s.[i];
          loop (i + 1)
  in
  loop 0;
  Buffer.contents buf

(* Inverse of [unescape_literal]: re-introduce template escapes in a resolved
   literal string ($ { -> $${ and %{ -> %%{) so it re-encodes to source form.
   Only the template introducers are escaped — quote/newline escaping belongs
   to the surrounding encoder (HCL printer, JSON), not here. *)
let escape_literal s =
  let len = CCString.length s in
  let buf = Buffer.create (len + 8) in
  let rec loop i =
    if i >= len then ()
    else if (s.[i] = '$' || s.[i] = '%') && i + 1 < len && s.[i + 1] = '{' then (
      Buffer.add_char buf s.[i];
      Buffer.add_char buf s.[i];
      Buffer.add_char buf '{';
      loop (i + 2))
    else (
      Buffer.add_char buf s.[i];
      loop (i + 1))
  in
  loop 0;
  Buffer.contents buf

(* Scan for the [}] that closes a [${] / [%{] whose brace body begins at [i]
   with [depth] braces already open, skipping nested [{}] and string literals —
   whose content may contain unbalanced braces and further nested
   interpolations. Shared by [parse_template_string_raw] (to extract an
   interpolation's expression) and [flush_heredoc_body] (to skip a span while
   splitting lines) so the two always agree on where a span ends. Returns the
   index of the closing brace, or [None] at end of input. *)
let rec scan_closing_brace s len i depth =
  if i >= len then None
  else
    match s.[i] with
    | '{' -> scan_closing_brace s len (i + 1) (depth + 1)
    | '}' -> if depth = 0 then Some i else scan_closing_brace s len (i + 1) (depth - 1)
    | '"' -> scan_closing_brace s len (scan_skip_string s len (i + 1)) depth
    | _ -> scan_closing_brace s len (i + 1) depth

and scan_skip_string s len j =
  if j >= len then j
  else
    match s.[j] with
    | '"' -> j + 1
    | '\\' when j + 1 < len -> scan_skip_string s len (j + 2)
    | ('$' | '%') as c when j + 2 < len && s.[j + 1] = c && s.[j + 2] = '{' ->
        (* Template escape [$${] / [%%{] — three literal bytes, not an opener. *)
        scan_skip_string s len (j + 3)
    | ('$' | '%') when j + 1 < len && s.[j + 1] = '{' -> (
        (* Nested interpolation/directive inside the string literal. *)
        match scan_closing_brace s len (j + 2) 0 with
        | None -> j + 2
        | Some close -> scan_skip_string s len (close + 1))
    | _ -> scan_skip_string s len (j + 1)

(* Leading run of White_Space code points of [s] starting at [i], stopping at
   [\n]; returns (code-point count, byte position after the run). Shared by both
   flush passes so they agree on what indentation is. *)
let leading_ws_from s i =
  let n = CCString.length s in
  let rec go i runes =
    if i >= n then (runes, i)
    else
      let d = String.get_utf_8_uchar s i in
      let u = Uchar.utf_decode_uchar d in
      if Uchar.equal u (Uchar.of_char '\n') then (runes, i)
      else if Uucp.White.is_white_space u then go (i + Uchar.utf_decode_length d) (runes + 1)
      else (runes, i)
  in
  go i 0

(* Byte position [m] code points past [i] in [s], clamped to the end. *)
let advance_runes s i m =
  let n = CCString.length s in
  let rec go i m =
    if m = 0 || i >= n then i
    else go (i + Uchar.utf_decode_length (String.get_utf_8_uchar s i)) (m - 1)
  in
  go i m

(* HCL [<<-] (flush) heredoc indent strip over a raw body, for a body with no
   template syntax in it. A body that has template syntax goes through
   {!flush_heredoc_parts} instead, after parsing, because its [~] markers decide
   what still counts as indentation; with no markers to resolve there is nothing
   to order and the raw text can be stripped directly. The rules are the same:
     - lines are split on newlines OUTSIDE any [${...}] / [%{...}] span, so a
       newline inside an interpolation or directive never starts a new line;
     - a line's indent is the leading run of Unicode White_Space code points
       (Go's [unicode.IsSpace] is exactly the White_Space property: space, tab,
       NBSP U+00A0, em space U+2003, ...), counted one per code point; a line
       that begins with a span has indent 0;
     - the minimum indent over all non-blank lines is removed from the start of
       every non-blank line; empty / all-whitespace lines don't affect the
       minimum and are left verbatim.
   [$${] / [%%{] are literal escapes, not spans. Spans are located with
   {!scan_closing_brace}, the same scanner {!parse_template_string_raw} uses, so
   flush and parse always agree on span boundaries. *)
let flush_heredoc_body body =
  let len = CCString.length body in
  (* Split into physical lines (each keeping its trailing newline), treating
     [${...}] / [%{...}] spans as opaque so their interior newlines don't split. *)
  let split_lines () =
    let lines = ref [] in
    let buf = Buffer.create 64 in
    let i = ref 0 in
    while !i < len do
      let c = body.[!i] in
      if c = '\n' then (
        Buffer.add_char buf '\n';
        lines := Buffer.contents buf :: !lines;
        Buffer.clear buf;
        incr i)
      else if (c = '$' || c = '%') && !i + 2 < len && body.[!i + 1] = c && body.[!i + 2] = '{' then (
        (* [$${] / [%%{] escape: three literal bytes, not a span. *)
        Buffer.add_substring buf body !i 3;
        i := !i + 3)
      else if (c = '$' || c = '%') && !i + 1 < len && body.[!i + 1] = '{' then (
        (* Interpolation / directive span: copy verbatim (interior newlines
           included) so the whole span stays on one line. *)
        let close =
          match scan_closing_brace body len (!i + 2) 0 with
          | Some p -> p + 1
          | None -> len
        in
        Buffer.add_substring buf body !i (close - !i);
        i := close)
      else (
        Buffer.add_char buf c;
        incr i)
    done;
    if Buffer.length buf > 0 then lines := Buffer.contents buf :: !lines;
    CCList.rev !lines
  in
  (* Starting at 0, the byte position after the run is its byte length. *)
  let leading_ws line = leading_ws_from line 0 in
  (* A line is blank when its content up to the trailing newline is entirely
     white space (so its leading-whitespace run spans the whole line). *)
  let is_blank line ws_bytes =
    let n = CCString.length line in
    let core = if n > 0 && line.[n - 1] = '\n' then n - 1 else n in
    ws_bytes >= core
  in
  let infos =
    split_lines ()
    |> CCList.map (fun l ->
        let runes, bytes = leading_ws l in
        (l, runes, is_blank l bytes))
  in
  let min_indent =
    CCList.fold_left
      (fun acc (_, runes, blank) ->
        if blank then acc
        else
          match acc with
          | None -> Some runes
          | Some m -> Some (min m runes))
      None
      infos
  in
  match min_indent with
  | None | Some 0 -> body
  | Some m ->
      (* Drop the first [m] leading code points (all white space, since
         [m <= indent]) from every non-blank line. *)
      let drop_leading_runes line =
        let n = CCString.length line in
        let rec advance i k =
          if k = 0 || i >= n then i
          else advance (i + Uchar.utf_decode_length (String.get_utf_8_uchar line i)) (k - 1)
        in
        let start = advance 0 m in
        CCString.sub line start (n - start)
      in
      infos
      |> CCList.map (fun (line, _, blank) -> if blank then line else drop_leading_runes line)
      |> CCString.concat ""

(* HCL [<<-] (flush) heredoc indent strip for a template body, applied to the
   PARSED parts — after {!parse_template_string_raw} has resolved the [~] strip
   markers. hclsyntax works the same way round: it scans the template first and
   flushes afterwards, in [flushHeredocTemplate].

   The ordering is observable, and getting it backwards is a value-changing bug.
   A [~] adjacent to a newline consumes that newline, so the whitespace opening
   the next source line stops being indentation and becomes ordinary mid-line
   text. hclsyntax flushes after the marker has run and therefore leaves it
   alone; flushing the raw body first strips it as indentation and shortens the
   value. The shortened value still applies, so state keeps what tofu produced
   and every later plan renders an update whose two sides differ only in
   whitespace.

   The indent rules are {!flush_heredoc_body}'s, restated over parts:
     - a line starts at the beginning of the body and after every [\n] inside a
       literal; a line that starts anywhere else (mid-literal text left over
       from a consumed newline) is not a line start and is never dedented;
     - a line's indent is its leading run of White_Space code points; a line
       whose first element is an interpolation or directive has indent 0, which
       pins the minimum at 0 and so disables the flush for the whole body;
     - blank (empty / all-whitespace) lines neither contribute to the minimum
       nor get dedented. A line holding only whitespace before a span is NOT
       blank — the span is content.

   Literals are visited in document order, descending into directive bodies,
   because a directive's body text is part of the same physical lines as the
   text around it. *)
let flush_heredoc_parts parts =
  let module Scan = struct
    (* Line position while walking the item list. [`Pending] is a line start whose
       blankness is still undecided because the literal ended inside its whitespace
       run: a span next makes the line content, nothing next leaves it blank. *)
    type state =
      [ `In_line
      | `At_line_start
      | `Pending of int * int * int
      ]

    (* Pass 1's accumulator: the line position, plus the two results being built --
       the minimum indent over non-blank lines, and the (literal index, byte offset,
       indent) of every non-blank line start that owns its indentation. *)
    type t = {
      state : state;
      min_indent : int option;
      starts : (int * int * int) list;
    }
  end in
  (* Literals in document order, each with the index the rewrite pass below will see. *)
  let items =
    let rec fold_parts (acc, idx) parts = CCList.fold_left fold_part (acc, idx) parts
    and fold_part (acc, idx) = function
      | Template_part.Literal s -> (`Lit (idx, s) :: acc, idx + 1)
      | Template_part.Interpolation _ -> (`Span :: acc, idx)
      | Template_part.If_directive { then_; else_; _ } ->
          let acc_idx = fold_parts (`Span :: acc, idx) then_ in
          let acc, idx =
            CCOption.map_or
              ~default:acc_idx
              (fun else_ ->
                let acc, idx = acc_idx in
                fold_parts (`Span :: acc, idx) else_)
              else_
          in
          (`Span :: acc, idx)
      | Template_part.For_directive { body; _ } ->
          let acc, idx = fold_parts (`Span :: acc, idx) body in
          (`Span :: acc, idx)
    in
    fold_parts ([], 0) parts |> fst |> CCList.rev
  in
  (* Pass 1: the minimum indent, and the (literal, byte offset) of every
     non-blank line start that owns its indentation. *)
  let contribute runes acc =
    {
      acc with
      Scan.min_indent = Some (CCOption.map_or ~default:runes (CCInt.min runes) acc.Scan.min_indent);
    }
  in
  let record ((_, _, runes) as start) acc =
    contribute runes { acc with Scan.starts = start :: acc.Scan.starts }
  in
  (* The state the fold ends on is never read: a run still pending there has
     nothing after it to make it content, so its line is blank. *)
  let scan_result =
    CCList.fold_left
      (fun acc item ->
        match (item, acc.Scan.state) with
        | `Span, `Pending start -> { (record start acc) with Scan.state = `In_line }
        | `Span, `At_line_start ->
            (* A line whose first element is a span has indent 0, which pins the
               minimum at 0 and disables the flush for the whole body. *)
            { (contribute 0 acc) with Scan.state = `In_line }
        | `Span, `In_line -> { acc with Scan.state = `In_line }
        | `Lit (idx, s), state ->
            let len = CCString.length s in
            let rec scan i (state : [ `In_line | `At_line_start ]) acc =
              if i >= len then { acc with Scan.state :> Scan.state }
              else
                match state with
                | `In_line ->
                    (* Text before the next newline belongs to a line that
                       started earlier, so it is neither measured nor dedented. *)
                    CCOption.map_or
                      ~default:{ acc with Scan.state = `In_line }
                      (fun nl -> scan (nl + 1) `At_line_start acc)
                      (CCString.index_from_opt s i '\n')
                | `At_line_start ->
                    let runes, after_ws = leading_ws_from s i in
                    if after_ws >= len then { acc with Scan.state = `Pending (idx, i, runes) }
                    else if Char.equal s.[after_ws] '\n' then scan (after_ws + 1) `At_line_start acc
                    else scan after_ws `In_line (record (idx, i, runes) acc)
            in
            (* A [`Pending] cannot reach a literal: consecutive literals always
               have a span between them, which resolves it first. *)
            let entry =
              match state with
              | `In_line -> `In_line
              | `At_line_start | `Pending _ -> `At_line_start
            in
            if len = 0 then acc else scan 0 entry acc)
      { Scan.state = `At_line_start; min_indent = None; starts = [] }
      items
  in
  match scan_result.Scan.min_indent with
  | None | Some 0 -> parts
  | Some m ->
      (* Pass 2: drop [m] leading code points at each recorded line start. All
         of them are white space, since [m] is at most that line's indent. *)
      let offsets_of_literal =
        CCList.fold_left
          (fun acc (idx, off, _) ->
            let prev = CCOption.get_or ~default:[] (CCList.assoc_opt ~eq:CCInt.equal idx acc) in
            CCList.Assoc.set ~eq:CCInt.equal idx (off :: prev) acc)
          []
          scan_result.Scan.starts
      in
      let dedent offsets s =
        let buf = Buffer.create (CCString.length s) in
        let pos =
          CCList.fold_left
            (fun pos off ->
              Buffer.add_substring buf s pos (off - pos);
              advance_runes s off m)
            0
            (CCList.sort CCInt.compare offsets)
        in
        Buffer.add_substring buf s pos (CCString.length s - pos);
        Buffer.contents buf
      in
      (* [idx] is threaded rather than counted in a [ref] so the numbering is tied
         to the traversal that produces it: the literal order here has to be the
         one [fold_parts] assigned above, or the offsets land on the wrong
         literal. *)
      let rec map_parts idx parts =
        let parts, idx =
          CCList.fold_left
            (fun (acc, idx) p ->
              let p, idx = map_part idx p in
              (p :: acc, idx))
            ([], idx)
            parts
        in
        (CCList.rev parts, idx)
      and map_part idx = function
        | Template_part.Literal s ->
            let s =
              CCOption.map_or
                ~default:s
                (fun offsets -> dedent offsets s)
                (CCList.assoc_opt ~eq:CCInt.equal idx offsets_of_literal)
            in
            (Template_part.Literal s, idx + 1)
        | Template_part.Interpolation _ as p -> (p, idx)
        | Template_part.If_directive { cond; then_; else_; strip_before; strip_after } ->
            let then_, idx = map_parts idx then_ in
            let else_, idx =
              CCOption.map_or
                ~default:(None, idx)
                (fun else_ ->
                  let else_, idx = map_parts idx else_ in
                  (Some else_, idx))
                else_
            in
            (Template_part.If_directive { cond; then_; else_; strip_before; strip_after }, idx)
        | Template_part.For_directive { vars; input; body; strip_before; strip_after } ->
            let body, idx = map_parts idx body in
            (Template_part.For_directive { vars; input; body; strip_before; strip_after }, idx)
      in
      map_parts 0 parts |> fst

type template_error =
  | Unclosed_interpolation
  | Unclosed_directive
  | Empty_directive
  | Invalid_interpolation_expression
  | Invalid_control_keyword
  | Extra_chars_in_else_marker
  | Unexpected_end_of_template
  | Unbalanced_directive of [ `Else | `Endif | `Endfor ]
  | Template_in_block_label of string

let string_of_template_error = function
  | Unclosed_interpolation -> "Unclosed template interpolation sequence"
  | Unclosed_directive -> "Unclosed template directive"
  | Empty_directive -> "Invalid template directive"
  | Invalid_interpolation_expression -> "Invalid expression in interpolation"
  | Invalid_control_keyword -> "Invalid template control keyword"
  | Extra_chars_in_else_marker -> "Extra characters in else marker"
  | Unexpected_end_of_template -> "Unexpected end of template"
  | Unbalanced_directive kind ->
      let name =
        match kind with
        | `Else -> "else"
        | `Endif -> "endif"
        | `Endfor -> "endfor"
      in
      Printf.sprintf "Unexpected %s directive" name
  | Template_in_block_label s ->
      Printf.sprintf "Template sequences are not allowed in this string: %S" s

module Make (P : sig
  val parse_expr_string : string -> Expr.t option
end) =
struct
  (* Raised internally by the recursive scanner when it spots a malformed template; converted to
     [Error] at each exported boundary by [to_result]. Kept internal (not in the .mli). *)
  exception Template_error of template_error

  (* Parse a string containing template syntax into Template_part list.

     [${expr}] becomes [Interpolation]; [%{if cond}..%{else}..%{endif}] and
     [%{for var in xs}..%{endfor}] become [If_directive] and [For_directive]
     respectively. Directives can nest; matching is by recursive descent. *)

  let parse_template_string_raw s =
    if not (contains_template_syntax s) then None
    else
      let len = CCString.length s in
      (* Brace/string-aware span scanning is shared with [flush_heredoc_body]
         via the top-level {!scan_closing_brace} / {!scan_skip_string}; this thin
         wrapper just fixes [s] / [len] for the [extract_braced] call below. *)
      let find_closing_brace i depth = scan_closing_brace s len i depth in
      (* Extract the content of a [${...}] or [%{...}] whose opener is at
         [i]. Returns [(content, strip_before, strip_after, end_pos)] or
         [None] when no matching [}] can be found; [end_pos] points past
         the closing brace. *)
      let extract_braced i =
        let start = i + 2 in
        let strip_before, content_start =
          if start < len && s.[start] = '~' then (true, start + 1) else (false, start)
        in
        match find_closing_brace content_start 0 with
        | None -> None
        | Some close_pos ->
            let content_end, strip_after =
              if close_pos > content_start && s.[close_pos - 1] = '~' then (close_pos - 1, true)
              else (close_pos, false)
            in
            let content = CCString.sub s content_start (content_end - content_start) in
            Some (content, strip_before, strip_after, close_pos + 1)
      in
      (* Recognize the directive kind given the trimmed [%{...}] content.
         [None] means the content isn't a known directive — callers then
         emit the raw [%{...}] as a literal, matching the prior behavior
         when directive parsing was a stub. *)
      (* A character that can continue an identifier (roughly ID_Continue);
         used to tell whether a substring match of a keyword like [if] /
         [for] / [in] is actually the full keyword and not the prefix of a
         longer identifier ([ifoo], [format], [invariant]). Kept to ASCII
         since HCL directive keywords are ASCII — a non-ASCII byte is
         treated as a separator, which correctly rejects e.g. [iféclair]
         as a lone [if] token. *)
      let is_ident_continue c =
        (c >= 'a' && c <= 'z')
        || (c >= 'A' && c <= 'Z')
        || (c >= '0' && c <= '9')
        || c = '_'
        || c = '-'
      in
      (* [starts_with_keyword s kw] is [true] iff [s] begins with [kw]
         followed by either end-of-string or a non-ident-continue char.
         Mirrors hclsyntax, where the directive keyword is a regular
         TokenIdent whose boundary is just the end of the identifier run
         (so [%{if(cond)}] — no space between [if] and [(] — is valid). *)
      let starts_with_keyword s kw =
        let klen = CCString.length kw in
        let slen = CCString.length s in
        slen >= klen
        && CCString.equal (CCString.sub s 0 klen) kw
        && (slen = klen || not (is_ident_continue s.[klen]))
      in
      let classify_directive content :
          [ `If of Expr.t | `For of (string * string option) * Expr.t | `Else | `Endif | `Endfor ]
          option =
        let trimmed = CCString.trim content in
        if CCString.equal trimmed "else" then Some `Else
        else if CCString.equal trimmed "endif" then Some `Endif
        else if CCString.equal trimmed "endfor" then Some `Endfor
        else if starts_with_keyword trimmed "else" then
          (* [%{else ...}] (e.g. the common-but-unsupported [%{else if ...}]
             chain): hclsyntax rejects with "Extra characters in else marker;
             Expected a closing brace to end the sequence, but found extra
             characters." Falling through would treat the whole sequence as
             literal text, hiding the typo. *)
          raise (Template_error Extra_chars_in_else_marker)
        else if starts_with_keyword trimmed "if" then
          let rest = CCString.sub trimmed 2 (CCString.length trimmed - 2) |> CCString.trim in
          match P.parse_expr_string rest with
          | Some expr -> Some (`If expr)
          | None -> None
        else if starts_with_keyword trimmed "for" then
          let rest = CCString.sub trimmed 3 (CCString.length trimmed - 3) |> CCString.trim in
          let rlen = CCString.length rest in
          (* Find the [in] keyword: two-character match with non-ident
             boundaries on both sides (start-of-string counts as a
             boundary). Rejects matches inside idents like [invariant]. *)
          let rec find_in_keyword k =
            if k + 2 > rlen then None
            else if
              rest.[k] = 'i'
              && rest.[k + 1] = 'n'
              && (k = 0 || not (is_ident_continue rest.[k - 1]))
              && (k + 2 = rlen || not (is_ident_continue rest.[k + 2]))
            then Some k
            else find_in_keyword (k + 1)
          in
          match find_in_keyword 0 with
          | None -> None
          | Some p -> (
              let vars_text = CCString.trim (CCString.sub rest 0 p) in
              let expr_text = CCString.trim (CCString.sub rest (p + 2) (rlen - p - 2)) in
              match P.parse_expr_string expr_text with
              | None -> None
              | Some input ->
                  (* Template_part.For_directive.vars = [value, optional key]:
                     [%{for v in xs}] → [("v", None)]; [%{for k, v in xs}] →
                     [("v", Some "k")]. *)
                  let vars =
                    match CCString.Split.left ~by:"," vars_text with
                    | Some (k, v) -> (CCString.trim v, Some (CCString.trim k))
                    | None -> (vars_text, None)
                  in
                  Some (`For (vars, input)))
        else None
      in
      (* Parse template parts from [start], stopping when [is_stop] accepts
         a directive kind (typically [`Endif]/[`Else]/[`Endfor]). Returns
         [(parts, end_pos, Some (kind, strip_before, strip_after))] when
         stopped at a terminator, or [(parts, len, None)] at EOF. Each call
         owns a fresh literal buffer so nested directive bodies don't leak
         partial literals into their parent.

         Strip-marker (tilde) handling mirrors hclsyntax's
         [parseTemplateParts] [ltrim]/[ltrimNext] logic. Each brace-delimited
         token carries a [strip_before] (tilde right after the opening `{`)
         and a [strip_after] (tilde right before the closing `}`).
         [strip_before] trims trailing whitespace of the last-accumulated
         literal; [strip_after] is propagated forward as [ltrim_next], which
         drops leading whitespace of the next literal character stream. Both
         are line-scoped, reaching only the literal's adjacent line — see
         [trim_last_line] below for why.
         Directive terminators ([%{else}], [%{endif}], [%{endfor}]) apply
         their own strip flags to the literals they border — and in
         particular a terminator's [strip_after] must propagate out of the
         recursive call so the OUTER loop trims the literal that follows
         the whole directive. That info is returned as the [sa] component
         of [Some (kind, sb, sa)] and consumed by the caller. *)
      let ws_char = function
        | ' ' | '\t' | '\r' | '\n' -> true
        | _ -> false
      in
      (* hclsyntax scans a template literal as one token per line, each token carrying its own
         trailing newline, and a strip marker reaches only the token it touches. A [~] before a
         directive therefore trims the literal's LAST line and stops: whitespace sitting on earlier
         lines is part of the value. Trimming the whole run instead silently shortens the string --
         and because the shortened value still applies, state keeps what tofu produced and every
         later plan renders an update whose two sides differ only in trailing spaces.

         [last_line_start] is that final token's offset: the byte after the last newline, ignoring a
         newline in final position because it terminates the last token rather than opening a new
         one ([" \n"] is one token, [" \nx"] is two). *)
      let last_line_start s =
        let len = CCString.length s in
        let rec find k =
          if k < 0 then 0 else if Char.equal s.[k] '\n' then k + 1 else find (k - 1)
        in
        if len = 0 then 0 else find (len - 2)
      in
      let trim_last_line s =
        let start = last_line_start s in
        CCString.take start s ^ CCString.rdrop_while ws_char (CCString.drop start s)
      in
      let trim_right_buf buf =
        let content = Buffer.contents buf in
        let trimmed = trim_last_line content in
        if CCString.length trimmed < CCString.length content then (
          Buffer.clear buf;
          Buffer.add_string buf trimmed)
      in
      let rec parse_body ~is_stop ~initial_ltrim start =
        let buf = Buffer.create 64 in
        let ltrim_next = ref initial_ltrim in
        let add_char c =
          if !ltrim_next && Buffer.length buf = 0 && ws_char c then (
            if
              (* The leading-side mirror of [trim_last_line]: a [~] after an interpolation or
               directive reaches only the FIRST line token of the literal that follows, so consuming
               that token's newline ends the trim and everything past it is content. *)
              Char.equal c '\n'
            then ltrim_next := false)
          else (
            ltrim_next := false;
            Buffer.add_char buf c)
        in
        let flush parts =
          (* Clear ltrim_next when a literal gets flushed: it only applies
             to the most recent literal being built. *)
          ltrim_next := false;
          if Buffer.length buf = 0 then parts
          else
            let p = Template_part.Literal (Buffer.contents buf) :: parts in
            Buffer.clear buf;
            p
        in
        let rec loop parts i =
          if i >= len then (CCList.rev (flush parts), i, None)
          else
            match try_consume_template_escape buf s len i with
            | Some i' -> loop parts i'
            | None ->
                let c = s.[i] in
                if c = '$' && i + 1 < len && s.[i + 1] = '{' then
                  match extract_braced i with
                  | None ->
                      (* A [${] opener with no matching [}] before end of input.
                         hclsyntax rejects with "Unclosed template interpolation
                         sequence". Previously we kept the [${...] as literal
                         text, silently accepting a template tofu rejects. *)
                      raise (Template_error Unclosed_interpolation)
                  | Some (content, strip_before, strip_after, end_pos) -> (
                      match P.parse_expr_string (CCString.trim content) with
                      | Some expr ->
                          if strip_before then trim_right_buf buf;
                          let parts = flush parts in
                          let parts =
                            Template_part.Interpolation { expr; strip_before; strip_after } :: parts
                          in
                          if strip_after then ltrim_next := true;
                          loop parts end_pos
                      | None ->
                          (* Expression didn't parse *)
                          raise (Template_error Invalid_interpolation_expression))
                else if c = '%' && i + 1 < len && s.[i + 1] = '{' then
                  match extract_braced i with
                  | None ->
                      (* A [%{] opener with no matching [}] before end of input.
                         hclsyntax rejects with "Unclosed template directive".
                         Previously we kept the [%{...] as literal text. *)
                      raise (Template_error Unclosed_directive)
                  | Some (content, _, _, _) when CCString.is_empty (CCString.trim content) ->
                      raise (Template_error Empty_directive)
                  | Some (content, strip_before, strip_after, end_pos) -> (
                      (* A non-empty sequence that [classify_directive] didn't recognize
                         (e.g. [%{while true}], [%{unknown_keyword}]). *)
                      match classify_directive content with
                      | None ->
                          (* A non-empty sequence that [classify_directive]
                             didn't recognize (e.g. [%{while true}],
                             [%{unknown_keyword}]). hclsyntax rejects with
                             "Invalid template control keyword". Previously
                             we kept the whole sequence as literal text,
                             hiding typos. *)
                          raise (Template_error Invalid_control_keyword)
                      (* A terminator's own [strip_before] is applied here, to the buffer, before the
                         literal is flushed — so the parts handed back to the caller are already
                         trimmed and the caller must not trim them again. The trim is line-scoped
                         and therefore not idempotent: a second pass would eat the line above. *)
                      | Some kind when is_stop kind ->
                          if strip_before then trim_right_buf buf;
                          (CCList.rev (flush parts), end_pos, Some (kind, strip_before, strip_after))
                      | Some (`If cond) ->
                          if strip_before then trim_right_buf buf;
                          let parts = flush parts in
                          (* [strip_after] on the opener propagates into
                             the then-branch as initial_ltrim. *)
                          let then_, after_then, term_then =
                            parse_body
                              ~is_stop:(fun k -> k = `Else || k = `Endif)
                              ~initial_ltrim:strip_after
                              end_pos
                          in
                          let collapse_empty_else = function
                            | [] -> None
                            | [ Template_part.Literal "" ] -> None
                            | xs -> Some xs
                          in
                          let then_, else_, after_all, endif_strip_after =
                            match term_then with
                            | Some (`Else, _, else_sa) ->
                                let e, ai, term_else =
                                  parse_body
                                    ~is_stop:(fun k -> k = `Endif)
                                    ~initial_ltrim:else_sa
                                    after_then
                                in
                                let e, endif_sa =
                                  match term_else with
                                  | Some (`Endif, _, endif_sa) -> (e, endif_sa)
                                  | None ->
                                      (* Ran off the end of the template without
                                         hitting [%{endif}]. hclsyntax rejects
                                         with "Unexpected end of template; The
                                         if directive ... is missing its
                                         corresponding endif directive." *)
                                      raise (Template_error Unexpected_end_of_template)
                                  | _ -> (e, false)
                                in
                                (then_, collapse_empty_else e, ai, endif_sa)
                            | Some (`Endif, _, endif_sa) -> (then_, None, after_then, endif_sa)
                            | None ->
                                (* No terminator for the [%{if}] — same shim
                                   diagnostic as the missing-endif case in the
                                   else branch above. *)
                                raise (Template_error Unexpected_end_of_template)
                            | _ -> (then_, None, after_then, false)
                          in
                          let parts =
                            Template_part.If_directive
                              { cond; then_; else_; strip_before; strip_after }
                            :: parts
                          in
                          if endif_strip_after then ltrim_next := true;
                          loop parts after_all
                      | Some (`For (vars, input)) ->
                          if strip_before then trim_right_buf buf;
                          let parts = flush parts in
                          let body, after_body, term_body =
                            parse_body
                              ~is_stop:(fun k -> k = `Endfor)
                              ~initial_ltrim:strip_after
                              end_pos
                          in
                          let endfor_strip_after =
                            match term_body with
                            | Some (`Endfor, _, endfor_sa) -> endfor_sa
                            | None ->
                                (* Ran off the end of the template without hitting
                                   [%{endfor}]. hclsyntax rejects with "Unexpected
                                   end of template; The for directive ... is missing
                                   its corresponding endfor directive." Mirrors the
                                   missing-[%{endif}] case in the [`If] branch. *)
                                raise (Template_error Unexpected_end_of_template)
                            | _ -> false
                          in
                          let parts =
                            Template_part.For_directive
                              { vars; input; body; strip_before; strip_after }
                            :: parts
                          in
                          if endfor_strip_after then ltrim_next := true;
                          loop parts after_body
                      | Some ((`Else as k) | (`Endif as k) | (`Endfor as k)) ->
                          (* Orphan terminator with no matching opener.
                             hclsyntax rejects with "Unexpected else/endif/
                             endfor directive; The control directives within
                             this template are unbalanced." Previously we
                             kept the literal text, hiding the typo. *)
                          raise (Template_error (Unbalanced_directive k)))
                else (
                  add_char c;
                  loop parts (i + 1))
        in
        loop [] start
      in
      let parts, _, _ = parse_body ~is_stop:(fun _ -> false) ~initial_ltrim:false 0 in
      Some parts

  (* Transform a string into Expr.Template if it contains template syntax,
     otherwise return Expr.String with escape sequences resolved.

     Nested expressions inside interpolation parts come from [parse_expr_string]
     without having been transformed, so recursively transform them here;
     otherwise an [Expr.String] nested inside a [Fun_call] argument (e.g.
     [sha256("${var.x}-y")] inside an outer [${...}]) would survive as a raw
     string and get escaped by [escape_hcl_string] at print time, mangling
     [${var.x}] into [$${var.x}]. *)
  let rec transform_string s =
    match parse_template_string_raw s with
    | Some parts ->
        Expr.Template (CCList.map (Hcl_ast_walker.map_in_template_part transform_f) parts)
    | None -> Expr.String (unescape_literal s)

  (* The parser emits every quoted-string object key as [Obj_key.Quoted s],
     even when [s] carries [${...}] / [%{...}] template syntax — but per
     the HCL spec such a key is a computed expression that evaluates the
     template. Promote those to [Obj_key.Template] here. Plain (non-
     template) [Quoted] payloads still get [unescape_literal] applied so
     [$${] / [%%{] source escapes round-trip through the AST the same way
     they do for [Expr.String]. [Computed] / [Expr] / [Template] recurse
     into their inner expressions; [Bare] is a leaf. *)
  and transform_obj_key k =
    match k with
    | Obj_key.Quoted s -> (
        match parse_template_string_raw s with
        | Some parts ->
            let parts = CCList.map (Hcl_ast_walker.map_in_template_part transform_f) parts in
            Obj_key.Template parts
        | None -> Obj_key.Quoted (unescape_literal s))
    | Obj_key.Template parts ->
        Obj_key.Template (CCList.map (Hcl_ast_walker.map_in_template_part transform_f) parts)
    | Obj_key.Computed e -> Obj_key.Computed (Hcl_ast_walker.map_in_expr transform_f e)
    | Obj_key.Expr e -> Obj_key.Expr (Hcl_ast_walker.map_in_expr transform_f e)
    | Obj_key.Bare _ -> k

  and transform_f expr =
    match expr with
    | Expr.String s -> Some (transform_string s)
    | Expr.Object pairs ->
        Some
          (Expr.Object
             (CCList.map
                (fun (k, v) -> (transform_obj_key k, Hcl_ast_walker.map_in_expr transform_f v))
                pairs))
    (* A heredoc whose body carries [${...}] / [%{...}] template syntax is
       promoted to [Template_heredoc] so its interpolations are structured —
       references and evaluation see them, while it still renders back as a
       heredoc. A plain literal heredoc stays [Heredoc]. [Heredoc'] ([<<-])
       additionally has its common leading whitespace stripped. *)
    | Expr.Heredoc (marker, body) -> Some (promote_heredoc ~flush:false marker body)
    | Expr.Heredoc' (marker, body) -> Some (promote_heredoc ~flush:true marker body)
    | _ -> None

  and promote_heredoc ~flush marker body =
    (* Promote to a structured [Template_heredoc] when the body carries
       interpolations, otherwise keep a literal [Heredoc] (its [$${] / [%%{]
       escapes are resolved at evaluation time, matching how [Expr.Heredoc]
       values are read).

       [<<-] flush strips the common leading whitespace AFTER the template has
       been parsed, because the [~] strip markers resolved during parsing decide
       what still counts as indentation — see {!flush_heredoc_parts}. A body with
       no template syntax has no markers, so flushing its raw text is the same
       computation, and {!flush_heredoc_body} does it in one pass.

       The strip happens here, at load time, and the printer does not re-emit the
       [<<-]: hclsyntax bakes it in while parsing too, and the shim-parity tests
       hold both ASTs to the same shape. Preserving the marker means preserving
       source tokens, which is a CST rather than this AST. *)
    match parse_template_string_raw body with
    | Some parts ->
        let parts = if flush then flush_heredoc_parts parts else parts in
        Expr.Template_heredoc
          (marker, CCList.map (Hcl_ast_walker.map_in_template_part transform_f) parts)
    | None -> Expr.Heredoc (marker, if flush then flush_heredoc_body body else body)

  let rec check_block_labels = function
    | [] -> ()
    | Hcl_parser_value.Attribute _ :: rest -> check_block_labels rest
    | Hcl_parser_value.Block { labels; body; _ } :: rest ->
        List.iter
          (function
            | Hcl_parser_value.Block_label.Lit s when contains_template_syntax s ->
                (* Include the offending label so users can locate it *)
                raise (Template_error (Template_in_block_label s))
            | _ -> ())
          labels;
        check_block_labels body;
        check_block_labels rest

  (* The exported entry points convert the internal [Template_error] exception
     ([classify_directive] / [parse_body] / [check_block_labels] all raise it
     when they spot a shim-rejected pattern) into [Result.Error] at the API
     boundary, so callers don't have to wrap each call in their own [try … with].
     The implementation still uses an exception because it's more convenient for
     nested recovery inside the recursive template scanner. Only [Template_error]
     is caught — an unrelated [Failure] from a nested call propagates rather than
     being mislabeled a template parse error. *)
  let to_result f x = try Ok (f x) with Template_error e -> Error e
  let transform_expr = to_result (Hcl_ast_walker.map_in_expr transform_f)

  let transform_ast =
    to_result (fun ast ->
        check_block_labels ast;
        Hcl_ast_walker.map_in_body transform_f ast)

  (* Promote only [Heredoc]/[Heredoc'] nodes whose body carries template syntax
     to [Template_heredoc], leaving every other node untouched.  Used by the
     native/shim backend, whose subprocess already promotes [Expr.String]
     templates but leaves heredoc bodies raw: running the full [transform_ast]
     there would re-process already-resolved [$${] / [%%{] escapes, so this
     pass touches heredocs only.  The heredoc body is itself freshly parsed, so
     its parts get the full [transform_f] — matching the Menhir path exactly. *)
  let heredoc_only_f = function
    | Expr.Heredoc (marker, body) -> Some (promote_heredoc ~flush:false marker body)
    | Expr.Heredoc' (marker, body) -> Some (promote_heredoc ~flush:true marker body)
    | _ -> None

  let promote_heredocs_ast = to_result (Hcl_ast_walker.map_in_body heredoc_only_f)

  (* [parse_template_string] runs the raw template parser and recursively
     transforms expressions inside the resulting parts so nested
     [Expr.String "${..}"] values become [Expr.Template] rather than
     surviving as raw strings (which would be double-escaped at print time).
     [Ok None] means the input contained no template syntax. *)
  let parse_template_string =
    to_result (fun s ->
        parse_template_string_raw s
        |> CCOption.map (CCList.map (Hcl_ast_walker.map_in_template_part transform_f)))
end
