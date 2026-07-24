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

  let search_path =
    let doc =
      "Directory to search for files referenced by foreign $refs (e.g. \
       \"common.json#/definitions/Foo\"). May be passed multiple times; directories are searched \
       in the order given."
    in
    C.Arg.(value & opt_all dir [] & info [ "S"; "search-path" ] ~doc ~docv:"DIR")

  let file_link =
    let link_conv =
      C.Arg.Conv.make
        ~docv:"FILE=MODULE_BASE"
        ~parser:(fun s ->
          match CCString.Split.left ~by:"=" s with
          | Some kv -> Ok kv
          | None -> Error "Must be of form FILE=MODULE_BASE")
        ~pp:(fun fmt (file, module_base) -> Format.fprintf fmt "%s=%s" file module_base)
        ()
    in
    let doc =
      "Reference a foreign schema file as an existing OCaml module instead of inlining it. Refs \
       into FILE generate references to MODULE_BASE (e.g. \
       \"session-capabilities.json=Sgs_session_caps\" makes \
       \"session-capabilities.json#/definitions/Foo\" generate \"Sgs_session_caps_foo.t\"). May be \
       passed multiple times."
    in
    C.Arg.(value & opt_all link_conv [] & info [ "file-link" ] ~doc)

  let convert_cmd f =
    let doc = "Convert to Ocaml" in
    C.Cmd.v
      (C.Cmd.info "convert" ~doc)
      C.Term.(
        const f
        $ non_strict_records
        $ input_file
        $ output_name
        $ output_dir
        $ search_path
        $ file_link)

  let default_cmd = C.Term.(ret (const (`Help (`Pager, None))))
end

let convert non_strict_records input_file output_name output_dir search_path file_link =
  let strict_records = not non_strict_records in
  Openapi_conv.convert ~strict_records ~search_path ~file_link ~input_file ~output_name ~output_dir

let cmds = Cmdline.[ convert_cmd convert ]

let () =
  let info = Cmdliner.Cmd.info "openapi_cli" in
  exit @@ Cmdliner.Cmd.eval @@ Cmdliner.Cmd.group ~default:Cmdline.default_cmd info cmds
