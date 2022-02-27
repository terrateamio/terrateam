module Cmdline = struct
  module C = Cmdliner

  let output_name =
    let doc = "Root name for output files" in
    C.Arg.(required & opt (some string) None & info [ "n"; "name" ] ~doc)

  let output_dir =
    let doc = "Directory to write outputs to" in
    C.Arg.(required & opt (some string) None & info [ "output-dir" ] ~doc)

  let input_file =
    let doc = "Input file" in
    C.Arg.(required & opt (some string) None & info [ "i"; "input" ] ~doc)

  let convert_cmd f =
    let doc = "Convert to Ocaml" in
    C.Cmd.v (C.Cmd.info "convert" ~doc) C.Term.(const f $ input_file $ output_name $ output_dir)

  let default_cmd = C.Term.(ret (const (`Help (`Pager, None))))
end

module Document = struct
  type t = {
    definitions : Json_schema_conv.Schema.t Json_schema_conv.Properties.t;
    one_of : Json_schema_conv.Schema.t list; [@key "oneOf"]
  }
  [@@deriving yojson { strict = false }, show]
end

let module_name_of_string s =
  s
  |> CCString.replace ~sub:"-" ~by:"_"
  |> CCString.replace ~sub:"$" ~by:"_"
  |> (function
       | s when CCString.prefix ~pre:"_" s -> CCString.drop_while (( = ) '_') s ^ "_"
       | s -> s)
  |> CCString.capitalize_ascii

let module_name_of_field_name defs s =
  if Json_schema_conv.String_map.mem (CCString.replace ~sub:"_" ~by:"-" s) defs then
    module_name_of_string s ^ "_"
  else module_name_of_string s

let module_name_of_ref ref_ =
  match CCString.split_on_char '/' ref_ with
  | [ "#"; "definitions"; n ] -> [ module_name_of_string n ]
  | _ -> failwith (Printf.sprintf "Unknown ref: %s" ref_)

let field_name_of_schema s =
  match CCString.lowercase_ascii s with
  | ("type" | "in" | "object" | "class" | "to" | "private" | "include" | "ref") as s -> s ^ "_"
  | s when CCString.prefix ~pre:"_" s -> CCString.drop_while (( = ) '_') s ^ "_"
  | s when CCString.prefix ~pre:"$" s -> CCString.drop_while (( = ) '$') s ^ "_"
  | s when CCString.prefix ~pre:"@" s -> CCString.drop_while (( = ) '@') s ^ "_"
  | "+1" -> "plus_one"
  | "-1" -> "minus_one"
  | s -> (
      s
      |> CCString.replace ~sub:"-" ~by:"_"
      |> CCString.replace ~sub:"$" ~by:"_"
      |> function
      | s when CCString.prefix ~pre:"_" s -> CCString.drop_while (( = ) '_') s ^ "_"
      | s -> s)

