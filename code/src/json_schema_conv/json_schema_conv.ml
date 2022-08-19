module String_map = CCMap.Make (CCString)
module String_set = CCSet.Make (CCString)

module Properties = struct
  type 'a properties = (string * 'a) list [@@deriving show]
  type 'a t = 'a String_map.t

  let of_yojson of_yojson m =
    m
    |> Yojson.Safe.Util.to_assoc
    |> CCList.map (fun (k, v) ->
           let open CCResult.Infix in
           of_yojson v >>= fun v -> Ok (k, v))
    |> CCResult.flatten_l
    |> CCResult.map String_map.of_list

  let to_yojson to_yojson m =
    `Assoc (CCList.map (fun (k, v) -> (k, to_yojson v)) (String_map.to_list m))

  let pp pp format v = pp_properties pp format (String_map.to_list v)
  let equal = String_map.equal
end

module Value = struct
  type 'a t =
    | Ref of string
    | V of 'a
  [@@deriving show, eq]

  let of_yojson of_yojson = function
    | `Assoc [ ("$ref", `String ref_) ] -> Ok (Ref ref_)
    | v ->
        let open CCResult.Infix in
        of_yojson v >>= fun v -> Ok (V v)

  let to_yojson to_yojson = function
    | Ref ref_ -> `Assoc [ ("$ref", `String ref_) ]
    | V v -> to_yojson v
end

module Additional_properties = struct
  type 'a t =
    | Bool of bool
    | V of 'a
  [@@deriving show, eq]

  let of_yojson of_yojson = function
    | `Bool b -> Ok (Bool b)
    | v ->
        let open CCResult.Infix in
        of_yojson v >>= fun v -> Ok (V v)

  let to_yojson to_yojson = function
    | Bool b -> `Bool b
    | V v -> to_yojson v
end

module Schema = struct
  type string_list = string list [@@deriving show]
  type 'a value = 'a Value.t [@@deriving yojson, show, eq]

  let string_set_of_yojson json = CCResult.([%of_yojson: string list] json >|= String_set.of_list)
  let string_set_to_yojson s = s |> String_set.to_list |> [%to_yojson: string list]

  (* [typ] can be nothing, a string, or a list of strings.  This specific
     implementation just recognizes when it's an array and one of the elements
     is [null].  We do some prep work and modify the JSON such that if [null] is
     in there, we set [nullable] to true and replace the [typ] with just the
     string for the type. *)
  let value_of_yojson of_yojson json =
    let json =
      match Yojson.Safe.Util.member "type" json with
      | `String "null" ->
          `Assoc
            (("type", `String "null")
            :: (json
               |> Yojson.Safe.Util.to_assoc
               |> CCList.filter (fun (k, _) -> not (CCString.equal "type" k))))
      | `Null | `String _ -> json
      | `List typs
        when CCList.mem ~eq:CCString.equal "null" (Yojson.Safe.Util.filter_string typs)
             && CCList.length typs = 2 ->
          let typ =
            CCList.(
              typs
              |> Yojson.Safe.Util.filter_string
              |> filter (fun v -> not (CCString.equal "null" v))
              |> hd)
          in
          `Assoc
            (("type", `String typ)
            :: ("nullable", `Bool true)
            :: (json
               |> Yojson.Safe.Util.to_assoc
               |> CCList.filter (fun (k, _) -> not (CCString.equal "type" k))))
      | `List _ -> failwith "'type' is list more than two entries or one entry is not null"
      | _ -> assert false
    in
    let json =
      match Yojson.Safe.Util.member "const" json with
      | `Null -> json
      | v -> `Assoc (("enum", `List [ v ]) :: Yojson.Safe.Util.to_assoc json)
    in
    Value.of_yojson of_yojson json

  type t_ = {
    typ : string option; [@default None] [@key "type"]
    multiple_of : int option; [@default None] [@key "multipleOf"]
    maximum : int option; [@default None]
    exclusive_maximum : int option; [@default None] [@key "exclusiveMaximum"]
    minimum : int option; [@default None]
    exclusive_minimum : int option; [@default None] [@key "exclusiveMinimum"]
    max_length : int option; [@default None] [@key "maxLength"]
    min_length : int option; [@default None [@key "minLength"]]
    max_items : int option; [@default None] [@key "maxItems"]
    min_items : int option; [@default None] [@key "minItems"]
    unique_items : bool option; [@default None] [@key "uniqueItems"]
    required : String_set.t;
        [@printer fun fmt v -> pp_string_list fmt (String_set.to_list v)]
        [@to_yojson string_set_to_yojson]
        [@of_yojson string_set_of_yojson]
        [@default String_set.empty]
    all_of : t list option; [@default None] [@key "allOf"]
    one_of : t list option; [@default None] [@key "oneOf"]
    any_of : t list option; [@default None] [@key "anyOf"]
    items : t option; [@default None]
    properties : t Properties.t; [@default String_map.empty]
    additional_properties : t Additional_properties.t;
        [@default Additional_properties.Bool true] [@key "additionalProperties"]
    format : string option; [@default None]
    enum : Yojson.Safe.t list option; [@default None]
    nullable : bool; [@default false]
    default : Yojson.Safe.t option; [@default None]
  }
  [@@deriving yojson { strict = false }, show, eq]

  and t = t_ value [@@deriving yojson, show, eq]

  let make_t_ () =
    {
      typ = None;
      multiple_of = None;
      maximum = None;
      exclusive_maximum = None;
      minimum = None;
      exclusive_minimum = None;
      max_length = None;
      min_length = None;
      max_items = None;
      min_items = None;
      unique_items = None;
      required = String_set.empty;
      all_of = None;
      one_of = None;
      any_of = None;
      items = None;
      properties = String_map.empty;
      additional_properties = Additional_properties.Bool true;
      format = None;
      enum = None;
      nullable = false;
      default = None;
    }

  let take_left_option l r =
    match (l, r) with
    | None, Some _ -> r
    | Some _, _ | _, _ -> l

  (* Merge two schema with the following rules:

     - For option values, if it is [None] in [l] then the [r] value is chosen.

     - [properties] are merged with the right value winning on conflict.

     - [required] are merged.

     - If [additional_properties] is [false] in [l] then take whatever is in
     [r].  If it is [true] in [l] then take [r] if it is a value.

     - [nullable] keep value in [l]. *)
  let rec merge (l : t_) (r : t_) =
    {
      typ = take_left_option l.typ r.typ;
      multiple_of = take_left_option l.multiple_of r.multiple_of;
      maximum = take_left_option l.maximum r.maximum;
      exclusive_maximum = take_left_option l.exclusive_maximum r.exclusive_maximum;
      minimum = take_left_option l.minimum r.minimum;
      exclusive_minimum = take_left_option l.exclusive_minimum r.exclusive_minimum;
      max_length = take_left_option l.max_length r.max_length;
      min_length = take_left_option l.min_length r.min_length;
      max_items = take_left_option l.max_items r.max_items;
      min_items = take_left_option l.min_items r.min_items;
      unique_items = take_left_option l.unique_items r.unique_items;
      required = String_set.union l.required r.required;
      all_of = take_left_option l.all_of r.all_of;
      one_of = take_left_option l.one_of r.one_of;
      any_of = take_left_option l.any_of r.any_of;
      items = take_left_option l.items r.items;
      properties =
        String_map.union
          (fun _ l r ->
            match (l, r) with
            | Value.V l, Value.V r -> Some (Value.V (merge l r))
            | _, r -> Some r)
          l.properties
          r.properties;
      additional_properties =
        (match (l.additional_properties, r.additional_properties) with
        | Additional_properties.(Bool true, V _) -> r.additional_properties
        | Additional_properties.(V (Value.V l), V (Value.V r)) ->
            Additional_properties.V (Value.V (merge l r))
        | _, _ -> l.additional_properties);
      format = take_left_option l.format r.format;
      enum = take_left_option l.enum r.enum;
      nullable = l.nullable || r.nullable;
      default = take_left_option l.default r.default;
    }
