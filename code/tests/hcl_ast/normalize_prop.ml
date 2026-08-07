(* Randomized coverage of the invariants of [Hcl_ast.Normalize], complementing
   the hand-written examples in [test.ml].

   Two families:
   - positive — inputs differing only in meaning-preserving surface form must
     converge to one normalized AST (otherwise [Sg_revision] reports a spurious
     revision change);
   - negative — inputs differing in meaning must NOT converge (otherwise
     [Sg_revision] hides a real revision change, the worse failure).

   The generators never re-derive the module's own notion of "statically
   evaluable object key": objects are built out of segments whose evaluability is
   known by construction. A test that mirrors the implementation proves nothing. *)

module Expr = Hcl_parser_value.Expr
module Obj_key = Hcl_parser_value.Obj_key
module Template_part = Hcl_parser_value.Template_part
module Block_label = Hcl_parser_value.Block_label
module Gen = QCheck.Gen

let count = 500
let default_seed = 0x5EED

(* Fixed by default so a CI failure reproduces locally; override to fuzz. *)
let seed =
  CCOption.map_or
    ~default:default_seed
    (fun s -> CCOption.get_or ~default:default_seed (int_of_string_opt s))
    (Sys.getenv_opt "HCL_PROP_SEED")

(* Small pools, so keys collide often enough that ordering and last-wins are
   actually exercised. ["7"] is a key name whose bareword form lexes as an
   integer. *)
let ident_names = [ "a"; "b"; "c"; "z1" ]
let key_names = [ "a"; "b"; "c"; "z1"; "7" ]
let gen_ident = Gen.oneof_list ident_names

let gen_label =
  Gen.map2 (fun lit s -> if lit then Block_label.Lit s else Block_label.Id s) Gen.bool gen_ident

(* [Expr.Float] is drawn from a finite list: the derived structural equality
   compares floats with [=], so a generated [nan] would fail even the identity
   property. *)
let gen_leaf =
  Gen.oneof_weighted
    [
      (4, Gen.map (fun i -> Expr.Int i) (Gen.int_bound 1000));
      (1, Gen.map (fun b -> Expr.Bool b) Gen.bool);
      (1, Gen.return Expr.Null);
      (1, Gen.map (fun f -> Expr.Float f) (Gen.oneof_list [ 0.0; 1.5; -2.25 ]));
      (2, Gen.map (fun s -> Expr.String s) gen_ident);
      (2, Gen.map (fun s -> Expr.Id s) gen_ident);
    ]

(* An object is generated as a list of segments so that the shuffling in the
   [gen_pair_*] generators knows, by construction, which entries may cross: a
   [Run] holds entries whose keys are statically evaluable, a [Barrier] holds one
   entry whose key is only known at evaluation time and therefore pins its
   neighbours. *)
