module State = struct
  let t_of_yojson = function
    | `String "accepted" -> Ok `Accepted
    | `String "declined" -> Ok `Declined
    | `String "pending" -> Ok `Pending
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Accepted -> `String "accepted"
    | `Declined -> `String "declined"
    | `Pending -> `String "pending"

  type t =
    ([ `Accepted
     | `Declined
     | `Pending
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  state : State.t;
  type_ : Githubc2_components_security_advisory_credit_types.t; [@key "type"]
  user : Githubc2_components_simple_user.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
