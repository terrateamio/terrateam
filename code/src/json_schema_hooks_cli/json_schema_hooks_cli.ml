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

  let non_strict_records =
    let doc = "Do not require records to be strict" in
    C.Arg.(value & flag & info [ "non-strict-records" ] ~doc)

  let convert_cmd f =
    let doc = "Convert to Ocaml" in
    C.Cmd.v
      (C.Cmd.info "convert" ~doc)
      C.Term.(const f $ non_strict_records $ input_file $ output_name $ output_dir)

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

let module_name_of_ref module_base ref_ =
  match CCString.split_on_char '/' ref_ with
  | [ "#"; "definitions"; n ] ->
      [ module_base ^ "_" ^ CCString.lowercase_ascii (module_name_of_string n) ]
  | _ -> failwith (Printf.sprintf "Unknown ref: %s" ref_)

let variant_name_of_ref ref_ =
  match CCString.split_on_char '/' ref_ with
  | [ "#"; "definitions"; n ] -> [ module_name_of_string n ]
  | _ -> failwith (Printf.sprintf "Unknown ref: %s" ref_)

let field_name_of_schema s =
  match CCString.lowercase_ascii s with
  | ("type" | "in" | "object" | "class" | "to" | "private" | "include" | "ref" | "method") as s ->
      s ^ "_"
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
    CCOption.get_or ~default:[] any_of
    @ CCOption.get_or ~default:[] one_of
    @ CCOption.get_or ~default:[] all_of
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

let convert_def strict_records definitions module_base def =
  Json_schema_conv.convert_str_schema
    (Json_schema_conv.Config.make
       ~field_name_of_schema
       ~module_name_of_ref:(module_name_of_ref module_base)
       ~module_name_of_field_name:(module_name_of_field_name definitions)
       ~prim_type_attrs:
         Json_schema_conv.Gen.(deriving [ yojson_deriver (); show_deriver; eq_deriver ])
       ~record_type_attrs:(fun strict ->
         Json_schema_conv.Gen.(
           deriving
             [
               yojson_deriver ~strict:(strict && strict_records) ();
               make_deriver;
               show_deriver;
               eq_deriver;
             ]))
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
       ~variant_name_of_ref
       ())
    def

let convert_document strict_records output_dir output_name { Document.definitions; one_of } =
  let module_base = CCString.capitalize_ascii output_name in
  let event = Json_schema_conv.{ (Schema.make_t_ ()) with Schema.one_of = Some one_of } in
  Json_schema_conv.String_map.iter
    (fun name def ->
      match def with
      | Json_schema_conv.Value.Ref _ -> ()
      | Json_schema_conv.Value.V def ->
          let module_name =
            module_base ^ "_" ^ CCString.lowercase_ascii (module_name_of_string name)
          in
          let structure = convert_def strict_records definitions module_base def in
          CCIO.with_out
            (Filename.concat output_dir (CCString.lowercase_ascii module_name ^ ".ml"))
            (fun oc -> CCIO.write_line oc (Pprintast.string_of_structure structure)))
    definitions;
  let structure =
    Ast_helper.(
      CCList.map
        (fun name ->
          let module_name =
            module_base ^ "_" ^ CCString.lowercase_ascii (module_name_of_string name)
          in
          Str.module_
            (Mb.mk
               (Location.mknoloc (Some (module_name_of_string name)))
               (Mod.ident (Location.mknoloc (Json_schema_conv.Gen.ident [ module_name ])))))
        (definitions
        |> Json_schema_conv.String_map.to_list
        |> CCList.map fst
        |> CCList.sort CCString.compare)
      @ [
          Str.module_
            (Mb.mk
               (Location.mknoloc (Some (module_name_of_string "event")))
               (Mod.structure (convert_def strict_records definitions module_base event)));
        ])
  in
  CCIO.with_out
    (Filename.concat output_dir (output_name ^ ".ml"))
    (fun oc -> CCIO.write_line oc (Pprintast.string_of_structure structure))

let convert non_strict_records input_file output_name output_dir =
  let strict_records = not non_strict_records in
  match Document.of_yojson (Yojson.Safe.from_file input_file) with
  | Ok document -> convert_document strict_records output_dir output_name document
  | Error err -> print_endline err

let cmds = Cmdline.[ convert_cmd convert ]

let () =
  let info = Cmdliner.Cmd.info "json_schema_hooks_cli" in
  exit @@ Cmdliner.Cmd.eval @@ Cmdliner.Cmd.group ~default:Cmdline.default_cmd info cmds
