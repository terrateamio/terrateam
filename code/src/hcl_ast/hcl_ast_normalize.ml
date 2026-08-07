(* Normalize the HCL AST for equality/hashing consumers (e.g. revision
   comparison): rewrite constructs whose surface form can vary but whose meaning
   to OpenTofu does not, so two semantically-equal inputs converge to one AST.

   Currently normalized:
   - object/map key order (stable sort on the evaluated key; last-wins preserved),
   - the [Bare]/[Quoted] object-key distinction (folded to one canonical form),
   - body item order (attributes sorted by name and hoisted above child blocks,
     which keep their relative order),
   - the [Id]/[Lit] block-label distinction.

   Deliberately NOT normalized: [Tuple] element order. A HCL [[...]] parses to
   [Tuple] whether it is an ordered list or an (order-insensitive) set, and the
   AST carries no type information to tell them apart, so sorting would corrupt
   genuine lists.

   The public entry points are re-exposed as [Hcl_ast.Normalize]. *)

module Expr = Hcl_parser_value.Expr
module Obj_key = Hcl_parser_value.Obj_key
module Template_part = Hcl_parser_value.Template_part
module Block_label = Hcl_parser_value.Block_label

let is_digit c = Char.code c >= Char.code '0' && Char.code c <= Char.code '9'
let is_int_bareword s = (not (CCString.is_empty s)) && CCString.for_all is_digit s

(* A bareword that lexes as an integer is evaluated as a number then stringified
   by OpenTofu, so [{007 = 1}] and [{7 = 1}] are the same key [7]. Collapse the
   surface form to the canonical integer string. Non-integer numeric barewords
   ([1.50], [1e3]) are left as-is: mis-normalizing them could only ever produce a
   spurious inequality (two equal keys kept apart), never a false equality. *)
let canonical_bare s =
  if is_int_bareword s then CCOption.map_or ~default:s string_of_int (int_of_string_opt s) else s

(* [canonical_key k] is [Some s] when [k] is a statically-evaluable object key
   whose evaluated string is [s], and [None] when [k] is a barrier — a key whose
   value is only known at evaluation time. Reordering may only ever cross
   evaluable keys; a barrier pins the entries around it. *)
let canonical_key k =
  match k with
  | Obj_key.Quoted s -> Some s
  | Obj_key.Bare s -> Some (canonical_bare s)
  | Obj_key.Template parts ->
      let rec collect acc = function
        | [] -> Some (CCString.concat "" (CCList.rev acc))
        | Template_part.Literal s :: rest -> collect (s :: acc) rest
        | _ -> None
      in
      collect [] parts
  | Obj_key.Computed _ | Obj_key.Expr _ -> None

(* [Hcl_ast_walker.map_in_expr] is top-down (it does not recurse into a node once
   [rewrite] returns [Some]), so the [Object] case recurses into its own values
   explicitly before returning. Every other constructor returns [None] and lets
   the walker recurse, which is where nested objects get caught. *)
let rec normalize_expr e = Hcl_ast_walker.map_in_expr rewrite e

and rewrite e =
  match e with
  | Expr.Object pairs ->
      let pairs = CCList.map (fun (k, v) -> (normalize_key k, normalize_expr v)) pairs in
      Some (Expr.Object (sort_object pairs))
  | _ -> None

and normalize_key k =
  match k with
  | Obj_key.Bare _ | Obj_key.Quoted _ -> k
  | Obj_key.Computed e -> Obj_key.Computed (normalize_expr e)
  | Obj_key.Expr e -> Obj_key.Expr (normalize_expr e)
  | Obj_key.Template parts ->
      Obj_key.Template (CCList.map (Hcl_ast_walker.map_in_template_part rewrite) parts)

(* Stable-sort each run of statically-evaluable keys by evaluated key string;
   barrier keys pin the entries around them. A stable sort keeps duplicate keys
   in source order, so HCL's last-wins semantics survive without folding —
   folding would drop the diagnostic of an overwritten-but-still-evaluated value
   ([{a = length(1), a = 2}] is a real error). Evaluable keys are rewritten to a
   single canonical [Quoted] form so [{foo = 1}] and [{"foo" = 1}] converge. *)