type 'a segment =
  | Barrier of (Obj_key.t * 'a)
  | Run of (Obj_key.t * 'a) list

let segment_entries = function
  | Barrier e -> [ e ]
  | Run entries -> entries

(* Surface forms that all evaluate to the object key [name]. A bareword lexing as
   an integer evaluates to that number, so [007] is a form of ["7"]. *)
let eval_key_forms name =
  let forms =
    [ Obj_key.Bare name; Obj_key.Quoted name; Obj_key.Template [ Template_part.Literal name ] ]
  in
  if CCString.equal name "7" then Obj_key.Bare "007" :: forms else forms

(* A random interleaving of [xs] and [ys] preserving the relative order within
   each list. *)
let rec gen_interleave xs ys =
  let open Gen in
  match (xs, ys) with
  | [], _ -> return ys
  | _, [] -> return xs
  | x :: xs', y :: ys' ->
      bool
      >>= fun take_x ->
      if take_x then map (fun rest -> x :: rest) (gen_interleave xs' ys)
      else map (fun rest -> y :: rest) (gen_interleave xs ys')

(* [fuel] bounds the nesting depth; every recursive call must decrease it. *)
let rec gen_expr fuel =
  if fuel <= 0 then gen_leaf
  else
    let sub = gen_expr (fuel - 1) in
    Gen.oneof_weighted
      [
        (4, gen_leaf);
        (3, gen_object (fuel - 1));
        (2, Gen.map (fun l -> Expr.Tuple l) (Gen.list_size (Gen.int_bound 3) sub));
        ( 1,
          Gen.map2
            (fun n args -> Expr.Fun_call (n, args))
            gen_ident
            (Gen.list_size (Gen.int_bound 2) sub) );
        (1, Gen.map3 (fun if_ then_ else_ -> Expr.Cond { if_; then_; else_ }) sub sub sub);
        (1, Gen.map2 (fun a b -> Expr.Add (a, b)) sub sub);
        (1, Gen.map2 (fun a b -> Expr.Idx (a, b)) sub sub);
        (1, Gen.map (fun parts -> Expr.Template parts) (gen_template (fuel - 1)));
      ]

and gen_object fuel =
  Gen.map
    (fun segments -> Expr.Object (CCList.flat_map segment_entries segments))
    (Gen.list_size (Gen.int_bound 3) (gen_segment fuel))

(* Keys are drawn with replacement, so duplicate keys — whose last-wins ordering
   normalization must preserve — show up in the general-purpose generator too. *)
and gen_segment fuel =
  Gen.oneof_weighted
    [
      ( 3,
        Gen.map
          (fun entries -> Run entries)
          (gen_entries (Gen.list_size (Gen.int_bound 3) (Gen.oneof_list key_names)) fuel) );
      (1, Gen.map2 (fun k v -> Barrier (k, v)) (gen_barrier_key fuel) (gen_expr fuel));
    ]

(* Pair each name from [names_gen] with one of its surface forms and a value. *)
and gen_entries names_gen fuel =
  let open Gen in
  let value_gen = gen_expr fuel in
  names_gen
  >>= fun names ->
  flatten_list (CCList.map (fun name -> pair (oneof_list (eval_key_forms name)) value_gen) names)

and gen_barrier_key fuel =
  Gen.oneof_weighted
    [
      (2, Gen.map (fun e -> Obj_key.Computed e) (gen_expr fuel));
      (2, Gen.map (fun e -> Obj_key.Expr e) (gen_expr fuel));
      (1, Gen.map (fun parts -> Obj_key.Template parts) (gen_template fuel));
    ]

(* Always carries an interpolation, so as an object key it is a barrier. *)
and gen_template fuel =
  Gen.map2
    (fun lit e ->
      [
        Template_part.Literal lit;
        Template_part.Interpolation { expr = e; strip_before = false; strip_after = false };
      ])
    gen_ident
    (gen_expr fuel)

(* Attribute names are distinct: duplicate attributes are an HCL hard error, and
   normalization is only required to be order-insensitive without them. *)
and gen_body fuel =
  let open Gen in
  let attr_value = gen_expr fuel in
  let blocks_gen =
    if fuel <= 0 then return [] else list_size (int_bound 2) (gen_block (fuel - 1))
  in
  shuffle_list ident_names
  >>= fun shuffled ->
  int_bound (CCList.length shuffled)
  >>= fun n_attrs ->
  flatten_list
    (CCList.map
       (fun name -> map (fun e -> Hcl_parser_value.Attribute (name, e)) attr_value)
       (CCList.take n_attrs shuffled))
  >>= fun attrs -> blocks_gen >>= fun blocks -> gen_interleave attrs blocks

and gen_block fuel =
  Gen.map3
    (fun type_ labels body -> Hcl_parser_value.Block { type_; labels; body })
    gen_ident
    (Gen.list_size (Gen.int_bound 2) gen_label)
    (gen_body fuel)

let gen_value fuel =
  Gen.oneof_weighted
    [
      (1, Gen.map2 (fun n e -> Hcl_parser_value.Attribute (n, e)) gen_ident (gen_expr fuel));
      (3, gen_block fuel);
    ]

(* --- Meaning-preserving twins ------------------------------------------- *)

(* [gen_pair_*] generate [(a, twin)] where [twin] differs from [a] only by
   reorderings normalization is required to collapse: entries permuted within a
   run of pairwise-distinct evaluable keys (so last-wins cannot change), and body
   items re-interleaved with the attributes permuted (child blocks keep their
   relative order, which is significant). *)
let rec gen_pair_expr fuel =
  if fuel <= 0 then Gen.map (fun e -> (e, e)) gen_leaf
  else
    let sub = gen_pair_expr (fuel - 1) in
    Gen.oneof_weighted
      [
        (4, Gen.map (fun e -> (e, e)) gen_leaf);
        (4, gen_pair_object (fuel - 1));
        ( 2,
          Gen.map
            (fun l -> (Expr.Tuple (CCList.map fst l), Expr.Tuple (CCList.map snd l)))
            (Gen.list_size (Gen.int_bound 3) sub) );
        ( 1,
          Gen.map2
            (fun n args ->
              (Expr.Fun_call (n, CCList.map fst args), Expr.Fun_call (n, CCList.map snd args)))
            gen_ident
            (Gen.list_size (Gen.int_bound 2) sub) );
      ]

and gen_pair_object fuel =
  let open Gen in
  list_size (int_bound 3) (gen_pair_segment fuel)
  >>= fun segments ->
  flatten_list
    (CCList.map
       (function
         | Barrier e -> return [ e ]
         | Run entries -> shuffle_list entries)
       segments)
  >>= fun shuffled ->
  let entries = CCList.flat_map segment_entries segments in
  return
    ( Expr.Object (CCList.map (fun (k, (a, _)) -> (k, a)) entries),
      Expr.Object (CCList.map (fun (k, (_, b)) -> (k, b)) (CCList.flatten shuffled)) )

and gen_pair_segment fuel =
  Gen.oneof_weighted
    [
      (3, Gen.map (fun entries -> Run entries) (gen_pair_run fuel));
      (1, Gen.map2 (fun k v -> Barrier (k, v)) (gen_barrier_key fuel) (gen_pair_expr fuel));
    ]

(* Names without replacement: permuting a run is only meaning-preserving when its
   evaluated keys are pairwise distinct. *)
and gen_pair_run fuel =
  let open Gen in
  let value_gen = gen_pair_expr fuel in
  shuffle_list key_names
  >>= fun shuffled ->
  int_bound (CCList.length shuffled)
  >>= fun n ->
  flatten_list
    (CCList.map
       (fun name -> pair (oneof_list (eval_key_forms name)) value_gen)
       (CCList.take n shuffled))

and gen_pair_body fuel =
  let open Gen in
  let attr_value = gen_pair_expr fuel in
  let blocks_gen =
    if fuel <= 0 then return [] else list_size (int_bound 2) (gen_pair_block (fuel - 1))
  in
  shuffle_list ident_names
  >>= fun shuffled ->
  int_bound (CCList.length shuffled)
  >>= fun n_attrs ->
  flatten_list
    (CCList.map
       (fun name ->
         map
           (fun (a, b) ->
             (Hcl_parser_value.Attribute (name, a), Hcl_parser_value.Attribute (name, b)))
           attr_value)
       (CCList.take n_attrs shuffled))
  >>= fun attrs ->
  blocks_gen
  >>= fun blocks ->
  gen_interleave (CCList.map fst attrs) (CCList.map fst blocks)
  >>= fun a ->
  shuffle_list (CCList.map snd attrs)
  >>= fun shuffled_attrs ->
  gen_interleave shuffled_attrs (CCList.map snd blocks) >>= fun b -> return (a, b)

and gen_pair_block fuel =
  Gen.map3
    (fun type_ labels (body_a, body_b) ->
      ( Hcl_parser_value.Block { type_; labels; body = body_a },
        Hcl_parser_value.Block { type_; labels; body = body_b } ))
    gen_ident
    (Gen.list_size (Gen.int_bound 2) gen_label)
    (gen_pair_body fuel)

let gen_pair_value fuel =
  Gen.oneof_weighted
    [
      ( 1,
        Gen.map2
          (fun n (a, b) -> (Hcl_parser_value.Attribute (n, a), Hcl_parser_value.Attribute (n, b)))
          gen_ident
          (gen_pair_expr fuel) );
      (3, gen_pair_block fuel);
    ]

(* --- Surface-form widening ----------------------------------------------- *)

let is_all_digits s =
  (not (CCString.is_empty s)) && CCString.for_all (fun c -> c >= '0' && c <= '9') s

(* Substitutions that provably cannot change what an object key or block label
   evaluates to. A [Bare] key is only widened when it is not an all-digit
   bareword: those evaluate as a number, and re-deriving that canonicalization
   here would only mirror the implementation. *)
let widen_key k =
  match k with
  | Obj_key.Bare s when not (is_all_digits s) -> Obj_key.Quoted s
  | Obj_key.Quoted s -> Obj_key.Template [ Template_part.Literal s ]
  | Obj_key.Bare _ | Obj_key.Template _ | Obj_key.Computed _ | Obj_key.Expr _ -> k

let widen_label l =
  match l with
  | Block_label.Id s -> Block_label.Lit s
  | Block_label.Lit _ -> l

(* [Hcl_ast.map_in_expr] does not recurse into a node once the callback returns
   [Some], so the [Object] case walks its own entries; every other constructor
   returns [None] and lets the walker recurse. *)
let rec widen_expr e = Hcl_ast.map_in_expr widen e

and widen e =
  match e with
  | Expr.Object pairs ->
      Some (Expr.Object (CCList.map (fun (k, v) -> (widen_key k, widen_expr v)) pairs))
  | _ -> None

let rec widen_value v =
  match v with
  | Hcl_parser_value.Attribute (name, e) -> Hcl_parser_value.Attribute (name, widen_expr e)
  | Hcl_parser_value.Block { type_; labels; body } ->
      Hcl_parser_value.Block
        { type_; labels = CCList.map widen_label labels; body = CCList.map widen_value body }

(* --- Structure counting --------------------------------------------------- *)

(* Every object entry and body item, counted recursively: normalization permutes,
   so it must never drop or duplicate one. *)
let count_expr_entries e =
  Hcl_ast_walker.fold_in_expr
    (fun acc e ->
      match e with
      | Expr.Object pairs -> `Continue (acc + CCList.length pairs)
      | _ -> `Continue acc)
    0
    e

let rec count_items v =
  match v with
  | Hcl_parser_value.Attribute (_, e) -> count_expr_entries e
  | Hcl_parser_value.Block { type_ = _; labels = _; body } ->
      CCList.fold_left (fun acc v -> acc + count_items v) (CCList.length body) body

(* --- Properties ----------------------------------------------------------- *)

let normalize_expr = Hcl_ast.Normalize.expr
let normalize_value = Hcl_ast.Normalize.value
let obj entries = normalize_expr (Expr.Object entries)
let show_pair show (a, b) = Printf.sprintf "%s\n--- vs ---\n%s" (show a) (show b)

let rotate l =
  match l with
  | [] -> []
  | x :: rest -> rest @ [ x ]

(* [if_assumptions_fail] is fatal: the negative properties below filter their
   inputs with [QCheck.assume], and a generator change that made most cases
   discardable would quietly turn them into no-ops rather than failing. *)
let prop ~name ~print gen f =
  Oth.test ~name (fun _ ->
      QCheck.Test.check_exn
        ~rand:(Random.State.make [| seed |])
        (QCheck.Test.make
           ~if_assumptions_fail:(`Fatal, 0.5)
           ~count
           ~name
           (QCheck.make ~print gen)
           f))

let show_barrier_case ((_, k1, v1), (_, k2, v2), (kb, vb)) =
  Printf.sprintf
    "{ %s = %s, %s = %s, %s = %s }"
    (Obj_key.show k1)
    (Expr.show v1)
    (Obj_key.show kb)
    (Expr.show vb)
    (Obj_key.show k2)
    (Expr.show v2)

let gen_barrier_case =
  let open Gen in
  triple
    (pair (oneof_list key_names) (oneof_list key_names))
    (pair (gen_expr 2) (gen_expr 2))
    (pair (gen_barrier_key 2) (gen_expr 2))
  >>= fun ((n1, n2), (v1, v2), (kb, vb)) ->
  map2
    (fun k1 k2 -> ((n1, k1, v1), (n2, k2, v2), (kb, vb)))
    (oneof_list (eval_key_forms n1))
    (oneof_list (eval_key_forms n2))

let gen_dup_case =
  let open Gen in
  oneof_list key_names
  >>= fun name ->
  let form = oneof_list (eval_key_forms name) in
  map2
    (fun (k1, k2) (v1, v2) -> ((k1, v1), (k2, v2)))
    (pair form form)
    (pair (gen_expr 2) (gen_expr 2))

(* --- Template flattening ([Normalize.template]) --------------------------- *)

let template = Hcl_ast.Normalize.template

(* Expressions biased to nest [${ <template> }] wrappers — an interpolation whose
   body is itself a template — inside the shapes [template] recurses through
   ([Template]/[Fun_call]/[Tuple]/[Object]) and one it does not ([Cond]), so the
   flattening and its boundary both get exercised. *)
let rec gen_tmpl_expr fuel =
  if fuel <= 0 then gen_leaf
  else
    let sub = gen_tmpl_expr (fuel - 1) in
    Gen.oneof_weighted
      [
        (3, gen_leaf);
        (4, Gen.map (fun parts -> Expr.Template parts) (gen_tmpl_parts (fuel - 1)));
        (2, Gen.map (fun l -> Expr.Tuple l) (Gen.list_size (Gen.int_bound 3) sub));
        ( 2,
          Gen.map2
            (fun n args -> Expr.Fun_call (n, args))
            gen_ident
            (Gen.list_size (Gen.int_bound 2) sub) );
        ( 1,
          Gen.map
            (fun vs -> Expr.Object (CCList.map (fun (k, v) -> (Obj_key.Bare k, v)) vs))
            (Gen.list_size (Gen.int_bound 2) (Gen.pair gen_ident sub)) );
        (1, Gen.map3 (fun if_ then_ else_ -> Expr.Cond { if_; then_; else_ }) sub sub sub);
      ]

and gen_tmpl_parts fuel = Gen.list_size (Gen.int_range 1 3) (gen_tmpl_part fuel)

and gen_tmpl_part fuel =
  Gen.oneof_weighted
    [
      (2, Gen.map (fun s -> Template_part.Literal s) gen_ident);
      ( 3,
        Gen.map
          (fun e ->
            Template_part.Interpolation { expr = e; strip_before = false; strip_after = false })
          (gen_tmpl_expr fuel) );
    ]

(* Independent oracle for "flattened normal form": [true] when a [${ <template> }]
   wrapper survives in a position [template] is required to reach. It detects the
   spec violation directly (an interpolation whose body is a [Template]) rather
   than re-running the flattening. It mirrors [template]'s recursion set: it does
   {b not} descend into [Cond]/[Idx]/operator arms or directive bodies, exactly
   the positions [template] leaves untouched. *)
let rec has_flattenable e =
  match e with
  | Expr.Template parts -> CCList.exists flattenable_part parts
  | Expr.Fun_call (_, args) -> CCList.exists has_flattenable args
  | Expr.Tuple xs -> CCList.exists has_flattenable xs
  | Expr.Object kvs -> CCList.exists (fun (_, v) -> has_flattenable v) kvs
  | _ -> false

and flattenable_part = function
  | Template_part.Interpolation { expr = Expr.Template _; _ } -> true
  | Template_part.Interpolation { expr; strip_before = _; strip_after = _ } -> has_flattenable expr
  | Template_part.Literal _ | Template_part.If_directive _ | Template_part.For_directive _ -> false

(* --- Parser rejection of malformed templates ------------------------------

   [Normalize.template] is total and receives an already-valid AST, so it has no
   invalid input to reject: a malformed template is unrepresentable in
   [Template_part.t] (directives carry their branches as nested [t list], and an
   interpolation holds a parsed [Expr.t] — an unclosed [${] or [%{if}] simply
   cannot be encoded). Malformed templates exist only as strings, and are rejected
   one layer down, at parse time. This section fuzzes that layer:
   [Hcl_ast.parse_template_string] (the production Menhir template parser) must
   reject every generated malformation.

   Each family below carries a defect for which no valid parse exists — verified
   empirically — so a generated string is never accidentally valid. Literals are
   drawn from a pool free of [$]/[%]/[{]/[}], so the only template introducer in a
   string is the malformed one. The shim backend's rejection is covered by the
   curated [statically_crafted_*_bad.hcl] / [single_unclosed_bad.hcl] fixtures. *)
let gen_safe_literal = Gen.oneof_list [ ""; "a"; "pre"; "x1" ]

let gen_malformed_template =
  let open Gen in
  let unclosed_interp =
    (* [${] with no closing [}]. *)
    map2 (fun lit id -> lit ^ "${" ^ id) gen_safe_literal (oneof_list [ ""; "a"; "b" ])
  in
  let empty_directive =
    (* [%{}] — a directive with no keyword. *)
    map2 (fun a b -> a ^ "%{}" ^ b) gen_safe_literal gen_safe_literal
  in
  let unclosed_if =
    (* [%{if cond}...], optionally with an [%{else}] arm, but never [%{endif}]. *)
    map2
      (fun (lit, cond, body) else_arm ->
        let base = lit ^ "%{if " ^ cond ^ "}" ^ body in
        CCOption.map_or ~default:base (fun e -> base ^ "%{else}" ^ e) else_arm)
      (triple gen_safe_literal (oneof_list [ "a"; "b" ]) gen_safe_literal)
      (option gen_safe_literal)
  in
  let unclosed_for =
    (* [%{for v in xs}...] with no [%{endfor}]. *)
    map3
      (fun lit var body -> lit ^ "%{for " ^ var ^ " in [1, 2]}" ^ body)
      gen_safe_literal
      (oneof_list [ "x"; "y" ])
      gen_safe_literal
  in
  let stray_marker =
    (* A close/else marker with no matching opener. *)
    map3
      (fun a marker b -> a ^ "%{" ^ marker ^ "}" ^ b)
      gen_safe_literal
      (oneof_list [ "endif"; "else"; "endfor" ])
      gen_safe_literal
  in
  oneof [ unclosed_interp; empty_directive; unclosed_if; unclosed_for; stray_marker ]

let tests =
  [
    (* Positive: meaning-preserving differences must converge. *)
    prop
      ~name:"normalize prop: value normalization is idempotent"
      ~print:Hcl_parser_value.show
      (gen_value 3)
      (fun v ->
        let once = normalize_value v in
        Hcl_parser_value.equal (normalize_value once) once);
    prop
      ~name:"normalize prop: expr normalization is idempotent"
      ~print:Expr.show
      (gen_expr 3)
      (fun e ->
        let once = normalize_expr e in
        Expr.equal (normalize_expr once) once);
    prop
      ~name:"normalize prop: object key and block label surface form is irrelevant"
      ~print:Hcl_parser_value.show
      (gen_value 3)
      (fun v -> Hcl_parser_value.equal (normalize_value (widen_value v)) (normalize_value v));
    prop
      ~name:"normalize prop: reorderable entries converge"
      ~print:(show_pair Hcl_parser_value.show)
      (gen_pair_value 3)
      (fun (a, b) -> Hcl_parser_value.equal (normalize_value a) (normalize_value b));
    prop
      ~name:"normalize prop: no entry is dropped or duplicated"
      ~print:Hcl_parser_value.show
      (gen_value 3)
      (fun v -> count_items (normalize_value v) = count_items v);
    (* Negative: meaning-changing differences must NOT converge. *)
    prop
      ~name:"normalize prop: tuple order is preserved"
      ~print:(QCheck.Print.list Expr.show)
      (Gen.list_size (Gen.int_range 2 4) (gen_expr 2))
      (fun l ->
        let normalized = CCList.map normalize_expr l in
        QCheck.assume
          (CCList.length (CCList.uniq ~eq:Expr.equal normalized) = CCList.length normalized);
        not (Expr.equal (normalize_expr (Expr.Tuple l)) (normalize_expr (Expr.Tuple (rotate l)))));
    prop
      ~name:"normalize prop: entries do not cross a computed key"
      ~print:show_barrier_case
      gen_barrier_case
      (fun ((n1, k1, v1), (n2, k2, v2), (kb, vb)) ->
        QCheck.assume (not (CCString.equal n1 n2));
        QCheck.assume (not (Expr.equal (normalize_expr v1) (normalize_expr v2)));
        not
          (Expr.equal (obj [ (k1, v1); (kb, vb); (k2, v2) ]) (obj [ (k2, v2); (kb, vb); (k1, v1) ])));
    prop
      ~name:"normalize prop: duplicate key last-wins order is preserved"
      ~print:(show_pair (fun (k, v) -> Obj_key.show k ^ " = " ^ Expr.show v))
      gen_dup_case
      (fun ((k1, v1), (k2, v2)) ->
        QCheck.assume (not (Expr.equal (normalize_expr v1) (normalize_expr v2)));
        not (Expr.equal (obj [ (k1, v1); (k2, v2) ]) (obj [ (k1, v2); (k2, v1) ])));
    prop
      ~name:"normalize prop: child block order is preserved"
      ~print:(show_pair Hcl_parser_value.show)
      (Gen.pair (gen_block 2) (gen_block 2))
      (fun (b1, b2) ->
        QCheck.assume (not (Hcl_parser_value.equal (normalize_value b1) (normalize_value b2)));
        let root body = Hcl_parser_value.Block { type_ = "root"; labels = []; body } in
        not
          (Hcl_parser_value.equal
             (normalize_value (root [ b1; b2 ]))
             (normalize_value (root [ b2; b1 ]))));
    (* [template] always yields flattened normal form: no [${ <template> }]
       wrapper survives in a position it reaches. *)
    prop
      ~name:"template prop: output is in flattened normal form"
      ~print:Expr.show
      (gen_tmpl_expr 4)
      (fun e -> not (has_flattenable (template e)));
    (* [template] only ever removes wrappers: an expression already free of them
       is returned unchanged — no tuple reorder, no dropped/duplicated part, no
       descent into a [Cond] arm (which [has_flattenable] also treats as opaque).
       Drawn from the low-wrapper [gen_expr] so the assumption rarely discards. *)
    prop ~name:"template prop: no-op on wrapper-free input" ~print:Expr.show (gen_expr 3) (fun e ->
        QCheck.assume (not (has_flattenable e));
        Expr.equal (template e) e);
    (* One pass reaches a fixpoint. *)
    prop
      ~name:"template prop: flattening is idempotent"
      ~print:Expr.show
      (gen_tmpl_expr 4)
      (fun e ->
        let once = template e in
        Expr.equal (template once) once);
    (* Parser layer: every malformed template string is rejected. *)
    prop
      ~name:"template prop: parser rejects malformed templates"
      ~print:(Printf.sprintf "%S")
      gen_malformed_template
      (fun s ->
        match Hcl_ast.parse_template_string s with
        | Error _ -> true
        | Ok (None | Some _) -> false);
  ]
