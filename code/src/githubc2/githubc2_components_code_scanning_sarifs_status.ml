module Primary = struct
  module Errors = struct
    type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Processing_status = struct
    let t_of_yojson = function
      | `String "complete" -> Ok `Complete
      | `String "failed" -> Ok `Failed
      | `String "pending" -> Ok `Pending
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Complete -> `String "complete"
      | `Failed -> `String "failed"
      | `Pending -> `String "pending"

    type t =
      ([ `Complete
       | `Failed
       | `Pending
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    analyses_url : string option; [@default None]
    errors : Errors.t option; [@default None]
    processing_status : Processing_status.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
