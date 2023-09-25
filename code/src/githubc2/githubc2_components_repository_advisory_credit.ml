module State = struct
  let t_of_yojson = function
    | `String "accepted" -> Ok "accepted"
    | `String "declined" -> Ok "declined"
    | `String "pending" -> Ok "pending"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  state : State.t;
  type_ : Githubc2_components_security_advisory_credit_types.t; [@key "type"]
  user : Githubc2_components_simple_user.t;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
