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

let convert input_file output_name output_dir =
  Openapi_conv.convert ~input_file ~output_name ~output_dir

let cmds = Cmdline.[ convert_cmd convert ]

let () =
  let info = Cmdliner.Cmd.info "openapi_cli" in
  exit @@ Cmdliner.Cmd.eval @@ Cmdliner.Cmd.group ~default:Cmdline.default_cmd info cmds
