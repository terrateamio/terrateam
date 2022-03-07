module String_map = CCMap.Make (CCString)
module String_set = CCSet.Make (CCString)
module Properties = Json_schema_conv.Properties
module Value = Json_schema_conv.Value
module Additional_properties = Json_schema_conv.Additional_properties
module Schema = Json_schema_conv.Schema
module Gen = Json_schema_conv.Gen

module Parameter = struct
  type t_ = {
    name : string;
    in_ : string; [@key "in"]
    description : string option; [@default None]
    required : bool; [@default false]
    deprecated : bool; [@default false]
    allow_empty_value : bool; [@default false]
    schema : Schema.t;
  }
  [@@deriving yojson { strict = false }]

  type t = t_ Value.t [@@deriving yojson]
end

module Media_type = struct
  type t = { schema : Schema.t } [@@deriving yojson { strict = false }]
end

module Request_body = struct
  type t_ = {
    description : string; [@default ""]
    content : Media_type.t Properties.t;
    required : bool; [@default false]
  }
  [@@deriving yojson { strict = false }]

  type t = t_ Value.t [@@deriving yojson]
end

module Response = struct
  type t_ = { content : Media_type.t Properties.t [@default String_map.empty] }
  [@@deriving yojson { strict = false }]

  type t = t_ Value.t [@@deriving yojson]
end

module Operation = struct
  type t = {
    summary : string; [@default ""]
    description : string; [@default ""]
    operation_id : string option; [@key "operationId"]
    parameters : Parameter.t list; [@default []]
    request_body : Request_body.t option; [@default None] [@key "requestBody"]
    responses : Response.t Properties.t;
  }
  [@@deriving yojson { strict = false }]
end

module Path = struct
  type t = {
    summary : string; [@default ""]
    description : string; [@default ""]
    get : Operation.t option; [@default None]
    put : Operation.t option; [@default None]
    post : Operation.t option; [@default None]
    delete : Operation.t option; [@default None]
    patch : Operation.t option; [@default None]
    parameters : Parameter.t list Value.t option; [@default None]
  }
  [@@deriving yojson { strict = false }]
end

module Components = struct
  type t = {
    schemas : Schema.t Properties.t; [@default String_map.empty]
    responses : Response.t Properties.t; [@default String_map.empty]
    parameters : Parameter.t Properties.t; [@default String_map.empty]
    request_bodies : Request_body.t Properties.t; [@default String_map.empty] [@key "requestBodies"]
  }
  [@@deriving yojson { strict = false }]
end

module Document = struct
  type t = {
    paths : Path.t Properties.t;
    components : Components.t;
  }
  [@@deriving yojson { strict = false }]
end

let module_name_of_string s =
  s
  |> CCString.replace ~sub:"-" ~by:"_"
  |> (function
       | s when CCString.prefix ~pre:"_" s -> CCString.drop_while (( = ) '_') s ^ "_"
       | s -> s)
  |> CCString.capitalize_ascii

let module_name_of_field_name { Components.schemas; _ } s =
  if String_map.mem (CCString.replace ~sub:"_" ~by:"-" s) schemas then module_name_of_string s ^ "_"
  else module_name_of_string s

let rec resolve_ref typ lookup ref_ =
  match ref_ with
  | Value.Ref ref_ -> (
      match CCString.split_on_char '/' ref_ with
      | [ "#"; "components"; t; name ] when CCString.equal t typ -> (
          match lookup name with
          | Some (Value.Ref _ as ref_) -> resolve_ref typ lookup ref_
          | Some (Value.V v) -> v
          | None -> failwith (Printf.sprintf "Could not resolve ref: %s" ref_))
      | _ -> failwith (Printf.sprintf "Unknown ref typ: %s" ref_))
  | Value.V v -> v

let resolve_schema_ref { Components.schemas; _ } =
  resolve_ref "schemas" (CCFun.flip String_map.get schemas)

let resolve_response_ref { Components.responses; _ } =
  resolve_ref "responses" (CCFun.flip String_map.get responses)

let resolve_parameter_ref { Components.parameters; _ } =
  resolve_ref "parameters" (CCFun.flip String_map.get parameters)

(* TODO: Fix this because we are actually only converting Schemas into
   Components and not into Components.Schemas.  This might change if we start
   converting responses into Components too. *)