end

module Gen = struct
  let ident ns = CCOption.get_exn_or ("ident " ^ CCString.concat "." ns) (Longident.unflatten ns)
  let prim_type t ts = Ast_helper.Typ.constr (Location.mknoloc (ident t)) ts
  let prim_unit = prim_type [ "unit" ] []
  let prim_string = prim_type [ "string" ] []
  let prim_int = prim_type [ "int" ] []
  let prim_float = prim_type [ "float" ] []
  let prim_bool = prim_type [ "bool" ] []
  let list ts = Ast_helper.Typ.constr (Location.mknoloc (ident [ "list" ])) ts
  let option ts = Ast_helper.Typ.constr (Location.mknoloc (ident [ "option" ])) ts
  let qualified_type t = Ast_helper.Typ.constr (Location.mknoloc (ident t)) []

  let deriving derivers =
    [
      Ast_helper.Attr.mk
        (Location.mknoloc "deriving")
        (Parsetree.PStr [ Ast_helper.Str.eval (Ast_helper.Exp.tuple derivers) ]);
    ]

  let yojson_deriver ?(strict = false) ?(meta = true) () =
    Ast_helper.Exp.apply
      (Ast_helper.Exp.ident (Location.mknoloc (ident [ "yojson" ])))
      [
        ( Asttypes.Nolabel,
          Ast_helper.Exp.record
            [
              ( Location.mknoloc (ident [ "strict" ]),
                Ast_helper.Exp.construct (Location.mknoloc (ident [ Bool.to_string strict ])) None
              );
              ( Location.mknoloc (ident [ "meta" ]),
                Ast_helper.Exp.construct (Location.mknoloc (ident [ Bool.to_string meta ])) None );
            ]
            None );
      ]

  let show_deriver = Ast_helper.Exp.ident (Location.mknoloc (ident [ "show" ]))
  let make_deriver = Ast_helper.Exp.ident (Location.mknoloc (ident [ "make" ]))

  let of_yojson_attr name =
    [
      Ast_helper.(
        Attr.mk
          (Location.mknoloc "of_yojson")
          (Parsetree.PStr [ Str.eval (Exp.ident (Location.mknoloc (ident [ name ]))) ]));
    ]

  let yojson_key_name name =
    [
      Ast_helper.Attr.mk
        (Location.mknoloc "key")
        (Parsetree.PStr
           [ Ast_helper.Str.eval (Ast_helper.Exp.constant (Ast_helper.Const.string name)) ]);
    ]

  let field_default v =
    [ Ast_helper.Attr.mk (Location.mknoloc "default") (Parsetree.PStr [ Ast_helper.Str.eval v ]) ]

  let field_default_none =
    field_default (Ast_helper.Exp.construct (Location.mknoloc (ident [ "None" ])) None)

  let make_str_type ~attrs name typ =
    Ast_helper.Str.type_
      Asttypes.Recursive
      [ Ast_helper.Type.mk ~attrs ~manifest:typ (Location.mknoloc name) ]

  let make_str_record ~attrs name fields =
    Ast_helper.Str.type_
      Asttypes.Recursive
      [ Ast_helper.Type.mk ~attrs ~kind:(Parsetree.Ptype_record fields) (Location.mknoloc name) ]

  let make_variant name typ =
    Ast_helper.Type.constructor
      ~args:(Parsetree.Pcstr_tuple [ prim_type typ [] ])
      (Location.mknoloc name)

  let make_variant_type ?attrs name variants =
    Ast_helper.Str.type_
      Asttypes.Recursive
      [ Ast_helper.Type.mk ?attrs ~kind:(Parsetree.Ptype_variant variants) (Location.mknoloc name) ]

  let make_func name body =
    Ast_helper.Str.value
      Asttypes.Nonrecursive
      [ Ast_helper.Vb.mk (Ast_helper.Pat.var (Location.mknoloc name)) body ]

  let rec make_list = function
    | [] -> Ast_helper.Exp.construct (Location.mknoloc (ident [ "[]" ])) None
    | v :: vs ->
        Ast_helper.Exp.construct
          (Location.mknoloc (ident [ "::" ]))
          (Some (Ast_helper.Exp.tuple [ v; make_list vs ]))

  let make_yojson_func_name typ n =
    match typ with
    | "t" -> n
    | typ -> typ ^ "_" ^ n

  let make_of_yojson_func combinator_name type_name variant_names =
    make_func
      (make_yojson_func_name type_name "of_yojson")
      (Ast_helper.Exp.apply
         (Ast_helper.Exp.ident (Location.mknoloc (ident [ "Json_schema"; combinator_name ])))
         [
           ( Asttypes.Nolabel,
             Ast_helper.Exp.open_
               (Ast_helper.Opn.mk (Ast_helper.Mod.ident (Location.mknoloc (ident [ "CCResult" ]))))
               (make_list
               @@ CCList.map
                    (fun (v, conversion) ->
                      Ast_helper.Exp.fun_
                        Asttypes.Nolabel
                        None
                        (Ast_helper.Pat.var (Location.mknoloc "v"))
                        (Ast_helper.Exp.apply
                           (Ast_helper.Exp.ident (Location.mknoloc (ident [ "map" ])))
                           [
                             ( Asttypes.Nolabel,
                               Ast_helper.Exp.fun_
                                 Asttypes.Nolabel
                                 None
                                 (Ast_helper.Pat.var (Location.mknoloc "v"))
                                 (Ast_helper.Exp.construct
                                    (Location.mknoloc (ident [ v ]))
                                    (Some (Ast_helper.Exp.ident (Location.mknoloc (ident [ "v" ])))))
                             );
                             ( Asttypes.Nolabel,
                               Ast_helper.Exp.apply
                                 (Ast_helper.Exp.ident
                                    (Location.mknoloc (ident (conversion @ [ "of_yojson" ]))))
                                 [
                                   ( Asttypes.Nolabel,
                                     Ast_helper.Exp.ident (Location.mknoloc (ident [ "v" ])) );
                                 ] );
                           ]))
                    variant_names) );
         ])

  let make_to_yojson_func type_name variant_names =
    let rec f = function
      | [] -> []
      | (v, conversion) :: vs ->
          Ast_helper.Exp.case
            (Ast_helper.Pat.construct
               (Location.mknoloc (ident [ v ]))
               (Some ([], Ast_helper.Pat.var (Location.mknoloc "v"))))
            (Ast_helper.Exp.apply
               (Ast_helper.Exp.ident (Location.mknoloc (ident (conversion @ [ "to_yojson" ]))))
               [ (Asttypes.Nolabel, Ast_helper.Exp.ident (Location.mknoloc (ident [ "v" ]))) ])
          :: f vs
    in
    make_func
      (make_yojson_func_name type_name "to_yojson")
      (Ast_helper.Exp.function_ (f variant_names))

  let make_all_of_of_yojson_func type_name =
    let open Ast_helper in
    make_func
      (make_yojson_func_name type_name "of_yojson")
      (Exp.fun_
         Asttypes.Nolabel
         None
         (Pat.var (Location.mknoloc "json"))
         (Exp.open_
            (Opn.mk (Mod.ident (Location.mknoloc (ident [ "CCResult" ]))))
            (Exp.apply
               (Exp.ident (Location.mknoloc (ident [ "flat_map" ])))
               [
                 ( Asttypes.Nolabel,
                   Exp.fun_
                     Asttypes.Nolabel
                     None
                     (Pat.var (Location.mknoloc "_"))
                     (Exp.apply
                        (Exp.ident (Location.mknoloc (ident [ "T"; "of_yojson" ])))
                        [ (Asttypes.Nolabel, Exp.ident (Location.mknoloc (ident [ "json" ]))) ]) );
                 ( Asttypes.Nolabel,
                   Exp.apply
                     (Exp.ident (Location.mknoloc (ident [ "All_of"; "of_yojson" ])))
                     [ (Asttypes.Nolabel, Exp.ident (Location.mknoloc (ident [ "json" ]))) ] );
               ])))
