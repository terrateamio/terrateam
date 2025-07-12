module Validation_err = struct
  type t = {
    msg : string;
    path : string;
  }
  [@@deriving show]
end

(* External declaration - links to C stub *)
external validate_json_schema_c :
  string -> string -> (unit, Validation_err.t list) result
  = "caml_validate_json_schema"

(* OCaml wrapper that handles the C interface *)
let validate_json_schema ~schema json =
  match validate_json_schema_c schema json with
  | Ok () -> Ok ()
  | Error errors -> Error errors