let field_default_of_value =
  let module Gen = Json_schema_conv.Gen in
  function
  | `String s -> Gen.field_default Ast_helper.(Exp.constant (Const.string s))
  | `Bool b ->
      Gen.field_default
        Ast_helper.(Exp.construct (Location.mknoloc (Gen.ident [ Bool.to_string b ])) None)
  | `Float fl -> Gen.field_default Ast_helper.(Exp.constant (Const.float (CCFloat.to_string fl)))
  | `Int int -> Gen.field_default Ast_helper.(Exp.constant (Const.integer (CCInt.to_string int)))
  | `List [] -> Gen.(field_default (make_list []))
  | `List (`String _ :: _ as v) ->
      Gen.(
        field_default
          (make_list
             (CCList.map
                (fun s -> Ast_helper.(Exp.constant (Const.string s)))
                (Yojson.Safe.Util.filter_string v))))
  | `List _ -> (* TODO: Add more *) []
  | json -> failwith (Printf.sprintf "Unknown field default value: %s" (Yojson.Safe.to_string json))

let rec resolve_ref definitions ref_ =
  let module Value = Json_schema_conv.Value in
  match ref_ with
  | Value.Ref ref_ -> (
      match CCString.split_on_char '/' ref_ with
      | [ "#"; "definitions"; name ] -> (
          match Json_schema_conv.String_map.get name definitions with
          | Some (Value.Ref _ as ref_) -> resolve_ref definitions ref_
          | Some (Value.V v) -> v
          | None -> failwith (Printf.sprintf "Could not resolve ref: %s" ref_))
      | _ -> failwith (Printf.sprintf "Unknown ref: %s" ref_))
  | Value.V v -> v

let rec collect_schema_refs
    { Json_schema_conv.Schema.properties; additional_properties; items; any_of; one_of; all_of; _ }
    =
  let open Json_schema_conv in
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

let extract_module_name_from_ref ref_ = CCList.hd (CCList.rev (CCString.split ~by:"/" ref_))

let convert_definitions definitions =
  let schemas_refs =
    Tsort.sort
      (CCList.map
         (fun (name, schema) ->
           match schema with
           | Json_schema_conv.Value.Ref ref_ -> (name, [ extract_module_name_from_ref ref_ ])
           | Json_schema_conv.Value.V schema ->
               (name, CCList.map extract_module_name_from_ref (collect_schema_refs schema)))
         (Json_schema_conv.String_map.to_list definitions))
  in
  match schemas_refs with
  | Tsort.Sorted sorted ->
      CCList.flatten
        (CCList.map
           (fun (name, def) ->
             match def with
             | Json_schema_conv.Value.Ref _ -> []
             | Json_schema_conv.Value.V def ->
                 [
                   Ast_helper.(
                     Str.module_
                       (Mb.mk
                          (Location.mknoloc (Some (module_name_of_string name)))
                          (Mod.structure
                             (Json_schema_conv.convert_str_schema
                                (Json_schema_conv.Config.make
                                   ~field_name_of_schema
                                   ~module_name_of_ref
                                   ~module_name_of_field_name:
                                     (module_name_of_field_name definitions)
                                   ~prim_type_attrs:
                                     Json_schema_conv.Gen.(
                                       deriving [ yojson_deriver (); show_deriver ])
                                   ~record_type_attrs:(fun strict ->
                                     Json_schema_conv.Gen.(
                                       deriving
                                         [ yojson_deriver ~strict (); make_deriver; show_deriver ]))
                                   ~record_field_attrs:(fun schema name required ->
                                     let field_name = field_name_of_schema name in
                                     CCList.flatten
                                       [
                                         (if CCString.equal field_name name then []
                                         else Json_schema_conv.Gen.yojson_key_name name);
                                         (if Json_schema_conv.String_set.mem name required then []
                                         else
                                           match schema.Json_schema_conv.Schema.default with
                                           | Some default -> field_default_of_value default
                                           | None -> Json_schema_conv.Gen.field_default_none);
                                       ])
                                   ~resolve_ref:(resolve_ref definitions)
                                   ())
                                def))));
                 ])
           (CCList.map
              (fun name -> (name, Json_schema_conv.String_map.find name definitions))
              sorted))
  | Tsort.ErrorCycle _ -> assert false

let convert_document output_base { Document.definitions; one_of } =
  let event = Json_schema_conv.(Value.V { (Schema.make_t_ ()) with Schema.one_of = Some one_of }) in
  let definitions = Json_schema_conv.String_map.add "event" event definitions in
  let definition_modules = convert_definitions definitions in
  CCIO.with_out (output_base ^ ".ml") (fun oc ->
      CCIO.write_line oc (Pprintast.string_of_structure definition_modules))

let convert input_file output_name output_dir =
  let output_base = Filename.concat output_dir output_name in
  match Document.of_yojson (Yojson.Safe.from_file input_file) with
  | Ok document -> convert_document output_base document
  | Error err -> print_endline err

let cmds = Cmdline.[ convert_cmd convert ]

let () =
  let info = Cmdliner.Cmd.info "json_schema_hooks_cli" in
  exit @@ Cmdliner.Cmd.eval @@ Cmdliner.Cmd.group ~default:Cmdline.default_cmd info cmds
