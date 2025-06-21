module Primary = struct
  module Status = struct
    let t_of_yojson = function
      | `String "started" -> Ok "started"
      | `String "finished" -> Ok "finished"
      | `String "failed" -> Ok "failed"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    batch_number : int option; [@default None]
    error : string option; [@default None]
    objects_count : int option; [@default None]
    status : Status.t option; [@default None]
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
