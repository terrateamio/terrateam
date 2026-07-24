type t = Uuidm.t

let to_yojson u = `String (Uuidm.to_string u)

let of_yojson = function
  | `String s -> (
      match Uuidm.of_string s with
      | Some u -> Ok u
      | None -> Error (Printf.sprintf "Invalid UUID: %s" s))
  | json -> Error (Printf.sprintf "Expected string, got: %s" (Yojson.Safe.to_string json))

let v4 = Uuidm.v4_gen (Random.State.make_self_init ())
let to_string = Uuidm.to_string
let of_string = Uuidm.of_string
