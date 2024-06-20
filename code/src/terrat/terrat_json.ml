module Process = Abb_process.Make (Abb)

type to_yaml_string_err = [ `Error ] [@@deriving show]
type of_yaml_string_err = [ `Error ] [@@deriving show]

let to_yaml_string json =
  let open Abb.Future.Infix_monad in
  Process.check_output
    ~input:(Yojson.Safe.to_string json)
    Abb_intf.Process.{ exec_name = "yj"; args = [ "yj"; "-jy" ]; env = None; cwd = None }
  >>= function
  | Ok (stdout, _) -> Abb.Future.return (Ok stdout)
  | Error #Abb_process.check_output_err -> Abb.Future.return (Error `Error)

let of_yaml_string yaml_str =
  let open Abb.Future.Infix_monad in
  Process.check_output
    ~input:yaml_str
    Abb_intf.Process.{ exec_name = "yj"; args = [ "yj" ]; env = None; cwd = None }
  >>= function
  | Ok (stdout, _) -> (
      try Abb.Future.return (Ok (Yojson.Safe.from_string stdout))
      with Yojson.Json_error _ -> Abb.Future.return (Error `Error))
  | Error #Abb_process.check_output_err -> Abb.Future.return (Error `Error)