end

module Type_idx = struct
  type t = {
    base : string;
    idx : int;
  }

  let default = { base = "t"; idx = 0 }
  let incr t = { t with idx = t.idx + 1 }

  let to_string = function
    | { base; idx = 0 } -> base
    | { base; idx } -> base ^ CCInt.to_string idx
end

module Config = struct
  type t = {
    create_yojson_funcs : bool;
    field_name_of_schema : string -> string;
    module_name_of_field_name : string -> string;
    module_name_of_ref : string -> string list;
    prim_type_attrs : Parsetree.attributes;
    record_field_attrs : Schema.t_ -> string -> String_set.t -> Parsetree.attributes;
    record_type_attrs : bool -> Parsetree.attributes;
    resolve_ref : Schema.t -> Schema.t_;
    strict_record : bool;
    tidx : Type_idx.t;
    variant_name_of_ref : string -> string list;
  }

  let make
      ?(create_yojson_funcs = true)
      ~field_name_of_schema
      ~module_name_of_field_name
      ~module_name_of_ref
      ~prim_type_attrs
      ~record_field_attrs
      ~record_type_attrs
      ~resolve_ref
      ~variant_name_of_ref
      () =
    {
      create_yojson_funcs;
      field_name_of_schema;
      module_name_of_ref;
      module_name_of_field_name;
      prim_type_attrs;
      record_field_attrs;
      record_type_attrs;
      resolve_ref;
      strict_record = true;
      tidx = Type_idx.default;
      variant_name_of_ref;
    }

  let create_yojson_funcs t = t.create_yojson_funcs
  let field_name_of_schema t = t.field_name_of_schema
  let module_name_of_ref t = t.module_name_of_ref
  let module_name_of_field_name t = t.module_name_of_field_name
  let prim_type_attrs t = t.prim_type_attrs
  let record_field_attrs t = t.record_field_attrs
  let record_type_attrs t = t.record_type_attrs t.strict_record
  let resolve_ref t = t.resolve_ref
  let set_strict strict t = { t with strict_record = strict }
  let tidx_incr t = { t with tidx = Type_idx.incr t.tidx }
  let tidx_reset t = { t with tidx = Type_idx.default }
  let tidx_to_string t = Type_idx.to_string t.tidx
  let variant_name_of_ref t = t.variant_name_of_ref
