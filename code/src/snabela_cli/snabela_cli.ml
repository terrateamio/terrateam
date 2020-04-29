module SMap = CCMap.Make (String)

module Cmdline = struct
  module C = Cmdliner

  let kv =
    let doc = "TOML file of variables." in
    C.Arg.(required & opt (some file) None & info [ "kv" ] ~docv:"FILE" ~doc)

  let transformers =
    let doc = "Directory containing transformers." in
    C.Arg.(value & opt_all dir [] & info [ "td" ] ~docv:"DIR" ~doc)

  let append_transformers =
    let doc = "Append these transformers to all replacements." in
    C.Arg.(value & opt_all dir [] & info [ "at" ] ~docv:"DIR" ~doc)
end

exception Invalid_type

exception Transformer_error of string

let result_of_toml_result = function
  | `Ok v    -> Ok v
  | `Error e -> Error (`Toml_parse_error e)

let rec kv_of_toml_table_exn tbl =
  let module Kv = Snabela.Kv in
  let open TomlTypes in
  Table.fold
    (fun k v acc ->
      let k = Table.Key.to_string k in
      match v with
        | TBool b            -> Kv.Map.add k (Kv.bool b) acc
        | TInt i             -> Kv.Map.add k (Kv.int i) acc
        | TFloat f           -> Kv.Map.add k (Kv.float f) acc
        | TString s          -> Kv.Map.add k (Kv.string s) acc
        | TArray arr         -> Kv.Map.add k (Kv.list (kv_of_toml_array_exn arr)) acc
        | TDate _ | TTable _ -> raise Invalid_type)
    tbl
    Kv.Map.empty

and kv_of_toml_array_exn arr =
  let open TomlTypes in
  match arr with
    | NodeEmpty -> []
    | NodeTable tbls -> ListLabels.map ~f:kv_of_toml_table_exn tbls
    | NodeBool _ | NodeInt _ | NodeFloat _ | NodeString _ | NodeDate _ | NodeArray _ ->
        raise Invalid_type

let kv_of_toml_table tbl =
  try Ok (kv_of_toml_table_exn tbl) with Invalid_type -> Error `Invalid_type

let run_transformer exec v =
  let b = Bytes.of_string (Snabela.string_of_scalar v) in
  try Snabela.Kv.S (String.concat "" (Process.read_stdout ~stdin:b exec [||]))
  with _ ->
    raise
      (Transformer_error
         (Printf.sprintf "Failed to execute transformer %s" (Filename.basename exec)))

let transformer_of_dir d =
  let files = Array.to_list (Sys.readdir d) in
  ListLabels.map ~f:(fun f -> (f, run_transformer (Filename.concat d f))) files

let load_transformers ds =
  ListLabels.fold_left
    ~f:(fun acc d ->
      let ts = transformer_of_dir d in
      let m = SMap.of_list ts in
      SMap.union (fun _ l _ -> Some l) acc m)
    ~init:SMap.empty
    ds

let snabela_apply kv_file transformers append_transformers =
  let open CCResult.Infix in
  let template_str = CCIO.read_all stdin in
  Snabela.Template.of_utf8_string template_str
  >>= fun template ->
  result_of_toml_result (Toml.Parser.from_filename kv_file)
  >>= fun toml ->
  kv_of_toml_table toml
  >>= fun kv ->
  let transformers = load_transformers transformers in
  let at =
    ListLabels.map
      ~f:(fun tname ->
        match SMap.get tname transformers with
          | Some tr -> tr
          | None    -> failwith "nyi")
      append_transformers
  in
  let cache = Snabela.of_template ~append_transformers:at template (SMap.to_list transformers) in
  Snabela.apply cache kv
  >>= fun applied ->
  output_string stdout applied;
  Ok ()

let snabela kv_file transformers append_transformers =
  match snabela_apply kv_file transformers append_transformers with
    | Ok _      -> `Ok ()
    | Error err ->
        let err_str =
          match err with
            | `Missing_key (key, ln)           ->
                Printf.sprintf "Missing key %s in replacement on line %d" key ln
            | `Expected_boolean (key, ln)      ->
                Printf.sprintf "Expected key %s to be a boolean in replacement on line %d" key ln
            | `Expected_list (key, ln)         ->
                Printf.sprintf "Expected key %s to be a list in replacement on line %d" key ln
            | `Missing_transformer (tr, ln)    ->
                Printf.sprintf "Missing transformer %s in replacement on line %d" tr ln
            | `Non_scalar_key (key, ln)        ->
                Printf.sprintf "Key %s must be a scalar in replacement on line %d" key ln
            | `Premature_eof                   -> "Template ended prematurely"
            | `Missing_closing_section section ->
                Printf.sprintf "Section named %s was not closed before end of file" section
            | `Exn exn                         -> Printf.sprintf
                                                    "Failed with exception %s"
                                                    (Printexc.to_string exn)
            | `Invalid_replacement ln          -> Printf.sprintf
                                                    "Malformed replacement on line %d"
                                                    ln
            | `Invalid_transformer ln          ->
                Printf.sprintf "Malformed transformer in replacement on line %d" ln
            | `Invalid_type                    -> "TOML file cannot be converted to a key-value"
            | `Toml_parse_error (s, _)         -> Printf.sprintf
                                                    "TOML parse error %s"
                                                    (String.trim s)
        in
        `Error (false, err_str)

let cmd =
  let doc = "Execute replacements in a template." in
  let exits = Cmdliner.Term.default_exits in
  Cmdliner.Term.
    ( ret Cmdline.(const snabela $ kv $ transformers $ append_transformers),
      info "snabela" ~version:"1.0" ~doc ~exits )

let () = Cmdliner.Term.(exit @@ eval cmd)
