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
    batched : bool option; [@default None]
    batches : Gitlabc_components_api_entities_bulkimports_exportbatchstatus.t option;
        [@default None]
    batches_count : int option; [@default None]
    error : string option; [@default None]
    relation : string option; [@default None]
    status : Status.t option; [@default None]
    total_objects_count : int option; [@default None]
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