end

let extract_prim_type = function
  | { Schema.typ = Some (("string" | "integer" | "number" | "boolean") as typ); _ } -> Some typ
  | _ -> None

let is_prim_type schema = CCOption.is_some (extract_prim_type schema)

let prim_type_of_string format typ =
  match (format, typ) with
  (* | ("uri", "string")          -> Gen.qualified_type [ "Json_schema"; "Format"; "Uri"; "t" ] *)
  (* | ("uri-template", "string") -> Gen.qualified_type [ "Json_schema"; "Format"; "Uritmpl"; "t" ]
   * | ("date-time", "string") -> Gen.qualified_type [ "Json_schema"; "Format"; "Date_time"; "t" ] *)
  | _, "string" -> Gen.prim_string
  | "int64", "integer" -> Gen.qualified_type [ "int64" ]
  | _, "integer" -> Gen.prim_int
  | _, "number" -> Gen.prim_float
  | _, "boolean" -> Gen.prim_bool
  | _ -> assert false

let maybe_make_nullable nullable typ = if nullable then Gen.option [ typ ] else typ

(* Convert a schema to an ocaml structure.  This is where all the magic happens.
   Not all of JSON Schema is supported, in particular:

   - integer/number/string restrictions are not implemented except for [enum]
   and [format].

   - Various regexp checks and patterns for properties are not checked.

   The encoding of a schema goes as such:

   - "primitive" types, [integer], [boolean], [number] are directly translated
   to the equivalent ocaml type.  [number] is translated as a [float].

   - [string] type is translated to an ocaml string, except if it has an
   [format] in which case it is translated to a corresponding type.Abb

   - TODO: Implement [enum]

   - [oneOf] - take the schema and apply it over all of the elements in the
   [oneOf] list and produce a variant for each one of those.  Some optimization
   is made for if there is no a base schema, in which case if the underlying
   variants are refs, just call out to them.

   - The same translation is performed for [anyOf].

   - [object] type with [allOf] specified - A new module called [All_of] with a
   type [t] that is the combination of all entries in the [allOf] block.  If any
   entries are references, they are reified in this type.  A type [t] is then
   made in the parent module which is the combination of all these as well.
   This [t] is created like an [object] with no combinators.  The special case
   is the [of_yojson] is implemented such that it first decodes the payload of
   [All_of.t] and if that succeeds then decodes it again using the of_yojson
   defined for the [t] type.  All this is necessary because if the [object]
   defines type information distinct from what is in the [allOf] block, the
   [allOf] block must be verified on its own, it is not equivalent to extended
   the schema. *)
