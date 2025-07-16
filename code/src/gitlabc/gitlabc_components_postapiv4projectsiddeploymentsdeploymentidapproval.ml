module Status = struct
  let t_of_yojson = function
    | `String "approved" -> Ok "approved"
    | `String "rejected" -> Ok "rejected"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  comment : string option; [@default None]
  represented_as : string option; [@default None]
  status : Status.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