let module_name_of_ref base_module_name context ref_ =
  match context with
  | "schemas" | "parameters" | "responses" -> (
      match CCString.split_on_char '/' ref_ with
      | [ "#"; "components"; m; n ] when CCString.equal m context -> [ module_name_of_string n ]
      | [ "#"; "components"; m; n ] -> [ CCString.capitalize_ascii m; module_name_of_string n ]
      | _ -> failwith (Printf.sprintf "Unknown ref type: %s" ref_))
  | _ -> (
      match CCString.split_on_char '/' ref_ with
      | [ "#"; "components"; m; n ] -> [ base_module_name ^ "_components"; module_name_of_string n ]
      | _ -> failwith (Printf.sprintf "Unknown ref type: %s" ref_))

let http_status_to_name = function
  | "100" -> "Continue"
  | "101" -> "Switching_protocols"
  | "102" -> "Processing"
  | "103" -> "Checkpoint"
  | "200" -> "OK"
  | "201" -> "Created"
  | "202" -> "Accepted"
  | "203" -> "Non_authoritative_information"
  | "204" -> "No_content"
  | "205" -> "Reset_content"
  | "206" -> "Partial_content"
  | "207" -> "Multi_status"
  | "208" -> "Already_reported"
  | "226" -> "Im_used"
  | "300" -> "Multiple_choices"
  | "301" -> "Moved_permanently"
  | "302" -> "Found"
  | "303" -> "See_other"
  | "304" -> "Not_modified"
  | "305" -> "Use_proxy"
  | "306" -> "Switch_proxy"
  | "307" -> "Temporary_redirect"
  | "308" -> "Permanent_redirect"
  | "400" -> "Bad_request"
  | "401" -> "Unauthorized"
  | "402" -> "Payment_required"
  | "403" -> "Forbidden"
  | "404" -> "Not_found"
  | "405" -> "Method_not_allowed"
  | "406" -> "Not_acceptable"
  | "407" -> "Proxy_authentication_required"
  | "408" -> "Request_timeout"
  | "409" -> "Conflict"
  | "410" -> "Gone"
  | "411" -> "Length_required"
  | "412" -> "Precondition_failed"
  | "413" -> "Request_entity_too_large"
  | "414" -> "Request_uri_too_long"
  | "415" -> "Unsupported_media_type"
  | "416" -> "Requested_range_not_satisfiable"
  | "417" -> "Expectation_failed"
  | "418" -> "I_m_a_teapot"
  | "420" -> "Enhance_your_calm"
  | "422" -> "Unprocessable_entity"
  | "423" -> "Locked"
  | "424" -> "Failed_dependency"
  | "426" -> "Upgrade_required"
  | "428" -> "Precondition_required"
  | "429" -> "Too_many_requests"
  | "431" -> "Request_header_fields_too_large"
  | "444" -> "No_response"
  | "449" -> "Retry_with"
  | "450" -> "Blocked_by_windows_parental_controls"
  | "451" -> "Wrong_exchange_server"
  | "499" -> "Client_closed_request"
  | "500" -> "Internal_server_error"
  | "501" -> "Not_implemented"
  | "502" -> "Bad_gateway"
  | "503" -> "Service_unavailable"
  | "504" -> "Gateway_timeout"
  | "505" -> "Http_version_not_supported"
  | "506" -> "Variant_also_negotiates"
  | "507" -> "Insufficient_storage"
  | "508" -> "Loop_detected"
  | "509" -> "Bandwidth_limit_exceeded"
  | "510" -> "Not_extended"
  | "511" -> "Network_authentication_required"
  | "598" -> "Network_read_timeout_error"
  | "599" -> "Network_connect_timeout_error"
  | code -> "Http_" ^ code

let get_json_media_type m =
  match String_map.get "application/json" m with
  | None -> String_map.get "*/*" m
  | r -> r

let extract_module_name_from_ref ref_ = CCList.hd (CCList.rev (CCString.split ~by:"/" ref_))
let module_name_of_operation_id s = s |> CCString.replace ~sub:"/" ~by:"_" |> module_name_of_string

let field_name_of_schema s =
  match CCString.lowercase_ascii s with
  | ("type" | "in" | "object" | "class" | "to" | "private" | "include" | "ref") as s -> s ^ "_"
  | s when CCString.prefix ~pre:"_" s -> CCString.drop_while (( = ) '_') s ^ "_"
  | s when CCString.prefix ~pre:"$" s -> CCString.drop_while (( = ) '$') s ^ "_"
  | s when CCString.prefix ~pre:"@" s -> CCString.drop_while (( = ) '@') s ^ "_"
  | "+1" -> "plus_one"
  | "-1" -> "minus_one"
  | s -> s

