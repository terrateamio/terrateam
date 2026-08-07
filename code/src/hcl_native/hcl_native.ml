type err = [ `Hcl_native_error of string ] [@@deriving show]

(* The shim is a sibling executable next to the current process. PDS lays
   builds out as code/build/<profile>/<module>/..., and the shim
   Makefile drops [sg_hcl_shim] into the same [<profile>] directory, so
   a binary running from [<profile>/<caller>/foo.native] finds the shim
   at [../hcl_native_shim/sg_hcl_shim]. The shim is only expected to be
   available in development and test environments. *)
let shim_relative_path = "../hcl_native_shim/sg_hcl_shim"
let shim_bin () = Filename.concat (Filename.dirname Sys.executable_name) shim_relative_path

(* One subprocess per OCaml process, spawned lazily. Access is serialized
   via [mutex]; the shim protocol is strictly request/response with no
   concurrency, so a single global channel is the simplest correct design. *)
type shim = {
  pid : int;
  stdin : out_channel;
  stdout : in_channel;
}

let mutex = Mutex.create ()
let shim : shim option ref = ref None

let spawn () =
  let bin = shim_bin () in
  let child_stdin_read, child_stdin_write = Unix.pipe ~cloexec:true () in
  let child_stdout_read, child_stdout_write = Unix.pipe ~cloexec:true () in
  let pid = Unix.create_process bin [| bin |] child_stdin_read child_stdout_write Unix.stderr in
  Unix.close child_stdin_read;
  Unix.close child_stdout_write;
  let stdin = Unix.out_channel_of_descr child_stdin_write in
  let stdout = Unix.in_channel_of_descr child_stdout_read in
  { pid; stdin; stdout }

let close_shim s =
  (try close_out s.stdin with _ -> ());
  (try close_in s.stdout with _ -> ());
  try
    let _ = Unix.waitpid [] s.pid in
    ()
  with _ -> ()

let ensure_shim () =
  match !shim with
  | Some s -> s
  | None ->
      let s = spawn () in
      shim := Some s;
      s

let write_u32_be oc n =
  let b = Bytes.create 4 in
  Bytes.set_uint8 b 0 ((n lsr 24) land 0xff);
  Bytes.set_uint8 b 1 ((n lsr 16) land 0xff);
  Bytes.set_uint8 b 2 ((n lsr 8) land 0xff);
  Bytes.set_uint8 b 3 (n land 0xff);
  output_bytes oc b

let read_u32_be ic =
  let b = Bytes.create 4 in
  really_input ic b 0 4;
  (Bytes.get_uint8 b 0 lsl 24)
  lor (Bytes.get_uint8 b 1 lsl 16)
  lor (Bytes.get_uint8 b 2 lsl 8)
  lor Bytes.get_uint8 b 3

(* Op byte values — must match sg_hcl_shim's const block. *)
let op_parse_file = '\x00'
let op_parse_expression = '\x01'
let op_parse_template = '\x02'

let send_request s op src =
  (* Length covers the op byte plus the source bytes. *)
  let n = 1 + String.length src in
  write_u32_be s.stdin n;
  output_char s.stdin op;
  output_string s.stdin src;
  flush s.stdin

let read_response s =
  let total = read_u32_be s.stdout in
  if total < 1 then failwith (Printf.sprintf "sg_hcl_shim: malformed response length %d" total);
  let status = input_char s.stdout in
  let payload = Bytes.create (total - 1) in
  really_input s.stdout payload 0 (total - 1);
  (status, Bytes.unsafe_to_string payload)

(* Round-trip one request through the shim, with a single respawn on failure. *)
let request op src =
  let try_once () =
    let s = ensure_shim () in
    send_request s op src;
    read_response s
  in
  try try_once ()
  with exn -> (
    (match !shim with
    | Some s ->
        close_shim s;
        shim := None
    | None -> ());
    (* Second attempt — the shim may have died between calls. *)
    try try_once ()
    with exn2 ->
      raise
        (Failure
           (Printf.sprintf
              "sg_hcl_shim: %s (first: %s)"
              (Printexc.to_string exn2)
              (Printexc.to_string exn))))

(* Decode a success payload via [of_yojson], normalizing errors into [err]. *)
let decode_with of_yojson payload =
  match Yojson.Safe.from_string payload with
  | exception Yojson.Json_error msg ->
      Error (`Hcl_native_error (Printf.sprintf "hcl_native: invalid JSON from shim: %s" msg))
  | json -> (
      match of_yojson json with
      | Ok v -> Ok v
      | Error msg ->
          Error (`Hcl_native_error (Printf.sprintf "hcl_native: shim/OCaml shape mismatch: %s" msg))
      )

let run_op op of_yojson src =
  (* Mutex.protect releases the lock on exception, so a raise in the decode
     path (out-of-memory, runtime error, ...) cannot leak the shim's
     serialization invariant. *)
  Mutex.protect mutex (fun () ->
      match request op src with
      | exception Failure msg -> Error (`Hcl_native_error msg)
      | status, payload -> (
          match status with
          | '\x00' -> decode_with of_yojson payload
          | '\x01' -> Error (`Hcl_native_error payload)
          | c ->
              Error
                (`Hcl_native_error
                   (Printf.sprintf "sg_hcl_shim: unknown status byte %d" (Char.code c)))))

let parse_string src = run_op op_parse_file [%of_yojson: Hcl_parser_value.t list] src
let parse_expr_string src = run_op op_parse_expression [%of_yojson: Hcl_parser_value.Expr.t] src

let parse_template_string src =
  run_op op_parse_template [%of_yojson: Hcl_parser_value.Template_part.t list] src
