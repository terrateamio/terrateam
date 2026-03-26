module Status = struct
  let t_of_yojson = function
    | `String "approved" -> Ok `Approved
    | `String "rejected" -> Ok `Rejected
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Approved -> `String "approved"
    | `Rejected -> `String "rejected"

  type t =
    ([ `Approved
     | `Rejected
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  comment : string option; [@default None]
  represented_as : string option; [@default None]
  status : Status.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