let field_default_of_value = function
  | `String s -> Some Ast_helper.(Exp.constant (Const.string s))
  | `Bool b ->
      Some Ast_helper.(Exp.construct (Location.mknoloc (Gen.ident [ Bool.to_string b ])) None)
  | `Float fl -> Some Ast_helper.(Exp.constant (Const.float (CCFloat.to_string fl)))
  | `Int int -> Some Ast_helper.(Exp.constant (Const.integer (CCInt.to_string int)))
  | `List [] -> Some Json_schema_conv.Gen.(make_list [])
  | `List (`String _ :: _ as v) ->
      Some
        Json_schema_conv.Gen.(
          make_list
            (CCList.map
               (fun s -> Ast_helper.(Exp.constant (Const.string s)))
               (Yojson.Safe.Util.filter_string v)))
  | `List _ -> (* TODO: Add more *) None
  | json -> failwith (Printf.sprintf "Unknown field default value: %s" (Yojson.Safe.to_string json))

let record_field_attrs schema name required =
  CCList.flatten
    [
      (match schema.Schema.default with
      | Some default when schema.Schema.nullable ->
          CCOpt.map_or
            ~default:[]
            (fun default ->
              Gen.field_default
                (Ast_helper.Exp.construct (Location.mknoloc (Gen.ident [ "Some" ])) (Some default)))
            (field_default_of_value default)
      | Some default ->
          CCOpt.map_or
            ~default:[]
            (fun default -> Gen.field_default default)
            (field_default_of_value default)
      | None when not (String_set.mem name required) -> Gen.field_default_none
      | None -> []);
      (if CCString.equal (field_name_of_schema name) name then [] else Gen.yojson_key_name name);
    ]

let request_param_of_op_params components param_in params =
  let params =
    params
    |> CCList.filter_map (fun p ->
           let p = resolve_parameter_ref components p in
           if CCString.equal p.Parameter.in_ param_in then Some p else None)
  in
  match params with
  | [] -> Gen.make_list []
  | params ->
      let option obj =
        Ast_helper.(Exp.construct (Location.mknoloc (Gen.ident [ "Option" ])) (Some obj))
      in
      let scalar v = Ast_helper.(Exp.construct (Location.mknoloc (Gen.ident [ v ])) None) in
      let array obj =
        Ast_helper.(Exp.construct (Location.mknoloc (Gen.ident [ "Array" ])) (Some obj))
      in
      let rec type_desc_of_schema = function
        | { Schema.typ = Some typ; _ } as schema when Json_schema_conv.is_prim_type schema -> (
            match Json_schema_conv.extract_prim_type schema with
            | Some "string" -> scalar "String"
            | Some "integer" -> scalar "Int"
            | Some "boolean" -> scalar "Bool"
            | Some "number" -> assert false
            | _ -> assert false)
        | { Schema.typ = Some "array"; items = Some items; _ } ->
            array (type_desc_of_schema (resolve_schema_ref components items))
        | schema -> failwith (Schema.show_t_ schema)
      in
      let open Ast_helper in
      Exp.open_
        (Opn.mk (Mod.ident (Location.mknoloc (Gen.ident [ "Openapi"; "Request"; "Var" ]))))
        (Exp.open_
           (Opn.mk (Mod.ident (Location.mknoloc (Gen.ident [ "Parameters" ]))))
           (params
           |> CCList.map (fun p ->
                  let param_name =
                    Exp.ident
                      (Location.mknoloc
                         (Gen.ident [ "params"; field_name_of_schema p.Parameter.name ]))
                  in
                  let type_desc =
                    match resolve_schema_ref components p.Parameter.schema with
                    | { Schema.one_of = Some schemas; _ } ->
                        Exp.match_
                          param_name
                          (CCList.mapi (fun idx schema ->
                               Exp.case
                                 (Pat.construct
                                    (Location.mknoloc
                                       (Gen.ident
                                          [
                                            module_name_of_string p.Parameter.name;
                                            Printf.sprintf "V%d" idx;
                                          ]))
                                    (Some (Pat.var (Location.mknoloc "v"))))
                                 (Exp.construct
                                    (Location.mknoloc (Gen.ident [ "Var" ]))
                                    (Some
                                       (Exp.tuple
                                          [
                                            Exp.ident (Location.mknoloc (Gen.ident [ "v" ]));
                                            type_desc_of_schema schema;
                                          ]))))
                          @@ CCList.map (resolve_schema_ref components) schemas)
                    | schema ->
                        let type_desc = type_desc_of_schema schema in
                        let type_desc =
                          if
                            (p.Parameter.required || CCOpt.is_some schema.Schema.default)
                            && not schema.Schema.nullable
                          then type_desc
                          else option type_desc
                        in
                        Exp.construct
                          (Location.mknoloc (Gen.ident [ "Var" ]))
                          (Some (Exp.tuple [ param_name; type_desc ]))
                  in
                  Exp.tuple [ Exp.constant (Const.string p.Parameter.name); type_desc ])
           |> Gen.make_list))

let rec collect_schema_refs
    { Schema.properties; additional_properties; items; any_of; one_of; all_of; _ } =
  let additional_schemas =
    CCOpt.get_or ~default:[] any_of
    @ CCOpt.get_or ~default:[] one_of
    @ CCOpt.get_or ~default:[] all_of
  in
  CCList.flatten
    [
      CCList.flatten
        (CCList.map
           (fun (_, schema) ->
             match schema with
             | Value.Ref ref_ -> [ ref_ ]
             | Value.V schema -> collect_schema_refs schema)
           (String_map.to_list properties));
      (match additional_properties with
      | Additional_properties.Bool _ -> []
      | Additional_properties.V (Value.V schema) -> collect_schema_refs schema
      | Additional_properties.V _ -> []);
      (match items with
      | Some (Value.V schema) -> collect_schema_refs schema
      | Some (Value.Ref ref_) -> [ ref_ ]
      | None -> []);
      CCList.flatten
      @@ CCList.map
           (function
             | Value.Ref ref_ -> [ ref_ ]
             | Value.V schema -> collect_schema_refs schema)
           additional_schemas;
    ]

(* To convert an operation we need to convert the parameters, request body, and
   responses.  The resulting module will have a function to create a
   [Openapi.Request] value.

   We will convert [parameters] to a module called [Parameters] as a record. *)
let convert_str_operation base_module_name components uritmpl op_typ op =
  assert (CCOpt.is_some op.Operation.operation_id);
  let operation_id = CCOpt.get_exn_or "operation_id" op.Operation.operation_id in
  let params_config =
    Json_schema_conv.Config.make
      ~create_yojson_funcs:false
      ~field_name_of_schema
      ~module_name_of_ref:(module_name_of_ref base_module_name "paths")
      ~module_name_of_field_name:module_name_of_string
      ~prim_type_attrs:Gen.(deriving [ show_deriver ])
      ~record_type_attrs:(fun _ -> Gen.(deriving [ make_deriver; show_deriver ]))
      ~record_field_attrs
      ~resolve_ref:(resolve_schema_ref components)
      ()
  in
  let parameters_module =
    let config = params_config in
    let parameters =
      Schema.
        {
          (make_t_ ()) with
          typ = Some "object";
          additional_properties = Additional_properties.Bool false;
          properties =
            String_map.of_list
              (CCList.map
                 (fun p ->
                   let { Parameter.name; schema; _ } = resolve_parameter_ref components p in
                   (name, schema))
                 op.Operation.parameters);
          required =
            String_set.of_list
              (CCList.filter_map
                 (fun p ->
                   let p = resolve_parameter_ref components p in
                   let schema_is_ref =
                     match p.Parameter.schema with
                     | Value.Ref _ -> true
                     | _ -> false
                   in
                   let schema = Json_schema_conv.Config.resolve_ref config p.Parameter.schema in
                   (* Things that are considered required:

                      - The parameter is marked as required

                      - The schema is a ref and the ref is nullable, that means
                      if this parameter is not marked as required, the
                      "optionness" is taken care of at the schema definition. *)
                   if p.Parameter.required || (schema_is_ref && schema.Schema.nullable) then
                     Some p.Parameter.name
                   else None)
                 op.Operation.parameters);
        }
    in
    [
      Ast_helper.(
        Str.module_
          (Mb.mk
             (Location.mknoloc (Some "Parameters"))
             (Mod.structure
                (match op.Operation.parameters with
                | [] -> []
                | _ -> Json_schema_conv.convert_str_schema config parameters))));
    ]
  in
  let request_body =
    let config =
      Json_schema_conv.Config.make
        ~field_name_of_schema
        ~module_name_of_ref:(module_name_of_ref base_module_name "paths")
        ~module_name_of_field_name:module_name_of_string
        ~prim_type_attrs:Gen.(deriving [ yojson_deriver ~meta:true (); show_deriver ])
        ~record_type_attrs:(fun strict ->
          Gen.(deriving [ yojson_deriver ~strict ~meta:true (); show_deriver ]))
        ~record_field_attrs
        ~resolve_ref:(resolve_schema_ref components)
        ()
    in
    match op.Operation.request_body with
    | Some (Value.V request_body) -> (
        match get_json_media_type request_body.Request_body.content with
        | Some { Media_type.schema = Value.V schema } ->
            [
              Ast_helper.(
                Str.module_
                  (Mb.mk
                     (Location.mknoloc (Some "Request_body"))
                     (Mod.structure (Json_schema_conv.convert_str_schema config schema))));
            ]
        | Some { Media_type.schema = Value.Ref ref_ } ->
            [
              Ast_helper.(
                Str.module_
                  (Mb.mk
                     (Location.mknoloc (Some "Request_body"))
                     (Mod.structure
                        [
                          Gen.make_str_type
                            ~attrs:(Json_schema_conv.Config.prim_type_attrs config)
                            "t"
                            (Gen.qualified_type
                               (Json_schema_conv.Config.module_name_of_ref config ref_ @ [ "t" ]));
                        ])));
            ]
        | None -> [])
    | Some (Value.Ref ref_) -> failwith (Printf.sprintf "Unexpected ref in request body: %s" ref_)
    | None -> []
  in
  let responses =
    let config =
      Json_schema_conv.Config.make
        ~field_name_of_schema
        ~module_name_of_ref:(module_name_of_ref base_module_name "paths")
        ~module_name_of_field_name:module_name_of_string
        ~prim_type_attrs:Gen.(deriving [ yojson_deriver ~meta:false (); show_deriver ])
        ~record_type_attrs:(fun strict ->
          Gen.(deriving [ yojson_deriver ~strict (); show_deriver ]))
        ~record_field_attrs
        ~resolve_ref:(resolve_schema_ref components)
        ()
    in
    let resolved_responses =
      op.Operation.responses
      |> String_map.to_list
      |> CCList.sort (fun (a, _) (b, _) -> CCString.compare a b)
      |> CCList.map (fun (c, r) -> (c, resolve_response_ref components r))
    in
    Ast_helper.(
      Str.module_
        (Mb.mk
           (Location.mknoloc (Some "Responses"))
           (Mod.structure
           @@ CCList.map
                (fun (code, r) ->
                  Str.module_
                    (Mb.mk
                       (Location.mknoloc (Some (http_status_to_name code)))
                       (Mod.structure
                          (match get_json_media_type r.Response.content with
                          | Some { Media_type.schema = Value.V schema } ->
                              Json_schema_conv.convert_str_schema config schema
                          | Some { Media_type.schema = Value.Ref ref_ } ->
                              [
                                Gen.make_str_type
                                  ~attrs:(Json_schema_conv.Config.prim_type_attrs config)
                                  (Json_schema_conv.Config.tidx_to_string config)
                                  (Gen.qualified_type
                                     (Json_schema_conv.Config.module_name_of_ref config ref_
                                     @ [ "t" ]));
                              ]
                          | None -> []))))
                resolved_responses
           @ [
               Str.type_
                 Asttypes.Recursive
                 [
                   Type.mk
                     ~attrs:Gen.(deriving [ show_deriver ])
                     ~manifest:
                       (Typ.variant
                          (CCList.map
                             (fun (code, r) ->
                               Rf.tag
                                 (Location.mknoloc (http_status_to_name code))
                                 false
                                 (match get_json_media_type r.Response.content with
                                 | Some _ ->
                                     [
                                       Typ.constr
                                         (Location.mknoloc
                                            (Gen.ident [ http_status_to_name code; "t" ]))
                                         [];
                                     ]
                                 | None -> []))
                             resolved_responses)
                          Asttypes.Closed
                          None)
                     (Location.mknoloc "t");
                 ];
               Str.value
                 Asttypes.Nonrecursive
                 [
                   Vb.mk
                     (Pat.var (Location.mknoloc "t"))
                     (resolved_responses
                     |> CCList.map (fun (code, r) ->
                            match get_json_media_type r.Response.content with
                            | Some r ->
                                Exp.tuple
                                  [
                                    Exp.constant (Const.string code);
                                    Exp.apply
                                      (Exp.ident
                                         (Location.mknoloc
                                            (Gen.ident [ "Openapi"; "of_json_body" ])))
                                      [
                                        ( Asttypes.Nolabel,
                                          Exp.fun_
                                            Asttypes.Nolabel
                                            None
                                            (Pat.var (Location.mknoloc "v"))
                                            (Exp.variant
                                               (http_status_to_name code)
                                               (Some
                                                  (Exp.ident (Location.mknoloc (Gen.ident [ "v" ])))))
                                        );
                                        ( Asttypes.Nolabel,
                                          Exp.ident
                                            (Location.mknoloc
                                               (Gen.ident [ http_status_to_name code; "of_yojson" ]))
                                        );
                                      ];
                                  ]
                            | None ->
                                Exp.tuple
                                  [
                                    Exp.constant (Const.string code);
                                    Exp.fun_
                                      Asttypes.Nolabel
                                      None
                                      (Pat.var (Location.mknoloc "_"))
                                      (Exp.construct
                                         (Location.mknoloc (Gen.ident [ "Ok" ]))
                                         (Some (Exp.variant (http_status_to_name code) None)));
                                  ])
                     |> Gen.make_list);
                 ];
             ])))
  in
  let url =
    Ast_helper.(
      Str.value
        Asttypes.Nonrecursive
        [ Vb.mk (Pat.var (Location.mknoloc "url")) (Exp.constant (Const.string uritmpl)) ])
  in
  let make_body =
    Ast_helper.(
      Exp.apply
        (Exp.ident (Location.mknoloc (Gen.ident [ "Openapi"; "Request"; "make" ])))
        (CCList.flatten
           [
             (match op.Operation.request_body with
             | Some (Value.V request_body)
               when request_body.Request_body.required
                    && CCOpt.is_some (get_json_media_type request_body.Request_body.content) ->
                 (* TODO: Handle reference bodies that are required *)
                 [
                   ( Asttypes.Labelled "body",
                     Exp.apply
                       (Exp.ident (Location.mknoloc (Gen.ident [ "Request_body"; "to_yojson" ])))
                       [ (Asttypes.Nolabel, Exp.ident (Location.mknoloc (Gen.ident [ "body" ]))) ]
                   );
                 ]
             | Some (Value.V _) -> []
             | Some _ ->
                 [
                   ( Asttypes.Optional "body",
                     Exp.apply
                       (Exp.ident (Location.mknoloc (Gen.ident [ "CCOpt"; "map" ])))
                       [
                         ( Asttypes.Nolabel,
                           Exp.ident (Location.mknoloc (Gen.ident [ "Request_body"; "to_yojson" ]))
                         );
                         (Asttypes.Nolabel, Exp.ident (Location.mknoloc (Gen.ident [ "body" ])));
                       ] );
                 ]
             | None -> []);
             [
               (Asttypes.Labelled "headers", Gen.make_list []);
               ( Asttypes.Labelled "url_params",
                 request_param_of_op_params components "path" op.Operation.parameters );
               ( Asttypes.Labelled "query_params",
                 request_param_of_op_params components "query" op.Operation.parameters );
               (Asttypes.Labelled "url", Exp.ident (Location.mknoloc (Gen.ident [ "url" ])));
               ( Asttypes.Labelled "responses",
                 Exp.ident (Location.mknoloc (Gen.ident [ "Responses"; "t" ])) );
               ( Asttypes.Nolabel,
                 Exp.variant
                   (match op_typ with
                   | `Get -> "Get"
                   | `Post -> "Post"
                   | `Put -> "Put"
                   | `Patch -> "Patch"
                   | `Delete -> "Delete")
                   None );
             ];
           ]))
  in
  (* The portion of the make function for params *)
  let make_params =
    let open Ast_helper in
    match op.Operation.parameters with
    | [] ->
        Exp.fun_
          Asttypes.Nolabel
          None
          (Pat.construct (Location.mknoloc (Gen.ident [ "()" ])) None)
          make_body
    | _ -> Exp.fun_ Asttypes.Nolabel None (Pat.var (Location.mknoloc "params")) make_body
  in
  let make =
    Gen.make_func
      "make"
      (match op.Operation.request_body with
      | Some (Value.V request_body) when request_body.Request_body.required ->
          (* TODO: Handle ref that is required *)
          Ast_helper.(
            Exp.fun_ (Asttypes.Labelled "body") None (Pat.var (Location.mknoloc "body")) make_params)
      | Some _ ->
          Ast_helper.(
            Exp.fun_ (Asttypes.Optional "body") None (Pat.var (Location.mknoloc "body")) make_params)
      | None -> make_params)
  in
  (operation_id, parameters_module @ request_body @ [ responses; url; make ])

let convert_str_components state { Components.schemas; responses; _ } =
  let schemas_refs =
    Tsort.sort
      (CCList.map
         (fun (name, schema) ->
           match schema with
           | Value.Ref ref_ -> (name, [ extract_module_name_from_ref ref_ ])
           | Value.V schema ->
               (name, CCList.map extract_module_name_from_ref (collect_schema_refs schema)))
         (String_map.to_list schemas))
  in
  match schemas_refs with
  | Tsort.Sorted sorted ->
      let modules =
        CCList.map
          (fun (name, schema) ->
            let m_expr =
              match schema with
              | Value.V schema ->
                  Ast_helper.Mod.structure (Json_schema_conv.convert_str_schema state schema)
              | Value.Ref _ -> Ast_helper.Mod.structure []
            in
            Ast_helper.(
              Str.module_ (Mb.mk (Location.mknoloc (Some (module_name_of_string name))) m_expr)))
          (CCList.map (fun name -> (name, String_map.find name schemas)) sorted)
      in
      modules
  | Tsort.ErrorCycle _ -> assert false

let convert_str_paths output_base base_module_name components paths =
  let modules =
    CCList.map
      (fun (uritmpl, path) ->
        assert (path.Path.parameters = None);
        CCList.map
          (CCFun.uncurry (convert_str_operation base_module_name components uritmpl))
          (CCList.filter_map
             (fun (t, op) -> CCOpt.map (fun op -> (t, op)) op)
             [
               (`Get, path.Path.get);
               (`Put, path.Path.put);
               (`Post, path.Path.post);
               (`Delete, path.Path.delete);
               (`Patch, path.Path.patch);
             ]))
      (String_map.to_list paths)
    |> CCList.flatten
    |> CCList.map (fun ((op, _) as v) -> (fst @@ CCString.Split.left_exn ~by:"/" op, [ v ]))
    |> String_map.of_list_with ~f:(fun _ -> CCList.append)
  in
  CCList.iter
    (fun (name, operations) ->
      let modules =
        CCList.map
          (fun (operation_id, body) ->
            let op_name = snd @@ CCString.Split.left_exn ~by:"/" operation_id in
            Ast_helper.(
              Str.module_
                (Mb.mk
                   (Location.mknoloc (Some (module_name_of_operation_id op_name)))
                   (Mod.structure body))))
          operations
      in
      CCIO.with_out
        (output_base ^ "_" ^ CCString.lowercase_ascii (module_name_of_string name) ^ ".ml")
        (fun oc -> CCIO.write_line oc (Pprintast.string_of_structure modules)))
    (String_map.to_list modules)

let convert_str_document output_base base_module_name { Document.paths; components } =
  let components_modules =
    convert_str_components
      (Json_schema_conv.Config.make
         ~field_name_of_schema
         ~module_name_of_ref:(module_name_of_ref base_module_name "schemas")
         ~module_name_of_field_name:(module_name_of_field_name components)
         ~prim_type_attrs:Gen.(deriving [ yojson_deriver (); show_deriver ])
         ~record_type_attrs:(fun strict ->
           Gen.(deriving [ yojson_deriver ~strict (); show_deriver ]))
         ~record_field_attrs
         ~resolve_ref:(resolve_schema_ref components)
         ())
      components
  in
  CCIO.with_out (output_base ^ "_components.ml") (fun cout ->
      CCIO.write_line cout (Pprintast.string_of_structure components_modules));
  convert_str_paths output_base base_module_name components paths

let convert ~input_file ~output_name ~output_dir =
  let output_base = Filename.concat output_dir output_name in
  let base_module_name = CCString.capitalize_ascii output_name in
  match Document.of_yojson (Yojson.Safe.from_file input_file) with
  | Ok document -> convert_str_document output_base base_module_name document
  | Error err -> print_endline ("ERROR: " ^ err)
