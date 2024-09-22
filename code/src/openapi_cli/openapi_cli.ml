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

let convert non_strict_records input_file output_name output_dir =
  let strict_records = not non_strict_records in
  Openapi_conv.convert ~strict_records ~input_file ~output_name ~output_dir

let cmds = Cmdline.[ convert_cmd convert ]

let () =
  let info = Cmdliner.Cmd.info "openapi_cli" in
  exit @@ Cmdliner.Cmd.eval @@ Cmdliner.Cmd.group ~default:Cmdline.default_cmd info cmds