and sort_object pairs =
  let emit_segment segment acc =
    List.stable_sort (fun (c1, _) (c2, _) -> CCString.compare c1 c2) (CCList.rev segment)
    |> CCList.fold_left (fun acc (c, v) -> (Obj_key.Quoted c, v) :: acc) acc
  in
  let rec loop segment acc = function
    | [] -> CCList.rev (emit_segment segment acc)
    | (k, v) :: rest -> (
        match canonical_key k with
        | Some c -> loop ((c, v) :: segment) acc rest
        | None -> loop [] ((k, v) :: emit_segment segment acc) rest)
  in
  loop [] [] pairs

(* A [Lit] label may hold characters no bareword can, so fold [Id] into [Lit]
   only, never the reverse. *)
let normalize_label l =
  match l with
  | Block_label.Id s -> Block_label.Lit s
  | Block_label.Lit _ -> l

(* Neither attribute order nor the position of an attribute relative to a child
   block is meaningful to OpenTofu (and duplicate attributes are a hard error, so
   there is no last-wins subtlety), but the relative order of child blocks is
   significant (repeated [ingress]/[provisioner] blocks form an ordered list).
   Canonical form is therefore: attributes sorted by name, then every block in
   source order. *)
let sort_body body =
  let attrs =
    body
    |> CCList.filter_map (function
      | Hcl_parser_value.Attribute (n, e) -> Some (n, e)
      | Hcl_parser_value.Block _ -> None)
    |> List.stable_sort (fun (a, _) (b, _) -> CCString.compare a b)
    |> CCList.map (fun (n, e) -> Hcl_parser_value.Attribute (n, e))
  in
  let blocks =
    CCList.filter
      (function
        | Hcl_parser_value.Attribute _ -> false
        | Hcl_parser_value.Block _ -> true)
      body
  in
  attrs @ blocks

(* Splice a nested single-template interpolation into its parent's part list:
   [${"${X}"}] -> [${X}]. Inlining a value whose whole payload is an interpolation
   ([foo = "${path.module}"]) into another template's interpolation
   ([bar = "${foo}/x"]) leaves the inner template wrapped as
   [Interpolation (Template …)]. That renders and evaluates fine, but a consumer
   that inspects the LEADING part of a template directly only recognises an anchor
   that is [${…}] DIRECTLY, so the wrapper must be flattened first. Recurses
   through the shapes such a value can take ([Template]/[Fun_call]/[Tuple]/
   [Object]); a wrapper buried inside a [Cond]/[Idx]/operator arm is left as-is. *)
let rec template e =
  match e with
  | Expr.Template parts -> Expr.Template (CCList.flat_map template_part parts)
  | Expr.Fun_call (f, args) -> Expr.Fun_call (f, CCList.map template args)
  | Expr.Tuple xs -> Expr.Tuple (CCList.map template xs)
  | Expr.Object kvs -> Expr.Object (CCList.map (fun (k, v) -> (k, template v)) kvs)
  | other -> other

and template_part = function
  | Template_part.Interpolation { expr; strip_before; strip_after } -> (
      match template expr with
      | Expr.Template inner -> inner
      | fe -> [ Template_part.Interpolation { expr = fe; strip_before; strip_after } ])
  | (Template_part.Literal _ | Template_part.If_directive _ | Template_part.For_directive _) as p ->
      [ p ]

let rec normalize_value ~flatten_templates v =
  match v with
  | Hcl_parser_value.Attribute (name, e) ->
      let e = normalize_expr e in
      let e = if flatten_templates then template e else e in
      Hcl_parser_value.Attribute (name, e)
  | Hcl_parser_value.Block { type_; labels; body } ->
      let labels = CCList.map normalize_label labels in
      let body = sort_body (CCList.map (normalize_value ~flatten_templates) body) in
      Hcl_parser_value.Block { type_; labels; body }

let expr ?(normalize_templates = false) e =
  let e = normalize_expr e in
  if normalize_templates then template e else e

let value ?(normalize_templates = false) v =
  normalize_value ~flatten_templates:normalize_templates v

let ast ?(normalize_templates = false) a = CCList.map (value ~normalize_templates) a