let rec convert_str_schema (config : Config.t) =
  let module S = Schema in
  function
  | { S.typ = Some "string"; nullable; enum = Some enum; _ } ->
      let rec f = function
        | [] ->
            [
              Ast_helper.(
                Exp.case
                  (Pat.var (Location.mknoloc "json"))
                  (Exp.construct
                     (Location.mknoloc (Gen.ident [ "Error" ]))
                     (Some
                        (Exp.apply
                           (Exp.ident (Location.mknoloc (Gen.ident [ "^" ])))
                           [
                             (Asttypes.Nolabel, Exp.constant (Const.string "Unknown value: "));
                             ( Asttypes.Nolabel,
                               Exp.apply
                                 (Exp.ident
                                    (Location.mknoloc
                                       (Gen.ident [ "Yojson"; "Safe"; "pretty_to_string" ])))
                                 [
                                   ( Asttypes.Nolabel,
                                     Exp.ident (Location.mknoloc (Gen.ident [ "json" ])) );
                                 ] );
                           ]))));
            ]
        | e :: es ->
            Ast_helper.(
              Exp.case
                (Pat.variant "String" (Some (Pat.constant (Const.string e))))
                (Exp.construct
                   (Location.mknoloc (Gen.ident [ "Ok" ]))
                   (Some (Exp.constant (Const.string e)))))
            :: f es
      in
      let of_yojson_name = Config.tidx_to_string config ^ "_of_yojson" in
      [
        Gen.make_func
          of_yojson_name
          Ast_helper.(Exp.function_ (f (Yojson.Safe.Util.filter_string enum)));
        Gen.(
          make_str_type
            ~attrs:(Config.prim_type_attrs config)
            (Config.tidx_to_string config)
            (maybe_make_nullable
               nullable
               (Ast_helper.Typ.constr
                  ~attrs:(of_yojson_attr of_yojson_name)
                  (Location.mknoloc (ident [ "string" ]))
                  [])));
      ]
  | { S.typ = Some typ; nullable; format; _ } as schema when is_prim_type schema ->
      [
        Gen.(
          make_str_type
            ~attrs:(Config.prim_type_attrs config)
            (Config.tidx_to_string config)
            (maybe_make_nullable
               nullable
               (prim_type_of_string (CCOption.get_or ~default:"" format) typ)));
      ]
  | { S.typ = Some "null"; _ } ->
      [
        Gen.(
          make_str_type
            ~attrs:(Config.prim_type_attrs config)
            (Config.tidx_to_string config)
            Gen.prim_unit);
      ]
  | { S.typ = Some "array"; items = None; _ } as schema ->
      convert_str_schema config { schema with S.items = Some (Value.V (S.make_t_ ())) }
  | { S.items = Some (Value.V items); nullable; _ } -> (
      match extract_prim_type items with
      | Some prim when CCOption.is_none items.Schema.enum ->
          [
            Gen.(
              make_str_type
                ~attrs:(Config.prim_type_attrs config)
                (Config.tidx_to_string config)
                (maybe_make_nullable
                   nullable
                   (list
                      [ prim_type_of_string (CCOption.get_or ~default:"" items.Schema.format) prim ])));
          ]
      | _ ->
          [
            Ast_helper.(
              Str.module_
                (Mb.mk
                   (Location.mknoloc (Some "Items"))
                   (Mod.structure (convert_str_schema config items))));
            Gen.(
              make_str_type
                ~attrs:(Config.prim_type_attrs config)
                (Config.tidx_to_string config)
                (list [ qualified_type [ "Items"; "t" ] ]));
          ])
  | { S.items = Some (Value.Ref ref_); _ } ->
      let module_name = Config.module_name_of_ref config ref_ in
      [
        Gen.(
          make_str_type
            ~attrs:(Config.prim_type_attrs config)
            (Config.tidx_to_string config)
            (list [ qualified_type (module_name @ [ "t" ]) ]));
      ]
  | { S.any_of = Some types; _ } as schema ->
      let schema = { schema with Schema.any_of = None } in
      let is_default_schema =
        (* Little hack because we do not care about what "nullable" is in this
           context when testing if it's a default *)
        Schema.equal_t_ { schema with Schema.nullable = false } (Schema.make_t_ ())
        || Schema.equal_t_
             { schema with Schema.nullable = false }
             Schema.{ (make_t_ ()) with typ = Some "object" }
      in
      let all_types_refs =
        CCList.for_all
          (function
            | Value.Ref _ -> true
            | Value.V _ -> false)
          types
      in
      (* If everything in here is a ref then we're going to use the name of the
         ref as the variant name *)
      let names =
        if all_types_refs then
          CCList.map
            (function
              | Value.Ref ref_ -> Config.variant_name_of_ref config ref_ |> CCList.rev |> CCList.hd
              | Value.V _ -> assert false)
            types
        else CCList.mapi (fun idx _ -> "V" ^ CCInt.to_string idx) types
      in
      let resolve_schema name typ =
        [
          Ast_helper.(
            Str.module_
              (Mb.mk
                 (Location.mknoloc (Some name))
                 (Mod.structure
                    (convert_str_schema
                       (Config.tidx_reset config)
                       (Schema.merge schema (Config.resolve_ref config typ))))));
        ]
      in
      let create_module =
        if is_default_schema then
          fun name -> function
            | Value.Ref _ -> []
            | schema -> resolve_schema name schema
        else resolve_schema
      in
      let modules = CCList.flatten (CCList.map2 create_module names types) in
      let conversion_modules =
        CCList.mapi
          (fun idx -> function
            | Value.Ref ref_ when is_default_schema -> Config.module_name_of_ref config ref_
            | _ -> [ "V" ^ CCInt.to_string idx ])
          types
      in
      let variants =
        CCList.map2
          (fun n -> function
            | Value.Ref ref_ -> Gen.make_variant n (Config.module_name_of_ref config ref_ @ [ "t" ])
            | _ -> Gen.make_variant n [ n; "t" ])
          names
          types
      in
      modules
      @ Gen.
          [
            make_variant_type
              ~attrs:(deriving [ show_deriver ])
              (Config.tidx_to_string config)
              variants;
          ]
      @
      if Config.create_yojson_funcs config then
        Gen.
          [
            make_of_yojson_func
              "any_of"
              (Config.tidx_to_string config)
              (CCList.combine names conversion_modules);
            make_to_yojson_func
              (Config.tidx_to_string config)
              (CCList.combine names conversion_modules);
          ]
      else []
  | { S.one_of = Some types; _ } as schema ->
      (* Remove [one_of] as we construct each one_of object *)
      let schema = { schema with Schema.one_of = None } in
      let is_default_schema =
        Schema.equal_t_ { schema with Schema.nullable = false } (Schema.make_t_ ())
        || Schema.equal_t_
             { schema with Schema.nullable = false }
             Schema.{ (make_t_ ()) with typ = Some "object" }
      in
      let all_types_refs =
        CCList.for_all
          (function
            | Value.Ref _ -> true
            | Value.V _ -> false)
          types
      in
      (* If everything in here is a ref then we're going to use the name of the
         ref as the variant name *)
      let names =
        if all_types_refs then
          CCList.map
            (function
              | Value.Ref ref_ -> Config.variant_name_of_ref config ref_ |> CCList.rev |> CCList.hd
              | Value.V _ -> assert false)
            types
        else CCList.mapi (fun idx _ -> "V" ^ CCInt.to_string idx) types
      in
      let resolve_schema name typ =
        [
          Ast_helper.(
            Str.module_
              (Mb.mk
                 (Location.mknoloc (Some name))
                 (Mod.structure
                    (convert_str_schema
                       (Config.tidx_reset config)
                       (Schema.merge schema (Config.resolve_ref config typ))))));
        ]
      in
      let create_module =
        if is_default_schema then
          fun name -> function
            | Value.Ref _ -> []
            | schema -> resolve_schema name schema
        else resolve_schema
      in
      let modules = CCList.flatten (CCList.map2 create_module names types) in
      let conversion_modules =
        CCList.mapi
          (fun idx -> function
            | Value.Ref ref_ when is_default_schema -> Config.module_name_of_ref config ref_
            | _ -> [ "V" ^ CCInt.to_string idx ])
          types
      in
      let variants =
        CCList.map2
          (fun n -> function
            | Value.Ref ref_ -> Gen.make_variant n (Config.module_name_of_ref config ref_ @ [ "t" ])
            | _ -> Gen.make_variant n [ n; "t" ])
          names
          types
      in
      modules
      @ Gen.
          [
            make_variant_type
              ~attrs:(deriving [ show_deriver ])
              (Config.tidx_to_string config)
              variants;
          ]
      @
      if Config.create_yojson_funcs config then
        Gen.
          [
            make_of_yojson_func
              "one_of"
              (Config.tidx_to_string config)
              (CCList.combine names conversion_modules);
            make_to_yojson_func
              (Config.tidx_to_string config)
              (CCList.combine names conversion_modules);
          ]
      else []
  | { S.all_of = Some types; _ } as schema ->
      (* TODO: If default object then turn into iterative check *)
      let all_of_schema =
        types
        |> CCList.map (Config.resolve_ref config)
        |> CCListLabels.fold_left ~f:Schema.merge ~init:(Schema.make_t_ ())
      in
      let schema = Schema.merge { schema with Schema.all_of = None } all_of_schema in
      [
        Ast_helper.(
          Str.module_
            (Mb.mk
               (Location.mknoloc (Some "All_of"))
               (Mod.structure (convert_str_schema Config.(tidx_reset config) all_of_schema))));
        Ast_helper.(
          Str.module_
            (Mb.mk
               (Location.mknoloc (Some "T"))
               (Mod.structure (convert_str_schema (Config.tidx_reset config) schema))));
        Gen.(
          make_str_type
            ~attrs:(Config.prim_type_attrs config)
            (Config.tidx_to_string config)
            (qualified_type [ "T"; "t" ]));
        Gen.(make_all_of_of_yojson_func (Config.tidx_to_string config));
      ]
  (* @ convert_str_schema config schema *)
  | { S.typ = None; properties; _ } as schema when not (String_map.is_empty properties) ->
      convert_str_schema config { schema with Schema.typ = Some "object" }
  | {
      S.typ = Some "object";
      properties;
      additional_properties = Additional_properties.Bool true;
      _;
    } as schema ->
      let is_empty = String_map.is_empty properties in
      let schema =
        { schema with Schema.additional_properties = Additional_properties.Bool false }
      in
      CCList.flatten
        [
          (if is_empty then []
          else
            [
              Ast_helper.(
                Str.module_
                  (Mb.mk
                     (Location.mknoloc (Some "Primary"))
                     (Mod.structure
                        (convert_str_schema Config.(set_strict false (tidx_reset config)) schema))));
            ]);
          [
            Ast_helper.(
              Str.include_
                (Incl.mk
                   (Mod.apply
                      (Mod.apply
                         (Mod.ident
                            (Location.mknoloc
                               (Gen.ident [ "Json_schema"; "Additional_properties"; "Make" ])))
                         (Mod.ident
                            (Location.mknoloc
                               (Gen.ident
                                  (if is_empty then [ "Json_schema"; "Empty_obj" ]
                                  else [ "Primary" ])))))
                      (Mod.ident (Location.mknoloc (Gen.ident [ "Json_schema"; "Obj" ]))))));
          ];
        ]
  | {
      S.typ = Some "object";
      properties;
      additional_properties = Additional_properties.V additional_schema;
      _;
    } as schema ->
      let is_empty = String_map.is_empty properties in
      let schema =
        { schema with Schema.additional_properties = Additional_properties.Bool false }
      in
      CCList.flatten
        [
          (if is_empty then []
          else
            [
              Ast_helper.(
                Str.module_
                  (Mb.mk
                     (Location.mknoloc (Some "Primary"))
                     (Mod.structure
                        (convert_str_schema Config.(set_strict false (tidx_reset config)) schema))));
            ]);
          (match additional_schema with
          | Value.V additional_schema ->
              [
                Ast_helper.(
                  Str.module_
                    (Mb.mk
                       (Location.mknoloc (Some "Additional"))
                       (Mod.structure
                          (convert_str_schema (Config.tidx_reset config) additional_schema))));
              ]
          | Value.Ref _ -> []);
          [
            Ast_helper.(
              Str.include_
                (Incl.mk
                   (Mod.apply
                      (Mod.apply
                         (Mod.ident
                            (Location.mknoloc
                               (Gen.ident [ "Json_schema"; "Additional_properties"; "Make" ])))
                         (Mod.ident
                            (Location.mknoloc
                               (Gen.ident
                                  (if is_empty then [ "Json_schema"; "Empty_obj" ]
                                  else [ "Primary" ])))))
                      (Mod.ident
                         (Location.mknoloc
                            (Gen.ident
                               (match additional_schema with
                               | Value.V _ -> [ "Additional" ]
                               | Value.Ref ref_ -> Config.module_name_of_ref config ref_)))))));
          ];
        ]
  | { S.typ = Some "object"; properties; _ } when String_map.is_empty properties ->
      [
        Gen.(
          make_str_type
            ~attrs:(Config.prim_type_attrs config)
            (Config.tidx_to_string config)
            (qualified_type [ "Json_schema"; "Empty_obj"; "t" ]));
      ]
  | { S.typ = Some "object"; properties; required; _ } ->
      (* TODO: Merge additional_properties *)
      let properties_config = Config.tidx_incr config in
      convert_str_schema_properties properties_config properties
      @ convert_str_schema_obj config properties_config required properties
  | { S.typ = None; _ } ->
      [
        Gen.(
          make_str_type
            ~attrs:(Config.prim_type_attrs config)
            (Config.tidx_to_string config)
            (qualified_type [ "Yojson"; "Safe"; "t" ]));
      ]
  | _ -> []

and convert_str_schema_properties config properties =
  (* Reset strict because the way we got here strict is set to reflect if there
     were additional properties *)
  let config = Config.set_strict true config in
  let _, acc =
    CCListLabels.fold_left
      ~init:(config, [])
      ~f:(fun (config, acc) (name, schema) ->
        match schema with
        | Value.V ({ Schema.typ = Some "string"; enum = Some _; _ } as schema) ->
            let acc =
              acc
              @ [
                  Ast_helper.(
                    Str.module_
                      (Mb.mk
                         (Location.mknoloc (Some (Config.module_name_of_field_name config name)))
                         (Mod.structure
                            (convert_str_schema
                               (Config.tidx_reset config)
                               { schema with Schema.nullable = false }))));
                ]
            in
            let config = Config.tidx_incr config in
            (config, acc)
        | Value.V schema when not (is_prim_type schema) ->
            let acc =
              acc
              @ [
                  Ast_helper.(
                    Str.module_
                      (Mb.mk
                         (Location.mknoloc (Some (Config.module_name_of_field_name config name)))
                         (Mod.structure (convert_str_schema (Config.tidx_reset config) schema))));
                ]
            in
            let config = Config.tidx_incr config in
            (config, acc)
        | Value.V _ -> (config, acc)
        | Value.Ref _ -> (config, acc))
      (CCList.sort (fun (l, _) (r, _) -> CCString.compare l r) (String_map.to_list properties))
  in
  acc

and convert_str_schema_obj config properties_config required properties =
  let _, fields =
    CCListLabels.fold_left
      ~init:(properties_config, [])
      ~f:(fun (config, acc) (name, schema) ->
        let field_name = Config.field_name_of_schema config name in
        let schema =
          match (schema, Config.resolve_ref config schema) with
          | _, ({ Schema.enum = None; _ } as schema) when is_prim_type schema -> Value.V schema
          | schema, _ -> schema
        in
        match schema with
        | Value.V schema ->
            let attrs = Config.record_field_attrs config schema name required in
            let config, field_type =
              match extract_prim_type schema with
              | Some prim when not (CCOption.is_some schema.Schema.enum && prim = "string") ->
                  ( config,
                    prim_type_of_string (CCOption.get_or ~default:"" schema.Schema.format) prim )
              | _ ->
                  let module_name = Config.module_name_of_field_name config name in
                  (Config.tidx_incr config, Gen.qualified_type [ module_name; "t" ])
            in
            let field_type =
              if
                (String_set.mem name required || CCOption.is_some schema.Schema.default)
                && not schema.Schema.nullable
              then field_type
              else Gen.option [ field_type ]
            in
            let acc =
              acc @ [ Ast_helper.Type.field ~attrs (Location.mknoloc field_name) field_type ]
            in
            (config, acc)
        | Value.Ref ref_ as schema ->
            let schema = Config.resolve_ref config schema in
            let attrs = Config.record_field_attrs config schema name required in
            (* let attrs = Config.record_field_attrs config (Schema.make_t_ ()) name required in *)
            let module_name = Config.module_name_of_ref config ref_ in
            let field_type = Gen.qualified_type (module_name @ [ "t" ]) in
            let field_type =
              if
                (String_set.mem name required || CCOption.is_some schema.Schema.default)
                && not schema.Schema.nullable
              then field_type
              else Gen.option [ field_type ]
            in
            let acc =
              acc @ [ Ast_helper.Type.field ~attrs (Location.mknoloc field_name) field_type ]
            in
            (config, acc))
      (CCList.sort (fun (l, _) (r, _) -> CCString.compare l r) (String_map.to_list properties))
  in
  [
    Gen.make_str_record
      ~attrs:(Config.record_type_attrs config)
      (Config.tidx_to_string config)
      fields;
  ]
